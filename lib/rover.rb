# dependencies
require "numo/narray"

# modules
require "rover/data_frame"
require "rover/group"
require "rover/vector"
require "rover/version"

module Rover
  class << self
    def read_csv(path, types: nil, **options)
      require "csv"
      csv_to_df(CSV.read(path, **csv_options(options)), types: types, headers: options[:headers])
    end

    def parse_csv(str, types: nil, **options)
      require "csv"
      csv_to_df(CSV.parse(str, **csv_options(options)), types: types, headers: options[:headers])
    end

    private

    # TODO use date converter
    def csv_options(options)
      options = {headers: true, converters: :numeric}.merge(options)
      raise ArgumentError, "Must specify headers" unless options[:headers]
      options
    end

    def csv_to_df(table, types: nil, headers: nil)
      if headers && headers.size < table.headers.size
        raise ArgumentError, "Expected #{table.headers.size} headers, got #{headers.size}"
      end

      table.by_col!
      data = {}
      keys = table.map { |k, _| [k, true] }.to_h
      unnamed_suffix = 1
      table.each do |k, v|
        # TODO do same for empty string in 0.3.0
        if k.nil?
          k = "unnamed"
          while keys.include?(k)
            unnamed_suffix += 1
            k = "unnamed#{unnamed_suffix}"
          end
          keys[k] = true
        end
        data[k] = v
      end

      DataFrame.new(data, types: types)
    end
  end
end
