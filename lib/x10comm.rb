## utility for communicating with X10

require 'socket'

module CIComm
  class X10
    def initialize(devices, hostname, hostport=1099, rf=true)
      @hostname = hostname
      @hostport = hostport
      if rf
        @transmit_cmd = 'rf'
      else
        @transmit_cmd = 'pl'
      end
      @device = Hash.new{ |h, k| h[k] = Array.new(2) }
      devices.each do |key, value|
        @device[key] = value.split(/([A-Pa-p])(1[0-6]|[1-9])/)
      end
    end

    def set_device(device_name)
      raise "Device #{device_name} not found" unless @device.key?(device_name)
      @current_device = device_name
    end

    def on(device_name = @current_device)
      x10_send(device_name.to_sym, :on)
    end

    def off(device_name = @current_device)
      x10_send(device_name.to_sym, :off)
    end

    def dim(device_name = @current_device, value)
      raise "dim value must be between 0 and 31" unless (0..31) === value
      x10_send(device_name.to_sym, :dim, value)
    end

    def bright(device_name = @current_device, value)
      raise "bright value must be between 0 and 31" unless (0..31) === value
      x10_send(device_name.to_sym, :bright, value)
    end

    def xdim(device_name = @current_device, value)
      raise "xdim value must be between 0 and 255" unless (0..255) === value
      x10_send(device_name.to_sym, :xdim, value)
    end

    def all_off
      @device.each_key do |k|
        off(k)
      end
    end

    def all_on
      @device.each_key do |k|
        on(k)
      end
    end

    def x10_send(device_name, op, val="")
      x10_open
      @session.puts "st 0" #clear interface status memory -- needed to initialize lights
      @session.puts "#@transmit_cmd #{@device[device_name].join} #{op} #{val}"
      x10_close
    end

    def x10_open
      @session = TCPSocket.new @hostname, @hostport
    end

    def x10_close
      @session.close
    end
  end
end