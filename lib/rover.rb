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

    def read_parquet(path, types: nil)
      require "parquet"
      parquet_to_df(Arrow::Table.load(path), types: types)
    end

    def parse_parquet(str, types: nil)
      require "parquet"
      parquet_to_df(Arrow::Table.load(Arrow::Buffer.new(str), format: :parquet), types: types)
    end

    private

    # TODO use date converter
    def csv_options(options)
      options = {headers: true, converters: :numeric}.merge(options)
      raise ArgumentError, "Must specify headers" unless options[:headers]
      options
    end

    def csv_to_df(table, types: nil, headers: nil)
      if headers && table[0] && headers.size < table[0].size
        raise ArgumentError, "Expected #{table[0].size} headers, got #{headers.size}"
      end
      table = table.to_a

      data = {}
      keys = {}
      unnamed_suffix = 1
      table.shift.each_with_index do |k, v|
        # TODO do same for empty string in 0.3.0
        if k.nil?
          k = "unnamed"
          while data.include?(k)
            unnamed_suffix += 1
            k = "unnamed#{unnamed_suffix}"
          end
        end
        data[k] = []
        keys[v] = k
      end

      table.each do |v|
        v.each_with_index do |k, v|
          data[keys[v]].push(k)
        end
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
      "uint8" => Numo::UInt8,
      "uint16" => Numo::UInt16,
      "uint32" => Numo::UInt32,
      "uint64" => Numo::UInt64
    }

    def parquet_to_df(table, types: nil)
      data = {}
      types ||= {}
      table.each_column do |column|
        k = column.field.name
        if types[k]
          data[k] = Vector.new(column.data.values, type: types[k])
        else
          type = column.field.data_type.to_s
          numo_type = PARQUET_TYPE_MAPPING[type]
          raise "Unknown type: #{type}" unless numo_type

          # TODO automatic conversion?
          # int => float
          # bool => object
          if (type.include?("int") || type == "bool") && column.n_nulls > 0
            raise "Nulls not supported for #{type} column: #{k}"
          end

          # TODO improve performance
          data[k] = numo_type.cast(column.data.values)
        end
      end
      DataFrame.new(data)
    end
  end
end
