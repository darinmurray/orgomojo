# app/controllers/wheel_of_life_controller.rb
class WheelOfLifeController < ApplicationController
def index
  # Temporarily bypass authentication for testing
  @categories = LifeCategory.all

  # Get a user for testing or use first user
  user = User.first
  @user_responses = user&.user_responses&.includes(:life_category, :life_goals) || []

  # Format categories for JavaScript
  @categories_data = @categories.map do |cat|
    {
      id: cat.id,
      name: cat.name&.humanize || "Unknown Category",
      prompt: cat.prompt_template || "No prompt available"
    }
  end

  Rails.logger.info "Categories data: #{@categories_data.inspect}"
  Rails.logger.info "Categories JSON: #{@categories_data.to_json}"
end

  def show_category
    @category = LifeCategory.find(params[:id])
    @user_response = current_user.user_responses.where(life_category: @category).last
  end

  def process_response
    @category = LifeCategory.find(params[:category_id])
    response_text = params[:response_text]

    if response_text.blank?
      render json: { error: "Response cannot be blank" }, status: 422
      return
    end

    service = WheelOfLifeService.new(current_user)
    user_response = service.process_category_response(@category.id, response_text)

    if user_response
      # Skip audio generation to save tokens
      # audio_path = service.generate_audio_summary(user_response)

      render json: {
        success: true,
        analysis: user_response.analysis_data,
        goals: user_response.life_goals.map do |goal|
          {
            title: goal.title,
            description: goal.description,
            timeframe: goal.timeframe,
            success_metric: goal.success_metric,
            addresses_challenge: goal.addresses_challenge
          }
        end,
        audio_url: nil,
        overall_satisfaction: user_response.analysis_data["overall_satisfaction"]
      }
    else
      render json: { error: "Failed to process response" }, status: 500
    end
  end

  def get_audio_summary
    @user_response = current_user.user_responses.find(params[:response_id])
    service = WheelOfLifeService.new(current_user)

    audio_path = service.generate_audio_summary(@user_response)

    if audio_path
      render json: { audio_url: "/#{audio_path}" }
    else
      render json: { error: "Failed to generate audio" }, status: 500
    end
  end
end
