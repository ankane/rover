module Rover
  class Group
    def initialize(df, columns)
      @df = df
      @columns = Array(columns)
    end

    [:count, :max, :min, :mean, :median, :percentile, :sum].each do |name|
      define_method(name) do |*args|
        rows = []
        grouped_dfs.each do |k, df|
          n = [name, args.first].compact.join("_")
          rows << k.merge(n => df.send(name, *args))
        end

        DataFrame.new(rows)
      end
    end

    private

    # TODO make more efficient
    def grouped_dfs
      # cache here so we can reuse for multiple calcuations if needed
      @grouped_dfs ||= begin
        raise ArgumentError, "No columns given" if @columns.empty?
        missing_keys = @columns - @df.keys
        raise ArgumentError, "Missing keys: #{missing_keys.join(", ")}" if missing_keys.any?

        groups = Hash.new { |hash, key| hash[key] = [] }
        i = 0
        @df.each_row do |row|
          groups[row.slice(*@columns)] << i
          i += 1
        end

        result = {}
        groups.keys.sort_by { |v| v.values_at(*@columns) }.each do |k|
          result[k] = @df[groups[k]]
        end
        result
      end
    end
  end
end
