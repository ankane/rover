module Rover
  class DataFrame
    def initialize(*args)
      data, options = process_args(args)

      @vectors = {}
      types = options[:types] || {}

      if data.is_a?(DataFrame)
        data.vectors.each do |k, v|
          @vectors[k] = v
        end
      elsif data.is_a?(Hash)
        data.to_h.each do |k, v|
          @vectors[k] =
            if v.respond_to?(:to_a)
              Vector.new(v, type: types[k])
            else
              v
            end
        end

        # handle scalars
        size = @vectors.values.find { |v| v.is_a?(Vector) }&.size || 1
        @vectors.each_key do |k|
          @vectors[k] = to_vector(@vectors[k], size: size, type: types[k])
        end
      elsif data.is_a?(Array)
        vectors = {}
        raise ArgumentError, "Array elements must be hashes" unless data.all? { |d| d.is_a?(Hash) }
        keys = data.flat_map(&:keys).uniq
        keys.each do |k|
          vectors[k] = []
        end
        data.each do |d|
          keys.each do |k|
            vectors[k] << d[k]
          end
        end
        vectors.each do |k, v|
          @vectors[k] = to_vector(v, type: types[k])
        end
      elsif defined?(ActiveRecord) && (data.is_a?(ActiveRecord::Relation) || (data.is_a?(Class) && data < ActiveRecord::Base) || data.is_a?(ActiveRecord::Result))
        result = data.is_a?(ActiveRecord::Result) ? data : data.connection.select_all(data.all.to_sql)
        result.columns.each_with_index do |k, i|
          @vectors[k] = to_vector(result.rows.map { |r| r[i] }, type: types[k])
        end
      else
        raise ArgumentError, "Cannot cast to data frame: #{data.class.name}"
      end

      # check keys
      @vectors.each_key do |k|
        check_key(k)
      end

      # check sizes
      sizes = @vectors.values.map(&:size).uniq
      if sizes.size > 1
        raise ArgumentError, "Different sizes: #{sizes}"
      end
    end

    def [](where)
      if (where.is_a?(Vector) && where.to_numo.is_a?(Numo::Bit)) || where.is_a?(Numeric) || where.is_a?(Range) || (where.is_a?(Array) && where.all? { |v| v.is_a?(Integer) } )
        new_vectors = {}
        @vectors.each do |k, v|
          new_vectors[k] = v[where]
        end
        DataFrame.new(new_vectors)
      elsif where.is_a?(Array)
        # multiple columns
        df = DataFrame.new
        where.each do |k|
          check_column(k)
          df[k] = @vectors[k]
        end
        df
      else
        # single column
        @vectors[where]
      end
    end

    def each_row
      return enum_for(:each_row) unless block_given?

      size.times do |i|
        yield @vectors.map { |k, v| [k, v[i]] }.to_h
      end
    end

    # dup to prevent direct modification of keys
    def vectors
      @vectors.dup
    end

    def types
      @vectors.map { |k, v| [k, v.type] }.to_h
    end

    def []=(k, v)
      check_key(k)
      v = to_vector(v, size: size)
      raise ArgumentError, "Size mismatch (given #{v.size}, expected #{size})" if @vectors.any? && v.size != size
      @vectors[k] = v
    end

    def size
      @vectors.values.first&.size || 0
    end
    alias_method :length, :size
    alias_method :count, :size

    # should this check for columns as well?
    def any?
      size > 0
    end

    # should this check for columns as well?
    def empty?
      size == 0
    end

    def clear
      @vectors.clear
    end

    def shape
      [size, @vectors.size]
    end

    def keys
      @vectors.keys
    end
    alias_method :names, :keys
    alias_method :vector_names, :keys

    def delete(key)
      @vectors.delete(key)
    end

    def except(*keys)
      dup.except!(*keys)
    end

    def except!(*keys)
      keys.each do |key|
        delete(key)
      end
      self
    end

    def include?(key)
      @vectors.include?(key)
    end

    def head(n = 5)
      first(n)
    end

    def tail(n = 5)
      last(n)
    end

    def first(n = 1)
      new_vectors = {}
      @vectors.each do |k, v|
        new_vectors[k] = v.first(n)
      end
      DataFrame.new(new_vectors)
    end

    def last(n = 1)
      new_vectors = {}
      @vectors.each do |k, v|
        new_vectors[k] = v.last(n)
      end
      DataFrame.new(new_vectors)
    end

    def sample(*args, **kwargs)
      # TODO make more efficient
      indexes = (0...size).to_a.sample(*args, **kwargs)
      self[indexes]
    end

    def to_a
      a = []
      each_row do |row|
        a << row
      end
      a
    end

    def to_h
      hsh = {}
      @vectors.each do |k, v|
        hsh[k] = v.to_a
      end
      hsh
    end

    def to_numo
      Numo::NArray.column_stack(vectors.values.map(&:to_numo))
    end

    # TODO raise error when collision
    def one_hot(drop: false)
      df = DataFrame.new
      vectors.each do |k, v|
        if v.to_numo.is_a?(Numo::RObject)
          df.merge!(v.one_hot(drop: drop, prefix: "#{k}_"))
        else
          df[k] = v
        end
      end
      df
    rescue ArgumentError => e
      if e.message == "All elements must be strings"
        # better error message
        raise ArgumentError, "All elements must be numeric or strings"
      end
      raise e
    end

    def to_csv
      require "csv"
      CSV.generate do |csv|
        csv << keys
        numo = vectors.values.map(&:to_numo)
        size.times do |i|
          csv << numo.map { |n| n[i] }
        end
      end
    end

    def to_parquet
      require "parquet"

      schema = {}
      types.each do |name, type|
        schema[name] =
          case type
          when :int64
            :int64
          when :uint64
            :uint64
          when :float64
            :double
          when :float32
            :float
          when :bool
            :boolean
          when :object
            if @vectors[name].all? { |v| v.is_a?(String) }
              :string
            else
              raise "Unknown type"
            end
          else
            type
          end
      end
      # TODO improve performance
      raw_records = []
      size.times do |i|
        raw_records << @vectors.map { |_, v| v[i] }
      end
      table = Arrow::Table.new(schema, raw_records)
      buffer = Arrow::ResizableBuffer.new(1024)
      table.save(buffer, format: :parquet)
      buffer.data.to_s
    end

    # for IRuby
    def to_html
      require "iruby"
      if size > 7
        # pass 8 rows so maxrows is applied
        IRuby::HTML.table((self[0..4] + self[-4..-1]).to_h, maxrows: 7)
      else
        IRuby::HTML.table(to_h)
      end
    end

    # TODO handle long text better
    def to_s
      return "#<Rover::DataFrame>" if keys.empty?

      lines = []
      line_start = 0
      spaces = 2

      summarize = size >= 30

      @vectors.each do |k, v|
        v = summarize ? v.first(5).to_a + ["..."] + v.last(5).to_a : v.to_a
        width = ([k] + v).map(&:to_s).map(&:size).max
        width = 3 if width < 3

        if lines.empty? || lines[-2].map { |l| l.size + spaces }.sum + width > 120
          line_start = lines.size
          lines << []
          v.size.times do |i|
            lines << []
          end
          lines << []
        end

        lines[line_start] << "%#{width}s" % k.to_s
        v.each_with_index do |v2, i|
          lines[line_start + 1 + i] << "%#{width}s" % v2.to_s
        end
      end

      lines.pop
      lines.map { |l| l.join(" " * spaces) }.join("\n")
    end
    alias_method :inspect, :to_s  # alias like hash

    def sort_by!
      indexes =
        size.times.sort_by do |i|
          yield @vectors.map { |k, v| [k, v[i]] }.to_h
        end

      @vectors.each do |k, v|
        self[k] = v.to_numo.at(indexes)
      end
      self
    end

    def sort_by(&block)
      dup.sort_by!(&block)
    end

    def group(*columns)
      Group.new(self, columns.flatten)
    end

    [:max, :min, :median, :mean, :percentile, :sum, :std, :var].each do |name|
      define_method(name) do |column, *args|
        check_column(column)
        self[column].send(name, *args)
      end
    end

    def deep_dup
      df = DataFrame.new
      @vectors.each do |k, v|
        df[k] = v.dup
      end
      df
    end

    def +(other)
      dup.concat(other)
    end

    # in-place, like Array#concat
    # TODO make more performant
    def concat(other)
      raise ArgumentError, "Must be a data frame" unless other.is_a?(DataFrame)

      size = self.size
      vectors.each do |k, v|
        @vectors[k] = Vector.new(v.to_a + (other[k] ? other[k].to_a : [nil] * other.size))
      end
      (other.vector_names - vector_names).each do |k|
        @vectors[k] = Vector.new([nil] * size + other[k].to_a)
      end
      self
    end

    def merge(other)
      dup.merge!(other)
    end

    def merge!(other)
      other.vectors.each do |k, v|
        self[k] = v
      end
      self
    end

    # see join for options
    def inner_join(other, on: nil)
      join(other, on: on, how: "inner")
    end

    # see join for options
    def left_join(other, on: nil)
      join(other, on: on, how: "left")
    end

    # don't check types
    def ==(other)
      size == other.size &&
      keys == other.keys &&
      keys.all? { |k| self[k].to_numo == other[k].to_numo }
    end

    def plot(x = nil, y = nil, type: nil, group: nil, stacked: nil)
      require "vega"

      raise ArgumentError, "Must specify columns" if keys.size != 2 && (!x || !y)
      x ||= keys[0]
      y ||= keys[1]
      type ||= begin
        if self[x].numeric? && self[y].numeric?
          "scatter"
        elsif types[x] == :object && self[y].numeric?
          "column"
        else
          raise "Cannot determine type. Use the type option."
        end
      end
      data = self[group.nil? ? [x, y] : [x, y, group]]

      case type
      when "line", "area"
        x_type =
          if data[x].numeric?
            "quantitative"
          elsif data[x].all? { |v| v.is_a?(Date) || v.is_a?(Time) }
            "temporal"
          else
            "nominal"
          end

        scale = x_type == "temporal" ? {type: "utc"} : {}
        encoding = {
          x: {field: x, type: x_type, scale: scale},
          y: {field: y, type: "quantitative"}
        }
        encoding[:color] = {field: group} if group

        Vega.lite
          .data(data)
          .mark(type: type, tooltip: true, interpolate: "cardinal", point: {size: 60})
          .encoding(encoding)
          .config(axis: {labelFontSize: 12})
      when "pie"
        raise ArgumentError, "Cannot use group option with pie chart" unless group.nil?

        Vega.lite
          .data(data)
          .mark(type: "arc", tooltip: true)
          .encoding(
            color: {field: x, type: "nominal", sort: "none", axis: {title: nil}, legend: {labelFontSize: 12}},
            theta: {field: y, type: "quantitative"}
          )
          .view(stroke: nil)
      when "column"
        encoding = {
          x: {field: x, type: "nominal", sort: "none", axis: {labelAngle: 0}},
          y: {field: y, type: "quantitative"}
        }
        if group
          encoding[:color] = {field: group}
          encoding[:xOffset] = {field: group} unless stacked
        end

        Vega.lite
          .data(data)
          .mark(type: "bar", tooltip: true)
          .encoding(encoding)
          .config(axis: {labelFontSize: 12})
      when "bar"
        encoding = {
          # TODO determine label angle
          y: {field: x, type: "nominal", sort: "none", axis: {labelAngle: 0}},
          x: {field: y, type: "quantitative"}
        }
        if group
          encoding[:color] = {field: group}
          encoding[:yOffset] = {field: group} unless stacked
        end

        Vega.lite
          .data(data)
          .mark(type: "bar", tooltip: true)
          .encoding(encoding)
          .config(axis: {labelFontSize: 12})
      when "scatter"
        encoding = {
          x: {field: x, type: "quantitative", scale: {zero: false}},
          y: {field: y, type: "quantitative", scale: {zero: false}},
          size: {value: 60}
        }
        encoding[:color] = {field: group} if group

        Vega.lite
          .data(data)
          .mark(type: "circle", tooltip: true)
          .encoding(encoding)
          .config(axis: {labelFontSize: 12})
      else
        raise ArgumentError, "Invalid type: #{type}"
      end
    end

    private

    # for clone
    def initialize_clone(_)
      @vectors = @vectors.clone
      super
    end

    # for dup
    def initialize_dup(_)
      @vectors = @vectors.dup
      super
    end

    def check_key(key)
      raise ArgumentError, "Key must be a String or Symbol, given #{key.class.name}" unless key.is_a?(String) || key.is_a?(Symbol)
    end

    # TODO make more efficient
    # TODO add option to prefix/suffix keys?
    # Supports:
    # - on: :key
    # - on: [:key1, :key2]
    # - on: {key1a: :key1b, key2a: :key2b}
    def join(other, how:, on: nil)
      self_on, other_on =
        if on.is_a?(Hash)
          [on.keys, on.values]
        else
          on ||= keys & other.keys
          on = [on] unless on.is_a?(Array)
          [on, on]
        end

      check_join_keys(self, self_on)
      check_join_keys(other, other_on)

      indexed = other.to_a.group_by { |r| r.values_at(*other_on) }
      indexed.default = []

      left = how == "left"

      types = {}
      vectors = {}
      keys = (self.keys + other.keys).uniq
      keys.each do |k|
        vectors[k] = []
        types[k] = join_type(self.types[k], other.types[k])
      end

      each_row do |r|
        matches = indexed[r.values_at(*self_on)]
        if matches.empty?
          if left
            keys.each do |k|
              vectors[k] << r[k]
            end
          end
        else
          matches.each do |r2|
            keys.each do |k|
              vectors[k] << (r2[k] || r[k])
            end
          end
        end
      end

      DataFrame.new(vectors, types: types)
    end

    def check_join_keys(df, keys)
      raise ArgumentError, "No keys" if keys.empty?
      missing_keys = keys.select { |k| !df.include?(k) }
      raise ArgumentError, "Missing keys: #{missing_keys.join(", ")}" if missing_keys.any?
    end

    def check_column(key)
      unless include?(key)
        raise KeyError.new("Missing column: #{key}", receiver: self, key: key)
      end
    end

    def join_type(a, b)
      if a.nil?
        b
      elsif b.nil?
        a
      elsif a == b
        a
      else
        # TODO specify
        nil
      end
    end

    def to_vector(v, size: nil, type: nil)
      if v.is_a?(Vector)
        v = v.to(type) if type && v.type != type
        return v
      end

      if size && !v.respond_to?(:to_a)
        v =
          if v.is_a?(Integer)
            Numo::Int64.new(size).fill(v)
          elsif v.is_a?(Numeric)
            Numo::DFloat.new(size).fill(v)
          elsif v == true || v == false
            Numo::Bit.new(size).fill(v)
          else
            # TODO make more efficient
            [v] * size
          end
      end

      Vector.new(v, type: type)
    end

    # can't use data = {} and keyword arguments
    # as this causes an unknown keyword error when data is passed as
    # DataFrame.new({a: ..., b: ...})
    #
    # at the moment, there doesn't appear to be a way to distinguish between
    # DataFrame.new({types: ...}) which should set data, and
    # DataFrame.new(types: ...) which should set options
    # https://bugs.ruby-lang.org/issues/16891
    #
    # there aren't currently options that should be used without data
    # if this is ever the case, we should still require data
    # to prevent new options from breaking existing code
    def process_args(args)
      data = args[0] || {}
      options = args.size > 1 && args.last.is_a?(Hash) ? args.pop : {}
      raise ArgumentError, "wrong number of arguments (given #{args.size}, expected 0..1)" if args.size > 1

      known_keywords = [:types]
      unknown_keywords = options.keys - known_keywords
      raise ArgumentError, "unknown keywords: #{unknown_keywords.join(", ")}" if unknown_keywords.any?

      [data, options]
    end
  end
end
