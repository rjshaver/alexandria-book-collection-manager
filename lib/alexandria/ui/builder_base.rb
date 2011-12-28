# Copyright (C) 2011 Cathal Mc Ginley
# Copyright (C) 2015 Matijs van Zuijlen
#
# Alexandria is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# Alexandria is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with Alexandria; see the file COPYING.  If not,
# write to the Free Software Foundation, Inc., 51 Franklin Street,
# Fifth Floor, Boston, MA 02110-1301 USA.

module Alexandria
  module UI
    class BuilderBase
      def initialize(filename, widget_names)
        file = File.join(Alexandria::Config::DATA_DIR, 'glade', filename)
        builder = Gtk::Builder.new
        builder.add_from_file(file)
        # FIXME: Add override defining connect_signals.
        # FIXME: Add back exception handler
        builder.connect_signals_full Proc.new { |b,o,sn,hn,co,f,ud|
          sn.gsub! /_/, '-'
          GObject.signal_connect o, sn, &self.method(hn)
        }, nil

        widget_names.each do |name|
          begin
            instance_variable_set("@#{name}".intern, builder[name.to_s])
          rescue => err
            puts "Error: #{err}" if $DEBUG
          end
        end
      end
    end
  end
end
