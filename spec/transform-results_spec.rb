require 'transform-results'

require 'rexml/document'

describe TransformResults do
  describe "#fromQUnit" do
    it "should return nil if there are no assertions" do
      TransformResults.fromQUnit({}).should be_nil
    end
  end
end
