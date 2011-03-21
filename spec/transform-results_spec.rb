require 'transform-results'

require 'rexml/document'

describe TransformResults do
  describe "#fromQUnit" do
    
    it "should return nil if test results evalute to nil" do
      TransformResults.fromQUnit(nil).should be_nil
    end
    
    it "should return nil if there are no assertions" do
      TransformResults.fromQUnit({}).should be_nil
    end
    
  end
end
