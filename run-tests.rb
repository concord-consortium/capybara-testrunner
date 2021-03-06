#!/usr/bin/env ruby

$:.unshift File.join(File.dirname(__FILE__), 'lib')

require 'trollop'  # For processing command-line options
require 'fileutils'
require 'json'

require 'transform-results'
require 'yaml'

# Process command-line options
@options = Trollop::options do
  opt :runner, "Browser runner", :short => 'b', :type => String, :default => "capybara"

  # capybara specific
  opt :driver, "Capybara driver", :short => 'd', :type => String, :default => "selenium"
  
  # sauce labs specific
  opt :tunnel, "Start Sauce Connect Tunnel", :short => 'c', :default => false
  
  # look for an environment variable so the port can be changed depending on 
  # the ci node that is running it
  opt :sc_server_port, "SC Server Port", :short => 'p', :type => :int, :default => (ENV['SC_SERVER_PORT'] || '4020').to_i
  opt :sc_server_host, "SC Server Host", :short => 's', :type => :string, :default => "localhost"
  
  opt :root_dir, "Root directory", :short => 'r', :type => :string, :default => ".."
  opt :tests_dir, "Tests directory", :short => 't', :type => :string, :default => "{apps,frameworks}"
  opt :exclude_dir, "Exclude test directory", :short => 'x', :type => :string, :multi => true
  
  opt :results_dir, "Results directory", :short => 'o', :type => :string, :default => "results"
  opt :junit, "Output JUnit XML", :short => 'j', :default => true
  opt :image, 'Save a png snapshot of the test page', :short => 'i', :default => false
  opt :html, 'Save an html snapshot of the test page', :short => 'h', :default => false
  
  opt :quiet, 'Quiet mode. Do not print messages while running', :short => 'q', :default => false
end

Trollop::die :image, "can only be enabled if using the selenium driver (you're using: #{@options[:driver]})" if @options[:image] && @options[:driver] != "selenium"

# check if DISPLAY environment variable is set on linux
if RUBY_PLATFORM =~ /linux/ and ENV['DISPLAY'].nil?
  Trollop::die "When running on linux the DISPLAY variable needs to be set to a valid X display"
end

FileUtils.mkdir_p @options[:results_dir]

@app_host = "http://#{@options[:sc_server_host]}:#{@options[:sc_server_port]}"
@browser = case @options[:runner]
when "capybara" then 
  require 'capybara-runner'
  CapybaraRunner.new(@options[:driver].to_sym, @app_host)
when "selenium-rc" then
  require 'selenium-rc-runner'
  SeleniumRCRunner.new(@app_host, 'localhost', '*safari')
when "sauce" then
  require 'sauce-runner'  
  SauceRunner.new(@app_host, File.dirname(__FILE__), @options[:tunnel])
end

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
  file_base = paths[3].gsub(/\.js$/, '') # remove .js if the entry is a js file instead of directory
  {:url => "/#{url_base}/en/current/tests/#{file_base}.html",
   :results_file => File.join(@options[:results_dir], "#{url_base}-#{file_base}-junit.xml".gsub('/',"-")),
   :results_html_file => File.join(@options[:results_dir], "#{url_base}-#{file_base}-page.html".gsub('/',"-")),
   :results_png_file => File.join(@options[:results_dir], "#{url_base}-#{file_base}-page.png".gsub('/',"-"))
  }
}

def save_results_xml(url, results)
  File.open(url[:results_file], 'w'){|file|
    TransformResults.transform(results, file)
  }
  #uncomment this to save results for quicker testing of the transform
  #puts results.to_yaml
end

def save_page_png(file_path)
  @browser.save_screenshot(file_path)
end

def save_page_html(file_path)
  # FIXME How do we get the result html without re-running the tests?
  # one method: get the current DOM and any script elements. this is possibly too aggressive
  html = @browser.body.gsub(/<script.*?<\/script>/m, '')
  File.open(file_path, 'w'){|file|
    file.write(html)
    file.flush
  }
end

testURLs.each{|url|
  print "visiting #{url[:url]}..." unless @options[:quiet]
  @browser.open(url[:url])
  print "visited\n" unless @options[:quiet]
  print "waiting for tests to finish"
  start = Time.now
  results = nil
  while Time.now < (start + 300)
    results = @browser.js_eval('CoreTest.plan.results')
    print "."
    break unless results['finish'].nil?
    sleep 0.2
  end
  puts "(#{Time.now - start} seconds)"
  save_results_xml(url, results) if @options[:junit]
  save_page_png(url[:results_png_file]) if @options[:image]
  save_page_html(url[:results_html_file]) if @options[:html]
}

@browser.close
