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
        builder.connect_signals do |handler_name|
          begin
            method(handler_name)
          rescue => ex
            puts "Error: #{ex}" if $DEBUG
          end
        end

        widget_names.each do |name|
          instance_variable_set("@#{name}".intern, builder.get_object(name.to_s))
        end
      end
    end
  end
end
