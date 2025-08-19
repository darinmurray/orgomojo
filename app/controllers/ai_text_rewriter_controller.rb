class AiTextRewriterController < ApplicationController
  def generate_first_degree
    Rails.logger.info "=== AI Text Rewriter Debug ==="
    Rails.logger.info "Received focus_word: #{params[:focus_word]}"

    focus_word = params[:focus_word]
    association_strength = params[:association_strength]&.to_i || 3


    Rails.logger.info "=== AI Text Rewriter Debug ==="
    Rails.logger.info "Received focus_word: #{focus_word}"
    Rails.logger.info "Received association_strength: #{association_strength}"

    if focus_word.blank?
      Rails.logger.error "Focus word is blank"
      render json: { error: "Focus word is required" }, status: :bad_request
      return
    end

    begin
      Rails.logger.info "Creating AI service..."
      ai_service = AiTextRewriter.new  # Remove "Services::" - it's just AiTextRewriter
      Rails.logger.info "AI service created successfully"

      Rails.logger.info "Calling generate_first_degree with: #{focus_word}, #{association_strength}"
      response = ai_service.generate_first_degree(focus_word, association_strength)
      Rails.logger.info "AI response received: #{response}"

      # Parse the AI response to extract the array of words
      first_degree_words = parse_ai_response(response)
      Rails.logger.info "Parsed words: #{first_degree_words}"

      render json: {
        focus_word: focus_word,
        first_degree_words: first_degree_words
      }
    rescue => e
      Rails.logger.error "AI generation error: #{e.class}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: "Failed to generate words: #{e.message}" }, status: :internal_server_error
    end

    response = ai_service.generate_first_degree(focus_word, association_strength)
  end




def generate_second_degree
  first_degree_words = params[:first_degree_words]
  focus_word = params[:focus_word] || "unknown"  # Get focus word from params
  association_strength = params[:association_strength]&.to_i || 3

  Rails.logger.info "=== Generating Second Degree Words ==="
  Rails.logger.info "Received first_degree_words: #{first_degree_words}"
  Rails.logger.info "Received focus_word: #{focus_word}"
  Rails.logger.info "Received association_strength: #{association_strength}"


  if first_degree_words.blank? || !first_degree_words.is_a?(Array)
    render json: { error: "First degree words array is required" }, status: :bad_request
    return
  end

  begin
    ai_service = AiTextRewriter.new
    Rails.logger.info "Calling generate_second_degree with: #{first_degree_words}, #{focus_word}, #{association_strength}"
    response = ai_service.generate_second_degree(first_degree_words, focus_word, association_strength)
    Rails.logger.info "AI response: #{response}"

    # Simplified parsing - no filtering needed
    second_degree_links = parse_second_degree_response_simple(response)
    Rails.logger.info "Parsed second degree links: #{second_degree_links}"

    render json: {
      first_degree_words: first_degree_words,
      second_degree_links: second_degree_links
    }
  rescue => e
    Rails.logger.error "Second degree generation error: #{e.message}"
    render json: { error: "Failed to generate second degree words: #{e.message}" }, status: :internal_server_error
  end

  response = ai_service.generate_second_degree(first_degree_words, focus_word, association_strength)
end



def parse_second_degree_response_simple(response)
  Rails.logger.info "Raw AI response: #{response}"

  begin
    # Clean the response - remove any markdown formatting
    cleaned_response = response.gsub(/```json|```/, "").strip
    Rails.logger.info "Cleaned response: #{cleaned_response}"

    # Try to parse as JSON
    if cleaned_response.match(/\{.*\}/m)
      json_match = cleaned_response.match(/(\{.*\})/m)
      if json_match
        parsed = JSON.parse(json_match[1])
        Rails.logger.info "Successfully parsed JSON: #{parsed}"

        # Simple normalization - no filtering needed since AI was instructed to avoid conflicts
        normalized = {}
        parsed.each do |key, value|
          clean_key = key.downcase.strip
          clean_values = value.is_a?(Array) ? value.map(&:strip).map(&:capitalize) : [ value.to_s.strip.capitalize ]
          normalized[clean_key] = clean_values.first(2)  # Ensure max 2 words
        end

        return normalized
      end
    end

    Rails.logger.warn "Could not parse JSON, returning empty hash"
    {}

  rescue => e
    Rails.logger.error "Parse error: #{e.message}"
    {}
  end
end





def generate_storyline
  focus_word = params[:focus_word]
  second_degree_word = params[:second_degree_word]
  storyline_length = params[:storyline_length]&.to_i || 15
  perspective = params[:perspective]&.to_i || 15
  age = params[:age]&.to_i || 3
  phrase_type = params[:phrase_type]&.to_i || 1

  if focus_word.blank? || second_degree_word.blank?
    render json: { error: "Both focus word and second degree word are required" }, status: :bad_request
    return
  end

  begin
    ai_service = AiTextRewriter.new
    storyline_text = ai_service.generate_storyline(focus_word, second_degree_word, storyline_length, perspective, age, phrase_type)

    render json: {
      storyline: storyline_text,
      focus_word: focus_word,
      second_degree_word: second_degree_word,
      storyline_length: storyline_length,
      perspective: perspective,
      age: age,
      phrase_type: phrase_type
    }
  rescue => e
    Rails.logger.error "Error generating storyline: #{e.message}"
    render json: { error: "Failed to generate storyline" }, status: :internal_server_error
  end
end


def debug_methods
  render json: {
    methods: self.class.instance_methods(false),
    has_generate_storyline: respond_to?(:generate_storyline)
  }
end

def analyze_core_value
  candidate = params[:candidate]

  if candidate.blank?
    render json: { error: "Candidate text is required" }, status: :bad_request
    return
  end

  begin
    ai_service = AiTextRewriter.new
    analysis_result = ai_service.core_value_or_not(candidate)

    # Check if the analysis indicates it's a core value
    is_core_value = analysis_result.downcase.include?("is a core value because")

    render json: {
      success: true,
      analysis: analysis_result,
      candidate: candidate,
      is_core_value: is_core_value
    }
  rescue => e
    Rails.logger.error "Error analyzing core value: #{e.message}"
    render json: {
      success: false,
      error: "Failed to analyze core value"
    }, status: :internal_server_error
  end
end

def create_core_value
  candidate = params[:candidate]

  if candidate.blank?
    render json: { error: "Candidate text is required" }, status: :bad_request
    return
  end

  begin
    # Check if core value already exists
    existing_value = CoreValue.find_by("LOWER(name) = ?", candidate.downcase)
    if existing_value
      render json: {
        success: false,
        error: "A core value with this name already exists."
      }, status: :unprocessable_entity
      return
    end

    # Generate AI data for the core value
    ai_service = AiTextRewriter.new
    ai_response = ai_service.generate_core_value_data(candidate)

    # Parse the AI response
    core_value_data = parse_core_value_data(ai_response)

    # Create the core value
    core_value = CoreValue.create!(
      name: core_value_data[:name],
      description: core_value_data[:description],
      examples: core_value_data[:examples]
    )

    render json: {
      success: true,
      message: "Core value '#{core_value.name}' has been created successfully!",
      core_value: {
        id: core_value.id,
        name: core_value.name,
        description: core_value.description,
        examples: core_value.examples
      }
    }
  rescue => e
    Rails.logger.error "Error creating core value: #{e.message}"
    render json: {
      success: false,
      error: "Failed to create core value: #{e.message}"
    }, status: :internal_server_error
  end
end



  private

  def parse_ai_response(response)
    begin
      # Try to extract JSON array from response
      if response.match(/\[.*\]/)
        array_match = response.match(/\[(.*)\]/)
        if array_match
          # Parse the array string
          words_string = array_match[1]
          words = words_string.split(",").map { |word| word.strip.gsub(/["']/, "") }
          return words.first(5) # Ensure max 5 words
        end
      end

      # Fallback: split by common delimiters and clean up
      words = response.split(/[,\n]/).map(&:strip).reject(&:blank?)
      words = words.map { |word| word.gsub(/[^\w\s]/, "").strip }.reject(&:blank?)
      words.first(5)
    rescue
      # Fallback to default words if parsing fails
      [ "related", "concept", "idea", "theme", "topic" ]
    end
  end


def parse_second_degree_response(response, first_degree_words)
  Rails.logger.info "Raw AI response: #{response}"

  # Create exclusion lists
  focus_word = params[:focus_word]&.downcase || "cookie"
  excluded_words = (first_degree_words.map(&:downcase) + [ focus_word ]).uniq
  Rails.logger.info "Excluded words: #{excluded_words}"

  begin
    # Clean the response - remove any markdown formatting
    cleaned_response = response.gsub(/```json|```/, "").strip
    Rails.logger.info "Cleaned response: #{cleaned_response}"

    # Try to parse as JSON
    if cleaned_response.match(/\{.*\}/m)
      json_match = cleaned_response.match(/(\{.*\})/m)
      if json_match
        parsed = JSON.parse(json_match[1])
        Rails.logger.info "Successfully parsed JSON: #{parsed}"

        # Normalize and filter
        normalized = {}
        parsed.each do |key, value|
          clean_key = key.downcase.strip
          next if excluded_words.include?(clean_key)

          # Filter and clean values
          clean_values = filter_duplicates_and_exclusions(value, excluded_words)
          normalized[clean_key] = clean_values if clean_values.length >= 2
          Rails.logger.info "Normalized: #{clean_key} => #{clean_values}"
        end
        return normalized
      end
    end

    Rails.logger.warn "Could not parse JSON, using fallback"
    create_filtered_fallback(first_degree_words, excluded_words)

  rescue => e
    Rails.logger.error "Parse error: #{e.message}"
    create_filtered_fallback(first_degree_words, excluded_words)
  end
end

private

def filter_duplicates_and_exclusions(values, excluded_words)
  clean_values = values.is_a?(Array) ? values.map(&:strip).map(&:downcase) : [ values.to_s.strip.downcase ]

  # Remove excluded words
  clean_values = clean_values.reject { |word| excluded_words.include?(word) }

  # Remove plural/singular duplicates
  filtered_values = []
  clean_values.each do |word|
    # Check if this word is a plural/singular variant of any already added word
    is_duplicate = filtered_values.any? do |existing|
      words_are_variants?(word, existing)
    end

    filtered_values << word unless is_duplicate
  end

  # Capitalize first letter for display
  filtered_values.map(&:capitalize).first(2)
end

def words_are_variants?(word1, word2)
  return true if word1 == word2

  # Check common plural patterns
  singular_patterns = [
    [ word1, word1 + "s" ],
    [ word1, word1 + "es" ],
    [ word1, word1.chomp("y") + "ies" ],
    [ word1, word1 + "ies" ]
  ]

  singular_patterns.each do |singular, plural|
    return true if (word1 == singular && word2 == plural) || (word1 == plural && word2 == singular)
  end

  false
end

def create_filtered_fallback(first_degree_words, excluded_words)
  fallback_options = {
    "biscuit" => [ "crumb", "butter", "jam", "tea" ],
    "baking" => [ "oven", "flour", "recipe", "timer" ],
    "dessert" => [ "cake", "pie", "cream", "fruit" ],
    "chocolate" => [ "cocoa", "dark", "milk", "bar" ],
    "snack" => [ "munch", "nibble", "bite", "quick" ]
  }

  fallback = {}
  first_degree_words.each do |word|
    clean_word = word.downcase
    next if excluded_words.include?(clean_word)

    available_options = fallback_options[clean_word] || [ "item", "thing", "object", "element" ]
    filtered_options = available_options.reject { |opt| excluded_words.include?(opt.downcase) }
    fallback[clean_word] = filtered_options.first(2).map(&:capitalize)
  end

  fallback
end

def parse_core_value_data(ai_response)
  begin
    # Clean the response - remove any markdown formatting
    cleaned_response = ai_response.gsub(/```json|```/, "").strip

    # Try to parse as JSON
    if cleaned_response.match(/\{.*\}/m)
      json_match = cleaned_response.match(/(\{.*\})/m)
      if json_match
        parsed = JSON.parse(json_match[1])

        return {
          name: parsed["name"]&.strip || "Unknown Value",
          description: parsed["description"]&.strip || "A meaningful core value.",
          examples: parsed["examples"]&.is_a?(Array) ? parsed["examples"].map(&:strip) : [ "Live with purpose", "Make ethical choices", "Stay true to yourself" ]
        }
      end
    end

    # Fallback if parsing fails
    candidate = params[:candidate] || "Value"
    {
      name: candidate.strip.titleize,
      description: "A meaningful personal value.",
      examples: [ "Live with purpose", "Make ethical choices", "Stay true to yourself" ]
    }
  rescue => e
    Rails.logger.error "Error parsing core value data: #{e.message}"

    # Fallback if parsing fails
    candidate = params[:candidate] || "Value"
    {
      name: candidate.strip.titleize,
      description: "A meaningful personal value.",
      examples: [ "Live with purpose", "Make ethical choices", "Stay true to yourself" ]
    }
  end
end
end
