#!/usr/bin/env ruby

$:.unshift File.join(File.dirname(__FILE__), 'lib')

require 'trollop'  # For processing command-line options
require 'fileutils'

require 'capybara'
require 'capybara/dsl'
require 'transform-results'
# this is only needed to save a fixture for testing the transform code
require 'yaml'

# Process command-line options
@options = Trollop::options do
  opt :driver, "Capybara driver", :short => 'd', :type => String, :default => "selenium"
  
  # look for an environment variable so the port can be changed depending on 
  # the ci node that is running it
  opt :sc_server_port, "SC Server Port", :short => 'p', :type => :int, :default => (ENV['SC_SERVER_PORT'] || 4020)
  opt :sc_server_host, "SC Server Host", :short => 'h', :type => :string, :default => "localhost"
  
  opt :root_dir, "Root directory", :short => 'r', :type => :string, :default => ".."
  opt :tests_dir, "Tests directory", :short => 't', :type => :string, :default => "{apps,frameworks}"
  opt :exclude_dir, "Exclude test directory", :short => 'x', :type => :string, :multi => true
  
  opt :results_dir, "Results directory", :short => 'o', :type => :string, :default => "results"
  opt :junit, "Output JUnit XML", :short => 'j', :default => true
  opt :snapshot, 'Save a "snapshot" of the test page html', :short => 's', :default => false
  
  opt :quiet, 'Quiet mode. Do not print messages while running', :short => 'q', :default => false
end

FileUtils.mkdir_p @options[:results_dir]

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

TEST_REGEXP = Regexp.new('.*?(frameworks|apps)/(.*)/tests/(.*)')
testURLs = testFolders.collect{|folder|
  puts "will gather tests from folder #{folder}" unless @options[:quiet]
  # switch to url slashes
  folder.gsub!(File::SEPARATOR, '/')
  paths = TEST_REGEXP.match(folder)
  url_base = paths[2].gsub('frameworks/','')
  {:url => "/#{url_base}/en/current/tests/#{paths[3]}.html",
   :results_file => File.join(@options[:results_dir], "#{url_base}-#{paths[3]}-junit.xml".gsub('/',"-")),
   :results_html_file => File.join(@options[:results_dir], "#{url_base}-#{paths[3]}-page.html".gsub('/',"-"))
  }
}

def save_results_xml(url)
  results = evaluate_script('CoreTest.plan.results')
  File.open(url[:results_file], 'w'){|file|
    TransformResults.transform(results, file)
  }
  #uncomment this to save results for quicker testing of the transform
  #puts results.to_yaml
end

def save_page_html(url)
  # FIXME How do we get the result html without re-running the tests?
  html = evaluate_script('')
  File.open(url[:results_html_file], 'w'){|file|
    file.write(html)
    file.flush
  }
end

testURLs.each{|url|
  print "visiting #{url[:url]}..." unless @options[:quiet]
  visit(url[:url])
  print "visited\n" unless @options[:quiet]
  save_results_xml(url) if @options[:junit]
  save_page_html(url) if @options[:snapshot]
}
