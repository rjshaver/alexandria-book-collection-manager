# Copyright (C) 2004-2005 Laurent Sansonetti
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
# write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.

module Alexandria
    class ImportFilter
        attr_reader :name, :patterns, :message

        include GetText
        extend GetText
        bindtextdomain(Alexandria::TEXTDOMAIN, nil, nil, "UTF-8")
        
        def self.all
            [
                self.new(_("Autodetect"), ['*'], :import_autodetect),
                self.new(_("Archived Tellico XML (*.bc, *.tc)"), 
                         ['*.tc', '*.bc'], :import_as_tellico_xml_archive),
                self.new(_("ISBN List (*.txt)"), ['*.txt'],
                         :import_as_isbn_list)
            ]
        end
   
        def on_iterate(&on_iterate_cb)
            @on_iterate_cb = on_iterate_cb
        end

        def on_error(&on_error_cb)
            @on_error_cb = on_error_cb
        end
   
        def invoke(library_name, filename)
            Library.send(@message, library_name, filename,
                         @on_iterate_cb, @on_error_cb)
        end
        
        #######
        private
        #######

        def initialize(name, patterns, message)
            @name = name
            @patterns = patterns
            @message = message
        end
    end

    class Library
        def self.import_autodetect(*args)
            import_as_isbn_list(*args) or import_as_tellico_xml_archive(*args)
        end
        
        def self.import_as_tellico_xml_archive(name, filename,
                                               on_iterate_cb, on_error_cb)
            return nil unless system("unzip -qqt \"#{filename}\"")
            tmpdir = File.join(Dir.tmpdir, "tellico_export")
            FileUtils.rm_rf(tmpdir) if File.exists?(tmpdir)
            Dir.mkdir(tmpdir)
            Dir.chdir(tmpdir) do
                begin
                    system("unzip -qq \"#{filename}\"")
                    file = File.exists?('bookcase.xml') \
                        ? 'bookcase.xml' : 'tellico.xml'
                    xml = REXML::Document.new(File.open(file))
                    raise unless (xml.root.name == 'bookcase' or 
                                  xml.root.name == 'tellico')
                    # FIXME: handle multiple collections
                    raise unless xml.root.elements.size == 1
                    collection = xml.root.elements[1]
                    raise unless collection.name == 'collection'
                    type = collection.attribute('type').value.to_i
		            raise unless (type == 2 or type == 5)
                    
                    content = []
                    entries = collection.elements.to_a('entry')
                    (total = entries.size).times do |n|
                        entry = entries[n]
                        elements = entry.elements
                        book = Book.new(elements['title'].text,
                                        elements['authors'].elements.to_a.map \
                                            { |x| x.text },
                                        elements['isbn'].text,
                                        elements['publisher'].text,
                                        elements['binding'].text)
                        content << [ book, elements['cover'] \
                                                ? elements['cover'].text \
                                                : nil ]
                        on_iterate_cb.call(n+1, total) if on_iterate_cb
                    end

                    library = Library.load(name)
                    content.each do |book, cover|
                        unless cover.nil?
                            library.save_cover(book, 
                                               File.join(Dir.pwd, "images", 
                                                         cover))
                        end
                        library << book
                        library.save(book)
                    end
                    break library
                rescue
                    break nil
                end
            end
        end
        
        def self.import_as_isbn_list(name, filename, on_iterate_cb, 
                                     on_error_cb)
            isbn_list = IO.readlines(filename).map do |line|
                canonicalise_isbn(line.chomp) rescue nil
            end 
            return nil unless isbn_list.all?
            books = []
            isbn_list.each_with_index do |isbn, n|
                begin
                    books << Alexandria::BookProviders.isbn_search(isbn)
                rescue => e
                    return nil unless
                        (on_error_cb and on_error_cb.call(e.message))
                end
                on_iterate_cb.call(n+1, isbn_list.length) if on_iterate_cb
            end
            library = load(name)
            books.each do |book, cover_uri|
                library.save_cover(book, cover_uri) if cover_uri != nil
                library << book
                library.save(book)
            end
            return library
        end
    end
end