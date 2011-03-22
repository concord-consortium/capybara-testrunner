$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'yaml'
require 'transform-results'
require 'results-writer'

results = YAML.load_file( 'example-hash.yml' )
jUnitXML = TransformResults.from_qunit(results)
ResultsWriter.write(jUnitXML, $stdout)
