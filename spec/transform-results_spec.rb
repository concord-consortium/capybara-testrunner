require 'transform-results'

describe TransformResults do

  shared_examples_for "any transform method" do
    specify { subject.call(nil).should be_nil }
    specify { subject.call({}).should be_nil }
  end
  
  describe "#from_qunit" do
    subject { TransformResults.method("from_qunit") }
    it_should_behave_like "any transform method"
  end
  
  describe "#from_jasmine" do
    subject { TransformResults.method("from_jasmine") }   
    it_should_behave_like "any transform method"
  end
  
end
