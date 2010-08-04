$:.unshift File.join(File.dirname(__FILE__), 'lib')

require 'trollop'  # For processing command-line options

require 'capybara'
require 'capybara/dsl'
require 'transform-results'
# this is only needed to save a fixture for testing the transform code
require 'yaml'

# Process command-line options
@options = Trollop::options do
  opt :driver, "Capybara driver", :type => String, :default => "selenium"
  
  # look for an environment variable so the port can be changed depending on 
  # the ci node that is running it
  opt :sc_server_port, "SC Server Port", :type => :int, :default => (ENV['SC_SERVER_PORT'] || 4020)
  opt :sc_server_host, "SC Server Host", :type => :string, :default => "localhost"
  
  opt :root_dir, "Root directory", :type => :string, :default => ".."
  opt :tests_dir, "Tests directory", :type => :string, :default => "{apps,frameworks}"
  opt :exclude_dir, "Exclude test directory", :type => :string, :multi => true
end

Capybara.current_driver = @options[:driver].to_sym
Capybara.app_host = "http://#{@options[:sc_server_host]}:#{@options[:sc_server_port]}"

include Capybara

# find all of the test subfolders in the tests of the current apps
# FIXME should change to support nested folders inside of tests
testFolders = Dir.glob( File.join(@options[:root_dir], @options[:tests_dir], "**", "tests", "*") )

excludes = [File.join("tmp","**")] + @options[:exclude_dir]
testFolders = testFolders.reject{|folder|
    excludes.any?{|exclude| File.fnmatch?(File.join(@options[:root_dir], exclude), folder)}
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
