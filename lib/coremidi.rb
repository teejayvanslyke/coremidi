$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'dl/import'

module CoreMIDI

  class Base
    ON  = 0x90
    OFF = 0x80
    PC  = 0xC0

    def initialize
      open
    end

    def open
      client_name = CF.cFStringCreateWithCString(nil, "RubyMIDI", 0)
      @client     = DL::PtrData.new(nil)
      C.mIDIClientCreate(client_name, nil, nil, @client.ref)

      port_name   = CF.cFStringCreateWithCString(nil, "Output",   0)
      @outport    = DL::PtrData.new(nil)
      C.mIDIOutputPortCreate(@client, port_name, @outport.ref)

      num         = C.mIDIGetNumberOfDestinations()
      raise       NoMIDIDestinations if num < 1
      @destination = C.mIDIGetDestination(0)
    end

    def close
      c.mIDIClientDispose(@client)
    end

    def message(*args)
      format = "C" * args.size
      bytes  = args.pack(format).to_ptr
      packet_list = DL.malloc(256)
      packet_ptr  = C.mIDIPacketListInit(packet_list)
      packet_ptr  = C.mIDIPacketListAdd(packet_list, 256, packet_ptr, 0, 0, args.size, bytes)
      C.mIDISend(@outport, @destination, packet_list)
    end

    def note_on(channel, note, velocity=64)
      message(ON | channel, note, velocity)
    end

    def note_off(channel, note, velocity=64)
      message(OFF | channel, note, velocity)
    end

    def program_change(channel, preset)
      message(PC | channel, preset)
    end
  end

  module C
    extend DL::Importable
    dlload '/System/Library/Frameworks/CoreMIDI.framework/Versions/Current/CoreMIDI'

    extern "int MIDIClientCreate(void *, void *, void *, void *)"
    extern "int MIDIClientDispose(void *)"
    extern "int MIDIGetNumberOfDestinations()"
    extern "void * MIDIGetDestination(int)"
    extern "int MIDIOutputPortCreate(void *, void *, void *)"
    extern "void * MIDIPacketListInit(void *)"
    extern "void * MIDIPacketListAdd(void *, int, void *, int, int, int, void *)"
    extern "int MIDISend(void *, void *, void *)"
  end

  module CF
    extend DL::Importable
    dlload '/System/Library/Frameworks/CoreFoundation.framework/Versions/Current/CoreFoundation'

    extern "void * CFStringCreateWithCString(void *, char *, int)"
  end
  
end
