# app/services/ai_text_rewriter.rb

class AiTextRewriter
  def initialize(client = nil)
    @client = client || (ENV["OPENAI_API_KEY"].present? ? OpenAI::Client.new : nil)
  end

  def api_available?
    @client.present?
  end


  def rewrite_element(text, slice_name)
    return text unless api_available?
    
    length = 9
    prompt = "Rewrite the text as an attainable element of #{slice_name}:\n\n#{text}. Make it concise and actionable. It should have a clear, tangible outcome. Use #{length} words or less. If it is already well written, only change the word length if necessary"
    response = @client.chat(
      parameters: {
        model: "gpt-4o",
        messages: [ { role: "user", content: prompt } ]
      }
    )
    response.dig("choices", 0, "message", "content")
  rescue => e
    Rails.logger.error "OpenAI API Error: #{e.message}"
    text # Return original text if API fails
  end


  def rewrite(text, target_tense:)
    prompt = "Rewrite the following text in #{target_tense} tense as if it is already so:\n\n#{text}"
    response = @client.chat(
      parameters: {
        model: "gpt-4o",
        messages: [ { role: "user", content: prompt } ]
      }
    )
    response.dig("choices", 0, "message", "content")
  end



def suggest_objective(element, word_count = 30)
  length = word_count
  prompt = "Please state why achieving this goal: '#{element.name}' is good for me and/or how it will make me feel better in the scope of #{element.pie_slice.name}. Use #{length} words or less. Speak from the first person perspective."

  response = @client.chat(
    parameters: {
      model: "gpt-4o",
      messages: [ { role: "user", content: prompt } ]
    }
  )
  response.dig("choices", 0, "message", "content")
end









def check_tangibility(objective, include_reasoning: false)
  if include_reasoning
    # Build the prompt content for detailed response
    prompt_content = "Determine if '#{objective}' is tangible (specific measurable outcome) or intangible (like a 'way of being', or developing a habit, or adopting a new mindset). First return 'true' or 'false' on the first line, then provide a brief explanation of your reasoning on the second line."

    response = @client.chat(
      parameters: {
        model: "gpt-4o",
        messages: [
          {
            role: "system",
            content: "You are a self help guru who expertly guides clients to fulfill their objectives. Provide clear, concise explanations."
          },
          {
            role: "user",
            content: prompt_content
          }
        ]
      }
    )
    response.dig("choices", 0, "message", "content")
  else
    # Build the prompt content separately to avoid nested interpolation
    prompt_content = "Determine if the #{objective} is tangible (specific measurable outcome) or intangible (like a 'way of being', or developing a habit, or adopting a new mindset). return 'true' if it is tangible, 'false' if it is intangible. Do not return any other text."

    response = @client.chat(
      parameters: {
        model: "gpt-4o",
        messages: [
          {
            role: "system",
            content: "You are a self help guru who expertly guides clients to fulfill their objectives. No explanations."
          },
          {
            role: "user",
            content: prompt_content
          }
        ]
      }
    )
    response.dig("choices", 0, "message", "content")
  end
end







def make_it_tangible(objective)
    # Build the prompt content for detailed response
    prompt_content = "rewrite '#{objective}' so that it is tangible (specific, actionable, measurable outcome), then provide a brief explanation of your reasoning on the second line."

    response = @client.chat(
      parameters: {
        model: "gpt-4o",
        messages: [
          {
            role: "system",
            content: "You are a self help guru who expertly guides clients to fulfill their objectives. Provide clear, concise explanations."
          },
          {
            role: "user",
            content: prompt_content
          }
        ]
      }
    )
    response.dig("choices", 0, "message", "content")
end




def habit_or_milestone(objective)
    # Build the prompt content separately to avoid nested interpolation
    prompt_content = "Determine if the #{objective} is a milestone (specific measurable outcome with an end) or a habit (doing something on a repeatable time frame). return 'habit' if it is a habit, 'milestone' if it is a milestone. Do not return any other text."

    response = @client.chat(
      parameters: {
        model: "gpt-4o",
        messages: [
          {
            role: "system",
            content: "You are a self help guru and project planner who expertly guides clients to write their goals. No explanations."
          },
          {
            role: "user",
            content: prompt_content
          }
        ]
      }
    )
    response.dig("choices", 0, "message", "content")
end




def generate_first_degree(focus_word, association_strength)
  first_degree_length = 5
  first_degree_characters = 12

  # Define association guidance based on strength
  association_guidance = case association_strength
  when 1
    "very loosely related - think of random, creative, or unexpected connections"
  when 2
    "loosely related - think of indirect connections or things that might remind you of the word"
  when 3
    "moderately related - clear connections but not too obvious"
  when 4
    "closely related - obvious direct connections"
  when 5
    "very closely related - direct, technical, or clinical associations"
  else
    "moderately related - clear connections but not too obvious"
  end

  # Build the prompt content separately to avoid nested interpolation
  prompt_content = "Generate exactly #{first_degree_length} single words that are #{association_guidance} to '#{focus_word}'. Each word must be #{first_degree_characters} characters or less. Return format: [\"word1\", \"word2\", \"word3\", \"word4\", \"word5\"]"

  response = @client.chat(
    parameters: {
      model: "gpt-4o",
      messages: [
        {
          role: "system",
          content: "You are a word association expert. Return only valid JSON arrays. No explanations."
        },
        {
          role: "user",
          content: prompt_content
        }
      ]
    }
  )
  response.dig("choices", 0, "message", "content")
end









def generate_second_degree(first_degree_words, focus_word, association_strength)
  second_degree_length = 2
  second_degree_characters = 12

  # Create exclusion list
  excluded_words = first_degree_words.map(&:downcase) + [ focus_word.downcase ]
  exclusion_text = excluded_words.join(", ")

  # Define association guidance based on strength
  association_guidance = case association_strength
  when 1
    "very loosely related - think of random, creative, or unexpected connections"
  when 2
    "loosely related - think of indirect connections or things that might remind you of each word"
  when 3
    "moderately related - clear connections but not too obvious"
  when 4
    "closely related - obvious direct connections"
  when 5
    "very closely related - direct, technical, or clinical associations"
  else
    "moderately related - clear connections but not too obvious"
  end

  # Build the prompt content separately to avoid nested interpolation
  words_list = first_degree_words.join(", ")
  prompt_content = "For each word in this list: #{words_list}, generate exactly #{second_degree_length} words that are #{association_guidance}. Max #{second_degree_characters} chars each. Do NOT use these exact words: #{exclusion_text}. Return JSON format: {\"puppy\": [\"tail\", \"playful\"], \"canine\": [\"teeth\", \"wild\"]}"

  response = @client.chat(
    parameters: {
      model: "gpt-4o",
      messages: [
        {
          role: "system",
          content: "You are a word association expert. Return only valid JSON. No explanations."
        },
        {
          role: "user",
          content: prompt_content
        }
      ]
    }
  )
  response.dig("choices", 0, "message", "content")
end







# Add this method to your app/services/ai_text_rewriter.rb file:

def generate_storyline(focus_word, second_degree_word, storyline_length, perspective, age, phrase_type)
# Define perspective guidance based on perspective

phrase_type_guidance = case phrase_type
when 1
  "Personal Brand Slogan - memorable, identity-focused phrase that captures someone's unique value and personality"
when 2
  "Product Tagline - catchy, commercial phrase designed to sell and make the product instantly recognizable"
when 3
  "Novel Plot - narrative-driven concept that tells a story with characters, conflict, and dramatic tension"
when 4
  "Marketing Ploy - strategic, persuasive angle designed to grab attention and drive consumer action"
when 5
  "Episodic Show - serialized entertainment concept with recurring themes, characters, and episode potential"
when 6
  "Stand-up Idea - comedic premise with punchline potential, observational humor, and audience appeal"
else
  "Personal Brand Slogan - memorable, identity-focused phrase that captures someone's unique value and personality"
end


perspective_guidance = case perspective
when 1
  "Stoner - relaxed, stream-of-consciousness thinking with unexpected creative leaps and unconventional associations"
when 2
  "Comedian - witty, humorous perspective that finds funny connections and entertaining wordplay"
when 3
  "Airhead - simple, surface-level thinking with obvious or stereotypical associations"
when 4
  "Amateur - basic knowledge with simple, straightforward connections based on common understanding"
when 5
  "Professional - knowledgeable industry perspective with practical, work-related associations"
when 6
  "Expert - deep specialized knowledge with sophisticated, nuanced connections and advanced terminology"
when 7
  "Highly Technical Expert - precise scientific/technical language with complex theoretical and specialized associations"
else
  "Amateur - basic knowledge with simple, straightforward connections based on common understanding"
end

age_guidance = case age
when 1
  "Spirit - ethereal, mystical perspective with ancient wisdom and otherworldly connections beyond physical existence"
when 2
  "Toddler - innocent, wonder-filled thinking with simple sensory associations and basic emotional responses"
when 3
  "Child - imaginative, playful perspective with fantasy elements and associations based on games, stories, and discovery"
when 4
  "Teenager - energetic, rebellious viewpoint with pop culture references and identity-focused associations"
when 5
  "Young Adult - ambitious, modern perspective with career, relationship, and lifestyle-focused connections"
when 6
  "Middle Aged - practical, experienced viewpoint with family, responsibility, and established life associations"
when 7
  "Senior Citizen - wise, reflective perspective with historical references and life experience-based connections"
else
  "Alien (from another planet) - completely foreign perspective with bizarre, non-human logic and incomprehensible associations"
end







  prompt_content = "Create a brief '#{phrase_type_guidance}' idea using these two words: '#{focus_word}' and '#{second_degree_word}'. The storyline should be creative and connect both words meaningfully. Use #{storyline_length} words or less. Return only the storyline text, no explanations."

  response = @client.chat(
    parameters: {
      model: "gpt-4o",
      messages: [
        {
          role: "system",
          content: "You are a creative storytelling expert. Generate concise, engaging storyline ideas from the perspectiv of a '#{age_guidance} #{perspective_guidance}'. Return only the storyline text, no explanations."
        },
        {
          role: "user",
          content: prompt_content
        }
      ]
    }
  )
  response.dig("choices", 0, "message", "content")
end

def core_value_or_not(candidate)
    # Build the prompt content for detailed response
    prompt_content = "If '#{candidate}' is a core value, then provide a brief explanation of your reasoning on the second line. If If '#{candidate}' is NOT a core value, then provide a brief explanation of your reasoning on the second line. Phrase it as '#{candidate} is a core value because...' or '#{candidate} is not a core value because...'."

    response = @client.chat(
      parameters: {
        model: "gpt-4o",
        messages: [
          {
            role: "system",
            content: "You are a self help guru who expertly guides clients to understand their core values. Provide clear, concise explanations."
          },
          {
            role: "user",
            content: prompt_content
          }
        ]
      }
    )
    response.dig("choices", 0, "message", "content")
end

def generate_core_value_data(candidate)
    # Build the prompt for generating complete core value data
    prompt_content = "Generate core value data for '#{candidate}'. Return ONLY a JSON object with this exact structure: {\"name\": \"#{candidate}\", \"description\": \"brief description (3-8 words)\", \"examples\": [\"example 1 (3-8 words)\", \"example 2 (3-8 words)\", \"example 3 (3-8 words)\"]}. The description should be concise and explain what this core value means. Each example should be a brief, actionable behavior that demonstrates this value."

    response = @client.chat(
      parameters: {
        model: "gpt-4o",
        messages: [
          {
            role: "system",
            content: "You are a core values expert. Return only valid JSON with the exact structure requested. No explanations or additional text."
          },
          {
            role: "user",
            content: prompt_content
          }
        ]
      }
    )
    response.dig("choices", 0, "message", "content")
end
end
