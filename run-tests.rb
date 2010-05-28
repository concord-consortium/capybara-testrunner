require 'capybara'
require 'capybara/dsl'
require 'transform-results'
# this is only needed to save a fixture for testing the transform code
require 'yaml'

Capybara.current_driver = :selenium

# look for an environment variable so the port can be changed depending on 
# the ci node that is running it
sc_server_port = ENV['SC_SERVER_PORT']
sc_server_port = '4020' if sc_server_port.nil?
Capybara.app_host = "http://localhost:#{sc_server_port}"

include Capybara

# find all of the test subfolders in the tests of the current apps
# FIXME should change to support nested folders inside of tests
rootDir = '..'

if ARGV[0] then 
  testFolders = Dir.glob( File.join(rootDir, ARGV[0], "**", "tests", "*") )
else
  testFolders = Dir.glob( File.join(rootDir, "{apps,frameworks}","**", "tests", "*") )
end


excludes = [File.join("tmp","**")]
testFolders = testFolders.reject{|folder|
    excludes.any?{|exclude| File.fnmatch?(File.join(rootDir, exclude), folder)}
}

testURLs = testFolders.collect{|folder|
  puts "will gather tests from folder #{folder}"
  # switch to url slashes
  folder.gsub(File::SEPARATOR, '/')
  paths = Regexp.new('.*(frameworks|apps)/([^/]*)/tests/(.*)').match(folder)
  {:url => "/#{paths[2]}/en/current/tests/#{paths[3]}.html",
   :results_file => "#{paths[2]}-#{paths[3].gsub('/',"-")}-junit.xml"
  }
}

testURLs.each{|url|
  print "visiting #{url[:url]}..."
  visit(url[:url])
  print "visited\n"
  results = evaluate_script('CoreTest.plan.results')
  File.open(url[:results_file], 'w'){|file|
    TransformResults.transform(results, file)
  }
  #uncomment this to save results for quicker testing of the transform
  #puts results.to_yaml
}
