
require 'welo'

module HexWrench
  module Resource
    include Welo::Resource

    def self.included(mod)
      mod.extend Welo::Resource::ClassMethods
      mod.extend ClassMethods
      mod.features_hash = {}
    end

    module ClassMethods
      attr_accessor :features_hash
      def feature(name, type=nil)
        if type
          f = Feature.for(name, self, type)
          yield f if block_given?
          features_hash[name] = f
        end
        features_hash[name]
      end

      def features(persp)
        perspective(persp).fields.map do |f|
          feature(f)
        end
      end
    end

    def features(persp)
      self.class.features(persp)
    end

    def feature(name)
      self.class.feature(name)
    end
  end
end
