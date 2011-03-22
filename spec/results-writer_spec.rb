require 'results-writer'
require 'stringio'

describe ResultsWriter do
     
  let (:stream) { StringIO.new }
  
  describe "#write" do
    it "should write an empty document if it is passed nil" do
      ResultsWriter.write(nil, stream)
      stream.string.should be_empty
    end
  end
  
end
