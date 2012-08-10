require 'yaml'
#$LOAD_PATH.unshift ".."
require_relative '../lib/x10comm'

def load_config
  config_file = File.read("../config/x10_config.yml")
  defaults.merge YAML.load(config_file)
end

def defaults
  {
      :hostname => "localhost",
      :hostport => 1099,
      :rf       => true,
      :devices  => {},
  }
end

def on_demo
  @transmitter.all_off
  @config[:devices].each do |d|
    @transmitter.on(d)
    sleep(1)
    @transmitter.off(d)
    sleep(1)
  end
  @transmitter.all_on
  sleep(1)
  @transmitter.all_off
end

def on_unstable
  @transmitter.off :passing
  @transmitter.on :failing
end

alias :on_unstable_in_progress :on_unstable

def on_passing
  @transmitter.off :failing
  @transmitter.on :passing
end

def on_passing_in_progress
  @transmitter.off :failing
  @transmitter.off :passing
  sleep(3)
  @transmitter.on :passing
  sleep(7)
end

def on_failing
  @transmitter.off :passing
  @transmitter.off :failing
  sleep(3)
  @transmitter.on :failing
  sleep(7)
end

def on_failing_in_progress
  @transmitter.off :passing
  @transmitter.on :failing
end

alias :on_aborted :on_failing_in_progress

alias :on_aborted_in_progress :on_failing_in_progress

def on_unknown
  @transmitter.all_on
end

if __FILE__ == $0
  if ARGV.empty?
    puts "USAGE: ruby x10_util.rb <BUILD_STATUS>\n"\
       "on_[BUILD_STATUS] must be a defined method\n"
    exit
  end

  @config = load_config
  @transmitter = CIComm::X10.new(@config[:devices], @config[:hostname], @config[:hostport], @config[:rf])

  build_status = ARGV.first
  send("on_#{build_status}")
end
