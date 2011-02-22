
require 'java'
require 'weka'

require 'hexwrench/weka/feature'

module HexWrench
  module Weka
    autoload :Explorer, 'hexwrench/weka/explorer'
    include_class 'weka.core.Attribute'
    include_class 'weka.core.FastVector'
    include_class 'weka.core.Instances'
    include_class 'weka.core.Instance'
  end
end
