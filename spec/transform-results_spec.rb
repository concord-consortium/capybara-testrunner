require 'transform-results'
require 'json'
require 'rexml/document'

describe TransformResults do

  # shared_examples_for "any transform method" do
  #   specify { subject.call(nil).should be_nil }
  #   specify { subject.call({}).should be_nil }
  # end
  
  describe "#from_qunit" do
    it "should return nil if passed nil or arguments with no assertions" do
      TransformResults.from_qunit(nil).should be_nil
      TransformResults.from_qunit({}).should be_nil
    end
  end
  
  describe "#from_jasmine" do
    it "should return nil if passed nil or arguments with no assertions" do
      TransformResults.from_jasmine(nil, nil).should be_nil
      TransformResults.from_jasmine(nil, {}).should be_nil
      TransformResults.from_jasmine({}, nil).should be_nil
      TransformResults.from_jasmine({}, {}).should be_nil
    end
    
    let (:suites) {
      JSON.parse(File.read(File.join(File.dirname(__FILE__), "data", "suites.json")))
    }
    
    specify { suites[0]["children"][0]["children"][0]["name"].should eq "When I mark the center cell" }

    let (:results) {
      JSON.parse(File.read(File.join(File.dirname(__FILE__), "data", "results.json")))
    }
    
    specify { results["2"]["result"].should eq "failed" }
    specify { results.length.should eq 64 }
    
  end
  
end
