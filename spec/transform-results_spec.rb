require 'transform-results'
require 'json'
require 'rexml/document'

describe TransformResults do
  
  describe "#from_qunit" do
    it "should return nil if passed nil or arguments with no assertions" do
      TransformResults.from_qunit(nil).should be_nil
      TransformResults.from_qunit({}).should be_nil
    end
  end
  
  describe "#from_jasmine" do
    
    describe "when it is passed nil arguments or arguments with no items" do
      it "should return nil" do
        TransformResults.from_jasmine(nil, nil).should be_nil
        TransformResults.from_jasmine({}, nil).should be_nil
        TransformResults.from_jasmine([], nil).should be_nil
        TransformResults.from_jasmine(nil, {}).should be_nil
        TransformResults.from_jasmine(nil, []).should be_nil
      end
    end
    
    describe "when it is passed valid data" do
      
      before(:all) do
        datadir = File.join(File.dirname(__FILE__), "data")
        @suites  = JSON.parse(File.read(File.join(datadir, "suites.json")))
        @results = JSON.parse(File.read(File.join(datadir, "results.json")))
      end
      
      describe "which meet JSON preconditions" do
        specify { @suites[0]["children"][0]["children"][0]["name"].should eq "When I mark the center cell" }
        specify { @results["2"]["result"].should eq "failed" }
        specify { @results.length.should eq 64 }
      end
      
      describe "the document it returns" do
        let (:doc) { TransformResults.from_jasmine(@suites, @results) }

        it "should be an XML document" do
          doc.should be_a REXML::Document
        end
    
        describe "the toplevel element of that document" do
          let (:toplevel) { doc.elements[1] }

          it "should be a <testsuites> element" do
            toplevel.name.should eq "testsuites"
          end
        
          it "should have only <testsuite> children" do
            toplevel.elements.each do |element|
              element.name.should eq "testsuite"
            end
          end
          
          it "should have one child per toplevel suite in the JSON" do
            toplevel.elements.size.should eq @suites.length
          end
        end
      end
      
    end
  end

end
