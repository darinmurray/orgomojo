class ConversationManager
  attr_reader :chat_session, :gemini_service, :gemini_tts_service

  def initialize(chat_session)
    @chat_session = chat_session
    @gemini_service = GeminiService.new
    @gemini_tts_service = GeminiTtsService.new
  end

  def start_conversation
    welcome_message = generate_welcome_message
    create_assistant_message(welcome_message, with_audio: true)
  end

  def process_user_message(content)
    # Save user message
    user_message = create_user_message(content)

    # Extract data from the message
    extract_data_from_message(content)

    # Determine next response
    response_content = generate_response(content)

    # Create assistant response with audio
    assistant_message = create_assistant_message(response_content, with_audio: true)

    # Check if conversation should be completed
    check_conversation_completion

    {
      user_message: user_message,
      assistant_message: assistant_message,
      completion_status: chat_session.completion_percentage
    }
  end

  private

  def generate_welcome_message
    prompt = build_welcome_prompt
    gemini_service.generate_text(prompt)
  end

  def generate_response(user_input)
    prompt = build_response_prompt(user_input)
    response = gemini_service.generate_text(prompt)

    # Handle API failures gracefully
    if response.nil? || response.strip.empty?
      handle_api_failure_response(user_input)
    else
      response
    end
  end

  def build_welcome_prompt
    <<~PROMPT
      You are a friendly health and wellness coach helping someone identify their health goals.#{' '}
      Start a conversation by warmly greeting them and asking about their current health situation#{' '}
      and where they'd like to be with their health in the future.

      Keep your response conversational, encouraging, and under 100 words. Ask one specific question#{' '}
      about their current health status or what they want to improve.
    PROMPT
  end

  def build_response_prompt(user_input)
    conversation_history = build_conversation_context
    extracted_data = chat_session.extracted_data_points.includes(:chat_session)
    missing_data = identify_missing_data_categories

    <<~PROMPT
      You are a health and wellness coach having a conversation with someone about their health goals.

      Conversation so far:
      #{conversation_history}

      User just said: "#{user_input}"

      Data we've collected so far:
      #{format_extracted_data(extracted_data)}

      Still need to collect:
      #{missing_data.join(', ')}

      Respond naturally and ask follow-up questions to gather missing information. Focus on:
      - Current health status and challenges
      - Specific tangible goals (weight, fitness levels, measurements)
      - Intangible goals (energy, confidence, wellbeing)
      - Timeline and milestones
      - What motivates them

      Keep your response under 100 words and ask one specific question.
    PROMPT
  end

  def build_conversation_context
    messages = chat_session.chat_messages.chronological.limit(10)
    messages.map { |msg| "#{msg.role.capitalize}: #{msg.content}" }.join("\n")
  end

  def format_extracted_data(data_points)
    return "None yet" if data_points.empty?

    data_points.group_by(&:category).map do |category, points|
      values = points.map(&:value).join(", ")
      "#{category.humanize}: #{values}"
    end.join("\n")
  end

  def identify_missing_data_categories
    collected_categories = chat_session.extracted_data_points.pluck(:category).uniq
    required_categories = %w[health_status tangible_goal intangible_goal current_state target_metrics]
    required_categories - collected_categories
  end

  def extract_data_from_message(content)
    DataExtractionService.new(chat_session).extract_from_text(content)
  end

  def create_user_message(content)
    chat_session.chat_messages.create!(
      role: "user",
      content: content
    )
  end

  def create_assistant_message(content, with_audio: false)
    message = chat_session.chat_messages.create!(
      role: "assistant",
      content: content
    )

    if with_audio
      generate_audio_for_message(message)
    end

    message
  end

  def generate_audio_for_message(message)
    begin
      audio_path = gemini_tts_service.generate_audio(
        message.content,
        filename: "chat_#{chat_session.id}_#{message.id}"
      )
      message.update(audio_file_path: audio_path)
    rescue => e
      Rails.logger.error "Failed to generate audio for message #{message.id}: #{e.message}"
    end
  end

  def check_conversation_completion
    if chat_session.ready_for_completion?
      ConversationFlowService.new(chat_session).generate_action_plan
      chat_session.mark_completed!
    end
  end

  private

  def handle_api_failure_response(user_input)
    # Provide helpful fallback responses when API is unavailable
    fallback_responses = [
      "I appreciate you sharing that with me! I'm having some technical difficulties right now, but I want to make sure I capture your goals properly. Could you tell me a bit more about your current fitness level?",
      "Thanks for that information! I'm experiencing some connectivity issues at the moment. While I work on that, could you share what your main health goal is right now?",
      "I hear you! I'm having some technical troubles, but I don't want to lose momentum in our conversation. What's one thing about your health you'd most like to improve?",
      "That's great input! I'm having some system issues right now, but let's keep going. Could you tell me about any challenges you're facing with your current health routine?"
    ]

    # Use the conversation turn count to vary responses
    response_index = (chat_session.chat_messages.count / 2) % fallback_responses.length
    fallback_responses[response_index]
  end
end
