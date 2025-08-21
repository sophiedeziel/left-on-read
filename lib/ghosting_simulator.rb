require_relative 'ai_participant'
require_relative 'conversation'
require 'json'
require 'fileutils'

class GhostingSimulator
  def initialize(protagonist_name: "Alex", protagonist_personality: :anxious_overthinker,
                 ghoster_name: "Blake", ghoster_personality: :casual_ghoster)
    @protagonist = AIParticipant.new(name: protagonist_name, personality: protagonist_personality)
    @ghoster = AIParticipant.new(name: ghoster_name, personality: ghoster_personality)
    @conversation = Conversation.new(@protagonist, @ghoster)
    @simulation_id = SecureRandom.uuid
  end

  def run
    puts "🎭 Starting Ghosting Simulation..."
    puts "Protagonist: #{@protagonist.name} (#{@protagonist.personality})"
    puts "Other: #{@ghoster.name} (#{@ghoster.personality})"
    puts "-" * 50

    # Initial conversation
    simulate_normal_conversation(3..5)
    
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
      message_content = current_sender.generate_message
      other = current_sender == @protagonist ? @ghoster : @protagonist
      
      msg = current_sender.send_message(message_content, to: other.name)
      @conversation.add_message(msg)
      
      sleep(rand(0.5..2))
      
      # Receiver checks messages
      other.check_messages
      
      # Switch sender for next message (usually)
      current_sender = other if rand < 0.8
      
      sleep(rand(1..3))
    end
  end

  def initiate_ghosting
    puts "\n💀 Ghosting initiated..."
    
    # Protagonist sends final message that will be left on read
    final_message = [
      "Want to grab coffee sometime?",
      "So what are you up to this weekend?",
      "We should hang out soon!",
      "Can I ask you something?",
      "I really enjoyed talking with you"
    ].sample
    
    msg = @protagonist.send_message(final_message, to: @ghoster.name)
    @conversation.add_message(msg)
    
    sleep(1)
    
    # Ghoster reads but doesn't respond
    @ghoster.check_messages
    @ghoster.think("I'm done with this conversation.")
    
    # Mark message as read but initiate ghost mode
    msg.mark_as_read!
    @conversation.initiate_ghosting(@ghoster.name)
  end

  def simulate_post_ghost_anxiety
    puts "\n😰 Post-ghost anxiety phase..."
    
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
      
      # Protagonist checks messages
      @protagonist.check_messages
      
      # Maybe send a follow-up message if really anxious
      if i == 3 && rand < 0.3
        follow_up = [
          "Hey, did you see my message?",
          "Everything okay?",
          "??",
          "Hello?"
        ].sample
        
        msg = @protagonist.send_message(follow_up, to: @ghoster.name)
        @conversation.add_message(msg)
        
        # This also gets left on read
        sleep(rand(60..300))
        msg.mark_as_read!
      end
      
      sleep(0.5) # For dramatic effect in output
    end
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
      protagonist: {
        name: @protagonist.name,
        personality: @protagonist.personality
      },
      other_participant: {
        name: @ghoster.name
      },
      timeline: @protagonist.timeline.map(&:to_h)
    }
    
    File.write(
      "output/simulation_#{@simulation_id}.json",
      JSON.pretty_generate(simulation_data)
    )
  end
end