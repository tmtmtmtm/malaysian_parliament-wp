#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'uri'
require 'require_all'
require_rel 'lib'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

terms = { 
  1 => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_1st_Malayan_Parliament',
  2 => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_2nd_Malaysian_Parliament',
  3 => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_3rd_Malaysian_Parliament',
  4 => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_4th_Malaysian_Parliament',
  5 => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_5th_Malaysian_Parliament',
  6 => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_6th_Malaysian_Parliament',
  7 => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_7th_Malaysian_Parliament',
  8 => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_8th_Malaysian_Parliament',
  9 => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_9th_Malaysian_Parliament',
  10 => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_10th_Malaysian_Parliament',
  11 => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_11th_Malaysian_Parliament',
  12 => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_12th_Malaysian_Parliament',
  13 => 'https://en.wikipedia.org/wiki/Members_of_the_Dewan_Rakyat,_13th_Malaysian_Parliament',
}

def scrape_term(term_number, url)
  term = TermPage.new(url).to_h
  term[:members].each do |member|
    member[:term] = term_number
    ScraperWiki.save_sqlite([:id, :term], member)
  end
  puts "Term #{term_number}: #{term[:members].count}"
end

# Start with a clean slate…
ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
terms.each do |term, url|
  scrape_term(term, url)
end
