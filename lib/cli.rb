require 'runner'

command = ARGV[0]

fail 'Please specify command (add,run)' unless command

case command
  when 'add'
    Cerberus::Runner.add!(Dir.pwd)
  when 'run'
    Cerberus::Runner.run!(ARGV[1])
  else
    fail "Do not know what to do with command '#{command}'"
end
