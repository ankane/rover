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

    def read_parquet(path)
      require "parquet"
      arrow_table_to_df(Arrow::Table.load(path))
    end

    def parse_parquet(str)
      require "parquet"
      arrow_table_to_df(Arrow::Table.load(Arrow::Buffer.new(str), format: :parquet))
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

    PARQUET_TYPE_MAPPING = {
      "bool" => Numo::Bit,
      "float" => Numo::SFloat,
      "double" => Numo::DFloat,
      "int8" => Numo::Int8,
      "int16" => Numo::Int16,
      "int32" => Numo::Int32,
      "int64" => Numo::Int64,
      "string" => Numo::RObject,
      "binary" => Numo::RObject,
      "decimal" => Numo::RObject,
      "uint8" => Numo::UInt8,
      "uint16" => Numo::UInt16,
      "uint32" => Numo::UInt32,
      "uint64" => Numo::UInt64
    }

    # @param [Arrow::Table] table
    # @return [Rover::DataFrame]
    def arrow_table_to_df(table)
      data = {}
      table.each_column do |column|
        k = column.field.name
        type = column.field.data_type.to_s
        numo_type = PARQUET_TYPE_MAPPING[format_arrow_type(type)]
        raise "Unknown type: #{type}" unless numo_type
        # TODO improve performance
        data[k] = numo_type.cast(column.data.values)
      end
      DataFrame.new(data)
    end

    # Decimal in parquet can have a lot of types, for example decimal128(38, 15) or decimal(10, 2)
    def format_arrow_type(type)
      PARQUET_TYPE_MAPPING.key?(type) ? type : type[/\Adecimal/]
    end
  end
end
