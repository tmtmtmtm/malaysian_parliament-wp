require 'field_serializer'
require 'nokogiri'

class String
  def tidy
    gsub(/[[:space:]]+/, ' ').strip
  end
end

class Row
  include FieldSerializer

  def initialize(tds)
    @tds = tds
  end

  field :id do
    tds[0].xpath('a/@title')
          .text
          .downcase
          .gsub(/ /,'_')
          .gsub('_(page_does_not_exist)','')
  end

  field :name do
    tds[0].xpath('a').text.tidy
  end

  field :coalition do
    tds[1].xpath('b/a/@title')[0].text rescue 'unknown'
  end

  field :coalition_id do
    tds[1].xpath('b/a')[0].text rescue 'unknown'
  end

  field :party do
    tds[1].xpath('b/a/@title')[1].text rescue 'unknown'
  end

  field :party_id do
    tds[1].xpath('b/a')[1].text rescue 'unknown'
  end

  field :state do
    tds.xpath('./preceding::h3[1]')
       .text
       .gsub('[edit]', '')
       .tidy
  end

  field :wikipedia do
    wiki_link
  end

  field :wikipedia_en do
    wiki_name
  end

  field :start_date do
    s = tds[0].xpath('small').text
    return unless s.include? 'from'
    Date.parse(s.split('from')[1].tidy).to_s
  end

  field :end_date do
    s = tds[0].xpath('small').text
    return unless s.include? 'until'
    Date.parse(s.split('until')[1].tidy).to_s
  end

  private

  attr_reader :tds

  def wiki_link
    return if wikiless?
    wiki_base +
      tds[0].xpath('a/@href').text.tidy
  end

  def wiki_name
    return if wikiless?
    tds[0].xpath('a/@title').text.tidy
  end

  def wiki_base
    'http://en.wikipedia.org'
  end

  def wikiless?
    tds[0].xpath('a/@class').text == 'new'
  end
end
