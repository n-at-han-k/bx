module BX
  class StateManager
    require 'singleton'
    include Singleton

    attr_reader :db

    def initialize
      @db_path = ENV['BX_STATE_DIR'] ? File.join(ENV['BX_STATE_DIR'], 'master.db') : File.join(ENV['HOME'], '.bx', 'master.db')
      @lock_path = ENV['BX_STATE_DIR'] ? File.join(ENV['BX_STATE_DIR'], 'state.lock') : File.join(ENV['HOME'], '.bx', 'state.lock')
      @db = nil
      @lock = nil
    end

    def connect!
      # Ensure directory exists
      dir = File.dirname(@db_path)
      FileUtils.mkdir_p(dir) unless File.directory?(dir)

      # Initialize database connection
      @db = SQLite3::Database.new(@db_path)
      @db.results_as_hash = true
      @db.execute('PRAGMA foreign_keys = ON')
      @db.execute('PRAGMA journal_mode = WAL')

      # Load and execute schema
      schema_path = File.join(File.dirname(__FILE__), '..', '..', 'config', 'schema.sql')
      if File.exist?(schema_path)
        schema = IO.binread(schema_path)
        @db.execute_batch(schema)
      else
        raise "Schema file not found: #{schema_path}"
      end

      # Initialize lock
      @lock = Lockfile.new(@lock_path, retries: 5, timeout: 5)

      @db
    end

    def with_lock(&block)
      raise "Database not connected. Call connect! first." unless @db
      raise "Lock not initialized. Call connect! first." unless @lock

      @lock.lock do
        block.call(@db)
      end
    rescue Lockfile::TimeoutError
      raise "Could not acquire state lock (another bx command running?)"
    end

    def query(sql, *params)
      raise "Database not connected. Call connect! first." unless @db
      @db.execute(sql, params)
    end

    def query_one(sql, *params)
      result = query(sql, *params)
      result.first
    end

    def close
      @db.close if @db
      @db = nil
    end

    # Verify tmux is installed and accessible
    def self.verify_tmux!
      unless system('which tmux > /dev/null 2>&1')
        raise "tmux not found in PATH. Please install tmux first."
      end

      # Check tmux version
      version_output = `tmux -V`.strip
      unless version_output =~ /tmux (\d+)\.(\d+)/
        raise "Could not determine tmux version: #{version_output}"
      end

      major, minor = $1.to_i, $2.to_i
      if major < 3
        warn "Warning: tmux #{major}.#{minor} detected. bx requires tmux 3.0+. Some features may not work correctly."
      end

      true
    end
  end
end
