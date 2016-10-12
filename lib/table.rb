require_relative 'row'

class Table
  def initialize(node)
    @table = node
  end

  def rows
    constituency = nil
    constituency_id = nil
    table.xpath('.//tr[td]').map do |tr|
      tds = tr.xpath('./td')
      next if tds.count == 1
      constituency = tds.shift.text.strip.gsub("\n", ' — ') if tds.count > 2
      constituency_id = tds.shift.text if tds.count > 2
      Row.new(tds).to_h.merge(constituency: constituency, constituency_id: constituency_id)
    end.compact
  end

  private

  attr_reader :table
end
