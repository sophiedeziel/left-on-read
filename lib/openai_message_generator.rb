require 'openai'
require 'dotenv/load'

class OpenAIMessageGenerator
  def initialize
    @client = OpenAI::Client.new(
      access_token: ENV['OPENAI_API_KEY'],
      request_timeout: 30
    )
  end

  def generate_message(persona:, other_persona: nil, context: nil, previous_messages: [])
    system_prompt = build_system_prompt_for_persona(persona, other_persona)
    
    messages = [
      { role: "system", content: system_prompt }
    ]
    
    if context
      messages << { role: "system", content: "Context: #{context}" }
    end
    
    previous_messages.each do |msg|
      role = msg[:from_self] ? "assistant" : "user"
      messages << { role: role, content: msg[:content] }
    end
    
    user_prompt = "Generate a single text message to send in this conversation. Stay in character."
    messages << { role: "user", content: user_prompt }
    
    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: messages,
        temperature: 0.8,
        max_tokens: 150
      }
    )
    
    response.dig("choices", 0, "message", "content")&.strip
  rescue => e
    puts "OpenAI API error: #{e.message}"
    nil
  end

  def generate_thought(persona:, situation:, anxiety_level: 0)
    system_prompt = "You are #{persona.name}: #{persona.description}. Generate a brief, realistic inner thought based on your character."
    
    messages = [
      { role: "system", content: system_prompt },
      { role: "user", content: "Situation: #{situation}\nAnxiety level (0-10): #{anxiety_level}\nGenerate a single inner thought (max 100 characters):" }
    ]
    
    response = @client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: messages,
        temperature: 0.8,
        max_tokens: 50
      }
    )
    
    response.dig("choices", 0, "message", "content")&.strip
  rescue => e
    puts "OpenAI API error for thought generation: #{e.message}"
    nil
  end

  private

  def build_system_prompt_for_persona(persona, other_persona)
    prompt = "You are #{persona.name}. #{persona.description}\n\n"
    
    if other_persona
      prompt += "You are texting with #{other_persona.name}, #{persona.relationship_to_other}\n"
      prompt += "About #{other_persona.name}: #{other_persona.description}\n\n"
    end
    
    prompt += "Stay true to your character. Write messages that reflect your personality and relationship dynamics."
    prompt
  end
end