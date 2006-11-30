require File.dirname(__FILE__) + '/test_helper'

require 'cerberus/cli'
require 'cerberus/scm/perforce'

class PerforceSCMTest < Test::Unit::TestCase
  def test_log_parser
    MSG =~ Cerberus::SCM::Perforce::CHANGES_LOG_REGEXP

    assert_equal '264179', $1
    assert_equal '2006/11/29', $2
    assert_equal 'someuser@someuser_SOMEUSER', $3
    assert_equal "dbcis-2356\njust test", $4.strip
  end

  MSG =<<END
Change 264179 on 2006/11/29 by someuser@someuser_SOMEUSER

        dbcis-2356
just test
END
end
require File.dirname(__FILE__) + '/test_helper'

require 'cerberus/cli'
require 'cerberus/scm/perforce'

class PerforceSCMTest < Test::Unit::TestCase
  def test_log_parser
    MSG =~ Cerberus::SCM::Perforce::CHANGES_LOG_REGEXP

    assert_equal '264179', $1
    assert_equal '2006/11/29', $2
    assert_equal 'someuser@someuser_SOMEUSER', $3
    assert_equal "dbcis-2356\njust test", $4.strip
  end

  MSG =<<END
Change 264179 on 2006/11/29 by someuser@someuser_SOMEUSER

        dbcis-2356
just test
END
end
