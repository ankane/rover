module Rover
  class Group
    def initialize(df, columns)
      @df = df
      @columns = columns
      check_columns
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

    def plot(*args, **options)
      raise ArgumentError, "Multiple groups not supported" if @columns.size > 1
      # same message as Ruby
      raise ArgumentError, "unknown keyword: :group" if options.key?(:group)

      @df.plot(*args, **options, group: @columns.first)
    end

    private

    # TODO make more efficient
    def grouped_dfs
      # cache here so we can reuse for multiple calcuations if needed
      @grouped_dfs ||= begin
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

    def check_columns
      raise ArgumentError, "No columns given" if @columns.empty?

      missing_keys = @columns - @df.keys
      raise ArgumentError, "Missing keys: #{missing_keys.join(", ")}" if missing_keys.any?
    end
  end
end
