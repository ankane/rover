module Rover
  class Group
    def initialize(df, columns)
      @df = df
      @columns = Array(columns)
    end

    # TODO make more efficient
    def count
      check_columns

      result = {}
      grouped_dfs.each do |k, df|
        result[k] = df.count
      end
      result
    end

    def max(column)
      check_columns([column])

      result = {}
      grouped_dfs.each do |k, df|
        result[k] = df.max(column)
      end
      result
    end

    private

    # TODO make more efficient
    def grouped_dfs
      groups = Hash.new { |hash, key| hash[key] = [] }
      if @columns.size == 1
        @df[@columns.first].each_with_index do |v, i|
          groups[v] << i
        end
      else
        i = 0
        @df.each_row do |row|
          groups[@columns.map { |c| row[c] }] << i
          i += 1
        end
      end

      result = {}
      groups.each do |k, indexes|
        result[k] = @df[indexes]
      end
      result
    end

    def check_columns(extra_columns = [])
      raise ArgumentError, "No columns given" if @columns.empty?
      missing_keys = @columns + extra_columns - @df.keys
      raise ArgumentError, "Missing keys: #{missing_keys.join(", ")}" if missing_keys.any?
    end
  end
end
