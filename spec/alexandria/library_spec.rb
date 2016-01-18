#-- -*- ruby -*-
# Copyright (C) 2004-2006 Dafydd Harries
# Copyright (C) 2007 Cathal Mc Ginley
# Copyright (C) 2011, 2014, 2015 Matijs van Zuijlen
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

require 'spec_helper'

describe Alexandria::Library do
  describe '::EXT' do
    it 'has symbolic references to file extensions' do
      extensions = Alexandria::Library::EXT
      expect(extensions[:book]).not_to be_nil
      expect(extensions[:cover]).not_to be_nil
    end
  end

  describe '#valid_isbn?' do
    it 'returns a true value for valid isbns' do
      for x in ['014143984X', '0-345-43192-8']
        expect(Alexandria::Library.valid_isbn?(x)).to be_truthy
      end
    end
  end

  describe '#valid_ean?' do
    it 'returns a true value for valid EANs' do
      expect(Alexandria::Library.valid_ean?('9780345431929')).to be_truthy

      # Regression test: this EAN has a checksum of 10, which should be
      # treated like a checksum of 0.
      expect(Alexandria::Library.valid_ean?('9784047041790')).to be_truthy
    end
  end

  describe '#canonicalise_isbn' do
    it 'returns the correct value for several examples' do
    expect(Alexandria::Library.canonicalise_isbn('014143984X')).to eq '014143984X'
    expect(Alexandria::Library.canonicalise_isbn('0-345-43192-8')).to eq '0345431928'
    expect(Alexandria::Library.canonicalise_isbn('3522105907')).to eq '3522105907'
    # EAN number
    expect(Alexandria::Library.canonicalise_isbn('9780345431929')).to eq '0345431928'
    end
  end

  context 'with an empty library' do
    before(:each) do
      FileUtils.mkdir(TESTDIR) unless File.exist? TESTDIR
    end

    it 'disallows multiple deletion of the same copy of a book' do
      my_library = Alexandria::Library.loadall[0]
      first_copy = an_artist_of_the_floating_world
      my_library << first_copy
      my_library.delete(first_copy)
      expect { my_library.delete(first_copy) }.to raise_error ArgumentError
    end

    it 'allows multiple copies of a book to be added and deleted in turn' do
      my_library = Alexandria::Library.loadall[0]
      first_copy = an_artist_of_the_floating_world
      # puts "first_copy #{first_copy.object_id}"
      my_library << first_copy
      my_library.delete(first_copy)

      second_copy = an_artist_of_the_floating_world
      my_library << second_copy
      third_copy = an_artist_of_the_floating_world
      my_library << third_copy

      # puts "AAA my_library.size #{my_library.size}"

      # puts "second_copy #{second_copy.object_id}"
      expect { my_library.delete(second_copy) }.not_to raise_error

      # puts "BBB my_library.size #{my_library.size}"
      # my_library.size.should == 1 # not yet an established feature...
    end

    after(:each) do
      FileUtils.rm_rf(TESTDIR)
    end
  end

  describe '.import_as_isbn_list' do
    before :all do
      require 'alexandria/import_library'
    end

    def __test_fake_import_isbns
      libraries = Alexandria::Libraries.instance
      library = Alexandria::Library.new('Test Library')
      libraries.add_library(library)
      [library, libraries]
    end

    it "doesn't work quite yet" do
      skip
      # Doesn't work quite yet.
      on_iterate_cb = proc { }
      on_error_cb = proc { }
      library, _libraries = __test_fake_import_isbns
      test_file = "data/isbns.txt"
      library.import_as_isbn_list("Test Library", test_file, on_iterate_cb, on_error_cb)
    end
  end

  context 'imported from 0.6.1 data files' do
    before(:each) do
      lib_version = File.join(LIBDIR, '0.6.1')
      FileUtils.cp_r(lib_version, TESTDIR)
    end

    it 'imports cleanly from version 0.6.1 data format' do
      libs = Alexandria::Library.loadall
      expect(libs.size).to eq(1)
      my_library = libs[0]
      expect(my_library.size).to eq(3)
      # Malory
      malory_book = my_library.select { |b| b.isbn == '9780192812179' }[0]
      expect(malory_book.publisher).to eq('Oxford University Press')
      expect(malory_book.authors.include?('Vinaver')).to be_truthy
      expect(malory_book.version).to eq(Alexandria::DATA_VERSION)

      # Guide to LaTeX
      latex_book = my_library.select { |b| b.title.include? 'Latex' }[0]
      expect(latex_book.isbn).to eq('9780201398250')
      expect(latex_book.publisher).to eq('Addison Wesley') # note, no Ruby-Amazon cruft
    end

    after(:each) do
      FileUtils.rm_rf(TESTDIR)
    end
  end

  context 'imported from 0.6.1 with books without an ISBN' do
    before(:each) do
      lib_version = File.join(LIBDIR, '0.6.1-noisbn')
      FileUtils.cp_r(lib_version, TESTDIR)
    end

    it 'allows books to have no ISBN' do
      libs = Alexandria::Library.loadall
      expect(libs.size).to eq(1)
      my_library = libs[0]
      expect(my_library.size).to eq(2)

      # Guide to LaTeX
      latex_book = my_library.select { |b| b.title.include? 'Latex' }[0]
      expect(latex_book.isbn).to eq('9780201398250')
      expect(latex_book.publisher).to eq('Addison Wesley') # note, no Ruby-Amazon cruft
      expect(latex_book.version).to eq(Alexandria::DATA_VERSION)

      # Lex and Yacc
      lex_and_yacc_book = my_library.select { |b| b.title.include? 'Lex' }[0]
      expect(lex_and_yacc_book.publisher).to eq("O'Reilley")

      # puts "ident -> " + lex_and_yacc_book.ident

      my_library.each do |book|
        my_library.save(book, true)
      end

      libraries_reloaded = Alexandria::Library.loadall
      my_library_reloaded = libraries_reloaded[0]

      expect(my_library_reloaded.size).to eq(2)

      latex_book = my_library_reloaded.select { |b| b.title.include? 'Latex' }[0]
      expect(latex_book).not_to be_nil
      expect(latex_book.publisher).to eq('Addison Wesley')
      # puts latex_book.title

      lex_and_yacc_book = my_library_reloaded.select { |b| b.title.include? 'Lex' }[0]
      expect(lex_and_yacc_book).not_to be_nil
      expect(lex_and_yacc_book.publisher).to eq("O'Reilley")
      # puts lex_and_yacc_book.title
    end

    after(:each) do
      FileUtils.rm_rf(TESTDIR)
    end
  end

  context 'when exporting' do
    before(:all) do
      require 'tmpdir'
      require 'csv'
    end

    before(:each) do
      lib_version = File.join(LIBDIR, '0.6.2')
      FileUtils.cp_r(lib_version, TESTDIR)
      @format = Alexandria::ExportFormat.new('CSV list', 'csv', :export_as_csv_list)
      @outfile = File.join(Dir.tmpdir, 'my_library-0.6.2.csv')
      @my_library = Alexandria::Library.loadall[0]
    end

    def load_rows_from_csv
      CSV.read(@outfile, col_sep: ';')
    end

    it 'can sort by title' do
      sort_by_title = Alexandria::LibrarySortOrder.new(:title)
      @format.invoke(@my_library, sort_by_title, @outfile)
      expect(File.exist?(@outfile)).to be_truthy
      rows = load_rows_from_csv
      rows.shift
      expect(rows.size).to eq(@my_library.size)
      TITLE = 0
      comparisons = rows.size - 1
      comparisons.times do |index|
        expect(rows[index][TITLE]).to be <= rows[index + 1][TITLE]
      end
    end

    it 'can sort in descending order' do
      sort_by_date_desc = Alexandria::LibrarySortOrder.new(:publishing_year, false)
      @format.invoke(@my_library, sort_by_date_desc, @outfile)
      expect(File.exist?(@outfile)).to be_truthy
      rows = load_rows_from_csv
      rows.shift
      expect(rows.size).to eq(@my_library.size)
      DATE = 5
      comparisons = rows.size - 1
      comparisons.times do |index|
        expect(rows[index][DATE]).to be >= rows[index + 1][DATE]
      end
    end

    after(:each) do
      FileUtils.rm_rf(TESTDIR)
      if File.exist? @outfile
        File.unlink @outfile
      end
    end
  end
end
