module Rover
  class Group
    def initialize(df, columns)
      @df = df
      @columns = Array(columns)
    end

    [:count, :max, :min, :mean, :median, :percentile, :sum].each do |name|
      define_method(name) do |*args|
        result = {}
        grouped_dfs.each do |k, df|
          result[k] = df.send(name, *args)
        end
        result
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
    end
  end
end
