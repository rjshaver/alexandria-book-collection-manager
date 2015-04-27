# Alexandria

Alexandria is a GNOME application for managing collections of books.

Alexandria is written in Ruby, and is free software, distributed under
the terms of the GNU General Public License, version 2 or later. See
the file COPYING for more information.

What is Alexandria?
===================

Alexandria is an application for managing a personal book library.
Its main recommending feature is its clean, intuitive interface.
Alexandria is able to retrieve book information and cover images from
a wide variety of online data sources. It also features extensive
import and export options, a loan interface, and smart libraries.
Alexandria is written in Ruby using ruby-gnome2.

Where can I get it?
===================

An experimental gem release can be installed by running

    gem install alexandria-book-collection-manager

Alternatively, download the source from the github repository at
http://www.github.com/mvz/alexandria-book-collection-manager and follow the
installation instructions.

Where can I find out more?
==========================

For source code and bug reporting, see the repository on github at
http://www.github.com/mvz/alexandria-book-collection-manager.

## Features

Alexandria is a simple program designed to allow individuals to keep a
catalogue of their book collection. In addition, it enables users to
keep track of books which are on loan.

    * retrieves and displays book information (sometimes with cover
      pictures) from several online libraries and bookshops, such as
          o Amazon
          o Proxis
          o DeaStore
          o AdLibris
          o Spanish Ministry of Culture
          o Livraria Siciliano
          o WorldCat
          o US Library of Congress
          o British Library
    * allows books to be added and updated by hand
    * enables searches either by ISBN, title, author or keyword
    * supports the Z39.50 standard and allow you to manage your own
      sources (e.g. university libraries)
    * saves data using the plain-text YAML format
    * can import and export data into ONIX, Tellico, ISBN-list
      and GoodReads CSV formats
    * can export XHTML web pages of your libraries, themable with CSS
    * allows marking your books as loaned, each with the loan-date and
      the name of the person who has borrowed them
    * features a HIG-compliant user interface
    * shows books in different views (standard list or icons list),
      that can be filtered and/or sorted
    * handles book rating and notes
    * supports CueCat and standard "keyboard wedge" barcode readers
    * includes translations for several languages
    * is documented in a complete manual (at the moment only in
      English and Japanese)

Alexandria is not without problems. See doc/BUGS for a summary of issues.

## Installation

There are full instructions for installing Alexandria from source in the
file INSTALL, including information about all the dependencies.

If you are installing on a Debian-based system, things should be
easier as the dependencies can be handled automatically.

To run the program, just type
    alexandria
or, to get verbose debugging information,
    alexandria --debug

If you are running GNOME, Alexandria should appear under the
'Applications > Office' menu.