require 'cerberus/builder/base'

class Cerberus::Builder::Bjam
 attr_reader :output

 def initialize(config)
   @config = config
 end

 def run
   Dir.chdir @config[:application_root]

   #set correct mountpoint if it present
   build_dir = @config[:builder, :bjam, :build_dir]
   Dir.chdir(build_dir) if build_dir

   cmd = @config[:builder, :bjam, :cmd] || 'bjam'
   task = @config[:builder, :bjam, :target] #|| 'clean'

   @output = `#{cmd} #{task} 2>&1`
   successful?
 end

 def successful?
   $?.exitstatus == 0 and not @output =~ /failed|error:|skipped/ 
     #/\*\*\* \d+ failure(s)? detected in test suite/ and not @output.include?("syntax error")
 end

 def brokeness
   return nil
 end
end