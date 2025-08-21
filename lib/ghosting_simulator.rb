require_relative 'ai_participant'
require_relative 'conversation'
require_relative 'openai_message_generator'
require_relative 'persona'
require 'json'
require 'fileutils'

class GhostingSimulator
  def initialize(protagonist_persona:, ghoster_persona:, use_ai: true)
    @protagonist = AIParticipant.new(persona: protagonist_persona, use_ai: use_ai)
    @ghoster = AIParticipant.new(persona: ghoster_persona, use_ai: use_ai)
    @conversation = Conversation.new(@protagonist, @ghoster)
    @simulation_id = SecureRandom.uuid
    @use_ai = use_ai
  end

  def run
    puts "🎭 Starting Ghosting Simulation..."
    puts "Mode: #{@use_ai && ENV['OPENAI_API_KEY'] ? 'AI-Generated Messages' : 'Fallback Messages'}"
    puts "\nProtagonist: #{@protagonist.persona.name}"
    puts "Description: #{@protagonist.persona.description}"
    puts "\nOther: #{@ghoster.persona.name}"
    puts "Description: #{@ghoster.persona.description}"
    puts "Relationship: #{@protagonist.persona.relationship_to_other}"
    puts "=" * 60
    puts "\n📱 Text Conversation:"
    puts "=" * 60

    # Initial conversation
    simulate_normal_conversation(5..8)
    
    # The ghosting moment
    initiate_ghosting
    
    # The aftermath - protagonist checks messages repeatedly
    simulate_post_ghost_anxiety
    
    # Save the results
    save_simulation
    
    puts "\n✅ Simulation complete! Results saved to output/simulation_#{@simulation_id}.json"
  end

  private

  def simulate_normal_conversation(message_count_range)
    message_count = rand(message_count_range)
    current_sender = [@protagonist, @ghoster].sample
    
    message_count.times do |i|
      # Sender generates and sends message
      other = current_sender == @protagonist ? @ghoster : @protagonist
      message_content = current_sender.generate_message(other_persona: other.persona)
      
      # Get the sender's pre-send thought from timeline
      timeline_size_before = current_sender.timeline.size
      
      msg = current_sender.send_message(message_content, to: other.name)
      @conversation.add_message(msg)
      
      # Display the thought that was just added
      if current_sender.timeline.size > timeline_size_before
        thought = current_sender.timeline[timeline_size_before]
        display_thought(current_sender.name, thought.content) if thought.type == :thought
      end
      
      # Display the message with unread status
      display_message(msg, status: "Delivered")
      
      sleep(rand(0.5..2))
      
      # Receiver checks messages and marks as read
      timeline_size_before = other.timeline.size
      other.check_messages
      msg.mark_as_read!
      display_read_status(msg)
      
      # Display the receiver's post-check thought
      if other.timeline.size > timeline_size_before
        # Find the last thought in the new timeline events
        new_events = other.timeline[timeline_size_before..-1]
        thought = new_events.find { |e| e.type == :thought }
        display_thought(other.name, thought.content) if thought
      end
      
      sleep(0.5)
      
      # Switch sender for next message (usually)
      current_sender = other if rand < 0.8
      
      sleep(rand(1..3))
    end
  end

  def initiate_ghosting
    puts "\n" + "=" * 60
    puts "💀 Ghosting moment approaching..."
    puts "=" * 60
    
    # Track timeline for thought display
    timeline_size_before = @protagonist.timeline.size
    
    # Protagonist sends final message that will be left on read
    if @use_ai && ENV['OPENAI_API_KEY']
      generator = OpenAIMessageGenerator.new
      final_message = generator.generate_message(
        persona: @protagonist.persona,
        other_persona: @ghoster.persona,
        context: "You're about to ask something that might lead to being ghosted. Maybe suggest meeting up or ask a personal question.",
        previous_messages: []
      )
    end
    
    final_message ||= [
      "Want to grab coffee sometime?",
      "So what are you up to this weekend?",
      "We should hang out soon!",
      "Can I ask you something?",
      "I really enjoyed talking with you"
    ].sample
    
    msg = @protagonist.send_message(final_message, to: @ghoster.name)
    @conversation.add_message(msg)
    
    # Display the protagonist's thought before sending
    if @protagonist.timeline.size > timeline_size_before
      thought = @protagonist.timeline[timeline_size_before]
      display_thought(@protagonist.name, thought.content) if thought.type == :thought
    end
    
    # Display the message with delivered status
    display_message(msg, status: "Delivered")
    
    sleep(1)
    
    # Ghoster reads but doesn't respond
    timeline_size_before = @ghoster.timeline.size
    @ghoster.check_messages
    msg.mark_as_read!
    display_read_status(msg)
    
    # Display the ghoster's post-check thought
    if @ghoster.timeline.size > timeline_size_before
      new_events = @ghoster.timeline[timeline_size_before..-1]
      thought = new_events.find { |e| e.type == :thought }
      display_thought(@ghoster.name, thought.content) if thought
    end
    
    # Ghoster's explicit ghosting thought
    ghost_thought = @ghoster.think("I'm done with this conversation.")
    display_thought(@ghoster.name, ghost_thought.content)
    
    # Initiate ghost mode
    @conversation.initiate_ghosting(@ghoster.name)
    
    puts " " * 30 + "(no response...)"
  end

  def simulate_post_ghost_anxiety
    puts "\n" + "=" * 60
    puts "😰 Post-ghost anxiety phase..."
    puts "=" * 60
    
    check_intervals = [
      30,    # 30 seconds
      120,   # 2 minutes  
      600,   # 10 minutes
      1800,  # 30 minutes
      3600,  # 1 hour
      7200,  # 2 hours
      14400, # 4 hours
      28800  # 8 hours
    ]
    
    check_intervals.each_with_index do |interval, i|
      # Simulate time passing
      simulated_time = Time.now + interval
      
      puts "\n⏰ #{format_time_passed(interval)} later..."
      puts "#{@protagonist.persona.name} checks their phone..."
      
      # Protagonist checks messages
      @protagonist.check_messages
      
      # Maybe send a follow-up message if really anxious
      if i == 3 && rand < 0.3
        puts "\n#{@protagonist.persona.name} decides to double-text..."
        
        # Track timeline for anxious thought
        timeline_size_before = @protagonist.timeline.size
        
        follow_up = [
          "Hey, did you see my message?",
          "Everything okay?",
          "??",
          "Hello?"
        ].sample
        
        msg = @protagonist.send_message(follow_up, to: @ghoster.name)
        @conversation.add_message(msg)
        
        # Display the anxious thought before double-texting
        if @protagonist.timeline.size > timeline_size_before
          thought = @protagonist.timeline[timeline_size_before]
          display_thought(@protagonist.name, thought.content) if thought.type == :thought
        end
        
        # Display the follow-up message with delivered status
        display_message(msg, status: "Delivered")
        
        # This also gets left on read
        sleep(1)
        msg.mark_as_read!
        display_read_status(msg)
        puts " " * 30 + "(still no response...)"
      end
      
      sleep(0.5) # For dramatic effect in output
    end
  end

  def display_message(msg, status: nil)
    max_width = 40
    
    if msg.from == @ghoster.name
      # Ghoster's message on the left
      wrapped = wrap_text(msg.content, max_width)
      wrapped.each do |line|
        puts "👻 #{line.ljust(max_width)}"
      end
      puts "   #{msg.from}"
      puts "   #{status}" if status
    else
      # Protagonist's message on the right
      wrapped = wrap_text(msg.content, max_width)
      wrapped.each do |line|
        puts " " * 20 + line.rjust(max_width) + " 💙"
      end
      puts " " * 20 + msg.from.rjust(max_width + 3)
      puts " " * 20 + status.rjust(max_width + 3) if status
    end
    puts ""
  end
  
  def display_thought(name, thought)
    puts "💭 [#{name} thinks: #{thought}]"
    puts ""
  end
  
  def display_read_status(msg)
    if msg.from == @ghoster.name
      puts "   Read ✓"
    else
      puts " " * 20 + "Read ✓".rjust(43)
    end
    puts ""
  end
  
  def wrap_text(text, max_width)
    return [text] if text.length <= max_width
    
    words = text.split(' ')
    lines = []
    current_line = ''
    
    words.each do |word|
      if current_line.empty?
        current_line = word
      elsif (current_line + ' ' + word).length <= max_width
        current_line += ' ' + word
      else
        lines << current_line
        current_line = word
      end
    end
    
    lines << current_line unless current_line.empty?
    lines
  end
  
  def format_time_passed(seconds)
    case seconds
    when 0..59
      "#{seconds} seconds"
    when 60..3599
      "#{seconds/60} minutes"
    when 3600..86399
      hours = seconds/3600
      "#{hours} hour#{'s' if hours > 1}"
    else
      "#{seconds/86400} days"
    end
  end

  def save_simulation
    FileUtils.mkdir_p('output')
    
    simulation_data = {
      simulation_id: @simulation_id,
      started_at: Time.now.utc.iso8601,
      protagonist: @protagonist.persona.to_h,
      other_participant: @ghoster.persona.to_h,
      timeline: @protagonist.timeline.map(&:to_h)
    }
    
    File.write(
      "output/simulation_#{@simulation_id}.json",
      JSON.pretty_generate(simulation_data)
    )
  end
end