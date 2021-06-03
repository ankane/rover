module Rover
  class Group
    def initialize(df, columns)
      @df = df
      @columns = columns
    end

    def group(*columns)
      Group.new(@df, @columns + columns.flatten)
    end

    [:count, :max, :min, :mean, :median, :percentile, :sum, :std, :var].each do |name|
      define_method(name) do |*args|
        n = [name, args.first].compact.join("_")

        rows = []
        grouped_dfs.each do |k, df|
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
        groups.keys.each do |k|
          result[k] = @df[groups[k]]
        end
        result
      end
    end
  end
end
