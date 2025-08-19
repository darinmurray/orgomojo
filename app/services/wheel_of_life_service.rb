# app/services/wheel_of_life_service.rb
class WheelOfLifeService
  def initialize(user)
    @user = user
    @claude = ClaudeService.new
    @tts = GeminiTtsService.new # Your existing TTS service
  end

  def process_category_response(category_id, response_text)
    category = LifeCategory.find(category_id)

    # Create user response record
    user_response = @user.user_responses.create!(
      life_category: category,
      raw_response: response_text,
      status: "pending"
    )

    # Analyze with Claude
    analysis = @claude.analyze_life_area_response(category.name, response_text)
    return nil unless analysis

    # Update response with analysis
    user_response.update!(
      analysis_data: analysis,
      status: "analyzed"
    )

    # Create actionable goals from "needs improvement" items
    if analysis["needs_improvement"].any?
      goals_data = @claude.create_actionable_goals(
        analysis["needs_improvement"],
        category.name
      )

      if goals_data && goals_data["goals"]
        create_life_goals(user_response, goals_data["goals"])
        user_response.update!(status: "goals_created")
      end
    end

    user_response.reload
  end

  def generate_audio_summary(user_response)
    summary_text = build_audio_summary(user_response)

    # Use your existing Gemini TTS service
    audio_file_path = "public/audio/wheel_summary_#{user_response.id}.wav"
    @tts.save_speech_to_file(summary_text, audio_file_path, "Kore")

    audio_file_path if File.exist?(audio_file_path)
  end

  private

  def create_life_goals(user_response, goals_data)
    goals_data.each do |goal_data|
      user_response.life_goals.create!(
        life_category: user_response.life_category,
        title: goal_data["goal_title"],
        description: goal_data["goal_description"],
        timeframe: goal_data["timeframe"],
        success_metric: goal_data["success_metric"],
        addresses_challenge: goal_data["addresses_challenge"],
        goal_type: "improvement"
      )
    end
  end

  def build_audio_summary(user_response)
    analysis = user_response.analysis_data
    category_name = user_response.life_category.name.humanize

    summary = "Here's your #{category_name} life area summary. "

    working_well = Array(analysis["working_well"])
    if working_well.any?
      summary += "What's working well: #{working_well.join(', ')}. "
    end

    needs_improvement = Array(analysis["needs_improvement"])
    if needs_improvement.any?
      summary += "Areas for improvement: #{needs_improvement.join(', ')}. "

      goals_count = user_response.life_goals.count
      if goals_count > 0
        summary += "I've created #{goals_count} actionable goals to help you improve in this area."
      end
    end

    summary
  end
end
