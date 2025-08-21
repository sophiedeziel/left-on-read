require_relative 'timeline_event'
require_relative 'message'
require_relative 'openai_message_generator'
require_relative 'persona'
require 'json'

class AIParticipant
  attr_reader :persona, :timeline, :conversation

  def initialize(persona:, use_ai: true)
    @persona = persona
    @timeline = []
    @conversation = nil
    @message_count = 0
    @anxiety_level = 0
    @use_ai = use_ai
    @ai_generator = OpenAIMessageGenerator.new if @use_ai && ENV['OPENAI_API_KEY']
    @message_history = []
  end

  def name
    @persona.name
  end

  def join_conversation(conversation)
    @conversation = conversation
  end

  def think(content)
    thought = TimelineEvent.new(
      type: :thought,
      content: content
    )
    @timeline << thought
    thought
  end

  def send_message(content, to:)
    think(generate_pre_send_thought())
    
    msg = Message.new(content: content, from: @persona.name, to: to)
    
    @message_history << { from_self: true, content: content, to: to }
    
    event = TimelineEvent.new(
      type: :tool_use,
      tool: 'send_message',
      data: {
        message: content,
        delivered: true
      }
    )
    @timeline << event
    @message_count += 1
    
    msg
  end

  def check_messages
    event = TimelineEvent.new(
      type: :tool_use,
      tool: 'check_messages',
      data: {}
    )
    
    if @conversation
      last_sent = @conversation.get_last_sent_by(@persona.name)
      new_messages = @conversation.get_unread_for(@persona.name)
      
      event.data[:last_sent_status] = last_sent&.read? ? 'read' : 'delivered' if last_sent
      
      if last_sent&.read?
        time_diff = last_sent.time_since_read
        event.data[:time_since_read] = format_time_diff(time_diff) if time_diff > 60
      end
      
      if new_messages.any?
        event.data[:new_messages] = new_messages.map do |msg|
          msg.mark_as_read!
          @message_history << { from_self: false, content: msg.content, from: msg.from }
          {
            from: msg.from,
            message: msg.content,
            received_at: msg.sent_at.iso8601
          }
        end
      else
        event.data[:new_messages] = []
      end
    end
    
    @timeline << event
    
    think(generate_post_check_thought(data: event.data))
    
    event
  end

  def generate_message(other_persona: nil)
    if @ai_generator
      recent_messages = @message_history.last(5)
      
      message = @ai_generator.generate_message(
        persona: @persona,
        other_persona: other_persona,
        previous_messages: recent_messages
      )
      
      return message if message
    end
    
    generate_fallback_message
  end
  
  def generate_fallback_message
    [
      "Hey, how's it going?",
      "What are you up to?",
      "Hi! How are you?",
      "Hey there!",
      "What's new?"
    ].sample
  end

  def generate_pre_send_thought(other_persona: nil)
    if @ai_generator
      thought = @ai_generator.generate_thought(
        persona: @persona,
        situation: "About to send a message",
        anxiety_level: @anxiety_level
      )
      return thought if thought
    end
    
    generate_fallback_pre_send_thought
  end
  
  def generate_fallback_pre_send_thought
    [
      "Should I send this?",
      "Hope this comes across well.",
      "Here goes nothing.",
      "Let me send this."
    ].sample
  end

  def generate_post_check_thought(other_persona: nil, data: {})
    situation = if data[:new_messages]&.empty? && data[:last_sent_status] == 'read'
      @anxiety_level += 1
      "Message was read but no response"
    elsif data[:new_messages]&.any?
      @anxiety_level = 0
      "Received new messages"
    else
      "Checking messages, nothing new"
    end
    
    if @ai_generator
      thought = @ai_generator.generate_thought(
        persona: @persona,
        situation: situation,
        anxiety_level: @anxiety_level
      )
      return thought if thought
    end
    
    generate_fallback_post_check_thought(data)
  end
  
  private

  def generate_fallback_post_check_thought(data)
    if data[:new_messages]&.empty? && data[:last_sent_status] == 'read'
      case @anxiety_level
      when 1
        "They read it but haven't responded yet. They're probably just busy."
      when 2
        "Okay, it's been a while. Maybe they're thinking of what to say?"
      when 3
        "Did I say something wrong? Was I too forward?"
      when 4
        "I've definitely been left on read. This is intentional."
      when 5..10
        [
          "Maybe their phone died? Maybe they're in the hospital?",
          "What if they hate me now? What did I do?",
          "I'm overthinking this. But am I? But what if I'm not?",
          "Should I double text? No that's desperate. But what if they're waiting for me to?",
          "They probably found someone more interesting to talk to."
        ].sample
      else
        "I've been ghosted. Time to accept it and move on. 😔"
      end
    elsif data[:new_messages]&.any?
      "Oh thank god, they responded!"
    else
      "No new messages yet."
    end
  end

  def format_time_diff(seconds)
    case seconds
    when 0..59
      "#{seconds.to_i} seconds"
    when 60..3599
      "#{(seconds/60).to_i} minutes"
    when 3600..86399
      "#{(seconds/3600).to_i} hours #{((seconds%3600)/60).to_i} minutes"
    else
      "#{(seconds/86400).to_i} days"
    end
  end

  def to_h
    {
      protagonist: @persona.to_h,
      timeline: @timeline.map(&:to_h)
    }
  end
end