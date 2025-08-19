class ConversationFlowService
  attr_reader :chat_session, :gemini_service

  def initialize(chat_session)
    @chat_session = chat_session
    @gemini_service = GeminiService.new
  end

  def determine_next_question
    missing_data = identify_missing_critical_data

    if missing_data.any?
      generate_targeted_question(missing_data.first)
    else
      generate_clarification_question
    end
  end

  def generate_action_plan
    prompt = build_action_plan_prompt
    action_plan = gemini_service.generate_text(prompt)

    # Store the action plan in the chat session
    chat_session.update_conversation_state("action_plan", action_plan)
    chat_session.update_conversation_state("action_plan_generated_at", Time.current.iso8601)

    # Create final message with the action plan
    create_action_plan_message(action_plan)

    action_plan
  end

  def conversation_completion_score
    required_categories = %w[health_status tangible_goal intangible_goal current_state target_metrics]
    collected_categories = chat_session.extracted_data_points.pluck(:category).uniq

    score = (collected_categories & required_categories).length.to_f / required_categories.length
    (score * 100).round
  end

  private

  def analyze_conversation_state
    {
      message_count: chat_session.messages_count,
      data_points_count: chat_session.extracted_data_points.count,
      categories_covered: chat_session.extracted_data_points.pluck(:category).uniq,
      conversation_depth: calculate_conversation_depth
    }
  end

  def calculate_conversation_depth
    # Simple metric based on average message length and follow-up questions
    avg_message_length = chat_session.chat_messages.user_messages.average("LENGTH(content)") || 0
    case avg_message_length
    when 0..20 then "shallow"
    when 21..50 then "moderate"
    else "deep"
    end
  end

  def identify_missing_critical_data
    required_categories = %w[health_status tangible_goal intangible_goal current_state target_metrics timeline motivation]
    collected_categories = chat_session.extracted_data_points.pluck(:category).uniq

    missing = required_categories - collected_categories

    # Prioritize based on conversation flow
    priority_order = %w[health_status current_state tangible_goal intangible_goal target_metrics timeline motivation]
    missing.sort_by { |cat| priority_order.index(cat) || 999 }
  end

  def generate_targeted_question(category)
    prompt = build_targeted_question_prompt(category)
    gemini_service.generate_text(prompt)
  end

  def generate_clarification_question
    prompt = build_clarification_prompt
    gemini_service.generate_text(prompt)
  end

  def build_targeted_question_prompt(category)
    conversation_context = build_conversation_context
    existing_data = format_existing_data

    question_guides = {
      "health_status" => "Ask about their current health situation, any concerns, or conditions they want to address.",
      "current_state" => "Ask about their current fitness level, weight, energy levels, or health measurements.",
      "tangible_goal" => "Ask about specific, measurable goals like target weight, fitness milestones, or health metrics.",
      "intangible_goal" => "Ask about how they want to feel - energy levels, confidence, mood, or overall wellbeing.",
      "target_metrics" => "Ask for specific numbers or measurements they want to achieve.",
      "timeline" => "Ask about when they want to achieve their goals and any important deadlines.",
      "motivation" => "Ask about why these changes are important to them and what drives their commitment."
    }

    <<~PROMPT
      You are a health coach continuing a conversation. You need to ask about: #{category.humanize}

      #{question_guides[category]}

      Current conversation:
      #{conversation_context}

      Data collected so far:
      #{existing_data}

      Ask a natural, conversational question to gather information about #{category.humanize}.#{' '}
      Keep it under 50 words and make it feel like a natural follow-up to the conversation.
    PROMPT
  end

  def build_clarification_prompt
    conversation_context = build_conversation_context
    existing_data = format_existing_data

    <<~PROMPT
      You are a health coach. You have gathered good information but need to clarify or get more#{' '}
      specific details to create an effective action plan.

      Conversation:
      #{conversation_context}

      Data collected:
      #{existing_data}

      Ask a follow-up question to clarify goals, get more specific details, or understand#{' '}
      priorities better. Keep it under 50 words.
    PROMPT
  end

  def build_action_plan_prompt
    conversation_context = build_conversation_context
    extracted_data = format_extracted_data_for_plan

    <<~PROMPT
      Based on this health conversation, create a personalized action plan with specific,#{' '}
      actionable steps to help them achieve their health goals.

      Conversation summary:
      #{conversation_context}

      Extracted data:
      #{extracted_data}

      Create an action plan that includes:
      1. 3-5 specific, actionable steps they can take immediately
      2. Weekly milestones for the first month
      3. Suggestions for tracking progress
      4. Tips for overcoming potential obstacles
      5. When to reassess and adjust the plan

      Make it personal, specific, and achievable based on their stated goals and current situation.
      Format it clearly with headers and bullet points.
    PROMPT
  end

  def build_conversation_context
    messages = chat_session.chat_messages.chronological.limit(10)
    messages.map { |msg| "#{msg.role.capitalize}: #{msg.content}" }.join("\n")
  end

  def format_existing_data
    ExtractedDataPoint.for_session_summary(chat_session)
      .map { |category, values| "#{category.humanize}: #{values}" }
      .join("\n")
  end

  def format_extracted_data_for_plan
    chat_session.extracted_data_points.group_by(&:category).map do |category, points|
      values = points.map { |p| "#{p.value} (confidence: #{p.confidence_score})" }.join(", ")
      "#{category.humanize}: #{values}"
    end.join("\n")
  end

  def create_action_plan_message(action_plan)
    chat_session.chat_messages.create!(
      role: "assistant",
      content: "Great! Based on our conversation, I've created a personalized action plan for you:\n\n#{action_plan}",
      metadata: { message_type: "action_plan", generated_at: Time.current.iso8601 }
    )
  end
end
