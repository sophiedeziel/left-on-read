require_relative 'message'
require 'securerandom'

class Conversation
  attr_reader :id, :messages, :participants

  def initialize(participant1, participant2)
    @id = SecureRandom.uuid
    @messages = []
    @participants = {
      participant1.name => participant1,
      participant2.name => participant2
    }
    @ghost_mode = false
    @ghoster = nil
    
    participant1.join_conversation(self)
    participant2.join_conversation(self)
  end

  def add_message(message)
    message.deliver!
    @messages << message
    
    # Randomly mark as read if not in ghost mode
    if !@ghost_mode && message.to != @ghoster
      sleep(rand(0.1..0.5))
      message.mark_as_read! if rand < 0.9
    end
  end

  def get_last_sent_by(name)
    @messages.reverse.find { |msg| msg.from == name }
  end

  def get_unread_for(name)
    @messages.select { |msg| msg.to == name && !msg.read? }
  end

  def initiate_ghosting(ghoster_name)
    @ghost_mode = true
    @ghoster = ghoster_name
  end

  def is_ghosting?
    @ghost_mode
  end

  def get_other_participant(name)
    @participants.find { |n, _| n != name }&.last
  end
end