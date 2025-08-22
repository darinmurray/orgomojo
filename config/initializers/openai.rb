if ENV["OPENAI_API_KEY"].present?
  OpenAI.configure do |config|
    config.access_token = ENV["OPENAI_API_KEY"]
    config.log_errors = true # recommended for development
  end
end
