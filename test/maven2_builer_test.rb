require File.dirname(__FILE__) + '/test_helper'

require 'cerberus/builder/maven2'
require 'mock/manager'
require 'tmpdir'

class Cerberus::Builder::Maven2
  attr_writer :output
end

class Maven2BuilderTest < Test::Unit::TestCase
  def test_builder
    tmp = Dir::tmpdir
    builder = Cerberus::Builder::Maven2.new(:application_root => tmp)
    builder.output = MVN_OUTPUT
    assert !builder.successful?

    surefire_file = "#{tmp}/target/surefire-reports/wicket.markup.html.form.persistence.CookieValuePersisterTest.txt"
    FileUtils.mkpath File.dirname(surefire_file)
    IO.write(surefire_file, SUREFIRE_CLASS_OUTPUT)

    output = builder.add_error_information(MVN_OUTPUT)
    assert output.include?('at wicket.markup.html.basic.SimplePageTest.testRenderHomePage_3(SimplePageTest.java:285)')
  end
end


MVN_OUTPUT =<<-END
-------------------------------------------------------
 T E S T S
-------------------------------------------------------
Running wicket.markup.html.list.PagedTableNavigatorWithMarginTest
Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.313 sec
Running wicket.markup.html.list.IncrementalTableNavigationTest
=== wicket.markup.html.list.IncrementalTableNavigationPage ===
=== wicket.markup.html.list.IncrementalTableNavigationPage : nextNext ===
=== wicket.markup.html.list.IncrementalTableNavigationPage : prev ===
Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.062 sec
Running wicket.markup.html.form.persistence.CookieValuePersisterTest
=== wicket.markup.html.list.IncrementalTableNavigationPage ===
=== wicket.markup.html.list.IncrementalTableNavigationPage : nextNext ===
Tests run: 1, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 0.516 sec <<< FAILURE!
Running wicket.util.string.StringListTest
Tests run: 8, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.016 sec

Results :
Tests run: 449, Failures: 4, Errors: 9, Skipped: 0

[INFO] ------------------------------------------------------------------------
[ERROR] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] There are test failures.
    END

SUREFIRE_CLASS_OUTPUT =<<-END
-------------------------------------------------------------------------------
Test set: wicket.markup.html.basic.SimplePageTest
-------------------------------------------------------------------------------
Tests run: 13, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 0.521 sec <<< FAILURE!
testRenderHomePage_3(wicket.markup.html.basic.SimplePageTest)  Time elapsed: 0.06 sec  <<< FAILURE!
junit.framework.AssertionFailedError
	at junit.framework.Assert.fail(Assert.java:47)
	at junit.framework.Assert.assertTrue(Assert.java:20)
	at junit.framework.Assert.assertTrue(Assert.java:27)
	at wicket.WicketTestCase.executeTest(WicketTestCase.java:78)
	at wicket.markup.html.basic.SimplePageTest.testRenderHomePage_3(SimplePageTest.java:285)

END