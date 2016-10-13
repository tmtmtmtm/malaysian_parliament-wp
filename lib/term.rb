require 'nokogiri'
require_relative 'table'

class Term < Page

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

  def tables
    noko.xpath('//h2[span[contains(text(), "Elected members")]]/following-sibling::table')
  end
end
