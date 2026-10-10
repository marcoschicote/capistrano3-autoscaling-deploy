require 'test_helper'
require 'fileutils'
require 'tmpdir'

class AwsCredentialsTest < Minitest::Test
  include AwsHelper

  AWS_ENV = %w(AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE AWS_SHARED_CREDENTIALS_FILE AWS_CONFIG_FILE)

  def setup
    @saved_env = AWS_ENV.to_h { |name| [name, ENV.delete(name)] }
    @dir = Dir.mktmpdir
    # Keep the developer's own ~/.aws files out of the tests
    ENV['AWS_SHARED_CREDENTIALS_FILE'] = File.join(@dir, 'credentials')
    ENV['AWS_CONFIG_FILE'] = File.join(@dir, 'config')
    reset_shared_config
  end

  def teardown
    @saved_env.each { |name, value| ENV[name] = value }
    FileUtils.remove_entry(@dir)
    reset_shared_config
  end

  def test_explicit_keys_are_used
    options = aws_client_options('us-west-2', 'key', 'secret')

    assert_equal 'us-west-2', options[:region]
    assert_equal 'key', options[:credentials].access_key_id
    assert_equal 'secret', options[:credentials].secret_access_key
  end

  def test_explicit_keys_win_over_profile
    options = aws_client_options('us-west-2', 'key', 'secret', 'deploy')

    assert_equal 'key', options[:credentials].access_key_id
    refute options.key?(:profile)
  end

  def test_profile_is_passed_to_the_sdk
    assert_equal({ region: 'us-west-2', profile: 'deploy' }, aws_client_options('us-west-2', nil, nil, 'deploy'))
  end

  def test_no_settings_leave_credentials_to_the_sdk
    assert_equal({ region: 'us-west-2' }, aws_client_options('us-west-2', nil, nil))
  end

  def test_only_one_key_is_an_error
    assert_raises(ArgumentError) { aws_client_options('us-west-2', 'key', nil) }
    assert_raises(ArgumentError) { aws_client_options('us-west-2', nil, 'secret') }
  end

  def test_default_chain_reads_environment_variables
    ENV['AWS_ACCESS_KEY_ID'] = 'env-key'
    ENV['AWS_SECRET_ACCESS_KEY'] = 'env-secret'
    ENV['AWS_SESSION_TOKEN'] = 'env-token'

    credentials = real_client(aws_client_options('us-west-2', nil, nil)).config.credentials.credentials

    assert_equal 'env-key', credentials.access_key_id
    assert_equal 'env-token', credentials.session_token
  end

  def test_profile_reads_shared_credentials_file
    File.write(ENV['AWS_SHARED_CREDENTIALS_FILE'], <<~INI)
      [deploy]
      aws_access_key_id = profile-key
      aws_secret_access_key = profile-secret
    INI
    reset_shared_config

    credentials = real_client(aws_client_options('us-west-2', nil, nil, 'deploy')).config.credentials.credentials

    assert_equal 'profile-key', credentials.access_key_id
  end

  private

  # The SDK reads the shared config and credentials files once and caches them
  def reset_shared_config
    Aws.instance_variable_set(:@shared_config, nil)
  end

  # A client that resolves credentials like it would in a real deploy. It is
  # never used to make a request.
  def real_client(options)
    Aws::AutoScaling::Client.new(options.merge(stub_responses: false))
  end
end
