require_relative '../vendor/tc/lib/tc'
require_relative '../lib/bx'
require 'fileutils'

# Test helper module for bx tests
module BXTestHelper
  def setup_test_env
    @test_dir = "/tmp/bx-test-#{Process.pid}-#{Time.now.to_i}"
    FileUtils.mkdir_p(@test_dir)
    ENV['BX_STATE_DIR'] = @test_dir

    # Kill any existing tmux sessions from previous test runs
    system("tmux kill-server 2>/dev/null")

    # Initialize state manager
    @state_manager = BX::StateManager.instance
    @state_manager.connect!
  end

  def teardown_test_env
    # Kill tmux server to clean up all sessions
    system("tmux kill-server 2>/dev/null")

    # Close database connection
    @state_manager.close if @state_manager

    # Remove test directory
    FileUtils.rm_rf(@test_dir) if @test_dir && File.exist?(@test_dir)

    # Clear environment
    ENV.delete('BX_STATE_DIR')
  end

  def create_test_project(name, files = {})
    project_dir = File.join(@test_dir, name)
    FileUtils.mkdir_p(project_dir)

    # Create any requested files
    files.each do |filename, content|
      file_path = File.join(project_dir, filename)
      FileUtils.mkdir_p(File.dirname(file_path))
      File.write(file_path, content)
    end

    project_dir
  end

  def wait_for_condition(timeout: 5, interval: 0.1, &block)
    start_time = Time.now
    loop do
      return true if block.call
      return false if Time.now - start_time > timeout
      sleep interval
    end
  end
end

# Verify tmux is available before running tests
begin
  BX::StateManager.verify_tmux!
  puts "✓ tmux verification passed"
rescue => e
  puts "✗ tmux verification failed: #{e.message}"
  puts "  Please install tmux 3.0+ to run bx tests"
  exit 1
end
