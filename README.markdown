JenX ReadMe
===========

About
-----

JenX powers the network-controlled jenkins build feedback device (nicknamed *Isengard*) for the Convio engineering department. This readme describes all stages of the process required to build and run a similar device.

JenX is written in ruby, and extends CIComm -- an in-house library we wrote to get reports on jenkins views, jobs, and builds. The X10 libraries/utilities communicate to a computer running [mochad](https://github.com/njh/mochad), which handles driving the X10 computer interface.

The feedback device is modular enough to be used to either poll Jenkins periodically or to run off of jenkins itself and command the lights upon a build starting/running/ending.

The README is split into 2 sections: Build and Extend. **Build** describes the steps required to get the software and hardware set up and running, how to configure the project. **Extend** is for those wanting to extend functionality of this project.

### Note
If this all seems complex, don't fret. It's actually pretty simple. There are really only 3 steps to setting this up:

1. Install drivers
2. Connect lights
3. Run the program

Because running this on a virtual machine may require filtering USB devices and installing windows drivers, the easiest method of setting this up is on a native box. These instructions include the additional steps required to set it up on VirtualBox.

Build
-----
**Foreword**: As with anything you put on your computer, please: read the man\[ual\] pages.

This section explains how to get up and running with your setup. Note that this is specific to a networked setup using the specified controllers on a linux machine. If you want to use a different controller or OS, then some or most of these instructions may not apply.

### Drivers
To communicate with a USB-connected X10 Firecracker controller on linux, you need to **download and install** [mochad](https://github.com/njh/mochad). The instructions provided on its github and sourceforge page should be enough guidance to do so. Check the README for manual operating instructions (though you won't explicitly need to use them for our purposes)

#### On a VM
If you are running in a virtual machine, you *may* also need the windows Firecracker [software](http://ftp.x10.com/pub/applications/firecracker/xfire.exe) (this should include the drivers). If it doesn't work after restarting your computer, try drivers from [here](http://www.x10.com/support/support_soft1.htm)

If you are running in Oracle VirtualBox, you also need to install the Oracle VirtualBox Extension Pack for your specific version to enable USB 2.0 support, and you need to add USB filters for the plugged in X10 device in settings for your virtual machine.

### The Hardware
If you are setting up a physical build feedback device, this section describes the devices and the procedures I used to build 'Isengard'. The only important part here is having a computer interface that is compatible with mochad. Everything else is limited only by your creativity.

#### Ingredients
This lists devices needed to communicate a "passing" and "not passing" status to separate lights. Add more modules, lights, and devices as necessary to your setup.

* 1 **X10 USB Controller CM19A "Firecracker"** (or any other device supported by mochad)
* 1 **X10 transceiver module**
* 1 **X10 lamp module**
* You can get a **4-piece Firecracker** kit for about $40 on the X10 website, which comes with all of the above and a remote.
    * Even though I ordered the CM17A kit, which should have come with a serial (not USB) interface, they shipped the USB interface CM19A instead. CM17A is most likely discontinued, but I'd give them a call to make sure you get the right equipment. I can't imagine calling to be any more difficult than using their website to order.
* Lights:
    * Use whichever 2 lights you prefer. I used a red and a green LED Strip from Hitlights (via Amazon) along with two 12v DC power adapters.
    *note* The adapters appear to be standard for LED strip lights, so many companies sell them but many are near-identical. The Hitlights strips have a DC power cable/plug (similar to what you see on routers and small electronics) in addition to positive and negative wires on the other end of the strip, so if you find a small dc power adapter to be more convenient than a bulkier power inverter, feel free to go for that instead.

#### Assembly

**Note**: By default, this project is pre-configured for 2 devices-- a failing and a passing device. The failing device is, by default, set to X10 location A1, and the passing one is, by default, on A2. Their names, locations, and the number of devices are entirely configurable.

1. Plug the device used to indicate a failing status into the transceiver module. Keep the module's knob turned to 'A'. The device plugged in to the transceiver responds to A1.

2. Plug the device used to indicate a passing status into the lamp (or appliance) module. Set the house code to 'A', and the unit code to '2'. Obviously, this device will respond to A2.

3. Then, plug the transmitter into your USB port.

That's it. You should now be able to communicate to X10 on linux via mochad and tcp on port 1099

#### Troubleshooting

To test if everything is working at this point, open a terminal on the computer with the transmitter plugged in to it. Type
```
nc localhost 1099
```
You should see no output, but your cursor should have dropped into a netcat shell. Then, turn on A1 by typing
```
rf a1 on
```
It should come on a few seconds. Now, turn on A2 by typing
```
rf a2 on
```
See the mochad readme for more commands.

If there are issues with A2, try to connect both devices to the same power strip, and make sure that both circuits are running on the same phase.

If the transmitter is not blinking when you send commands (or netcat doesn't come on), make sure the device shows up with ```lsusb```. If it does not, make sure the device works in windows if you are running in a virtual machine. If it does, then you probably need to set a USB filter (i.e., forward the device to the virtual machine) for your vm. You may also have to get the Oracle Extension Pack, as this enables USB 2.0 support. **Make sure** the extension pack is for **your version** of virtualbox.

X10 related problems go beyond the scope of this project, so consult another resource for help with x10 configuration.

### The Software
Clone this project. First, configure anything you need in ```config/x10_config.yml```. The default settings should work when running on the same computer as mochad. Then, go to the bin/ directory, and run ```ruby update_device.rb URL_TO_JENKINS_JOB_or_VIEW```. That's it, your lights should now have been updated.

#### Other configurations
Ok that's all fine and good, you say, but how do we *keep* the lights updated? We don't want to have to manually run the script every time a job builds. Onward, I describe how I configured polling and pushing for my project.

* **Polling**
    * I use the following bash script (named it saruman.sh) to poll Jenkins every 5 seconds:

    ```
    #!/bin/bash

    # we have to cd into the bin directory
    cd /path/to/jenx/bin/

    # number of seconds to run the script for
    run_for=36000

    # number of seconds between each poll
    poll_every=5

    # url of job or view
    url="http://jenkins/view/or/job/url"

    # command to get the status and update the devices"
    ruby_cmd="ruby update_device.rb $url"

    # command to run the above every $poll_every seconds
    watch_cmd="watch -n $poll_every $ruby_cmd"

    # command to stop updating the devices after a period of time
    cmd="timelimit -t$run_for -T$run_for $watch_cmd"

    # execute it
    $cmd

    # after it finishes, we need to turn off the lights
    turn_off="ruby update_device.rb all_off"
    $turn_off
    ```

    * If you run this at work or for others to monitor, I recommend getting the timelimit application to automatically turn off the lights after some time (to prevent overheating). (On Ubuntu: ```sudo apt-get install timelimit```). Set your crontab to run the above script when you want it to turn on. Type ```crontab -e``` and add the following line

    ```
    00 08 * * 1-5 /path/to/script.sh
    ```

    * This starts the script at 8AM monday through friday. The script stops running after 10 hours, so effectively this updates the devices form 8AM to 6PM monday to friday.
* **Pushing**
    * Simply add this project as a jenkins job and use build triggers to run it after your watched builds complete. Set the job to run bash or batch commands, and tell it to cd to the bin directory and run ```ruby update_device.rb url-of-view-or-job```. This way the lights are updated right before or after a build. On the upstream project, configure it to execute the script even if the build fails, otherwise you'll never communicate a failing status to your lights.

Extend
------
The logic for receiving build statuses and turning them into X10 commands is stored in ```bin/x10_util.rb``` which uses ```lib/x10comm.rb``` to deal with the direct mochad commands. When a failing status is received, on_failing is called, when passing, on_passing is called. Add more per you preference and your jenkins configuration.

The logic for getting statuses from Jenkins URLs is handled in ```bin/update_device.rb```, which uses ```lib/ci_comm.rb``` to objectify and navigate through Jenkins responses. Here you define exactly what information it is you're fetching from jenkins, and what information you're passing to x10_util.rb. You are actually not limited to job colors and build statuses-- you could extend this to handle any part of a Jenkins view, job, build, and configuration and then just add methods in x10_util to handle to arguments passed to it.

### TODO
* Add tracking of previous status
* Add commandline options for specifying output, getting help, and reading a list of URLs
* Support for other X10 interfaces
* Support for usb devices
