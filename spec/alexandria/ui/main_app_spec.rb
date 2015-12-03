# Copyright (C) 2007 Joseph Method
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

require File.dirname(__FILE__) + '/../../spec_helper'

# break this up!

describe CellRendererToggle do
  it 'should work'
end

describe Gtk::ActionGroup do
  it 'should work'
end

describe Gtk::IconView do
  it 'should work'
end

describe Alexandria::UI::MainApp do
  it 'should be a singleton' do
    expect do
      Alexandria::UI::MainApp.new
    end.to raise_error NoMethodError
  end

  it 'runs' do
    @main_app = Alexandria::UI::MainApp.instance

    exception = nil
    # FIXME: Function should take a block automatically
    GLib.timeout_add(GLib::PRIORITY_DEFAULT, 100, proc do
      begin
        @main_app.main_app.destroy
      rescue => e
        exception = e
      end
      Gtk.main_quit
    end, nil, nil)

    Gtk.main
    raise exception if exception
  end
end
