require 'json'
require 'selenium-rc-runner'
require 'trollop'

class SauceRunner < SeleniumRCRunner 
  def initialize(app_host, config_folder, start_tunnel) 

    # check if the saucelabs.yml file exists
    saucelabs_config = File.join(config_folder, 'saucelabs.yml')
    if File.exists? saucelabs_config
      sauce_browser_opts = YAML.load_file(saucelabs_config)
    elsif !ENV['SELENIUM_DRIVER'].nil? and !ENV['SAUCELABS_USER'].nil? and !ENV['SAUCELABS_KEY'].nil? 
      # this is to handle the URI strings sent in by hudson's saucelabs plugin there is some documentation here:
      # http://selenium-client-factory.infradna.com/driver-sauceOnDemand.html
      # normally URI.parse(url).query could be used here but it appears not to handle non standard URI schemes    
      selenium_driver_opts = CGI.parse(ENV['SELENIUM_DRIVER'].split('?')[1])
      # this will return something like {"os"=>["Linux"], "browser"=>["firefox"], "browser-version"=>["3."]}
      # so we need to make the values single instead of arrays
      sauce_browser_opts = {}
      selenium_driver_opts.each{|key,value| sauce_browser_opts[key]=value[0]}

      # add in the user and API key
      sauce_browser_opts['username'] = ENV['SAUCELABS_USER']
      sauce_browser_opts['access-key'] = ENV['SAUCELABS_KEY']
    else
      Trollop::die "When running with selenium-rc either a saucelabs.yml file is needed or the appropriate environment variables need to be set"
    end

    if start_tunnel
      require 'sauce'

      # startup tunnel so saucelabs can connect to our server
      client = Sauce::Client.new(:username => sauce_browser_opts['username'],
                                 :access_key => sauce_browser_opts['access-key'])
                               
      @tunnel = client.tunnels.create('DomainNames' => [app_host])
      @tunnel.refresh!
    end
    
    super(app_host, 'saucelabs.com', sauce_browser_opts.to_json)
  end

  def close()
    super()
    @tunnel.destroy unless @tunnel.nil?
  end
end