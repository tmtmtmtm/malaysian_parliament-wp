# frozen_string_literal: true

require 'scraped'
require 'table_unspanner'

# Remove all TRs that span the whole table - i.e with party counts
class RemovePartyCounts < Scraped::Response::Decorator
  def body
    Nokogiri::HTML(super).tap do |doc|
      doc.xpath('.//tr[.//td[@colspan="4"]]').remove
    end.to_s
  end
end
