require 'test_helper'

class AutoscalingTasksTest < Minitest::Test
  include Capistrano::DSL
  include AutoScalingStubs

  def setup
    Capistrano::Configuration.reset!
    Rake::Task.tasks.each(&:reenable)
    Rake::Task['load:defaults'].invoke
    set :aws_autoscaling_group_name, 'my-group'
    set :aws_access_key_id, 'key'
    set :aws_secret_access_key, 'secret'
    set :aws_deploy_user, 'deploy'
    set :aws_deploy_roles, [:web, :app, :db]
    stub_aws(%w(i-3 i-1 i-2))
  end

  def servers
    Capistrano::Configuration.env.servers.to_a
  end

  def test_first_instance_gets_every_role_and_is_primary
    capture_io { Rake::Task['autoscaling_deploy:setup_instances'].invoke }

    first = servers.first
    assert_equal 'i-3.public.example.com', first.hostname
    assert_equal 'deploy', first.user
    assert_equal Set[:web, :app, :db], first.roles
    assert first.primary
  end

  def test_other_instances_skip_db_role_and_are_not_primary
    capture_io { Rake::Task['autoscaling_deploy:setup_instances'].invoke }

    assert_equal %w(i-1.public.example.com i-2.public.example.com), servers.drop(1).map(&:hostname)
    servers.drop(1).each do |server|
      assert_equal Set[:web, :app], server.roles
      refute server.primary
    end
  end

  def test_works_without_explicit_keys
    set :aws_access_key_id, nil
    set :aws_secret_access_key, nil
    set :aws_profile, 'deploy'
    capture_io { Rake::Task['autoscaling_deploy:setup_instances'].invoke }

    assert_equal 3, servers.size
  end

  def test_runs_before_deploy_starting
    assert_includes Rake::Task["deploy:starting"].prerequisites.map(&:to_s), 'deploy:check_autoscaling_hooks'
  end

  def test_hook_adds_servers_when_enabled
    capture_io { Rake::Task['deploy:check_autoscaling_hooks'].invoke }

    assert_equal 3, servers.size
  end

  def test_hook_does_nothing_when_disabled
    set :aws_autoscaling, false
    Rake::Task['deploy:check_autoscaling_hooks'].invoke

    assert_empty servers
  end
end
