#!/bin/bash
#[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# we have to cd into the bin directory
cd $JENX_HOME/bin/

# number of seconds to run the script for
run_for=36000

# number of seconds between each poll
poll_every=5

# cmd to get the status and update the devices
ruby_cmd="ruby update_device.rb"

# cmd to run the above every $poll_every seconds
watch_cmd="watch -n $poll_every $ruby_cmd"

# cmd to stop updating the devices after a period of time passes
cmd="timelimit -t$run_for -T$run_for $watch_cmd"

# execute it
$cmd

# after it finishes, we need to turn off the lights
turn_off="ruby update_device.rb all_off"
$turn_off
