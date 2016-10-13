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
    coalition_node.xpath('@title').text rescue 'unknown'
  end

  field :coalition_id do
    coalition_node.text rescue 'unkown'
  end

  field :party do
    party_node.xpath('@title').text rescue 'unknown'
  end

  field :party_id do
    party_node.text rescue 'unknowm'
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
    from_date = s.split('from')[1].tidy.split('until')[0].tidy
    Date.parse(from_date).to_s
  end

  field :end_date do
    s = tds[0].xpath('small').text
    return unless s.include? 'until'
    until_date = s.split('until')[1].tidy
    Date.parse(until_date).to_s rescue until_date
  end

  private

  attr_reader :tds

  def party_node
    return affiliation_cell[0] unless affiliation_cell.count > 1
    cell[1]
  end

  def coalition_node
    return affiliation_cell[0] unless affiliation_cell.count < 2
  end

  def affiliation_cell
    tds[1].xpath('b/a')
  end

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
