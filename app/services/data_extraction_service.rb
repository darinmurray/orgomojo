class DataExtractionService
  attr_reader :chat_session, :gemini_service

  def initialize(chat_session)
    @chat_session = chat_session
    @gemini_service = GeminiService.new
  end

  def extract_from_text(text)
    prompt = build_extraction_prompt(text)
    response = gemini_service.generate_text(prompt)

    # Handle nil or empty response from API
    if response.nil? || response.strip.empty?
      Rails.logger.error "Empty or nil response from Gemini API"
      return []
    end

    begin
      extracted_data = JSON.parse(response)
      save_extracted_data(extracted_data)
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse extraction response: #{e.message}"
      Rails.logger.error "Response was: #{response}"
      []
    end
  end

  private

  def build_extraction_prompt(text)
    conversation_context = build_conversation_context

    <<~PROMPT
      Extract structured health-related data from this user message. Return ONLY valid JSON with this exact structure:

      {
        "data_points": [
          {
            "category": "category_name",
            "data_type": "data_type",
            "value": "extracted_value",
            "confidence_score": 0.8,
            "context": "relevant_context"
          }
        ]
      }

      Categories to look for:
      - health_status: Current health condition, symptoms, diagnoses
      - tangible_goal: Specific measurable goals (weight loss, fitness level, measurements)
      - intangible_goal: Feeling-based goals (energy, confidence, mood)
      - current_state: Current measurements, habits, fitness level
      - target_metrics: Specific numbers they want to achieve
      - timeline: When they want to achieve goals
      - obstacles: Challenges or barriers they mention
      - motivation: Why they want to change
      - support_system: People or resources helping them
      - past_experience: Previous attempts or experience

      Data types: text, number, weight, distance, duration, percentage, date, boolean, list

      User message: "#{text}"

      Previous conversation context:
      #{conversation_context}

      Extract only clear, specific information. Use confidence_score between 0.0-1.0.
    PROMPT
  end

  def build_conversation_context
    recent_messages = chat_session.chat_messages.chronological.limit(5)
    recent_messages.map { |msg| "#{msg.role}: #{msg.content}" }.join("\n")
  end

  def save_extracted_data(extracted_data)
    return [] unless extracted_data["data_points"].is_a?(Array)

    saved_points = []

    extracted_data["data_points"].each do |point|
      next unless valid_data_point?(point)

      # Check if similar data point already exists
      existing_point = find_existing_data_point(point)

      if existing_point
        update_existing_data_point(existing_point, point)
        saved_points << existing_point
      else
        saved_points << create_new_data_point(point)
      end
    end

    saved_points
  end

  def valid_data_point?(point)
    point.is_a?(Hash) &&
      point["category"].present? &&
      point["value"].present? &&
      ExtractedDataPoint::CATEGORIES.include?(point["category"])
  end

  def find_existing_data_point(point)
    chat_session.extracted_data_points.find_by(
      category: point["category"],
      data_type: point["data_type"]
    )
  end

  def update_existing_data_point(existing_point, new_point)
    # Update if new confidence is higher or add to existing value
    if new_point["confidence_score"].to_f > existing_point.confidence_score.to_f
      existing_point.update!(
        value: new_point["value"],
        confidence_score: new_point["confidence_score"],
        context: merge_context(existing_point.context, new_point["context"])
      )
    end
  end

  def create_new_data_point(point)
    chat_session.extracted_data_points.create!(
      category: point["category"],
      data_type: point["data_type"] || "text",
      value: point["value"],
      confidence_score: point["confidence_score"] || 0.5,
      context: { "extracted_from" => point["context"] || "user_message" }
    )
  end

  def merge_context(existing_context, new_context)
    existing = existing_context || {}
    existing["additional_context"] = new_context if new_context.present?
    existing
  end
end
