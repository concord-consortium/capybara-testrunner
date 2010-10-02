require "selenium/client"
require "json"

class SeleniumRCRunner
  def initialize()
    @browser = Selenium::Client::Driver.new(
             :host => 'localhost',
             :port => 4444, 
             :browser => '*safari',
             :url => "http://localhost:4020", 
             :timeout_in_seconds => 90)

             # browser = Selenium::Client::Driver.new(
             #         :host => 'saucelabs.com',
             #         :port => 4444, 
             #         :browser => '{"username": "scytacki",' +
             #           # put a valid access-key in here:
             #                       '"access-key": "",' +
             #                       '"os": "Windows 2003",' +
             #                       '"browser": "iexplore",' +
             #                       '"browser-version": "8.",' +
             #                       # '"browser": "opera",' +
             #                       # '"browser-version": "10.",' +
             #                       '"job-name": "TestSwarm test"}',
             #         :url => "http://testswarm.dev.concord.org", 
             #         :timeout_in_seconds => 90)


    @browser.start_new_browser_session    
  end
  
  def open(url)
     @browser.open(url)
  end
  
  def js_eval(javascript)
    results_str = @browser.js_eval("JSON.stringify(window.#{javascript})")
    JSON.parse(results_str)
  end
  
  def save_screenshot(file_path)
    @browser.capture_screenshot(File.join(Dir.pwd, file_path))
  end
  
  def body
    @browser.get_html_source
  end
  
  def close()
    @browser.close_current_browser_session
  end
end