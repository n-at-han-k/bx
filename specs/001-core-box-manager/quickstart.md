# Quickstart Guide: bx MVP

**Target Audience**: Developers implementing the bx CLI tool
**Prerequisites**: Ruby 3.1+, tmux installed, basic understanding of tmux and process management
**Estimated Time**: 30 minutes to set up development environment and run first tests

---

## 1. Repository Setup (5 minutes)

### Clone and Setup

```bash
cd ~/projects/bx
bundle install
```

### Symlink tc for Dogfooding

```bash
# Create symlink to tc project for rapid co-evolution
mkdir -p vendor
ln -s ~/gh/ahoward/tc vendor/tc
```

**Why symlink?** Changes to tc are instantly available to T-Rex tests. Both projects evolve together during development.

### Verify tmux

```bash
tmux -V  # Should show tmux 3.x or higher
```

### Create Test Database

```bash
mkdir -p ~/.bx-dev
export BX_STATE_DIR=~/.bx-dev
```

---

## 2. Database Schema (10 minutes)

### Create Schema File

See `config/schema.sql` for complete schema. Key tables:
- `boxes` - Box entities with hierarchy (parent_id)
- `processes` - Running processes per box
- `env_vars` - Environment variables with source tracking
- `history` - Command execution history
- `messages` - Inter-box communication

### Initialize Development Database

```ruby
# In lib/bx/state_manager.rb
def initialize_database
  db_path = "#{ENV['TREX_STATE_DIR'] || "#{ENV['HOME']}/.trex"}/master.db"
  FileUtils.mkdir_p(File.dirname(db_path))

  db = SQLite3::Database.new(db_path)
  db.results_as_hash = true
  db.execute("PRAGMA journal_mode=WAL")  # Enable concurrent reads

  schema_sql = IO.binread("#{__dir__}/../../config/schema.sql")
  db.execute_batch(schema_sql)

  db
end
```

---

## 3. Core Components (15 minutes)

### Module Structure

```ruby
# lib/bx.rb
module BX
  VERSION = '0.1.0' unless defined? BX::VERSION

  def BX.version
    BX::VERSION
  end

  def BX.libdir(*args, &block)
    @libdir ||= File.expand_path(__FILE__).sub(/\.rb$/,'')
    args.empty? ? @libdir : File.join(@libdir, *args)
  ensure
    if block
      begin
        $LOAD_PATH.unshift(@libdir)
        block.call()
      ensure
        $LOAD_PATH.shift()
      end
    end
  end

  def BX.load(*libs)
    libs = libs.join(' ').scan(/[^\s+]+/)
    BX.libdir{ libs.each{|lib| Kernel.load(lib) } }
  end
end

# Load dependencies
require 'sqlite3'
require 'map'
require 'fattr'
require 'lockfile'
require 'dotenv'

# Load library components
BX.load %w[
  trex/state_manager.rb
  trex/box.rb
  trex/process.rb
  trex/environment.rb
  trex/detector.rb
  trex/tmux_wrapper.rb
  trex/history.rb
  trex/cli.rb
]
```

### Box Entity

```ruby
# lib/bx/box.rb
module BX
  class Box
    Fattr(:state_manager){ BX::StateManager.instance }

    attr_reader :id, :name, :path, :parent_id, :state

    def initialize(attributes)
      @id = attributes[:id]
      @name = attributes[:name]
      @path = attributes[:path]
      @parent_id = attributes[:parent_id]
      @state = attributes[:state] || 'stopped'
    end

    def self.create(name:, path:, parent_id: nil)
      # Insert into database, return Box instance
      # See data-model.md for validation rules
    end

    def start
      # 1. Load configuration (YAML or auto-detect)
      # 2. Create tmux session
      # 3. Create windows for each process
      # 4. Launch processes with environment
      # 5. Update state to 'running'
    end

    def stop
      # 1. Send SIGTERM to all processes
      # 2. Wait for graceful shutdown
      # 3. Kill tmux session
      # 4. Update state to 'stopped'
    end

    def status
      # Query process states, calculate uptime
    end
  end
end
```

### Tmux Wrapper

```ruby
# lib/bx/tmux_wrapper.rb
module BX
  module TmuxWrapper
    def self.create_session(name)
      system("tmux new-session -d -s #{name}")
      $?.success?
    end

    def self.create_window(session, window_name, command, env = {})
      target = "#{session}:#{window_name}"

      # Create window
      system("tmux new-window -t #{session} -n #{window_name}")

      # Set environment variables
      env.each do |key, value|
        system("tmux setenv -t #{target} #{key} '#{value}'")
      end

      # Send command
      system("tmux send-keys -t #{target} '#{command}' C-m")

      # Get PID
      pid = `tmux display-message -t #{target} -p '#{pane_pid}'`.strip.to_i
      pid
    end

    def self.kill_session(name)
      system("tmux kill-session -t #{name}")
    end

    def self.list_sessions
      `tmux list-sessions -F '#{session_name}'`.split("\n")
    end

    def self.session_exists?(name)
      list_sessions.include?(name)
    end
  end
end
```

---

## 4. Auto-Detection (Pattern Matching)

```ruby
# lib/bx/detector.rb
module BX
  class Detector
    def self.detect_commands(path)
      return load_config(path) if test(?e, "#{path}/trex.yml")
      return parse_procfile(path) if test(?e, "#{path}/Procfile")
      return detect_nodejs(path) if test(?e, "#{path}/package.json")
      return detect_ruby(path) if test(?e, "#{path}/Gemfile")
      return detect_docker(path) if test(?e, "#{path}/docker-compose.yml")

      nil  # No pattern matched
    end

    private

    def self.detect_nodejs(path)
      package_json = JSON.parse(IO.binread("#{path}/package.json"))
      scripts = package_json['scripts'] || {}

      # Prefer dev > start > serve
      command = scripts['dev'] || scripts['start'] || scripts['serve']
      return nil unless command

      [{name: 'server', command: "npm run #{scripts.key(command)}"}]
    end

    def self.detect_ruby(path)
      commands = []

      # Look for script/server
      if test(?e, "#{path}/script/server")
        commands << {name: 'server', command: 'bundle exec ./script/server'}
      end

      # Look for script/console (optional window)
      if test(?e, "#{path}/script/console")
        commands << {name: 'console', command: 'bundle exec ./script/console'}
      end

      commands.empty? ? nil : commands
    end

    def self.parse_procfile(path)
      procfile_content = IO.binread("#{path}/Procfile")
      procfile_content.lines.map do |line|
        next if line.strip.empty? || line.start_with?('#')

        name, command = line.split(':', 2)
        {name: name.strip, command: command.strip}
      end.compact
    end
  end
end
```

---

## 5. CLI Implementation (main gem)

```ruby
# lib/bx/cli.rb
require 'main'

Main {
  description 'T-Rex - Tmux session manager with box-of-boxes paradigm'

  mode(:init) {
    description 'Initialize a new box'

    argument('name'){
      optional
      description 'Box name (defaults to directory name)'
    }

    option('path'){
      argument_optional
      description 'Path to project directory'
      default '.'
    }

    def run
      name = params['name'].value || File.basename(Dir.pwd)
      path = File.expand_path(params['path'].value)

      box = BX::Box.create(name: name, path: path)
      puts "Initialized box '#{name}' at #{path}"

      # Auto-detection
      commands = BX::Detector.detect_commands(path)
      if commands
        puts "\nAuto-detected:"
        commands.each do |cmd|
          puts "  - #{cmd[:name]}: #{cmd[:command]}"
        end
      end
    end
  }

  mode(:start) {
    description 'Start a box'

    argument('name'){
      optional
      description 'Box name'
    }

    option('attach'){
      description 'Attach to session after starting'
    }

    def run
      name = params['name'].value || detect_current_box
      box = BX::Box.find_by_name(name)

      abort "Box '#{name}' not found" unless box

      box.start
      puts "Box '#{name}' started"

      if params['attach'].given?
        exec("tmux attach-session -t trex-#{name}")
      end
    end
  }

  mode(:stop) {
    description 'Stop a box'

    argument('name'){
      description 'Box name'
    }

    def run
      name = params['name'].value
      box = BX::Box.find_by_name(name)

      abort "Box '#{name}' not found" unless box

      box.stop
      puts "Box '#{name}' stopped"
    end
  }

  mode(:status) {
    description 'Show box status'

    argument('name'){
      optional
      description 'Box name (shows all if omitted)'
    }

    def run
      name = params['name'].value

      if name
        show_box_status(name)
      else
        show_all_boxes
      end
    end
  }

  # Add more modes: tree, attach, sub, delete, env, history, logs, config...
}
```

---

## 6. Running Tests (with tc framework)

### Integration Test Example

```ruby
# tests/integration/test_box_lifecycle.rb
require_relative '../../vendor/tc/lib/tc'
require_relative '../../lib/bx'

TC.testing 'box lifecycle' do
  before do
    @test_dir = "/tmp/trex-test-#{Process.pid}"
    FileUtils.mkdir_p(@test_dir)
    ENV['TREX_STATE_DIR'] = @test_dir

    # Kill any existing tmux sessions
    system("tmux kill-server 2>/dev/null")
  end

  after do
    system("tmux kill-server 2>/dev/null")
    FileUtils.rm_rf(@test_dir)
  end

  test 'box initialization and start/stop cycle' do |t|
    # Create test project
    project_dir = "#{@test_dir}/myapp"
    FileUtils.mkdir_p(project_dir)
    File.write("#{project_dir}/package.json", '{"scripts":{"dev":"echo hello"}}')

    # Initialize box
    box = BX::Box.create(name: 'myapp', path: project_dir)
    t.assert box.name == 'myapp', "Expected box name to be 'myapp'"
    t.assert box.path == project_dir, "Expected box path to match project dir"

    # Start box
    box.start
    t.assert box.state == 'running', "Expected box state to be 'running'"

    # Verify tmux session exists
    t.assert BX::TmuxWrapper.session_exists?('trex-myapp'),
      "Expected tmux session 'trex-myapp' to exist"

    # Stop box
    box.stop
    t.assert box.state == 'stopped', "Expected box state to be 'stopped'"

    # Verify tmux session killed
    t.assert !BX::TmuxWrapper.session_exists?('trex-myapp'),
      "Expected tmux session to be terminated"
  end
end
```

### Run Tests

```bash
ruby tests/integration/test_box_lifecycle.rb
```

**Note**: tc is symlinked at `vendor/tc -> ~/gh/ahoward/tc` for rapid co-evolution. Changes to tc are instantly available to T-Rex tests. T-Rex is tc's first real-world deployment - dogfooding at its finest!

---

## 7. Development Workflow

### Test-Driven Development (Constitution Requirement)

1. **Write test first** (see example above)
2. **Verify test fails** (RED)
3. **Implement feature**
4. **Verify test passes** (GREEN)
5. **Refactor**

### Running Individual Components

```bash
# Test tmux wrapper
ruby -I lib -r trex/tmux_wrapper -e 'BX::TmuxWrapper.create_session("test")'

# Test detector
ruby -I lib -r trex/detector -e 'p BX::Detector.detect_commands(".")'

# Test CLI
bin/bx init testbox
bin/bx start testbox
bin/bx status testbox
bin/bx stop testbox
```

---

## 8. Common Debugging

### Check State Database

```bash
sqlite3 ~/.trex/master.db "SELECT * FROM boxes;"
sqlite3 ~/.trex/master.db "SELECT * FROM processes;"
```

### Check Tmux Sessions

```bash
tmux list-sessions
tmux list-windows -t trex-myapp
```

### Check Logs

```bash
tail -f ~/.trex/logs/myapp/server.log
```

---

## 9. Next Steps

After quickstart:
1. Implement all CLI modes (see contracts/cli-interface.md)
2. Add process monitoring and auto-restart
3. Implement environment inheritance
4. Add sub-box creation
5. Implement history tracking
6. Write comprehensive integration tests
7. Test with real projects (Node.js, Ruby, Docker)

---

## Reference Files

- **Specification**: `spec.md` - User stories and requirements
- **Research**: `research.md` - Technical decisions
- **Data Model**: `data-model.md` - Database schema and entities
- **CLI Contract**: `contracts/cli-interface.md` - Command interface
- **Constitution**: `.specify/memory/constitution.md` - Coding principles
- **Code Patterns**: `./ai/CODE.md` - Ruby style guide

---

## Troubleshooting

**tmux not found**:
```bash
# Install tmux
brew install tmux        # macOS
sudo apt install tmux    # Ubuntu/Debian
```

**Permission denied on ~/.trex**:
```bash
mkdir -p ~/.trex
chmod 755 ~/.trex
```

**SQLite locked error**:
```bash
# Remove lock file
rm ~/.trex/master.db-wal
rm ~/.trex/master.db-shm
```

**Tests failing with "session exists"**:
```bash
# Kill all tmux sessions before testing
tmux kill-server
```

---

This quickstart gets you from zero to running tests in 30 minutes. Follow test-first development per constitution requirements.
