
require 'hexwrench/core/feature'

module HexWrench
  class DateFeature < Feature
    attr_writer :weka_format
    DEFAULT_WEKA_FORMAT = "yyyy-MM-dd"
    def weka_format
      @weka_format || format || DEFAULT_WEKA_FORMAT
    end
  end

  class NominalFeature < Feature
    def labels_fv
      unless @labels_fv
        @labels_fv = Weka::FastVector.new
        allowed_labels.each{|l| @labels_fv.add_element(l.to_s)}
      end
      @labels_fv
    end
  end
end
