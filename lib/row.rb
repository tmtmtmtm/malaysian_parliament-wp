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
    id_from_anchor || id_from_name
  end

  field :name do
    tds[-2].xpath('a').text.tidy
  end

  field :coalition do
    return if coalition_node.nil?
    coalition_node.xpath('@title').text
  end

  field :coalition_id do
    return if coalition_node.nil?
    coalition_node.text
  end

  field :party do
    return if party_node.nil?
    party_node.xpath('@title').text
  end

  field :party_id do
    return if party_node.nil?
    party_node.text
  end

  field :state do
    tds.xpath('./preceding::h3[1]/span[1]')
       .text
       .tidy
  end

  field :wikipedia do
    return if wikiless?
    wiki_base +
      name_cell.xpath('a/@href').text.tidy
  end

  field :wikipedia_en do
    return if wikiless?
    name_cell.xpath('a/@title').text.tidy
  end

  field :start_date do
    return unless date_string.include? 'from'
    from_date = date_string.split('from')[1].tidy.split('until')[0].tidy
    date_or_year(from_date)
  end

  field :end_date do
    return unless date_string.include? 'until'
    until_date = date_string.split('until')[1].tidy
    date_or_year(until_date)
  end

  private

  attr_reader :tds

  def id_from_anchor
    name_cell.xpath('a/@title')
          .text
          .downcase
          .gsub(/ /,'_')
          .gsub('_(page_does_not_exist)','')
    rescue nil
  end

  def id_from_name
    name_cell.xpath('a').text.tidy.downcase.tr(' ', '_')
  end

  def party_node
    return affiliation_cell[0] unless affiliation_cell.count > 1
    affiliation_cell[1]
  end

  def coalition_node
    return affiliation_cell[0] unless affiliation_cell.count < 2
  end

  def affiliation_cell
    tds[-1].xpath('b/a')
  end

  def name_cell
    tds[-2]
  end

  def date_string
    name_cell.xpath('small').text
  end

  def date_or_year(date_str)
    Date.parse(date_str).to_s rescue year_only(date_str)
  end

  def year_only(str)
    m = str.match(/\b((19|20)\d{2})\b/)
    return unless m
    m.to_s
  end

  def wiki_base
    'http://en.wikipedia.org'
  end

  def wikiless?
    name_cell.xpath('a/@class').text == 'new'
  end
end
