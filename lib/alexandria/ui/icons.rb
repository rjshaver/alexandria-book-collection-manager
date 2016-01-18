# Copyright (C) 2004-2006 Laurent Sansonetti
# Copyright (C) 2014, 2015 Matijs van Zuijlen
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

module GdkPixbuf
  load_class :Pixbuf
end

class GdkPixbuf::Pixbuf
  def tag(tag_pixbuf)
    # Computes some tweaks.
    tweak_x = tag_pixbuf.width / 3
    tweak_y = tag_pixbuf.height / 3

    # Creates the destination pixbuf.
    new_pixbuf = GdkPixbuf::Pixbuf.new(GdkPixbuf::Pixbuf::COLORSPACE_RGB,
                                 true,
                                 8,
                                 width + tweak_x,
                                 height + tweak_y)

    # Fills with blank.
    new_pixbuf.fill!(0)

    # Copies the current pixbuf there (south-west).
    copy_area(0, 0,
              width, height,
              new_pixbuf,
              0, tweak_y)

    # Copies the tag pixbuf there (north-est).
    tag_pixbuf_x = width - (tweak_x * 2)
    new_pixbuf.composite!(tag_pixbuf,
                          0, 0,
                          tag_pixbuf.width + tag_pixbuf_x,
                          tag_pixbuf.height,
                          tag_pixbuf_x, 0,
                          1, 1,
                          GdkPixbuf::Pixbuf::INTERP_HYPER, 255)
    new_pixbuf
  end
end

module Alexandria
  module UI
    module Icons
      ICONS_DIR = File.join(Alexandria::Config::DATA_DIR, 'icons')
      def self.init
        load_icon_images
      end

      # loads icons from icons_dir location and gives them as uppercase constants to
      # Alexandria::UI::Icons namespace, e.g., Icons::STAR_SET
      def self.load_icon_images
        Dir.entries(ICONS_DIR).each do |file|
          next unless file =~ /\.png$/    # skip non '.png' files
          # Don't use upcase and use tr instead
          # For example in Turkish the upper case of 'i' is still 'i'.
          name = File.basename(file, '.png').tr('a-z', 'A-Z')
          const_set(name, GdkPixbuf::Pixbuf.new_from_file(File.join(ICONS_DIR, file)))
        end
      end

      def self.cover(library, book)
        begin
          return BOOK_ICON if library.nil?
          filename = library.cover(book)
          if File.exist?(filename)
            return GdkPixbuf::Pixbuf.new_from_file(filename)
          end
        rescue => err
          # report load error; FIX should go to a Logger...
          puts err.message
          puts err.backtrace.join("\n> ")
          puts "Failed to load GdkPixbuf::Pixbuf, please ensure that from #{filename} is a valid image file"
        end
        BOOK_ICON
      end

      def self.blank?(filename)
        pixbuf = GdkPixbuf::Pixbuf.new_file(filename)
        pixbuf.width == 1 and pixbuf.height == 1
      rescue => err
        puts err.message
        puts err.backtrace.join("\n> ")
        true
      end
    end
  end
end
