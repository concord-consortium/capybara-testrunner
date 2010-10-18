require 'daemon_controller'
require 'socket'
require 'fileutils'

class SCServerController < DaemonController
  def initialize(sc_server_path, port)
    sc_server_cmd = [sc_server_path,
           '--daemonize',   # run in the background
           "--pid='#{File.join(Dir.pwd, 'server.pid')}'", # save the pid to the server.pid file
           "--logfile='#{File.join(Dir.pwd, 'server.log')}'", # save the log messages to  server.log
           "--port=#{port}",
           "--host=0.0.0.0"]  # this is necessary on our ci server because otherwise it only binds to ipv6 address
           
    #call the DaemonController
    super(
       :identifier    => 'SproutCore Server',
       :start_command => sc_server_cmd.join(' '),
       :ping_command  => lambda { TCPSocket.new('localhost', port) },
       :pid_file      => 'server.pid',
       :log_file      => 'server.log',
       :start_timeout => 25
    )
  end
  
  def start
    # print out the command 
    puts @start_command
    super
  end  
end