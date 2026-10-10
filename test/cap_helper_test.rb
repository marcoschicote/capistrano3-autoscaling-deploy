require 'test_helper'

class CapHelperTest < Minitest::Test
  include CapHelper

  def test_removes_db_role
    assert_equal [:web, :app], sanitize_roles([:web, :app, :db])
  end

  def test_removes_primary_from_role_options
    assert_equal [:web, { no_release: true }], sanitize_roles([:web, { primary: true, no_release: true }])
  end
end
