
# This file takes the Example from:
#
# https://svn.scms.waikato.ac.nz/svn/weka/branches/stable-3-6/wekaexamples/src/main/java/wekaexamples/core/CreateInstances.java
#
# and it extends it with more relationships in the non-default perspective

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
  feature :att5, :related 
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

xp = HexWrench::Weka::Explorer.new(A)

#like example
as.each do |a|
  xp.header(:default).add_resource a
end
puts xp.header(:default).instances.to_s

#more than example
perspectives_tree = [:default, {:att5 => [:more_than_example, {:att5_3 => :default, :att5_4 => :default}]}]
as.each do |a|
  xp.header(perspectives_tree).add_resource a
end
puts xp.header(perspectives_tree).instances.to_s
