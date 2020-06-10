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
      csv_to_df(CSV.read(path, **csv_options(options)), types: types)
    end

    def parse_csv(str, types: nil, **options)
      require "csv"
      csv_to_df(CSV.parse(str, **csv_options(options)), types: types)
    end

    private

    # TODO use date converter
    def csv_options(options)
      options = {headers: true, converters: :numeric}.merge(options)
      raise ArgumentError, "Must specify headers" unless options[:headers]
      options
    end

    def csv_to_df(table, types: nil)
      table.by_col!
      data = {}
      table.each do |k, v|
        data[k] = v
      end
      DataFrame.new(data, types: types)
    end
  end
end
