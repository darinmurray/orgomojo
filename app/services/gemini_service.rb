# app/services/gemini_service.rb
require "gemini-ai"

class GeminiService
  def initialize
    @client = Gemini.new(
      credentials: {
        service: "generative-language-api",
        api_key: ENV["GOOGLE_API_KEY"]
      },
      options: {
        model: "gemini-1.5-flash",
        server_sent_events: false
      }
    )
  end

  def generate_text(prompt)
    result = @client.generate_content({
      contents: [ {
        parts: [ { text: prompt } ]
      } ]
    })

    result.dig("candidates", 0, "content", "parts", 0, "text")
  rescue => e
    Rails.logger.error "Gemini API Error: #{e.message}"
    puts "Full error: #{e.inspect}"

    # Log specific error types for better debugging
    if e.message.include?("429") || e.message.include?("quota")
      Rails.logger.warn "Gemini API quota exceeded - consider upgrading plan or waiting for reset"
    end

    nil
  end

  def api_available?
    # Simple test to check if API is responding
    result = generate_text("Test")
    !result.nil?
  rescue
    false
  end
end
