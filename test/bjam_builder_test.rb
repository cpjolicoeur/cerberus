require File.dirname(__FILE__) + '/test_helper'

require 'cerberus/builder/bjam'
require 'tmpdir'

class Cerberus::Builder::Bjam
 attr_writer :output
end

class BjamBuilderTest < Test::Unit::TestCase
 def test_builder
   tmp = Dir::tmpdir
   builder = Cerberus::Builder::Bjam.new(:application_root => tmp)
   builder.output = BJAM_INITIAL_BUILD_OK_OUTPUT
   assert builder.successful?

   builder.output = BJAM_BUILD_OK_OUTPUT
   assert builder.successful?

   builder.output = BJAM_COMPILER_ERROR_OUTPUT
   assert !builder.successful?

   builder.output = BJAM_TEST_ERROR_OUTPUT
   assert !builder.successful?
 end
end

BJAM_INITIAL_BUILD_OK_OUTPUT =<<-END
MkDir1 bin
MkDir1 bin\cerberus_unit.test
MkDir1 bin\cerberus_unit.test\msvc-7.1
MkDir1 bin\cerberus_unit.test\msvc-7.1\debug
MkDir1 bin\cerberus_unit.test\msvc- 7.1\debug\threading-multi
msvc.compile.c++ bin\cerberus_unit.test\msvc-7.1\debug\threading-multi\cerberus_unit.obj
cerberus_unit.cpp
msvc.link bin\cerberus_unit.test\msvc-7.1\debug\threading-multi\cerberus_unit.exe
testing.capture-output bin\cerberus_unit.test\msvc-7.1\debug\threading-multi\cerberus_unit.run
       1 file(s) copied.
**passed** bin\cerberus_unit.test\msvc-7.1\debug\threading-multi\cerberus_unit.test
...updated 11 targets...
END

BJAM_BUILD_OK_OUTPUT =<<-END
warning: toolset gcc initialization: can't find tool g++
warning: initialized from
Building Boost.Regex with the optional Unicode/ICU support disabled.
Please refer to the Boost.Regex documentation for more information
(and if you don't know what ICU is then you probably don't need it).
...found 108 targets...
...updating 6 targets...
msvc.compile.c++ bin\cerberus_unit.test\msvc- 7.1\debug\threading-multi\cerberus_unit.obj
cerberus_unit.cpp
msvc.link bin\cerberus_unit.test\msvc-7.1\debug\threading-multi\cerberus_unit.exe
testing.capture-output bin\cerberus_unit.test\msvc-7.1\debug\threading-multi\cerberus_unit.run
       1 file(s) copied.
**passed** bin\cerberus_unit.test\msvc-7.1\debug\threading-multi\cerberus_unit.test
...updated 6 targets...
END


BJAM_COMPILER_ERROR_OUTPUT =<<-END
warning: toolset gcc initialization: can't find tool g++
warning: initialized from
Building Boost.Regex with the optional Unicode/ICU support disabled.
Please refer to the Boost.Regex documentation for more information
(and if you don't know what ICU is then you probably don't need it).
...found 108 targets...
...updating 6 targets...
msvc.compile.c++ bin\cerberus_unit.test\msvc-7.1\debug\threading-multi\cerberus_unit.obj
cerberus_unit.cpp
cerberus_unit.cpp(29) : error C2143: syntax error : missing ';' before '}'

   call "f:\msvc\vc71\VC7\bin\vcvars32.bat" > nul
cl  /Zm800 -nologo -TP  /Z7 /Od /Ob0 /GR /MDd /Zc:forScope /Zc:wchar_t  /wd4675 /EHs   @"bin\cerberus_unit.test\msvc-7.1\debug\threading-multi\cerberus_unit.obj.rsp "  -c -Fo"bin\cerberus_unit.test\msvc-7.1\debug\threading-multi\cerberus_unit.obj"  && del /f  "bin\cerberus_unit.test\msvc-7.1\debug\threading-multi\cerberus_unit.obj.rsp"

...failed msvc.compile.c++ bin\cerberus_unit.test\msvc-7.1\debug\threading-multi\cerberus_unit.obj...
...removing bin\cerberus_unit.test\msvc-7.1\debug\threading-multi\cerberus_unit.obj
...skipped <pbin\cerberus_unit.test\msvc- 7.1\debug\threading-multi>cerberus_unit.exe.rsp for lack of <pbin\cerberus_unit.test\msvc-7.1\debug\threading-multi>cerberus_unit.obj...
...skipped <pbin\cerberus_unit.test\msvc-7.1\debug\threading-multi>cerberus_unit.exe for lack of <pbin\cerberus_unit.test\msvc- 7.1\debug\threading-multi>cerberus_unit.obj...
...skipped <pbin\cerberus_unit.test\msvc-7.1\debug\threading-multi>cerberus_unit.run for lack of <pbin\cerberus_unit.test\msvc-7.1\debug\threading-multi>cerberus_unit.exe...
...removing outdated bin\cerberus_unit.test\msvc-7.1\debug\threading-multi\cerberus_unit.test
...failed updating 1 target...
...skipped 4 targets...
...updated 1 target...
END

BJAM_TEST_ERROR_OUTPUT =<<-END
warning: toolset gcc initialization: can't find tool g++
warning: initialized from
Building Boost.Regex with the optional Unicode/ICU support disabled.
Please refer to the Boost.Regex documentation for more information
(and if you don't know what ICU is then you probably don't need it).
...found 108 targets...
...updating 6 targets...
msvc.compile.c++ bin\cerberus_unit.test\msvc-7.1\debug\threading-multi\cerberus_unit.obj
cerberus_unit.cpp
msvc.link bin\cerberus_unit.test\msvc-7.1\debug\threading-multi\cerberus_unit.exe
testing.capture-output bin\cerberus_unit.test\msvc-7.1\debug\threading-multi\cerberus_unit.run
====== BEGIN OUTPUT ======
Running 1 test case...
cerberus_unit.cpp(28): error in "CerberusTest::test_constructing": check 0 == 1 failed

*** 1 failure detected in test suite "Master test suite"

EXIT STATUS: 201
====== END OUTPUT ======

   set PATH=F:\codeshop\vlog\trunk\thirdp\boost_1_33_0\bin.v2\libs\date_time\build\msvc-7.1\debug\threading-multi;F:\codeshop\vlog\trunk\thirdp\boost_1_33_0\bin.v2\libs\filesystem\build\msvc- 7.1\debug\threading-multi;F:\codeshop\vlog\trunk\thirdp\boost_1_33_0\bin.v2\libs\program_options\build\msvc-7.1\debug\threading-multi;F:\codeshop\vlog\trunk\thirdp\boost_1_33_0\bin.v2\libs\regex\build\msvc-7.1\debug\threading-multi ;F:\codeshop\vlog\trunk\thirdp\boost_1_33_0\bin.v2\libs\signals\build\msvc-7.1\debug\threading-multi;F:\codeshop\vlog\trunk\thirdp\boost_1_33_0\bin.v2\libs\thread\build\msvc-7.1\debug\threading-multi;%PATH%

    bin\cerberus_unit.test\msvc- 7.1\debug\threading-multi\cerberus_unit.exe    > bin\cerberus_unit.test\msvc-7.1\debug\threading-multi\cerberus_unit.output  2>&1
   set status=%ERRORLEVEL%
   echo.  >> bin\cerberus_unit.test\msvc- 7.1\debug\threading-multi\cerberus_unit.output
   echo EXIT STATUS: %status%  >> bin\cerberus_unit.test\msvc-7.1\debug\threading-multi\cerberus_unit.output
   if %status% EQU 0 (
       copy  bin\cerberus_unit.test\msvc- 7.1\debug\threading-multi\cerberus_unit.output  bin\cerberus_unit.test\msvc-7.1\debug\threading-multi\cerberus_unit.run
   )
   set verbose=0
   if %status% NEQ 0 (
       set verbose=1
   )
   if %verbose% EQU 1 (
       echo ====== BEGIN OUTPUT ======
       type  bin\cerberus_unit.test\msvc-7.1\debug\threading-multi\cerberus_unit.output
       echo ====== END OUTPUT ======
   )
   exit %status%

...failed testing.capture-output bin\cerberus_unit.test\msvc-7.1\debug\threading-multi\cerberus_unit.run...
...removing bin\cerberus_unit.test\msvc-7.1\debug\threading-multi\cerberus_unit.run
...removing outdated bin\cerberus_unit.test\msvc- 7.1\debug\threading-multi\cerberus_unit.test
...failed updating 1 target...
...skipped 1 target...
...updated 4 targets...
END