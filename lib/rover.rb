# dependencies
require "numo/narray"

# modules
require "rover/data_frame"
require "rover/vector"
require "rover/version"

module Rover
  class << self
    def read_csv(path, **options)
      require "csv"
      csv_to_df(CSV.read(path, **csv_options(options)))
    end

    def parse_csv(str, **options)
      require "csv"
      csv_to_df(CSV.parse(str, **csv_options(options)))
    end

    private

    # TODO use date converter
    def csv_options(options)
      options = {headers: true, converters: :numeric}.merge(options)
      raise ArgumentError, "Must specify headers" unless options[:headers]
      options
    end

    def csv_to_df(table)
      table.by_col!
      data = {}
      table.each do |k, v|
        data[k] = v
      end
      DataFrame.new(data)
    end
  end
end
