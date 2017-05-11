#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'pry'
require 'scraped'
require 'scraperwiki'
require 'uri'

require_rel 'lib/remove_notes'
require_rel 'lib/remove_party_counts'
require_rel 'lib/unspan_all_tables'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

terms = {
  1  => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_1st_Malayan_Parliament',
  2  => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_2nd_Malaysian_Parliament',
  3  => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_3rd_Malaysian_Parliament',
  4  => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_4th_Malaysian_Parliament',
  5  => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_5th_Malaysian_Parliament',
  6  => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_6th_Malaysian_Parliament',
  7  => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_7th_Malaysian_Parliament',
  8  => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_8th_Malaysian_Parliament',
  9  => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_9th_Malaysian_Parliament',
  10 => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_10th_Malaysian_Parliament',
  11 => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_11th_Malaysian_Parliament',
  12 => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_12th_Malaysian_Parliament',
  13 => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_13th_Malaysian_Parliament',
}

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

class MembershipRow < Scraped::HTML
  field :id do
    to_slugify = member ? member.attr('title') : tds[2].text
    binding.pry if to_slugify.downcase.include? 'party'
    to_slugify.downcase.tr(' ', '_').gsub('_(page_does_not_exist)', '')
  end

  field :name do
    member ? member.text.strip : tds[2].text.strip
  end

  field :state do
    noko.xpath('.//preceding::h3[1]').css('span.mw-headline').text.strip
  end

  field :constituency do
    tds[1].text.strip
  end

  field :constituency_id do
    '%s-%s' % [tds[0].text.strip, term]
  end

  field :wikipedia do
    href = tds[2].xpath('.//a[not(@class="new")]/@href') or return
    # TODO make this absolute again. This version is just to make sure
    # we have minimal diffs
    href.text.sub('https','http')
  end

  field :wikipedia__en do
    href = tds[2].xpath('.//a[not(@class="new")]/@title') or return
    href.text
  end

  field :party_id do
    pid = party_and_coalition.first[:id]
    return 'PKR' if pid == 'KeADILan'
    pid
  end

  field :party do
    party_and_coalition.first[:name]
  end

  field :term do
    url.sub('https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_','').to_i
  end

  field :source do
    url
  end

  field :area do
    [constituency, state].reject(&:empty?).compact.join(', ')
  end

  field :coalition do
    coalition_data[:name] if coalition_data
  end

  field :coalition_id do
    coalition_data[:id] if coalition_data
  end

  def vacant?
    tds[3].text == 'VAC' rescue binding.pry
  end

  private

  def tds
    @tds ||= noko.css('td')
  end

  def member
    @member ||= tds[2].at_xpath('a')
  end

  def coalition_data
    party_and_coalition.last
  end

  def party_and_coalition
    unknown = { id: 'unknown', name: 'unknown' }
    binding.pry unless td = tds[3]
    return [] if tds[3].text == 'VAC'
    #return [unknown, unknown] if td.css('a').count == 0
    binding.pry if td.css('a').count == 0
    expand = ->(a) { { id: a.text, name: a.xpath('@title').text.split('(').first.strip } }
    return [expand.call(td.css('a')), nil] if td.css('a').count == 1
    td.css('a').reverse.map { |a| expand.call(a) }
  end
end

class ListPage < Scraped::HTML
  decorator RemovePartyCounts
  decorator UnspanAllTables
  decorator RemoveNotes
  decorator Scraped::Response::Decorator::AbsoluteUrls

  field :members do
    noko.xpath('//table[.//th[.="Member"]]//tr[td[4]]').reject { |tr| tr.css('td').first.text == tr.css('td').last.text }.map do |row|
      fragment row => MembershipRow
    end
  end
end

def scrape_term(term, url)
  page = ListPage.new(response: Scraped::Request.new(url: url).response)
  # TODO: can remove the reject once everything is consistent
  data = page.members.reject { |m| m.vacant? }.map { |m| m.to_h.reject { |_,v| v.to_s.empty? } }
  # puts data
  ScraperWiki.save_sqlite(%i(id constituency term), data)
  data.count
end

# Start with a clean slate
ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
terms.each do |term, url|
  added = scrape_term(term, url)
  puts "Term #{term}: #{added}"
end
