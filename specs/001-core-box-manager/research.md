# Research: Core Box Manager (T-Rex MVP)

**Date**: 2025-10-29
**Phase**: 0 - Research & Technical Decisions
**Status**: Complete

## Overview

This document consolidates technical research and decision-making for the T-Rex MVP. All technical unknowns from the plan have been researched and resolved.

---

## Decision 1: Tmux Interaction Approach

**Question**: How should we interact with tmux - shell commands, Ruby wrapper gem, or native binding?

**Decision**: Direct shell command execution via Ruby's backticks/system/spawn

**Rationale**:
- **Simplicity**: tmux has excellent CLI - no need to wrap it
- **Constitution compliance**: "Simple beats clever" - shell commands are simplest
- **Reliability**: tmux CLI is stable and well-documented
- **Flexibility**: Full tmux feature access without dependency on wrapper gem updates
- **Debugging**: Shell commands are transparent and easy to troubleshoot

**Alternatives considered**:
1. **tmuxinator gem** - Provides Ruby DSL for tmux but adds abstraction layer we don't need. We're building our own orchestration, not using theirs.
2. **Custom C binding** - Massive overkill for MVP. Ruby's shell execution is sufficient.
3. **tmux-ruby gem** - Unmaintained, adds unnecessary dependency.

**Implementation approach**:
```ruby
# Use system() for simple commands
system("tmux new-session -d -s #{session_name}")

# Use backticks for output capture
sessions = `tmux list-sessions -F '#{session_name}'`.split("\n")

# Use spawn + Process.wait for async monitoring
pid = spawn("tmux send-keys -t #{target} '#{command}' C-m")
Process.wait(pid)
```

---

## Decision 2: SQLite Schema Design

**Question**: How to structure SQLite schema for boxes, processes, history while maintaining query performance?

**Decision**: Normalized schema with indexes on frequently queried columns

**Rationale**:
- **Performance**: Indexes on box_id, parent_id, state, created_at support fast tree queries
- **Data integrity**: Foreign keys maintain referential integrity
- **Query patterns**: Optimized for: box tree traversal, process status checks, history filtering
- **Storage efficiency**: Normalized design reduces duplication

**Schema**:
```sql
-- Boxes table
CREATE TABLE boxes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE NOT NULL,
  path TEXT NOT NULL,
  parent_id INTEGER,
  machine TEXT NOT NULL DEFAULT (SELECT hostname FROM (SELECT 1)),
  state TEXT NOT NULL DEFAULT 'stopped',
  config_hash TEXT,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  last_active INTEGER,
  FOREIGN KEY (parent_id) REFERENCES boxes(id) ON DELETE CASCADE
);
CREATE INDEX idx_boxes_parent ON boxes(parent_id);
CREATE INDEX idx_boxes_state ON boxes(state);
CREATE INDEX idx_boxes_machine ON boxes(machine);

-- Processes table
CREATE TABLE processes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  box_id INTEGER NOT NULL,
  command TEXT NOT NULL,
  pid INTEGER,
  tmux_window TEXT,
  state TEXT NOT NULL DEFAULT 'stopped',
  started_at INTEGER,
  stopped_at INTEGER,
  exit_code INTEGER,
  restart_count INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (box_id) REFERENCES boxes(id) ON DELETE CASCADE
);
CREATE INDEX idx_processes_box ON processes(box_id);
CREATE INDEX idx_processes_state ON processes(state);

-- History table
CREATE TABLE history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  box_id INTEGER NOT NULL,
  command TEXT NOT NULL,
  output TEXT,
  started_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  duration_ms INTEGER,
  exit_code INTEGER,
  machine TEXT NOT NULL,
  FOREIGN KEY (box_id) REFERENCES boxes(id) ON DELETE CASCADE
);
CREATE INDEX idx_history_box ON history(box_id);
CREATE INDEX idx_history_started ON history(started_at);
CREATE INDEX idx_history_exit ON history(exit_code);

-- Environment variables table
CREATE TABLE env_vars (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  box_id INTEGER NOT NULL,
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  source TEXT NOT NULL,
  FOREIGN KEY (box_id) REFERENCES boxes(id) ON DELETE CASCADE,
  UNIQUE(box_id, key)
);
CREATE INDEX idx_env_box ON env_vars(box_id);

-- Messages table (for inter-box communication)
CREATE TABLE messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  from_box INTEGER NOT NULL,
  to_box INTEGER NOT NULL,
  message TEXT NOT NULL,
  sent_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  read INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (from_box) REFERENCES boxes(id) ON DELETE CASCADE,
  FOREIGN KEY (to_box) REFERENCES boxes(id) ON DELETE CASCADE
);
CREATE INDEX idx_messages_to ON messages(to_box, read);
```

**Alternatives considered**:
1. **NoSQL/Document store** - Overkill for MVP, adds dependency, less query flexibility
2. **Flat file storage** - Poor query performance, complex locking
3. **In-memory only** - Loses state on restart (violates FR-044)

---

## Decision 3: Auto-Detection Pattern Matching

**Question**: What patterns should we match for auto-detection and in what priority order?

**Decision**: Priority-ordered pattern matching with fallback to config

**Detection order**:
1. **Explicit config** (`trex.yml`, `trex.rb`) - Always highest priority
2. **Procfile** - Multi-process definition, create window per line
3. **package.json** - Check for "dev", "start", "serve" scripts
4. **Gemfile + ./script/*** - Ruby project, look for script/server, script/console
5. **docker-compose.yml** - Offer `docker-compose up`
6. **Prompt user** - No pattern matched, ask what to run

**Rationale**:
- **Explicit over implicit**: User config always wins
- **Multi-process first**: Procfile defines multiple processes explicitly
- **Common patterns**: Node.js and Ruby are most common in target user base
- **Graceful degradation**: Always provide escape hatch (prompt user)

**Pattern matching logic**:
```ruby
def detect_command(project_path)
  return load_config if test(?e, "#{project_path}/trex.yml")
  return parse_procfile if test(?e, "#{project_path}/Procfile")
  return detect_nodejs if test(?e, "#{project_path}/package.json")
  return detect_ruby if test(?e, "#{project_path}/Gemfile")
  return detect_docker if test(?e, "#{project_path}/docker-compose.yml")
  prompt_user_for_command
end
```

**Alternatives considered**:
1. **AI-based detection** - Deferred to v1.0, adds complexity and API dependency
2. **Git repo analysis** - Too slow, adds complexity
3. **File extension scanning** - Ambiguous, less reliable than manifest files

---

## Decision 4: Process Monitoring Strategy

**Question**: How to monitor process state and detect crashes without polling?

**Decision**: Hybrid approach - tmux hooks + periodic health checks

**Rationale**:
- **tmux hooks**: Use `set-hook` to trigger on pane-died events
- **Health checks**: Lightweight periodic scan (every 5s) to verify state consistency
- **Trade-off**: Balance between responsiveness (hooks) and reliability (polling backup)

**Implementation**:
```ruby
# Set tmux hook for crash detection
system("tmux set-hook -t #{session} pane-died 'run-shell \"trex notify-crash #{box_id} #{process_id}\"'")

# Periodic health check (separate background process)
loop do
  sleep 5
  check_all_processes
  restart_crashed_processes
end
```

**Alternatives considered**:
1. **Pure polling** - Simple but slow response time (2-5s delay)
2. **Pure hooks** - Fast but can miss edge cases (tmux restart, manual kills)
3. **Process.wait** - Blocks, doesn't work with detached tmux panes

---

## Decision 5: Environment Variable Inheritance

**Question**: How to implement hierarchical environment inheritance efficiently?

**Decision**: Recursive query with override merging at box start time

**Rationale**:
- **Simplicity**: Build env map once at box start, not on every lookup
- **Performance**: Single recursive query vs. multiple lookups
- **Correctness**: Child overrides parent, no surprising behavior

**Implementation**:
```ruby
def environment_for_box(box_id)
  env = {}

  # Recursive CTE to get all ancestors
  query = <<-SQL
    WITH RECURSIVE ancestors AS (
      SELECT id, parent_id FROM boxes WHERE id = ?
      UNION ALL
      SELECT b.id, b.parent_id FROM boxes b
      JOIN ancestors a ON b.id = a.parent_id
    )
    SELECT key, value, source FROM env_vars
    WHERE box_id IN (SELECT id FROM ancestors)
    ORDER BY box_id ASC  -- Parents first, children override
  SQL

  db.execute(query, box_id).each do |row|
    env[row['key']] = row['value']  # Later values override
  end

  env
end
```

**Alternatives considered**:
1. **Lazy evaluation** - Complex, error-prone, hard to debug
2. **Copy on inherit** - Storage duplication, sync issues
3. **Env var inheritance in tmux** - Limited, doesn't support source tracking

---

## Decision 6: Concurrency and Locking

**Question**: How to handle concurrent CLI invocations safely?

**Decision**: File-based locking with timeout + SQLite WAL mode

**Rationale**:
- **File locking**: Cross-process synchronization via `lockfile` gem
- **WAL mode**: SQLite write-ahead logging allows concurrent reads
- **Timeout**: Prevent deadlocks (5s timeout, fail with clear error)
- **Atomic operations**: Critical state changes wrapped in transactions

**Implementation**:
```ruby
require 'lockfile'

STATE_LOCK = Lockfile.new("#{ENV['HOME']}/.bx/state.lock", retries: 5, timeout: 5)

def with_state_lock(&block)
  STATE_LOCK.lock do
    block.call
  end
rescue Lockfile::TimeoutError
  abort "Error: Could not acquire state lock (another bx command running?)"
end

# Enable WAL mode in SQLite
db.execute("PRAGMA journal_mode=WAL")
```

**Alternatives considered**:
1. **No locking** - Race conditions, corrupted state
2. **SQLite locking only** - Not sufficient for process spawn coordination
3. **Distributed lock** - Overkill for local-only MVP

---

## Decision 7: Log Management

**Question**: Where and how should we store process output logs?

**Decision**: Centralized logs under `~/.bx/logs/` with rotation

**Rationale**:
- **Centralization**: Easy to find all logs in one place
- **Rotation**: Prevent unbounded growth (keep last 100MB per box)
- **Accessibility**: Standard text files, greppable, tail-able
- **Performance**: Async writes, don't block process execution

**Log structure**:
```
~/.bx/logs/
├── {box-name}/
│   ├── {window-name}.log     # Combined stdout/stderr
│   └── {window-name}.err     # Stderr only (for easier filtering)
└── bx.log                     # bx internal logs
```

**Rotation strategy**:
- Max 100MB per box
- Rotate when log file exceeds 10MB
- Keep last 10 rotated files
- Use simple rename + truncate (no fancy log library)

**Alternatives considered**:
1. **Store in SQLite** - Poor performance, bloated database
2. **No logs** - Can't debug issues, violates FR-022
3. **Syslog integration** - Overkill for dev tool

---

## Decision 8: Configuration Format

**Question**: Should we support both YAML and Ruby DSL in MVP?

**Decision**: YAML only in MVP, Ruby DSL deferred to v0.2

**Rationale**:
- **Simplicity**: YAML is sufficient for 90% of use cases
- **Parsing**: Standard library YAML parser, no custom DSL evaluation
- **MVP focus**: Ship faster with one config format
- **Future-proof**: Can add Ruby DSL later without breaking YAML configs

**YAML structure**:
```yaml
name: myapp
windows:
  - name: server
    command: ./script/server
    restart: true
    max_restarts: 3
    env:
      RAILS_ENV: development

  - name: worker
    command: bundle exec sidekiq
    restart: true
    depends_on: server  # Start after server is up

  - name: logs
    command: tail -f log/development.log
    temporary: true
    restart: false
```

**Alternatives considered**:
1. **Ruby DSL only** - More powerful but requires `eval`, security concerns
2. **JSON** - Less human-friendly than YAML
3. **TOML** - Adds dependency, less familiar to Ruby devs

---

## Decision 9: Testing Approach

**Question**: What testing framework and strategy for constitution-mandated integration tests?

**Decision**: Symlink `tc` (minimal BDD test framework) and co-evolve it with T-Rex development - "dogfooding" approach

**Rationale**:
- **Constitution alignment**: "If testy (78 lines of code) can handle it, use that level of simplicity"
- **Symlink approach**: Link tc project directly into `vendor/tc/` for rapid co-evolution
- **Dogfooding**: Adjust tc during development to meet T-Rex testing needs, changes reflect immediately in both projects
- **Integration focus**: Test real tmux interactions, SQLite persistence, CLI commands
- **No mocks**: Test against real tmux, real SQLite file
- **First use "in anger"**: T-Rex is tc's initial production deployment
- **Rapid iteration**: Changes to tc are instantly available to T-Rex tests without copying

**Symlink strategy**:
```
vendor/
└── tc -> ~/gh/ahoward/tc    # Symlink to tc project for rapid co-evolution
```

**Setup**:
```bash
cd vendor
ln -s ~/gh/ahoward/tc tc
```

**Test structure** (tc API):
```ruby
require_relative '../vendor/tc/lib/tc'

TC.testing 'box lifecycle' do
  test 'init creates config file' do |t|
    test_dir = "/tmp/trex-test-#{Process.pid}"
    FileUtils.mkdir_p(test_dir)

    system("cd #{test_dir} && trex init mybox")

    t.assert test(?e, "#{test_dir}/trex.yml"),
      "Expected trex.yml to be created"

    FileUtils.rm_rf(test_dir)
  end

  test 'box start launches tmux session' do |t|
    system("trex start mybox")
    sessions = `tmux list-sessions -F '#{session_name}'`.split("\n")

    t.assert sessions.include?("trex-mybox"),
      "Expected tmux session to be created"
  end
end
```

**Alternatives considered**:
1. **RSpec** - Too heavy, verbose DSL, constitution says "you wrote testy because RSpec sucked"
2. **Minitest** - Good but not aligned with dogfooding tc
3. **Test::Unit** - Standard library but tc is more constitution-aligned
4. **tc as gem** - Vendoring preferred for co-evolution with T-Rex

---

## Decision 10: Gem Dependencies

**Question**: Confirm exact gem versions and justify each dependency?

**Decision**: Minimal dependencies with version constraints

**Gemspec**:
```ruby
spec.add_dependency 'main', '~> 6.2'           # CLI framework
spec.add_dependency 'sqlite3', '~> 1.6'        # State storage
spec.add_dependency 'fattr', '~> 2.4'          # Class attributes
spec.add_dependency 'map', '~> 6.6'            # Enhanced hashes
spec.add_dependency 'lockfile', '~> 2.1'       # File locking
spec.add_dependency 'dotenv', '~> 2.8'         # Env loading
```

**Justifications**:
- **main**: Constitution-approved pattern from 143 gems
- **sqlite3**: Only local persistence option considered
- **fattr/map**: Constitution-approved, used everywhere in author's code
- **lockfile**: Constitution-approved, needed for state consistency
- **dotenv**: Standard for .env file parsing

**Total**: 6 runtime dependencies (minimal)

**Alternatives considered**:
1. **Thor** instead of main - Not constitution-approved pattern
2. **sequel** for SQLite - Overkill ORM, prefer raw SQL
3. **activesupport** - Massive dependency, constitution says "don't use ActiveSupport monkey patches"

---

## Summary

All technical decisions resolved. No blockers for implementation. Constitution compliance verified for all choices. Ready to proceed to Phase 1 (Design & Contracts).

**Key takeaways**:
- Direct tmux shell commands (simple)
- Normalized SQLite schema with indexes (performant)
- Pattern-based auto-detection (no AI in MVP)
- Hybrid monitoring (hooks + polling)
- YAML-only config (ship faster)
- Simple integration tests (no fancy frameworks)
- 6 minimal dependencies (all justified)
