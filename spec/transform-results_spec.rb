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
       
    describe "#find_jasmine_specs" do
      
      describe "when passed a spec" do
        let (:spec) { { "id" => 0, "name" => "spec", "type" => "spec", "children" => [] } }
        
        it "should return an hash indexed by the spec id" do
          TransformResults.find_jasmine_specs(spec, "", nil).should == { "0" => "spec" }
        end
        
        it "should append the supplied prefix to the spec" do
          TransformResults.find_jasmine_specs(spec, "suite name: ", nil).should == { "0" => "suite name: spec" }
        end
        
        it "should not call the supplied traversal method" do
          method = double()
          method.should_not_receive(:call)
          TransformResults.find_jasmine_specs(spec, "", method)
        end
      end
    end
    
    describe "when passed a suite" do
      let (:spec0) { { "id" => 0, "name" => "spec 0", "type" => "spec",  "children" => [] } }
      let (:spec1) { { "id" => 1, "name" => "spec 1", "type" => "spec",  "children" => [] } }      
      let (:suite) { { "id" => 0, "name" => "suite 0",  "type" => "suite", "children" => [spec0, spec1] } }
    
      describe "for each child" do
        it "should call the supplied find method and supply the suite name as the prefix" do
          method = double()
          method.stub(:call).and_return({})
          method.should_receive(:call).with(spec0, "suite 0: ", method)
          method.should_receive(:call).with(spec1, "suite 0: ", method)
          TransformResults.find_jasmine_specs(suite, "", method)
        end
      end
      
      it "should merge the results from each child of the suite" do 
        class TransformResultsMock
          def find_jasmine_specs(node, prefix, method)
            @callcount = (@callcount || 0) + 1
            @callcount == 1 ? { "0" => "spec 0" } : { "1" => "spec 1", "2" => "spec 2"}
          end
        end
        method = TransformResultsMock.new.method(:find_jasmine_specs)
        
        find_results = TransformResults.find_jasmine_specs(suite, "", method)
        find_results.should == { "0" => "spec 0", "1" => "spec 1", "2" => "spec 2" }
      end
      
      describe "when suites and specs are nested at different levels" do
        let (:spec2)       { { "id" => 2, "name" => "spec 2",  "type" => "spec",  "children" => [] } }
        let (:outer_suite) { { "id" => 1, "name" => "suite 1", "type" => "suite", "children" => [suite, spec2] } }
        
        it "should produce merged results with appropriate prefixes" do
          TransformResults.find_jasmine_specs(outer_suite).should == { 
            "0" => "suite 1: suite 0: spec 0", 
            "1" => "suite 1: suite 0: spec 1",
            "2" => "suite 1: spec 2"
          }
        end
      end
    end
  end
end
