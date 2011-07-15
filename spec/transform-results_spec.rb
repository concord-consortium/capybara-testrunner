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
        TransformResults.from_jasmine(nil).should be_nil
        TransformResults.from_jasmine({}).should be_nil
        TransformResults.from_jasmine([]).should be_nil
      end
    end
    
    describe "when it is passed valid data" do
      
      before(:all) do
        datadir = File.join(File.dirname(__FILE__), "data")
        @results = JSON.parse(File.read(File.join(datadir, "results.json")))
      end
      
      describe "which meet JSON preconditions" do
        specify { @results["suites"][0]["results"][1]["name"].should eq "S1: Result 2" }
        specify { @results["suites"][0]["results"][2]["status"].should eq "failed" }
        specify { @results["suites"].length.should eq 4 }
      end
      
      describe "the document it returns" do
        let (:doc) { TransformResults.from_jasmine(@results) }

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
          
          it "should have one child per spec in the JSON" do
            toplevel.elements.size.should eq @results["suites"].length
          end
        end
      end
    end    
  end
  
  describe "finding jasmine specs" do

    let (:spec0) { { "id" => 0, "name" => "spec 0", "type" => "spec",  "children" => [] } }
    let (:spec1) { { "id" => 1, "name" => "spec 1", "type" => "spec",  "children" => [] } }      
    let (:suite) { { "id" => 0, "name" => "suite 0",  "type" => "suite", "children" => [spec0, spec1] } }

    describe "#find_jasmine_specs_in" do
           
      describe "when passed a spec" do
        it "should return an hash indexed by the spec id" do
          TransformResults.find_jasmine_specs_in(spec0, "").should == { "0" => "spec 0" }
        end
      
        it "should append the supplied prefix to the spec" do
          TransformResults.find_jasmine_specs_in(spec0, "suite name: ").should == { "0" => "suite name: spec 0" }
        end
      end
  
      describe "when passed a suite" do
        it "should return the value of #merge_jasmine_specs_from" do
          TransformResults.stub(:merge_jasmine_specs_from).and_return(:stubbed_value)
          TransformResults.find_jasmine_specs_in(suite, "prefix: ").should == :stubbed_value
        end
        
        it "should pass the list of the suite's children to #merge_jasmine_specs_from" do
          args = {}
          TransformResults.stub(:merge_jasmine_specs_from) do |nodes, prefix|
            args["nodes"] = nodes
          end
          TransformResults.find_jasmine_specs_in(suite, "prefix: ")
          args["nodes"].should == suite["children"]
        end
        
        it "should append the suite's name to the prefix passed to #merge_jasmine_specs_from" do
          args = {}
          TransformResults.stub(:merge_jasmine_specs_from) do |nodes, prefix|
            args["prefix"] = prefix
          end
          TransformResults.find_jasmine_specs_in(suite, "prefix: ")
          args["prefix"].should == "prefix: suite 0: "
        end
      end

      describe "when passed suites and specs are nested at different levels" do
        let (:spec2)       { { "id" => 2, "name" => "spec 2",  "type" => "spec",  "children" => [] } }
        let (:outer_suite) { { "id" => 1, "name" => "suite 1", "type" => "suite", "children" => [suite, spec2] } }
  
        it "should produce merged results with appropriate prefixes" do
          TransformResults.find_jasmine_specs_in(outer_suite).should == { 
            "0" => "suite 1: suite 0: spec 0", 
            "1" => "suite 1: suite 0: spec 1",
            "2" => "suite 1: spec 2"
          }
        end
      end
    end  
    
    
    describe "#merge_jasmine_specs_from" do

      describe "for each child" do
        it "should call the #find_jasmine_specs_in method" do
          nodes = []
          prefixes = []
          TransformResults.stub(:find_jasmine_specs_in) do |node, prefix|
            nodes.push(node)
            prefixes.push(prefix)
            {}
          end
          
          TransformResults.merge_jasmine_specs_from([spec0, spec1], "prefix")
          nodes.should == [spec0, spec1]
          prefixes.should == ["prefix", "prefix"]
        end
      end
    
      it "should merge the results from each call to #find_jasmine_specs_in" do 
        call_count = 0
        
        TransformResults.stub(:find_jasmine_specs_in) do
          call_count += 1
          call_count == 1 ? { "0" => "spec 0" } : { "1" => "spec 1", "2" => "spec 2"}
        end
        
        find_results = TransformResults.merge_jasmine_specs_from([spec0, spec1], "")
        find_results.should == { "0" => "spec 0", "1" => "spec 1", "2" => "spec 2" }
      end
    end
  end
end
