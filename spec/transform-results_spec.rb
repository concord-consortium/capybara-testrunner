require 'transform-results'
require 'json'

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
    
    let (:suites) {
      JSON.parse(File.read(File.join(File.dirname(__FILE__), "data", "suites.json")))
    }
    
    let (:results) {
      JSON.parse(File.read(File.join(File.dirname(__FILE__), "data", "results.json")))
    }
    
    specify { results["2"]["result"].should eq "failed" }
    specify { results.length.should eq 64 }
    specify { suites[0]["children"][0]["children"][0]["name"].should eq "When I mark the center cell" }
    
  end
  
end
