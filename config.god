APP_ROOT = '/data/www/twatlr.com/current'
# APP_ROOT = '/Users/gianni/Projects/racket/twatlr.com'

God.watch do |w|
  w.name = 'twatlr'
  w.pid_file = "#{APP_ROOT}/app.pid"
  w.log = "#{APP_ROOT}/log/stdout.log"

  w.start = "env racket #{APP_ROOT}/app.rkt"
  w.stop = "env kill #{w.pid_file}"

  w.interval = 30.seconds
  w.start_grace = 10.seconds
  w.restart_grace = 10.seconds
  
  w.behavior(:clean_pid_file)

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 5.seconds
      c.running = false
    end
  end
  
  w.restart_if do |restart|
    restart.condition(:memory_usage) do |c|
      c.above = 150.megabytes
      c.times = [3, 5] # 3 out of 5 intervals
    end
  
    restart.condition(:cpu_usage) do |c|
      c.above = 50.percent
      c.times = 5
    end
  end
  
  # lifecycle
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
    end
  end
end
