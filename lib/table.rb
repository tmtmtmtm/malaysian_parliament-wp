require_relative 'row'

class Table
  def initialize(node)
    @table = node
  end

  def to_a
    constituency = nil
    constituency_id = nil
    table.xpath('.//tr[td]').map do |tr|
      tds = tr.xpath('./td')
      next if tds.count == 1
      constituency_id = tds.shift.text.strip if tds.count > 2
      constituency = tds.shift.text.strip if tds.count > 2
      Row.new(tds).to_h.merge(constituency: constituency, constituency_id: constituency_id)
    end.compact
  end

  private

  attr_reader :table
end
