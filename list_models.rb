#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'

# List available Gemini models
api_key = ENV['GOOGLE_API_KEY']
uri = URI("https://generativelanguage.googleapis.com/v1beta/models")

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

request = Net::HTTP::Get.new(uri)
request["x-goog-api-key"] = api_key
response = http.request(request)

if response.code == "200"
  result = JSON.parse(response.body)

  puts "Available Gemini models:"
  puts "========================"

  result["models"]&.each do |model|
    name = model["name"]
    methods = model["supportedGenerationMethods"]

    # Look for TTS-related models
    if name.include?("tts") || methods&.include?("generateContent")
      puts "\nModel: #{name}"
      puts "  Supported methods: #{methods}"
      puts "  Description: #{model['description']}" if model['description']
    end
  end

  # Also show all models that support generateContent for debugging
  puts "\n\nAll models with generateContent support:"
  puts "========================================"

  result["models"]&.each do |model|
    name = model["name"]
    methods = model["supportedGenerationMethods"]

    if methods&.include?("generateContent")
      puts "- #{name}"
    end
  end
else
  puts "Error: #{response.code} - #{response.body}"
end
