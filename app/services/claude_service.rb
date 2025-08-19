# app/services/claude_service.rb
require "anthropic"

class ClaudeService
  def initialize
    @client = Anthropic::Client.new(
      api_key: ENV["ANTHROPIC_API_KEY"]
    )
  end

  def analyze_life_area_response(category_name, user_response)
    prompt = build_analysis_prompt(category_name, user_response)

    response = @client.messages.create(
      model: "claude-3-5-sonnet-20241022",
      max_tokens: 1500,
      messages: [
        {
          role: "user",
          content: prompt
        }
      ]
    )

    parse_analysis_response(response.content[0].text)
  rescue => e
    Rails.logger.error "Claude API Error: #{e.message}"
    nil
  end

  def create_actionable_goals(not_working_items, category_name)
    prompt = build_goals_prompt(not_working_items, category_name)

    response = @client.messages.create(
      model: "claude-3-5-sonnet-20241022",
      max_tokens: 1000,
      messages: [
        {
          role: "user",
          content: prompt
        }
      ]
    )

    parse_goals_response(response.content[0].text)
  rescue => e
    Rails.logger.error "Claude Goals API Error: #{e.message}"
    nil
  end

  private

  def build_analysis_prompt(category_name, user_response)
    <<~PROMPT
      I'm helping someone assess their life using the "Wheel of Life" framework. They've responded about the #{category_name} area of their life.

      Their response: "#{user_response}"

      Please analyze this response and break it down into:
      1. What's Working Well (positive aspects they mentioned)
      2. What Needs Improvement (challenges, dissatisfactions, or gaps they mentioned)

      Format your response as JSON:
      {
        "working_well": [
          "specific positive point 1",
          "specific positive point 2"
        ],
        "needs_improvement": [
          "specific challenge or gap 1",
          "specific challenge or gap 2"
        ],
        "overall_satisfaction": "brief 1-2 sentence summary of their overall satisfaction in this area"
      }

      Be specific and actionable. Extract concrete details from their response rather than generic statements.
    PROMPT
  end

  def build_goals_prompt(not_working_items, category_name)
    items_text = not_working_items.map.with_index { |item, index| "#{index + 1}. #{item}" }.join("\n")

    <<~PROMPT
      Based on these challenges in the #{category_name} area of someone's life, create specific, actionable, measurable goals:

      Challenges:
      #{items_text}

      For each challenge, create a SMART goal (Specific, Measurable, Achievable, Relevant, Time-bound) that directly addresses the issue.

      Format as JSON:
      {
        "goals": [
          {
            "addresses_challenge": "the original challenge",
            "goal_title": "Brief, clear goal title (max 8 words)",
            "goal_description": "Specific action with timeframe and measurable outcome",
            "timeframe": "suggested timeframe (daily, weekly, monthly, etc.)",
            "success_metric": "how they'll know they've succeeded"
          }
        ]
      }

      Examples:
      - Challenge: "I want more friends" → Goal: "Attend 2 new social events monthly to meet potential friends"
      - Challenge: "I'm always tired" → Goal: "Establish consistent 10:30 PM bedtime for 30 days"
      - Challenge: "No time for exercise" → Goal: "Schedule 3 weekly 30-minute workout sessions"

      Make goals specific, realistic, and directly actionable.
    PROMPT
  end

  def parse_analysis_response(response_text)
    # Extract JSON from the response
    json_match = response_text.match(/\{.*\}/m)
    return nil unless json_match

    JSON.parse(json_match[0])
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse Claude analysis response: #{e.message}"
    nil
  end

  def parse_goals_response(response_text)
    json_match = response_text.match(/\{.*\}/m)
    return nil unless json_match

    JSON.parse(json_match[0])
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse Claude goals response: #{e.message}"
    nil
  end
end
