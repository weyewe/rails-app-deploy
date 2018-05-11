# Set your full path to application.
app_dir =    "/var/www/p2p_app/current" # File.expand_path('../../', __FILE__)
shared_dir = File.expand_path('../../../shared/', __FILE__)

# Set unicorn options
worker_processes 1
preload_app true
timeout 30

# Fill path to your app
working_directory app_dir

# Set up socket location
listen "#{shared_dir}/sockets/unicorn.sock", :backlog => 64
listen 8000, :tcp_nopush => true

# Loging
stderr_path "#{shared_dir}/log/unicorn.stderr.log"
stdout_path "#{shared_dir}/log/unicorn.stdout.log"

# Set master PID location
pid "#{shared_dir}/pids/unicorn.pid"


before_fork do |server, worker|

  Signal.trap "USR2" do
    puts "Since a black hole is lurking and eating USR2s we will hit http_server#reexec ourselves"
    server.send(:reexec)
  end


  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!
  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection

  port = 5000 + worker.nr

  child_pid = server.config[:pid].sub('.pid', ".#{port}.pid")
  system("echo #{Process.pid} > #{child_pid}")
end

before_exec do |server|
  ENV['BUNDLE_GEMFILE'] = "/var/www/p2p_app/current/Gemfile"
  ENV["HOME"] = "/var/www/p2p_app/current"
end
