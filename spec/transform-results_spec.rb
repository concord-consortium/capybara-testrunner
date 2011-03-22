require 'transform-results'

describe TransformResults do

  shared_examples_for "any transform method" do
    specify { subject.call(nil).should be_nil }
    specify { subject.call({}).should be_nil }
  end
  
  describe "#fromQUnit" do
    subject { TransformResults.method('fromQUnit') }
    it_should_behave_like "any transform method"
  end
  
  describe "#fromJasmine" do
    subject { TransformResults.method('fromJasmine') }   
    it_should_behave_like "any transform method"
  end
  
end
