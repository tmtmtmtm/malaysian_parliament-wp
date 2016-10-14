require 'nokogiri'
require_relative 'table'

class TermPage < Page

  field :members do
    tables.flat_map { |node| Table.new(node).to_a }
  end

  private

  def tables
    noko.xpath('//h2[span[contains(text(), "Elected members")]]/following-sibling::table')
  end
end
