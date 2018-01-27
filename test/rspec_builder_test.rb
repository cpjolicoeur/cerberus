require File.dirname(__FILE__) + '/test_helper'

require 'cerberus/builder/rspec'
require 'tmpdir'

class Cerberus::Builder::RSpec
  attr_writer :output
end

class RSpecBuilderTest < Test::Unit::TestCase
  def test_builder
    `whoami` # clear $? for tests run via rake

    tmp = Dir::tmpdir
    builder = Cerberus::Builder::RSpec.new(:application_root => tmp)

    builder.output = RSPEC_TEST_OK_OUTPUT
    assert builder.successful?

    builder.output = RSPEC_TEST_OK_OUTPUT_ALT
    assert builder.successful?

    builder.output = RSPEC_TEST_OK_OUTPUT_WITH_PENDING
    assert builder.successful?

    builder.output = RSPEC_TEST_ERROR_OUTPUT
    assert !builder.successful?
    assert_equal 1, builder.brokeness

    builder.output = RSPEC_TEST_ERROR_OUTPUT_WITH_PENDING
    assert !builder.successful?
    assert_equal 3, builder.brokeness
  end
end

RSPEC_TEST_OK_OUTPUT = <<-END
/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin/ruby /Library/Ruby/Gems/1.8/gems/rspec-1.1.12/bin/spec spec/views/clients/show.html.erb_spec.rb spec/models/role_spec.rb spec/models/dashboard_spec.rb spec/models/client_spec.rb spec/helpers/admin/users_helper_spec.rb spec/controllers/sessions_controller_spec.rb spec/models/query_dates_spec.rb spec/helpers/heatmaps_helper_spec.rb spec/helpers/passwords_helper_spec.rb spec/controllers/admin/reports_controller_spec.rb spec/models/role_assignment_spec.rb spec/models/default_role_spec.rb spec/controllers/sites_controller_spec.rb spec/controllers/dashboards_controller_spec.rb spec/models/widget_instance_spec.rb spec/models/widget_spec.rb spec/controllers/admin/roles_controller_spec.rb spec/models/user_spec.rb spec/models/right_spec.rb spec/views/clients/new.html.erb_spec.rb spec/helpers/reports_helper_spec.rb spec/controllers/reports_controller_spec.rb spec/models/site_spec.rb spec/helpers/admin/rights_helper_spec.rb spec/models/data_warehouse_spec.rb spec/helpers/users_helper_spec.rb spec/helpers/clients_helper_spec.rb spec/helpers/admin/roles_helper_spec.rb spec/views/clients/index.html.erb_spec.rb spec/controllers/users_controller_spec.rb spec/controllers/clients_routing_spec.rb spec/controllers/clients_controller_spec.rb spec/controllers/admin/users_controller_spec.rb spec/controllers/access_control_spec.rb spec/models/query_cache_key_spec.rb spec/views/clients/edit.html.erb_spec.rb spec/controllers/passwords_controller_spec.rb spec/controllers/authenticated_system_spec.rb spec/helpers/application_helper_spec.rb spec/models/report_spec.rb spec/models/query_spec.rb spec/helpers/admin/reports_helper_spec.rb spec/controllers/queries_controller_spec.rb spec/controllers/application_controller_spec.rb spec/models/excel_export_spec.rb spec/controllers/admin/rights_controller_spec.rb -O spec/spec.opts 
..............................................................................................................................................................................................................................................*....*..................................................................................................................................................................................................................*.................................................................................................................*..*....*.................................................................................................................................................................................................

Pending:

SessionsController logout_keeping_session! forgets me (Not Yet Implemented)
/src/parkassist/paseweb/vendor/gems/rspec-rails-1.1.12/lib/spec/rails/example/controller_example_group.rb:109:in `initialize'

SessionsController logout_killing_session! forgets me (Not Yet Implemented)
/src/parkassist/paseweb/vendor/gems/rspec-rails-1.1.12/lib/spec/rails/example/controller_example_group.rb:109:in `initialize'

Report query_data should return a hash of all queries via :dom_id => :data (TODO)
./spec/models/report_spec.rb:109

ReportsController GET show xls format request should return an excel spreadsheet (TODO)
./spec/controllers/reports_controller_spec.rb:56

ReportsController GET show should query the DataWarehouse (TODO)
./spec/controllers/reports_controller_spec.rb:39

DashboardsController it should save user-customized layout should check access before saving (TODO)
./spec/controllers/dashboards_controller_spec.rb:280

Finished in 41.688393 seconds

770 examples, 0 failures, 6 pending
END

RSPEC_TEST_OK_OUTPUT_ALT = <<-END
Git commit message (fixes #111)
diff...
(in /Users/deployer/.cerberus/work/webapp/sources)
Profiling enabled.
..................................................................................................................................................
.................................................................................................................................................


Top 10 slowest examples:
6.0324890 Setting should update the modified_time_unix attribute after
destroy
3.0633630 Recorded should update the modified_time_unix whenever the
wildcard value is updated in nvp
3.0267280 Setting should update the modified_time_unix attribute after
save
0.8593440 Audit searching for auditables should find audits for a
deleted package and its children
0.7079580 Package a fully activatable valid package should delete all
child records when destroyed
0.3543940 POST create should audit a time segment split
0.3363000 Package a fully activatable valid package should insert into
the db successfully
0.3159420 Audit searching for auditables should find audits for a
deleted number
0.2989840 Audit searching for auditables should find all auditables in
1 week as default
0.2906990 POST create should audit the created profile

Finished in 35.621931 seconds

291 examples, 0 failures
END

RSPEC_TEST_OK_OUTPUT_WITH_PENDING = <<-END
/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin/ruby /Library/Ruby/Gems/1.8/gems/rspec-1.1.12/bin/spec spec/views/clients/show.html.erb_spec.rb spec/models/role_spec.rb spec/models/dashboard_spec.rb spec/models/client_spec.rb spec/helpers/admin/users_helper_spec.rb spec/controllers/sessions_controller_spec.rb spec/models/query_dates_spec.rb spec/helpers/heatmaps_helper_spec.rb spec/helpers/passwords_helper_spec.rb spec/controllers/admin/reports_controller_spec.rb spec/models/role_assignment_spec.rb spec/models/default_role_spec.rb spec/controllers/sites_controller_spec.rb spec/controllers/dashboards_controller_spec.rb spec/models/widget_instance_spec.rb spec/models/widget_spec.rb spec/controllers/admin/roles_controller_spec.rb spec/models/user_spec.rb spec/models/right_spec.rb spec/views/clients/new.html.erb_spec.rb spec/helpers/reports_helper_spec.rb spec/controllers/reports_controller_spec.rb spec/models/site_spec.rb spec/helpers/admin/rights_helper_spec.rb spec/models/data_warehouse_spec.rb spec/helpers/users_helper_spec.rb spec/helpers/clients_helper_spec.rb spec/helpers/admin/roles_helper_spec.rb spec/views/clients/index.html.erb_spec.rb spec/controllers/users_controller_spec.rb spec/controllers/clients_routing_spec.rb spec/controllers/clients_controller_spec.rb spec/controllers/admin/users_controller_spec.rb spec/controllers/access_control_spec.rb spec/models/query_cache_key_spec.rb spec/views/clients/edit.html.erb_spec.rb spec/controllers/passwords_controller_spec.rb spec/controllers/authenticated_system_spec.rb spec/helpers/application_helper_spec.rb spec/models/report_spec.rb spec/models/query_spec.rb spec/helpers/admin/reports_helper_spec.rb spec/controllers/queries_controller_spec.rb spec/controllers/application_controller_spec.rb spec/models/excel_export_spec.rb spec/controllers/admin/rights_controller_spec.rb -O spec/spec.opts 
............................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................

Finished in 23.895298 seconds

764 examples, 0 failures
END

RSPEC_TEST_ERROR_OUTPUT = <<-END
/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin/ruby /Library/Ruby/Gems/1.8/gems/rspec-1.1.12/bin/spec spec/models/site_spec.rb -O spec/spec.opts 
...........F...

1)
'Site being created increments Site#count' FAILED
count should not have changed, but did change from 1 to 2
./spec/models/site_spec.rb:21:

Finished in 0.433946 seconds

15 examples, 1 failure
END

RSPEC_TEST_ERROR_OUTPUT_WITH_PENDING = <<-END
/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin/ruby /Library/Ruby/Gems/1.8/gems/rspec-1.1.12/bin/spec spec/models/site_spec.rb -O spec/spec.opts 
...........F..*

Pending:

Site should respond to :client (TODO)
./spec/models/site_spec.rb:31

1)
'Site being created increments Site#count' FAILED
count should not have changed, but did change from 1 to 2
./spec/models/site_spec.rb:21:

Finished in 0.245002 seconds

15 examples, 3 failures, 1 pending
END
