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

    def csv_to_numeric(table)
    table.to_a.map.with_index{|x,i|
      i==0 ? x : x.map{|cell| cell ? (cell.tr("^0-9","")==cell ? cell.to_f : Float::NAN) : nil}
    }
    end
    # TODO use date converter
    def csv_options(options)
      options = {headers: true}.merge(options)
      raise ArgumentError, "Must specify headers" unless options[:headers]
      options
    end

    def csv_to_df(table, types: nil, headers: nil)
      if headers && headers.size < table[0].size
        raise ArgumentError, "Expected #{table[0].size} headers, got #{headers.size}"
      end

      table=csv_to_numeric(table)
      data = {}
      keys = {}
      unnamed_suffix = 2
 
      table.shift.each_with_index do |table_key,index|
        key=table_key.to_s
        if key.empty? then
          key="unnamed"
          while data.include?(key)
            key="unnamed#{unnamed_suffix}"
            unnamed_suffix+=1
          end
        end
        data[key]=[]
        keys[index]=key
      end

      table.each do |v|
        v.each_with_index do |val,index|
          data[keys[index]].push(val)
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
