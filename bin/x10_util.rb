require 'yaml'
#$LOAD_PATH.unshift ".."
require_relative '../lib/x10comm'

def load_config
  config_file = File.read("../config/x10_config.yml")
  yaml = YAML.load(config_file)
  @config = defaults.merge(yaml)
  @hostname = @config[:hostname]
  @hostport = @config[:hostport]
  @urls = @config[:urls]
  @rf = @config[:rf]
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
  sleep(2)
  @transmitter.on :passing
  sleep(2)
end

def on_failing
  @transmitter.off :passing
  @transmitter.on :failing
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

  load_config
  build_status = ARGV.first
  @urls.each do |url|
    @transmitter = CIComm::X10.new(url[:devices], @hostname, @hostport, @rf)
    send("on_#{build_status}")
  end
end
