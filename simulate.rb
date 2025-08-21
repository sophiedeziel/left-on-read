#!/usr/bin/env ruby

require_relative 'lib/ghosting_simulator'
require_relative 'lib/persona'
require 'optparse'
require 'dotenv/load'

options = {
  use_ai: true
}

# Default personas
protagonist_description = nil
protagonist_relationship = nil
ghoster_description = nil
ghoster_relationship = nil
protagonist_name = "Alex"
ghoster_name = "Blake"

OptionParser.new do |opts|
  opts.banner = "Usage: ruby simulate.rb [options]"

  opts.on("-p", "--protagonist NAME", "Protagonist's name") do |name|
    protagonist_name = name
  end

  opts.on("--p-desc DESCRIPTION", "Protagonist's description (who they are, their personality)") do |desc|
    protagonist_description = desc
  end

  opts.on("--p-rel RELATIONSHIP", "How the protagonist knows the other person") do |rel|
    protagonist_relationship = rel
  end

  opts.on("-g", "--ghoster NAME", "Ghoster's name") do |name|
    ghoster_name = name
  end

  opts.on("--g-desc DESCRIPTION", "Ghoster's description (who they are, their personality)") do |desc|
    ghoster_description = desc
  end

  opts.on("--g-rel RELATIONSHIP", "How the ghoster knows the protagonist") do |rel|
    ghoster_relationship = rel
  end

  opts.on("--no-ai", "Disable AI message generation and use fallback messages") do
    options[:use_ai] = false
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    puts "\nExamples:"
    puts "  ruby simulate.rb --p-desc \"anxious grad student who overthinks everything\" \\"
    puts "                   --p-rel \"met on a dating app last week\" \\"
    puts "                   --g-desc \"busy professional who loses interest quickly\" \\"
    puts "                   --g-rel \"matched but not really invested\""
    puts ""
    puts "  ruby simulate.rb -p Sarah --p-desc \"enthusiastic and uses lots of emojis\" \\"
    puts "                   --p-rel \"coworker who has a crush\" \\"
    puts "                   -g Jordan --g-desc \"aloof and mysterious\" \\"
    puts "                   --g-rel \"colleague who keeps things professional\""
    puts "\nAI Message Generation:"
    puts "  By default, messages are generated using OpenAI API."
    puts "  Set OPENAI_API_KEY environment variable in .env file."
    puts "  Use --no-ai flag to disable AI generation."
    exit
  end
end.parse!

# Set default descriptions if not provided
protagonist_description ||= "someone who tends to overthink text conversations and gets anxious when left on read"
protagonist_relationship ||= "someone they've been talking to for a while"

ghoster_description ||= "someone who gets easily bored in conversations and tends to ghost people"
ghoster_relationship ||= "someone they matched with but aren't really interested in anymore"

# Create personas
protagonist_persona = Persona.new(
  name: protagonist_name,
  description: protagonist_description,
  relationship_to_other: protagonist_relationship,
  ghost_threshold: 0.1
)

ghoster_persona = Persona.new(
  name: ghoster_name,
  description: ghoster_description,
  relationship_to_other: ghoster_relationship,
  ghost_threshold: 0.8
)

if options[:use_ai] && !ENV['OPENAI_API_KEY']
  puts "⚠️  Warning: OPENAI_API_KEY not found in environment."
  puts "To use AI message generation, create a .env file with:"
  puts "OPENAI_API_KEY=your_api_key_here"
  puts "\nFalling back to pre-written messages...\n"
  sleep(2)
end

simulator = GhostingSimulator.new(
  protagonist_persona: protagonist_persona,
  ghoster_persona: ghoster_persona,
  use_ai: options[:use_ai]
)
simulator.run