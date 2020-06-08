module Rover
  class Group
    def initialize(df, columns)
      @df = df
      @columns = Array(columns)
    end

    def count
      operation(:count)
    end

    [:max, :min, :mean, :median, :percentile, :sum].each do |name|
      define_method(name) do |column, *args|
        operation(name, column, *args)
      end
    end

    private

    def operation(method, *args)
      check_columns(args.first)

      result = {}
      grouped_dfs.each do |k, df|
        result[k] = df.send(method, *args)
      end
      result
    end

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

    def check_columns(column)
      raise ArgumentError, "No columns given" if @columns.empty?
      missing_keys = @columns + [column].compact - @df.keys
      raise ArgumentError, "Missing keys: #{missing_keys.join(", ")}" if missing_keys.any?
    end
  end
end
