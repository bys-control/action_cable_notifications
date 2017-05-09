module HashDB
  class Base

    def initialize(data=nil)
      if data.present?
        @data = Array(data)
      else
        @data = []
      end
    end

    def data
      @data
    end

    def data=(data)
      @data = data || []
    end

    def wrap(data)
      HashDB::Base.new(data)
    end

    private :wrap

    def all(options={})
      if options.has_key?(:conditions)
        where(options[:conditions])
      else
        wrap(@data ||= [])
      end
    end

    def count
      all.length
    end

    def where(options)
      return @data if options.blank?

      data = (@data || []).select do |record|
        match_options?(record, options)
      end

      wrap(data)
    end

    def match_options?(record, options)
      options.all? do |col, match|
        if [Array, Range].include?(match.class)
          match.include?(record[col])
        else
          record[col] == match
        end
      end
    end

    private :match_options?

    def scoped_collection ( scope = :all )
      scope = scope.to_a if scope.is_a? Hash
      Array(scope).inject(self) do |o, a|
        o.try(*a)
      end
    end

    def select( fields=nil )
      if fields.present?
        wrap(all.map{|v| v.attributes.slice(*Array(fields))})
      else
        all
      end
    end

    def limit( count=nil )
      if count.present? and count>0
        wrap(@data.slice(0,count))
      else
        all
      end
    end

    def delete_all
      @data = []
    end

    def first
      @data.first
    end

    def last
      @data.last
    end

    def find(id, * args)
      case id
        when nil
          nil
        when :all
          all
        when :first
          all(*args).first
        when Array
          id.map { |i| find(i) }
        else
          where({id: id})
      end
    end

  end
end
