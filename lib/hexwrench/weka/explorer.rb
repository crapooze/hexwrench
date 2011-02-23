
require 'hexwrench/core/explorer'

module HexWrench
  module Weka
    class Explorer < HexWrench::Explorer
      class Header #represents an ARFF-like header 
        attr_reader :model, :perspective, :perspectives, :resources_cnt, :relation_name
        def initialize(model, perspective_tree, resources_cnt=0, name="dummy")
          @model = model
          if perspective_tree.is_a?(Array)
            @perspective = perspective_tree[0]
            @perspectives = perspective_tree[1]
          else
            @perspective = perspective_tree
            @perspectives = {}
          end
          @resources_cnt = resources_cnt
          @relation_name = name
        end

        def features
          model.perspective(perspective).fields.map do |sym|
            model.feature(sym)
          end
        end

        def attribute(name)
          pair = attributes_pairs.find{|n, attr| n == name}
          pair.last if pair
        end

        def attributes
          attributes_pairs.map{|name, attr| attr}
        end

        def attributes_pairs
          @attributes_pairs ||= create_attributes_pairs
        end

        def fast_vector
          @fast_vector ||= create_fast_vector
        end

        def instances
          @instances ||= create_instances
        end

        def create_attributes_pairs
          features.map do |feat|
            [feat.sym, attribute_for_feature(feat)]
          end
        end

        # headers for related attributes
        def headers
          @headers ||= {}
        end

        def header(name)
          headers[name]
        end

        def attribute_for_feature(feat)
          name = File.join(relation_name, feat.sym.to_s)
          case feat
          when NumericFeature
            Weka::Attribute.new(name)
          when DateFeature
            Weka::Attribute.new(name, feat.weka_format)
          when NominalFeature
            Weka::Attribute.new(name, feat.labels_fv)
          when StringFeature
            construct = Weka::Attribute.java_class.constructor(java.lang.String, 
                                                               Weka::FastVector)
            construct.new_instance(name, nil).to_java
          when RelationFeature
            related_model = feat.related_model
            related_persp = perspectives[feat.sym] || :default 
            cnt = 0 #XXX could be taken more cleverly if support in Welo's relationship
            header = Header.new(related_model, related_persp, cnt, name)
            headers[feat.sym] = header
            construct = Weka::Attribute.java_class.constructor(java.lang.String, 
                                                               Weka::Instances)
            construct.new_instance(name, header.instances).to_java
          else
            raise ArgumentError, "don't know how to handler #{feat} to make an attribute"
          end
        end

        def create_fast_vector
          fv = Weka::FastVector.new
          attributes.each do |attribute|
            fv.add_element(attribute)
          end
          fv
        end

        def create_instances
          Weka::Instances.new(relation_name, fast_vector, resources_cnt)
        end

        def values_for_resources(resource)
          features.map do |feat|
            rb_val = resource.send(feat.sym)
            attribute = attribute(feat.sym)
            val = case feat
                  when DateFeature
                    date_str = if rb_val.respond_to?(:strftime)
                                 fmt = feat.format || DateFeature.default_format
                                 rb_val.send(:strftime, fmt)
                               else
                                 rb_val
                               end
                    attribute.parseDate(date_str) 
                  when NominalFeature
                    attribute.indexOfValue(rb_val.to_s.to_java)
                  when StringFeature
                    attribute.addStringValue(rb_val.to_java)
                  when RelationFeature
                    header = header(feat.sym) 
                    raise NotImplementedError, "no header built for #{feat} yet" unless header
                    data_instances = Weka::Instances.new(attribute.relation, 0)
                    if feat.relationship.many?
                      rb_val.each do |rb_val_|
                        header.add_resource_to_instances(rb_val_, data_instances)
                      end
                    else
                      header.add_resource_to_instances(rb_val, data_instances)
                    end
                    attribute.addRelation(data_instances) 
                  else
                    rb_val
                  end
            val
          end
        end

        def new_data_instances
        end

        def add_values_to_instances(values, instances)
          instances.add(Weka::Instance.new(1.0, values.to_java(Java::double)))
        end

        def add_resource_to_instances(resource, instances)
          add_values_to_instances(values_for_resources(resource), instances)
        end

        def add_resource(resource)
          add_resource_to_instances(resource, instances)
        end
      end

      attr_reader :headers

      def initialize(model)
        super(model)
        @headers = {}
      end

      def header(persp)
        @headers[persp] ||= create_header(persp)
      end

      def create_header(persp)
        Header.new(model, persp)
      end
    end
  end
end
