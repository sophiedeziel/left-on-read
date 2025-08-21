#!/usr/bin/env ruby

require_relative 'lib/ghosting_simulator'
require 'optparse'

options = {
  protagonist_name: "Alex",
  protagonist_personality: :anxious_overthinker,
  ghoster_name: "Blake", 
  ghoster_personality: :casual_ghoster
}

OptionParser.new do |opts|
  opts.banner = "Usage: ruby simulate.rb [options]"

  opts.on("-p", "--protagonist NAME", "Protagonist's name") do |name|
    options[:protagonist_name] = name
  end

  opts.on("--p-personality PERSONALITY", "Protagonist personality (anxious_overthinker, eager_pleaser)") do |p|
    options[:protagonist_personality] = p.to_sym
  end

  opts.on("-g", "--ghoster NAME", "Ghoster's name") do |name|
    options[:ghoster_name] = name
  end

  opts.on("--g-personality PERSONALITY", "Ghoster personality (casual_ghoster, mysterious_type)") do |p|
    options[:ghoster_personality] = p.to_sym
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    puts "\nAvailable personalities:"
    puts "  - anxious_overthinker: Overthinks everything, writes long messages"
    puts "  - eager_pleaser: Uses lots of emojis, seeks validation"
    puts "  - casual_ghoster: Brief responses, gets bored easily"
    puts "  - mysterious_type: Cryptic, minimal responses"
    exit
  end
end.parse!

simulator = GhostingSimulator.new(**options)
simulator.run