JenX ReadMe
===========

About
-----

JenX powers the network-controlled jenkins build feedback device (nickname *Isengard*) for the Convio engineering department. This readme describes all stages of the process required to build and run a similar device.

JenX is written in ruby, and extends CIComm -- an in-house library we wrote to get reports on jenkins views, jobs, and builds. The X10 libraries/utilities communicate to a computer running [mochad](https://github.com/njh/mochad), which handles driving the X10 computer interface.

The feedback device is modular enough to use it either to poll Jenkins periodically or to off of jenkins itself to push the commands immediately upon a build starting/running/ending.

We've divided the README into 2 sections: Build and Extend. **Build** describes the steps required to get the software and hardware set up and running, how to configure the project. **Extend** is for those wanting to extend functionality of this project.

### Note
If this all seems complex, don't fret. It's actually pretty simple. There are really only 3 steps to setting this up:

1. Install drivers
2. Connect lights
3. Run the program

Build
-----
This section explains how to get up and running with your setup. Note that these instructions are specific to a networked setup using the specified controllers on a linux machine. If you want to use a different controller or OS, then some or most of these instructions may not apply.

### Drivers
To communicate with a USB-connected X10 Firecracker controller on linux, you need to download and install [mochad](https://github.com/njh/mochad). The instructions provided on the github and sourceforge page should be enough guidance to do so. Check the README for manual operating instructions (though you won't explicitly need to use them for our purposes)

If you are running in a virtual machine, you may also need the windows Firecracker [software](ftp://ftp.x10.com/pub/applications/firecracker/xfire.exe) (this should include the drivers). If it doesn't work after restarting your computer, try drivers from [here](http://www.x10.com/support/support_soft1.htm)

If you are running in Oracle VirtualBox, you also need to install the Oracle VirtualBox Extension Pack for your specific version to enable USB 2.0 support, and you need to add USB filters for the plugged in X10 device in settings for your virtual machine.

### The Hardware
This section describes the devices and the procedures necessary to get them hooked up.

#### Ingredients
List of devices needed to communicate a "passing" and "not passing" status to 2 devices. Add more modules, lights, and devices as necessary to your setup.

* 1 **X10 USB Controller CM19A "Firecracker"** (or any other device supported by mochad)
* 1 **X10 transceiver module**
* 1 **X10 lamp module**
* You can get a **4-piece Firecracker** kit for about $40 on the X10 website, which comes with all of the above and a remote.
    * Even though I ordered the CM17A kit, which should have come with a serial (not USB) interface, they shipped the USB interface CM19A instead. CM17A is most likely discontinued, but I'd give them a call to make sure you get the right equipment
* Lights:
    * Use whatever 2 lights you prefer. I used a red and a green LED Strip from Hitlights (via Amazon) along with two 12v DC power adapters. The adapters appear to be standard for LED strip lights, so many companies sell them but many are near-identical. The Hitlights strips have a DC power cable/plug (similar to what you see on routers and small electronics) in addition to positive and negative wires on the other end of the strip, so if you find a small dc power adapter to be more convenient than a bulkier power inverter, feel free to go for that instead.

#### Assembly

**Note**: By default, this project is pre-configured for 2 devices-- a failing and a passing device. The failing device is, by default, set to X10 location A1, and the passing one is, by default, on A2. Their names, locations, and the number of devices is entirely configurable.

Plug the device used to indicate a failing status into the transceiver module. Keep the module's knob turned to 'A'. The device plugged in to the transceiver responds to A1.

Plug the device used to indicate a passing status into the lamp (or appliance) module. Set the house code to 'A', and the unit code to '2'. Obviously, this device will respond to A2.

Then, plug the transmitter into your USB port.

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
get it
```
```

Clone the project. First, configure anything you need in config/x10_config.yml. The default settings should work when running on the same computer as mochad. Then, go to the bin/ directory, and run ```ruby feedback_device.rb URL_TO_JENKINS_JOB_or_VIEW```. That's it.

#### Other configurations
* **Polling**
    * I use the following bash script to poll Jenkins every 5 seconds:

    ```
    #!/bin/bash
    cmd="watch -n 5 'ruby cicomm/bin/feedback_device.rb http://linkto/view/jenkins/job/name'"
    $cmd
    ```

    * If you run this for others to monitor, I recommend getting the timelimit application. (On Ubuntu: ```sudo apt-get install timelimit```) and adding something like this to your crontab:

    ```
    00 08 * * 1-5 timelimit -t36000 -T36000 /path/to/./script.sh
    ```

    * This runs the script from 8AM to 6PM monday to friday
* **Pushing**
    * Simply add this project as a jenkins job and use build triggers to run it after your watched builds complete.

Extend
------
The logic for receiving build statuses and turning them into X10 commands is stored in ```bin/x10_util.rb``` which uses ```lib/x10comm.rb``` to deal with the direct mochad commands. When a failing status is received, on_failing is called, when passing, on_passing is called. Add more per you preference and your jenkins configuration.

The logic for getting statuses from Jenkins URLs is handled in ```bin/feedback_device.rb```, which uses ```lib/ci_comm.rb``` to objectify and navigate through Jenkins responses. Here you define exactly what information it is you're fetching from jenkins, and what information you're passing to x10_util.rb. You are actually not limited to job colors and build statuses-- you could extend this to handle any part of a Jenkins view, job, build, and configuration and then just add methods in x10_util to handle to arguments passed to it.

### TODO
* Add tracking of previous status
* Add commandline options for specifying output, getting help, and reading a list of URLs
