require 'nokogiri'
require_relative 'table'

class Term < Page

  field :members do
    tables.map do |table|
      Table.new(table).to_a
    end.flatten
  end

  private

  def tables
    noko.xpath('//h2[span[contains(text(), "Elected members")]]/following-sibling::table')
  end
end
