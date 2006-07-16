module Cerberus
  module FSLatch
    #Emulate File.flock
    def self.lock(lock_file, wait_for_unlock=true)
      counter = 0
      while File.exists?(lock_file)
        return unless wait_for_unlock #if file exists then return

        sleep(10) #sleep for 10 seconds
        counter += 1
        raise "Could not wait anymore file unlocking '#{lock_file}'" if counter > 20 #if we are waiting more than 200 secs then raise exception
      end

      begin
        File.new(lock_file, 'w')
        yield
      ensure
        File.rm(lockfile)
      end
    end
  end
end