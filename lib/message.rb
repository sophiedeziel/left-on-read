require 'securerandom'
require 'time'

class Message
  attr_accessor :id, :content, :from, :to, :sent_at, :delivered_at, :read_at

  def initialize(content:, from:, to:)
    @id = SecureRandom.uuid
    @content = content
    @from = from
    @to = to
    @sent_at = Time.now.utc
    @delivered_at = nil
    @read_at = nil
  end

  def deliver!
    @delivered_at = Time.now.utc
  end

  def mark_as_read!
    @read_at = Time.now.utc
  end

  def delivered?
    !@delivered_at.nil?
  end

  def read?
    !@read_at.nil?
  end

  def time_since_read
    return nil unless read?
    Time.now.utc - @read_at
  end

  def to_h
    {
      id: @id,
      content: @content,
      from: @from,
      to: @to,
      sent_at: @sent_at.iso8601,
      delivered_at: @delivered_at&.iso8601,
      read_at: @read_at&.iso8601
    }
  end
end