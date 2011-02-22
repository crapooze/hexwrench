
# Example from:
#
# https://svn.scms.waikato.ac.nz/svn/weka/branches/stable-3-6/wekaexamples/src/main/java/wekaexamples/core/CreateInstances.java
#

$LOAD_PATH << 'lib'
require 'hexwrench'
require 'hexwrench/weka'

class A
  include HexWrench::Resource
  attr_accessor :att1, :att2, :att3, :att4, :att5
  perspective :default, [:att1, :att2, :att3, :att4, :att5]
  perspective :no_rel, [:att1, :att2, :att3, :att4]
  feature :att1, :numeric
  feature :att2, :nominal do |feat|
    feat.allowed_labels = ['val1', 'val2', 'val3', 'val4', 'val5']
  end
  feature :att3, :string
  feature :att4, :date do |feat|
    feat.weka_format = "yyyy-MM-dd"
  end
  relationship :att5, :B, [:many]
  feature :att5, :related do |feat|
    feat.related_perspective = :more_than_example
  end
  def initialize
    @att5 = []
  end
end

class B
  include HexWrench::Resource
  attr_accessor :att5_1, :att5_2, :att5_3, :att5_4
  perspective :default, [:att5_1, :att5_2]
  perspective :more_than_example, [:att5_1, :att5_2, :att5_3, :att5_4]
  feature :att5_1, :numeric
  feature :att5_2, :nominal do |feat|
    feat.allowed_labels = ['val5.1', 'val5.2', 'val5.3', 'val5.4', 'val5.5']
  end
  relationship :att5_3, :C, [:many]
  relationship :att5_4, :C, [:one]
  feature :att5_3, :related
  feature :att5_4, :related
  def initialize
    @att5_3 = []
    @att5_4 = C.new
  end
end

class C
  include HexWrench::Resource
  attr_accessor :att5_3_1
  perspective :default, [:att5_3_1]
  feature :att5_3_1, :numeric
  def initialize
    @att5_3_1 = rand()
  end
end

as = []
# 1st instance
a = A.new
a.att1 = Math::PI
a.att2 = 'val3'
a.att3 = 'this is a string'
a.att4 = Time.now #example had "2011-11-09"
bs = []
b = B.new
b.att5_1 = Math::PI + 1
b.att5_2 = 'val5.3'
b.att5_3 << C.new
bs << b
b = B.new
b.att5_1 = Math::PI + 2
b.att5_2 = 'val5.2'
b.att5_3 << C.new
bs << b
a.att5 = bs
as << a
# 2nd instance
a = A.new
a.att1 = Math::E
a.att2 = 'val1'
a.att3 = 'and another string'
a.att4 = "2000-12-01"
bs = []
b = B.new
b.att5_1 = Math::E + 1
b.att5_2 = 'val5.4'
b.att5_3 << C.new
bs << b
b = B.new
b.att5_1 = Math::E + 2
b.att5_2 = 'val5.1'
bs << b
b.att5_3 << C.new
a.att5 = bs
as << a

module HexWrench
  class WekaExplorer < Explorer
    class Header #represents an ARFF-like header 
      attr_reader :model, :perspective, :resources_cnt, :name
      def initialize(model, perspective, resources_cnt=0, name="dummy")
        @model = model
        @perspective = perspective
        @resources_cnt = resources_cnt
        @name = name
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
        name = feat.sym.to_s
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
          related_persp = feat.related_perspective
          header = Header.new(related_model, related_persp)
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
        inst = Weka::Instances.new(name, fast_vector, resources_cnt)
      end

      def add_resource(resource)
        values = features.map do |feat|
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
                  if feat.relationship.many?
                    rb_val.each do |rb_val_|
                      header.add_resource(rb_val_)
                    end
                  else
                    header.add_resource(rb_val)
                  end
                  attribute.addRelation(header.instances)
                else
                  rb_val
                end
          val
        end
        instances.add(Weka::Instance.new(1.0, values.to_java(Java::double)))
      end
    end

    attr_reader :headers

    def initialize(model, resources=[])
      super(model, resources)
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

xp = HexWrench::WekaExplorer.new(A)
p xp.header(:default).features
p xp.header(:no_rel).attributes
p xp.header(:no_rel).fast_vector
p xp.header(:no_rel).instances
as.each do |a|
  xp.header(:no_rel).add_resource a
end
puts xp.header(:no_rel).instances.to_s

p xp.header(:default).instances
as.each do |a|
  xp.header(:default).add_resource a
end
puts xp.header(:default).instances.to_s
