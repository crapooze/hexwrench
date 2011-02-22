
module HexWrench
  class Feature 
    def self.mapping
      {:numeric => NumericFeature,
        :date => DateFeature,
        :nominal => NominalFeature,
        :string => StringFeature,
        :related => RelationFeature
      }
    end

    def self.for(sym, resource, type)
      raise ArgumentError.new, "not understood type: #{type}" unless mapping.has_key?(type)
      klass = mapping[type]
      klass.new(sym, resource)
    end

    attr_accessor :sym, :resource

    def initialize(sym, resource)
      @resource = resource
      @sym = sym
    end
  end

  class NumericFeature < Feature
  end

  class DateFeature < Feature
    attr_accessor :format
    def self.default_format
      "%Y-%m-%d"
    end

    def initialize(sym, resource, format=nil)
      super(sym, resource)
      @format = format
    end
  end

  class NominalFeature < Feature
    attr_accessor :allowed_labels
    def initialize(sym, resource, labels = [])
      super(sym, resource)
      @allowed_labels = labels
    end
  end

  class StringFeature < Feature
  end

  class RelationFeature < Feature
    def relationship
      resource.relationship(sym)
    end

    def related_model_from_relationship_klass
      Kernel.const_get relationship.klass
    end

    attr_writer :related_model

    def related_model
      @related_model || related_model_from_relationship_klass
    end

    attr_accessor :related_perspective

    def related_perspective
      @related_perspective || :default
    end
  end

end
