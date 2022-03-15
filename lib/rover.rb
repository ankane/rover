# dependencies
require "numo/narray"

# modules
require "rover/data_frame"
require "rover/group"
require "rover/vector"
require "rover/version"

module Rover
  class << self
    def read_csv(path, **options)
      csv_to_df(**options) do |csv_options|
        CSV.read(path, **csv_options)
      end
    end

    def parse_csv(str, **options)
      csv_to_df(**options) do |csv_options|
        CSV.parse(str, **csv_options)
      end
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

    def csv_to_df(types: nil, headers: nil, **csv_options)
      require "csv"
      raise ArgumentError, "Must specify headers" if headers == false

      # TODO use date converter
      table = yield({converters: :numeric}.merge(csv_options))

      if headers && table.first && headers.size < table.first.size
        raise ArgumentError, "Expected #{table.first.size} headers, got #{headers.size}"
      end

      table_headers = (headers || table.shift || []).dup
      # keep same behavior as headers: true
      if table.first
        while table_headers.size < table.first.size
          table_headers << nil
        end
      end

      data = {}
      keys = table_headers.map { |k| [k, true] }.to_h
      unnamed_suffix = 1
      table_headers.each_with_index do |k, i|
        # TODO do same for empty string in 0.3.0
        if k.nil?
          k = "unnamed"
          while keys.include?(k)
            unnamed_suffix += 1
            k = "unnamed#{unnamed_suffix}"
          end
          keys[k] = true
        end
        table_headers[i] = k
      end

      table_headers.each_with_index do |k, i|
        values = []
        table.each do |row|
          values << row[i]
        end
        data[k] = values
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
