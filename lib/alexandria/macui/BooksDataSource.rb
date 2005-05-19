# Copyright (C) 2005 Laurent Sansonetti
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
module UI
    class BooksDataSource < OSX::NSObject
        include OSX
        
        attr_accessor :library
        
        def numberOfRowsInTableView(tableView)
            @library != nil ? @library.length : 0
        end
        
        def tableView_objectValueForTableColumn_row (tableView, col, row)
            book = @library[row]
            case col.identifier.to_s
                when 'title'
                    book.title
                when 'authors'
                    book.authors.join(', ')
                when 'isbn'
                    book.isbn
                when 'publisher'
                    book.publisher
                when 'binding'
                    book.edition
            end
        end
    end
end
end