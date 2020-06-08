module Rover
  class Group
    def initialize(df, columns)
      @df = df
      @columns = Array(columns)
    end

    # TODO make more efficient
    def count
      raise ArgumentError, "No columns given" if @columns.empty?
      missing_keys = @columns - @df.keys
      raise ArgumentError, "Missing keys: #{missing_keys.join(", ")}" if missing_keys.any?

      result = Hash.new(0)
      if @columns.size == 1
        @df[@columns.first].each do |v|
          result[v] += 1
        end
      else
        @df.each_row do |row|
          result[@columns.map { |c| row[c] }] += 1
        end
      end
      result.default = nil
      result
    end
  end
end
