require 'json'
require 'time'

class TimelineEvent
  attr_accessor :timestamp, :type, :content, :tool, :data

  def initialize(type:, content: nil, tool: nil, data: nil)
    @timestamp = Time.now.utc
    @type = type # :thought, :tool_use, :event
    @content = content
    @tool = tool
    @data = data
  end

  def to_h
    {
      timestamp: @timestamp.iso8601,
      type: @type.to_s
    }.tap do |h|
      h[:content] = @content if @content
      h[:tool] = @tool if @tool
      h[:data] = @data if @data
    end
  end
end