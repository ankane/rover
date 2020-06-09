module Rover
  class DataFrame
    def initialize(data = {})
      @vectors = {}

      if data.is_a?(DataFrame)
        data.vectors.each do |k, v|
          @vectors[k] = v
        end
      elsif data.is_a?(Hash)
        data.to_h.each do |k, v|
          @vectors[k] =
            if v.respond_to?(:to_a)
              Vector.new(v)
            else
              v
            end
        end

        # handle scalars
        size = @vectors.values.find { |v| v.is_a?(Vector) }&.size || 1
        @vectors.each_key do |k|
          @vectors[k] = to_vector(@vectors[k], size)
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
          @vectors[k] = to_vector(v)
        end
      elsif defined?(ActiveRecord) && (data.is_a?(ActiveRecord::Relation) || (data.is_a?(Class) && data < ActiveRecord::Base))
        result = data.connection.select_all(data.all.to_sql)
        result.columns.each_with_index do |k, i|
          @vectors[k] = to_vector(result.rows.map { |r| r[i] })
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
          df[k] = @vectors[k]
        end
        df
      else
        # single column
        @vectors[where]
      end
    end

    # return each row as a hash
    def each_row
      size.times do |i|
        yield @vectors.map { |k, v| [k, v[i]] }.to_h
      end
    end

    # dup to prevent direct modification of keys
    def vectors
      @vectors.dup
    end

    def []=(k, v)
      check_key(k)
      v = to_vector(v, size)
      raise ArgumentError, "Size mismatch: expected #{size}, got #{v.size}" if @vectors.any? && v.size != size
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

    def first(n = nil)
      new_vectors = {}
      @vectors.each do |k, v|
        new_vectors[k] = v.first(n)
      end
      DataFrame.new(new_vectors)
    end

    def last(n = nil)
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
      new_vectors = {}
      vectors.each do |k, v|
        if v.to_numo.is_a?(Numo::RObject)
          raise ArgumentError, "All elements must be numeric or strings" unless v.all? { |vi| vi.is_a?(String) }

          # maybe sort values first
          values = v.uniq.to_a
          values.shift if drop
          values.each do |v2|
            # TODO use types
            new_vectors["#{k}_#{v2}"] = (v == v2).to_numo.cast_to(Numo::Int64)
          end
        else
          new_vectors[k] = v
        end
      end
      DataFrame.new(new_vectors)
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

    # for IRuby
    def to_html
      require "iruby"
      IRuby::HTML.table(to_h)
    end

    # TODO handle long text better
    def inspect
      return "#<Rover::DataFrame>" if keys.empty?

      lines = []
      line_start = 0
      spaces = 2

      @vectors.each do |k, v|
        v = v.first(5).to_a
        width = ([k] + v).map(&:to_s).map(&:size).max
        width = 3 if width < 3

        if lines.empty? || lines[-2].map { |l| l.size + spaces }.sum + width > 120
          line_start = lines.size
          lines << []
          [size, 5].min.times do |i|
            lines << []
          end
          lines << [] if size > 5
          lines << []
        end

        lines[line_start] << "%#{width}s" % k.to_s
        v.each_with_index do |v2, i|
          lines[line_start + 1 + i] << "%#{width}s" % v2.to_s
        end
        lines[line_start + 6] << "%#{width}s" % "..." if size > 5
      end

      lines.pop
      lines.map { |l| l.join(" " * spaces) }.join("\n")
    end
    alias_method :to_s, :inspect # alias like hash

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

    def group(columns)
      Group.new(self, columns)
    end

    [:max, :min, :median, :mean, :percentile, :sum].each do |name|
      define_method(name) do |column, *args|
        check_column(column)
        self[column].send(name, *args)
      end
    end

    def dup
      df = DataFrame.new
      @vectors.each do |k, v|
        df[k] = v
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
      keys.all? { |k| self[k] == other[k] }
    end

    private

    def check_key(key)
      raise ArgumentError, "Key must be a string or symbol, got #{key.inspect}" unless key.is_a?(String) || key.is_a?(Symbol)
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

      vectors = {}
      keys = (self.keys + other.keys).uniq
      keys.each do |k|
        vectors[k] = []
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

      DataFrame.new(vectors)
    end

    def check_join_keys(df, keys)
      raise ArgumentError, "No keys" if keys.empty?
      missing_keys = keys.select { |k| !df.include?(k) }
      raise ArgumentError, "Missing keys: #{missing_keys.join(", ")}" if missing_keys.any?
    end

    def check_column(key)
      raise ArgumentError, "Missing column: #{key}" unless include?(key)
    end

    def to_vector(v, size = nil)
      return v if v.is_a?(Vector)

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

      Vector.new(v)
    end
  end
end
