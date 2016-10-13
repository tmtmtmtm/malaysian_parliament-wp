require 'nokogiri'
require_relative 'table'

class Term
  def initialize(term, url)
    @term = term
    @url = url
  end

  def to_h
    {
      members: tables.map do |table|
        Table.new(table).to_a
      end.flatten
    }[:members].each do |mem|
      mem[:term] = term
      end
  end

  private

  attr_reader :url, :term

  def doc
    @doc ||= noko_for(url)
  end

  def noko_for(url)
    Nokogiri::HTML(open(url).read)
  end

  def tables
    doc.xpath('//h2[span[contains(text(), "Elected members")]]/following-sibling::table')
  end
end
