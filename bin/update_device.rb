#$LOAD_PATH.unshift ".."
require_relative '../lib/ci_comm'
require_relative '../bin/x10_util'

def get_status(job)
  case job.color
    when /blue\z/
      "passing"
    when /blue_anime/
      "passing_in_progress"
    when /yellow\z/
      "unstable"
    when /yellow_anime/
      "unstable_in_progress"
    when /red\z/
      "failing"
    when /red_anime/
      "failing_in_progress"
    when /grey\z/
      "aborted"
    when /grey_anime/
      "aborted_in_progress"
    else
      Kernel.warn "status for color #{job.color} not defined. Defaulting to \"failing\""
      "failing"
  end
end

if ARGV.empty?
  raise "No jenkins view or job url specified"
else
  jenkins = CIComm::Jenkins.get_resource(ARGV.join(" "))
  puts jenkins.name
end

if jenkins.is_a? CIComm::Jenkins::Job
  @overall_status = get_status(jenkins)
elsif jenkins.is_a? CIComm::Jenkins::View
  jenkins.jobs.reject do |job|
    true if job.name =~ /Build Feedback Device/ or job.name =~ /\A__/
  end.each do |job|
    current_status = get_status(job)
    @overall_status = "failing" if current_status !=~ /passing/
    puts "#{current_status.capitalize}:  #{job.name}"
  end
  @overall_status ||= "passing"
else
  raise "URL not recognized or Jenkins is down. Aborting"
end

@config = load_config
@transmitter = CIComm::X10.new(@config[:devices], @config[:hostname], @config[:hostport], @config[:rf])

puts "overall: #{@overall_status}"
send("on_#@overall_status")