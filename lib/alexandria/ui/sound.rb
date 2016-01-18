# -*- ruby -*-
#--
# Copyright (C) 2011 Cathal Mc Ginley
# Copyright (C) 2015 Matijs van Zuijlen
#
# This file is part of Alexandria, a GNOME book collection manager.
#
# Alexandria is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# Alexandria is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Alexandria; see the file COPYING. If not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA.
#++

require 'gir_ffi-gst'
Gst.init []

module Alexandria
  module UI
    ## Uses Ruby/GStreamer to play Ogg/Vorbis sound effects
    class SoundEffectsPlayer
      def initialize
        @sounds_dir = Alexandria::Config::SOUNDS_DIR
        @ogg_vorbis_pipeline = Gst::Pipeline.new 'pipeline'
        set_up_pipeline
        @playing = false
        set_up_glib_loop
      end

      def play(effect)
        file = File.join(@sounds_dir, "#{effect}.ogg")
        unless @playing
          @filesrc.location = file
          start_playback
        end
      end

      def set_up_pipeline
        @filesrc = Gst::ElementFactory.make('filesrc', 'file source')
        demuxer = Gst::ElementFactory.make('oggdemux', 'demuxer')
        decoder = Gst::ElementFactory.make('vorbisdec', 'decoder')
        converter = Gst::ElementFactory.make('audioconvert', 'converter') # #??
        audiosink = Gst::ElementFactory.make('autoaudiosink', 'audiosink')

        @ogg_vorbis_pipeline.add_many([@filesrc, demuxer, decoder,
                                       converter, audiosink])
        @filesrc.link demuxer

        # this next must be a dynamic link, as demuxers potentially
        # have multiple src pads (for audio/video muxed streams)

        demuxer.signal_connect('pad-added') do |_parser, ogg_src_pad|
          vorbis_sink_pad = decoder.get_pad('sink')
          ogg_src_pad.link(vorbis_sink_pad)
        end

        decoder.link_many([converter, audiosink])
      end

      def set_up_glib_loop
        @loop = GLib::MainLoop.new(nil, false)

        @bus = @ogg_vorbis_pipeline.bus
        @bus.add_watch(GLib::PRIORITY_DEFAULT, proc do |_bus, message|
          case message.type
          when Gst::Message::EOS
            @playing = false
            @loop.quit
          when Gst::Message::ERROR
            if $DEBUG
              puts 'ERROR loop.quit'
              p message.parse
            end
            @playing = false
            @loop.quit
          end
          true
        end, nil, nil)
      end

      def start_playback
        @playing = true
        @ogg_vorbis_pipeline.play
        begin
          @loop.run
        rescue Interrupt
        ensure
          @ogg_vorbis_pipeline.stop
          @playing = false
        end
      end

      def stop_playback
        @ogg_vorbis_pipeline.stop
      end
    end
  end
end
