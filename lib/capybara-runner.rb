require 'capybara'
require 'capybara/dsl'

class CapybaraRunner
  def initialize(driver, app_host)
    puts "app_host: #{app_host}"
    Capybara.current_driver = driver
    Capybara.app_host = app_host
  end
  
  def open(url)
    Capybara.visit(url)
  end
  
  def js_eval(javascript)
    Capybara.evaluate_script(javascript)
  end
  
  def save_screenshot(file_path)
    Capybara.current_session.driver.browser.save_screenshot(file_path)
  end
  
  def body
    Capybara.body
  end
  
  def close()
    # we weren't doing anything here before and it was shuting itself down
  end
  
end