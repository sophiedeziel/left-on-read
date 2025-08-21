require_relative 'timeline_event'
require_relative 'message'
require 'json'

class AIParticipant
  attr_reader :name, :personality, :timeline, :conversation

  PERSONALITIES = {
    anxious_overthinker: {
      traits: [:anxious, :analytical, :self_doubting],
      message_style: :verbose,
      ghost_threshold: 0.1
    },
    casual_ghoster: {
      traits: [:aloof, :brief, :easily_bored],
      message_style: :short,
      ghost_threshold: 0.7
    },
    eager_pleaser: {
      traits: [:enthusiastic, :emoji_heavy, :validation_seeking],
      message_style: :friendly,
      ghost_threshold: 0.2
    },
    mysterious_type: {
      traits: [:cryptic, :slow_responder, :minimal],
      message_style: :minimal,
      ghost_threshold: 0.6
    }
  }

  def initialize(name:, personality:)
    @name = name
    @personality = personality
    @timeline = []
    @conversation = nil
    @message_count = 0
    @anxiety_level = 0
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
    think(generate_pre_send_thought)
    
    msg = Message.new(content: content, from: @name, to: to)
    
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
      last_sent = @conversation.get_last_sent_by(@name)
      new_messages = @conversation.get_unread_for(@name)
      
      event.data[:last_sent_status] = last_sent&.read? ? 'read' : 'delivered' if last_sent
      
      if last_sent&.read?
        time_diff = last_sent.time_since_read
        event.data[:time_since_read] = format_time_diff(time_diff) if time_diff > 60
      end
      
      if new_messages.any?
        event.data[:new_messages] = new_messages.map do |msg|
          msg.mark_as_read!
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
    
    think(generate_post_check_thought(event.data))
    
    event
  end

  def generate_message
    style = PERSONALITIES[@personality][:message_style]
    
    case style
    when :verbose
      [
        "Hey! How's your day going? I was just thinking about that thing we talked about last time and wondered what your thoughts were?",
        "So I saw this really interesting article today and it reminded me of our conversation. Want to hear about it?",
        "I hope I'm not bothering you, but I just wanted to check in and see how everything's going with you!"
      ].sample
    when :short
      ["Yeah good", "Cool", "K", "Sure", "Nm u?", "Busy rn"].sample
    when :friendly
      [
        "Omg hiiii! How are you?? 😊✨",
        "Hope you're having an amazing day! 💕",
        "Miss talking to you! What have you been up to? 🌟"
      ].sample
    when :minimal
      [".", "Interesting", "Perhaps", "Hm", "..."].sample
    end
  end

  private

  def generate_pre_send_thought
    case @personality
    when :anxious_overthinker
      [
        "Is this too much? Maybe I should wait longer...",
        "Okay, I've rewritten this message 5 times. Just send it.",
        "What if they think I'm annoying? No, it's fine. It's fine."
      ].sample
    when :casual_ghoster
      [
        "Ugh, they messaged again.",
        "I guess I should respond... or should I?",
        "This conversation is getting boring."
      ].sample
    when :eager_pleaser
      [
        "I hope they like this message!",
        "Adding more emojis to seem friendly!",
        "They're going to love this response!"
      ].sample
    when :mysterious_type
      [
        "...",
        "They don't need to know everything.",
        "Less is more."
      ].sample
    end
  end

  def generate_post_check_thought(data)
    if data[:new_messages]&.empty? && data[:last_sent_status] == 'read'
      @anxiety_level += 1
      
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
      @anxiety_level = 0
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
      protagonist: {
        name: @name,
        personality: @personality
      },
      timeline: @timeline.map(&:to_h)
    }
  end
end