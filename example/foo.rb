
$LOAD_PATH << 'lib'
require 'hexwrench'

OriginalCluster = Struct.new(:x, :y, :spread)

class Oyo
  include HexWrench::Resource
  perspective :default, [:val]
  feature :val, :numeric
  attr_reader :val
  def initialize
    @val = rand(16)
  end
end

class Foo
  include HexWrench::Resource
  attr_reader :bar, :baz, :str, :nominal, :oyo

  perspective :default, [:bar, :baz]
  perspective :with_relation, [:bar, :baz, :oyo]
  perspective :with_nominal, [:bar, :baz, :nominal]
  perspective :with_string, [:bar, :baz, :str]
  relationship :oyo, :Oyo, [:one]
  feature :bar, :numeric
  feature :baz, :numeric
  feature :str, :string
  feature :nominal, :nominal do |feat|
    feat.allowed_labels = ['a', 'b', 'c', 'd']
  end
  feature :oyo, :related 

  def initialize(cluster)
    @bar = cluster.x + rand(cluster.spread)
    @baz = cluster.y + rand(cluster.spread)
    @str = "x" * rand(2) + " " + "y" *rand(3)
    @nominal = ['a', 'b', 'c', 'd'].sort_by{rand()}.first
    @oyo = Oyo.new
  end
end

cls = []
cls << OriginalCluster.new(10, 10, 3)
cls << OriginalCluster.new(5, 2, 7)

foos = []

cls.each do |cl|
  (1000 + rand(500)).times do |t|
    foos << Foo.new(cl)
  end
end


if RUBY_PLATFORM =~ /java/
  require 'hexwrench/weka'
  include_class 'weka.clusterers.SimpleKMeans'
  xp = HexWrench::Weka::Explorer.new(Foo)
  head = xp.header(:default)
  foos.each do |foo|
    head.add_resource(foo)
  end
  data = head.instances

  kmeans = SimpleKMeans.new
  kmeans.build_clusterer data

  data.num_instances.times do |i|
    obs = data.instance(i)
    cluster = kmeans.cluster_instance(obs)
    puts "#{obs}, #{cluster}"
  end
end
