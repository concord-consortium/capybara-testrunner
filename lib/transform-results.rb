require 'rexml/document'

module TransformResults
  include REXML

  class TestModule
    attr_accessor :name, :tests, :failures, :errors
  
    def initialize(name)
      @name = name
      @tests = []
      @failures = 0
      @errors = 0
    end
  end


  class TestTest
    attr_accessor :name, :assertions, :failed
  
    def initialize(name)
      @name = name
      @assertions = []
      @failed = false
    end
  
    def message
      messages = self.assertions.collect{|assertion| 
        assertion['result'].to_s.upcase + ': ' + assertion['message'].to_s
      }
      messages.join('\n')
    end
  end


  def self.parseResults(results)
    modules = []
    currentModule = nil
    currentTest = nil

    results ||= {}
    assertions = results['assertions'] ||= []
    
    assertions.each{|assertion|
      if currentModule.nil? or currentModule.name != assertion['module']
        currentModule = TestModule.new(assertion['module'])    
        modules.push(currentModule)
      end
  
      if currentTest.nil? or currentTest.name != assertion['test']
        currentTest = TestTest.new(assertion['test'])
        currentModule.tests.push(currentTest)
      end
  
      currentModule.failures += 1 if assertion['result'] == ('failed')
      currentModule.errors   += 1 if assertion['result'] == ('errors')
      if assertion['result'] != 'passed'
        currentTest.failed = true
      end
      currentTest.assertions.push(assertion)  
    } 
  
    modules
  end


  def self.from_qunit(results)
    modules = parseResults(results)
 
    if modules.empty? then
      return nil
    end
    
    jUnitXML = Document.new();
    testsuites = jUnitXML.add_element('testsuites')

    modules.each{ |currModule|
      testsuite = testsuites.add_element('testsuite', {
        'name'     => currModule.name.split(' ')[1], 
        'tests'    => currModule.tests.length,
        'failures' => currModule.failures, 
        'errors'   => currModule.errors
      })
      
      fileName = currModule.name.split(' ')[0]
      className = fileName.sub(/\.js/, '').gsub(/\//, '.')
      
      currModule.tests.each{ |currTest|
        testcase = testsuite.add_element('testcase', {
          'name'      => currTest.name, 
          'classname' => className
        })
        
        message = currTest.message.gsub("\\n", "\n\n")
        if currTest.failed      
          testcase.add_element('failure', { 'message' => message })
        elsif
          testcase.add_element('pass',    { 'message' => message })
        end
      }  
    }

    jUnitXML
  end
  
  
  def self.from_jasmine(results)
    if results.nil? or results == [] or results['suites'].nil? or results['suites'].length == 0 then
      return nil
    end
    
    jUnitXML = Document.new();
    testsuites_element = jUnitXML.add_element("testsuites")    
    
    results['suites'].each do |suite|
      results = suite['results']
      passed = results.select{|r| r['status'] == "passed" }
      skipped = results.select{|r| r['status'] == "skipped" }
      failures = (results-passed).select{|r| r['status'] == "failed" }
      errors = results-(passed+failures+skipped)

      testsuite_element = testsuites_element.add_element("testsuite", {'name' => suite['name'], 'tests' => results.size, 'failures' => failures.size, 'errors' => errors.size, 'skipped' => skipped.size})

      results.each do |result|
        testcase_element = testsuite_element.add_element("testcase", {'name' => result['name']})

        # TODO We should add the combined results of all the assertions
        # to the pass or failure messages
        case result['status']
        when "passed"
          testcase_element.add_element("pass", {'message' => 'passed'})
        when "failed"
          testcase_element.add_element("failure", {'message' => 'failed'})
        when "skipped"
          testcase_element.add_element("skipped", {'message' => 'skipped'})
        else
          testcase_element.add_element("failure", {'message' => 'unknown status: ' + result['status']})
        end
      end
    end
    
    jUnitXML
  end
  
  
  def self.find_jasmine_specs_in(node, prefix="")
    if node["type"] == "spec" then
      { node["id"].to_s => (prefix + node["name"]) }
    elsif node["type"] == "suite" then
      merge_jasmine_specs_from(node["children"], prefix + node["name"] + ": ")
    end
  end
  
  
  def self.merge_jasmine_specs_from(nodes, prefix="")
    results = {}
    nodes.each do |node|
      results.merge!(find_jasmine_specs_in(node, prefix))
    end
    results
  end
  
end
