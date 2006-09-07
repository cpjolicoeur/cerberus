require 'fileutils'

module Cerberus
  class Latch
    #Emulate File.flock
    def self.lock(lock_file, options = {})
      if File.exists?(lock_file)
        modif_time = File::Stat.new(lock_file).mtime
        ttl = options[:lock_ttl]

        if ttl 
          if modif_time < ttl.ago
            File.delete(lock_file)
          else
            yield
            return
          end
        end
      end

      begin
        FileUtils.mkpath(File.dirname(lock_file))
        File.new(lock_file, 'w').close
        yield
      ensure
        File.delete(lock_file)
      end
    end
  end
end