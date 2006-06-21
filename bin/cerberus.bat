@echo off
if not "%~f0" == "~f0" goto WinNT
ruby -Sx "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofruby
:WinNT
"ruby" -x "%~f0" %*
rem "%~d0%~p0ruby" -x "%~f0" %*
goto endofruby
#!c:/progra~1/ruby/bin/ruby
$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'cli'

Cerberus::CLI.run(ARGV)

__END__
:endofruby
