# Copyright (C) 2009 Cathal Mc Ginley
# Copyright (C) 2014-2016 Matijs van Zuijlen
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

# New Proxis provider, taken from Palatina MetaDataSource and modified
# for Alexandria. (20 Dec 2009)

require 'cgi'
require 'alexandria/book_providers/web'

module Alexandria
  class BookProviders
    class ProxisProvider < WebsiteBasedProvider
      # include GetText
      include Alexandria::Logging
      # GetText.bindtextdomain(Alexandria::TEXTDOMAIN, :charset => "UTF-8")

      # Proxis essentially has three book databases, NL, FR and EN.
      # Currently, this provider only searches the NL database, since
      # it adds most to Alexandria (Amazon already has French and
      # English titles).

      SITE = 'http://www.proxis.nl'.freeze
      BASE_SEARCH_URL = "#{SITE}/NLNL/Search/IndexGSA.aspx?search=%s" \
        '&shop=100001NL&SelRubricLevel1Id=100001NL'.freeze
      ISBN_REDIRECT_BASE_URL = "#{SITE}/NLNL/Search/Index.aspx?search=%s" \
        '&shop=100001NL&SelRubricLevel1Id=100001NL'.freeze

      def initialize
        super('Proxis', 'Proxis (Belgium)')
        # prefs.add("lang", _("Language"), "fr",
        #          LANGUAGES.keys)
        prefs.read
      end

      def search(criterion, type)
        req = create_search_uri(type, criterion)
        puts req if $DEBUG
        html_data = transport.get_response(URI.parse(req))

        results = parse_search_result_data(html_data.body)
        raise NoResultsError if results.empty?
        if type == SEARCH_BY_ISBN
          get_book_from_search_result(results.first)
        else
          results.map { |result| get_book_from_search_result(result) }
        end
      end

      def create_search_uri(search_type, search_term)
        if search_type == SEARCH_BY_ISBN
          BASE_SEARCH_URL % Library.canonicalise_ean(search_term)
        else
          BASE_SEARCH_URL % CGI.escape(search_term)
        end
      end

      def get_book_from_search_result(result)
        log.debug { "Fetching book from #{result[:lookup_url]}" }
        html_data = transport.get_response(URI.parse(result[:lookup_url]))
        parse_result_data(html_data.body)
      end

      def url(book)
        ISBN_REDIRECT_BASE_URL % Library.canonicalise_ean(book.isbn) if book.isbn.nil? || book.isbn.empty?
      end

      ## from Palatina
      def text_of(node)
        if node.nil?
          nil
        else
          if node.text?
            node.to_html
          elsif node.elem?
            if node.children.nil?
              nil
            else
              node_text = node.children.map { |n| text_of(n) }.join
              node_text.strip.squeeze(' ')
            end
          end
          # node.inner_html.strip
        end
      end

      def parse_search_result_data(html)
        doc = html_to_doc(html)
        book_search_results = []
        items = doc.search('table.searchResult tr')
        items.each do |item|
          result = {}
          title_link = item % 'h5 a'
          if title_link
            result[:title] = text_of(title_link)
            result[:lookup_url] = title_link['href']
            result[:lookup_url] = "#{SITE}#{result[:lookup_url]}" unless result[:lookup_url] =~ /^http/
          end
          book_search_results << result
        end
        # require 'pp'
        # pp book_search_results
        # raise :Ruckus
        book_search_results
      end

      def data_for_header(th)
        tr = th.parent
        td = tr.at('td')
        text_of(td) if td
      end

      def parse_result_data(html)
        doc = html_to_doc(html)
        book_data = {}
        book_data[:authors] = []
        # TITLE
        if (title_header = doc.search('div.detailBlock h3'))
          header_spans = title_header.first.search('span')
          title = text_of(header_spans.first)
          title = Regexp.last_match[1].strip if title =~ /(.+)-$/
          book_data[:title] = title
        end

        info_headers = doc.search('table.productInfoTable th')

        isbns = []
        unless info_headers.empty?
          info_headers.each do |th|
            isbns << data_for_header(th) if th.inner_text =~ /(ISBN|EAN)/
          end
          book_data[:isbn] = Library.canonicalise_ean(isbns.first)
        end

        # book = Book.new(title, ISBN.get(isbns.first))

        unless info_headers.empty?
          info_headers.each do |th|
            header_text = th.inner_text
            if header_text =~ /Type/
              book_data[:binding] = data_for_header(th)
            elsif header_text =~ /Verschijningsdatum/
              date = data_for_header(th)
              date =~ /\/([\d]{4})/
              book_data[:publish_year] = Regexp.last_match[1].to_i
            elsif header_text =~ /Auteur/
              book_data[:authors] << data_for_header(th)
            elsif header_text =~ /Uitgever/
              book_data[:publisher] = data_for_header(th)
            end
          end
        end

        image_url = nil
        if (cover_img = doc.at("img[@id$='imgProduct']"))
          image_url = if cover_img['src'] =~ /^http/
                        cover_img['src']
                      else
                        "#{SITE}/#{cover_img['src']}" # TODO: use html <base>
                      end
          image_url = nil if image_url =~ /ProductNoCover/
        end

        book = Book.new(book_data[:title], book_data[:authors],
                        book_data[:isbn], book_data[:publisher],
                        book_data[:publish_year], book_data[:binding])
        [book, image_url]
      end
    end
  end
end
