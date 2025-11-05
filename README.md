# bx

> **Philosophy**: Ultra Unix. Zero bloat. Vim-level efficiency.
> **Status**: Design Phase

## TL;DR

A tmux session manager with a "box of boxes" paradigm for organizing development environments. Combines process management, environment orchestration, and hierarchical organization. Think: workflowy meets tmux meets pm2, written in Ruby, CLI-first.

---

## The Problem

You have multiple projects. Each needs:
- Multiple processes running (server, tests, watcher, editor)
- Specific environment variables loaded
- Consistent naming and organization
- The ability to stop/start reliably
- Cross-machine access (local, ssh, mosh)
- Persistent history of what ran where

Current tools (tmuxinator, sesh, pm2) solve parts of this. None solve it all. None are simple enough to replace your desktop.

---

## Core Concept: "Box of Boxes"

A **box** is:
- **State**: Environment variables, files, database state
- **Behavior**: Code/scripts to execute
- **Purpose**: A useful thing happening (server running, editor open, AI agent working)

Boxes are **hierarchical**:

```
Desktop (root box)
├── Project A (box)
│   ├── Server (sub-box: ./script/server)
│   ├── Tests (sub-box: ./script/test)
│   └── Editor (sub-box: $EDITOR ./src/server.py)
├── Project B (box)
│   ├── API (sub-box)
│   ├── Worker (sub-box)
│   └── Logs (sub-box: temporary)
└── Research (box)
    └── Claude session (sub-box: long-running AI experiment)
```

Each level is a tmux session or window. One window per process (no splits). Home row navigation. Ultra clean.

---

## Key Features

### 1. Directory-Based Auto-Discovery

```bash
# Your projects
~/projects/
├── api/              # bx figures out how to run this
├── frontend/         # Has package.json? Run npm dev
├── research/config.rb    # Explicit config
└── worker/config.yml     # YAML config
```

**Auto-detection** (pattern-based):
- Detects `package.json` → runs `npm run dev`
- Detects `Gemfile` + `./script/server` → runs `bundle exec ./script/server`
- Detects `Procfile` → runs foreman
- Detects `docker-compose.yml` → offers to run compose
- Falls back to config files when present

### 2. Process Management (PM2-style)

- **Start/Stop/Restart**: Keep processes running
- **Auto-restart**: Like pm2, ensures uptime
- **Log management**: Centralized, tailable, searchable
- **Status monitoring**: "How are you doing? Done yet?"

### 3. Environment Trees

```bash
# Load environment from dotenvx or .env
# All child boxes inherit parent environment
# Support environment "trees" - nested contexts

Project A (env: RAILS_ENV=development)
  └── Background Job (inherits RAILS_ENV + adds JOB_QUEUE=high)
```

### 4. Sub-Boxes (Novel Concept)

**Temporary or permanent sub-contexts:**

```bash
# From Project A, kick off a temporary analysis
$ trex sub "analyze logs" -- tail -f logs/production.log | grep ERROR

# Creates temporary sub-box:
# - Inherits Project A's environment
# - Runs the command
# - Re-attachable (can detach/reattach)
# - Supports Ctrl-C properly
# - Appears in box tree
```

**Use case**: Users or AI agents can spawn sub-boxes for long-running tasks, then reattach to check progress.

### 5. Inter-Box Communication

```bash
# From Box A, message Box B
$ trex send project-b "restart server"
$ trex ask project-b "status?"
$ trex broadcast "deploying - pause work"
```

**Implementation**: Unix philosophy - files, named pipes, or sqlite pub/sub.

### 6. Cross-Machine Support

- **SSH/Mosh sessions**: Nested boxes work transparently
- **Cross-machine clipboard**: Copy in local box, paste in remote box
- **Unified navigation**: Same keybindings everywhere
- **State sync** (optional): Turso cloud sync for history/config

### 7. Durable History

Track everything:
- Commands run
- When they ran
- Which machine
- Which box
- Exit codes
- Duration
- Logs

Store in SQLite (local) or Turso (cloud-synced). Query your entire dev history:

```bash
$ trex history --project api --last-week --failed
$ trex replay session-id-12345
```

### 8. WorkFlowy-Style Organization

- **Zoom in/out**: Focus on one box, hide everything else
- **Hierarchical thinking**: Outliner for processes, not just notes
- **Abstract enough**: Supports research, writing, coding, project management
- **Replace desktop**: Everything is a box. Your entire workspace is the tree.

---

## Philosophy & Design Principles

### Unix Philosophy

1. **Text in, text out**: stdin/args → stdout, errors → stderr
2. **Composable**: Boxes can message each other
3. **Files as interface**: Config is files. State is SQLite (which is a file).
4. **Do one thing well**: Manage sessions/processes. Nothing else.

### Simplicity First

- **Home row keybindings**: Never leave home row
- **Zero bloat**: No fancy TUI unless necessary. Pure tmux when possible.
- **Discoverable**: `trex` with no args shows tree. `trex help` shows everything.
- **Sensible defaults**: Works out of the box, customizable via files.

### AI-First + CLI-First

- **AI figures things out**: Auto-detection of how to run projects
- **CLI for humans**: Simple, intuitive commands
- **File-based config**: `$name.yml` or `.$name/config.yml,db.sqlite`
- **Git-friendly**: Check configs into version control

### Ruby-Focused

See `./ai/CODE.md` for detailed patterns:
- Use `fattr`, `map` gems for core functionality
- Binary I/O, `test()` for file checks
- Simple beats clever
- Direct, honest communication in output

---

## Technical Architecture (Proposed)

```
┌─────────────────────────────────────────────────────────────┐
│                          bx CLI                              │
│  (Ruby gem, installed globally: `gem install bx`)            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Core Components                         │
├─────────────────────────────────────────────────────────────┤
│  • Box Manager        - Create/destroy/navigate boxes       │
│  • Process Manager    - Start/stop/monitor processes        │
│  • Config Loader      - Read .yml/.rb configs, auto-detect  │
│  • Env Manager        - Load dotenvx/.env, build env trees  │
│  • Tmux Wrapper       - Drive tmux sessions/windows         │
│  • State Manager      - SQLite/Turso for state/history      │
│  • Message Bus        - Inter-box communication (pub/sub)   │
│  • Clipboard Manager  - Cross-machine copy/paste            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Storage Layer                             │
├─────────────────────────────────────────────────────────────┤
│  • ~/.trex/master.db     - Global state (all boxes)         │
│  • ./.trex/project.db    - Per-project state (optional)     │
│  • ~/.trex/config/       - Global config                    │
│  • ./trex.yml            - Project config (git-friendly)    │
│  • ~/.trex/logs/         - Centralized logs                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Tmux Layer                              │
│  (Foundation - bx orchestrates, doesn't replace)             │
└─────────────────────────────────────────────────────────────┘
```

### Data Model (SQLite Schema)

```sql
-- Master DB: ~/.trex/master.db
CREATE TABLE boxes (
  id INTEGER PRIMARY KEY,
  name TEXT UNIQUE,
  path TEXT,           -- Directory location
  parent_id INTEGER,   -- For hierarchy
  machine TEXT,        -- Hostname
  created_at INTEGER,
  last_active INTEGER,
  state TEXT,          -- running, stopped, failed
  config_hash TEXT     -- Detect config changes
);

CREATE TABLE processes (
  id INTEGER PRIMARY KEY,
  box_id INTEGER,
  command TEXT,
  pid INTEGER,
  tmux_window TEXT,    -- session:window.pane
  started_at INTEGER,
  stopped_at INTEGER,
  exit_code INTEGER,
  restart_count INTEGER
);

CREATE TABLE history (
  id INTEGER PRIMARY KEY,
  box_id INTEGER,
  command TEXT,
  output TEXT,         -- Last N lines
  started_at INTEGER,
  duration_ms INTEGER,
  exit_code INTEGER,
  machine TEXT
);

CREATE TABLE messages (
  id INTEGER PRIMARY KEY,
  from_box INTEGER,
  to_box INTEGER,
  message TEXT,
  sent_at INTEGER,
  read INTEGER DEFAULT 0
);

CREATE TABLE env_vars (
  id INTEGER PRIMARY KEY,
  box_id INTEGER,
  key TEXT,
  value TEXT,
  source TEXT          -- dotenvx, .env, parent, config
);
```

### Technology Stack

| Component | Technology | Why |
|-----------|-----------|-----|
| **Language** | Ruby 3.x | See ./ai/CODE.md - simple, expressive, perfect for this |
| **Database** | SQLite + Turso (optional) | Local-first, cloud-optional, SQL is perfect for queries |
| **Tmux** | Latest stable | Foundation - don't replace, orchestrate |
| **Environment** | dotenvx | Modern .env with encryption support |
| **Config** | YAML + Ruby DSL | YAML for simple, Ruby for complex |
| **CLI** | main gem | See ./ai/CODE.md - your CLI pattern |
| **Dependencies** | Minimal | fattr, map, lockfile, parallel (your usual stack) |

### Ruby Gems (Proposed)

```ruby
# Core
gem 'fattr'          # Class-level attributes
gem 'map'            # Better hashes
gem 'main'           # CLI framework
gem 'lockfile'       # File locking for state

# Tmux interaction
gem 'tmuxinator'     # Optional: parse existing configs
# OR write our own tmux wrapper (simpler)

# Environment
gem 'dotenv'         # .env loading
# OR shell out to dotenvx

# Database
gem 'sqlite3'        # Local state
gem 'turso'          # Cloud sync (optional)

# Process management
# No gem - use Process.spawn, IO.popen4 patterns from open4

# Testing
gem 'testy'          # Your 78-line test framework
```

---

## Configuration Examples

### Auto-Detected Project (No Config)

```bash
# Directory: ~/projects/rails-api
# Contains: Gemfile, ./script/server

$ cd ~/projects/rails-api
$ trex start

# bx auto-detects:
# - Rails project (Gemfile present)
# - Has ./script/server → runs it
# - Creates box "rails-api" with one window
```

### Simple YAML Config

```yaml
# ~/projects/myapp/trex.yml
name: myapp
windows:
  - name: server
    command: ./script/server
    env:
      RAILS_ENV: development

  - name: worker
    command: bundle exec sidekiq
    env:
      REDIS_URL: redis://localhost:6379

  - name: editor
    command: $EDITOR .
```

### Ruby DSL Config (Advanced)

```ruby
# ~/projects/complex/trex.rb
TRex.box do |box|
  box.name = 'complex'
  box.path = __dir__

  # Load env from multiple sources
  box.env.load '.env'
  box.env.load '.env.local' if test(?e, '.env.local')
  box.env['CUSTOM'] = 'value'

  # Define windows
  box.window 'api' do
    command './script/server'
    restart_on_failure true
    max_restarts 3
  end

  box.window 'worker' do
    command 'bundle exec sidekiq'
    depends_on 'api'  # Start after API is up
  end

  # Conditional windows
  if ENV['DEVELOPMENT']
    box.window 'logs' do
      command 'tail -f log/development.log'
      temporary true
    end
  end

  # Lifecycle hooks
  box.on :start do
    puts "Starting #{box.name}..."
    system 'bundle install --quiet'
  end

  box.on :stop do
    puts "Stopping #{box.name}..."
  end
end
```

---

## CLI Interface (Proposed)

```bash
# Start/manage boxes
trex start [box-name]              # Start box (auto-detect or config)
trex stop [box-name]               # Stop box
trex restart [box-name]            # Restart box
trex status [box-name]             # Show status
trex tree                          # Show all boxes (hierarchical)

# Navigation
trex attach [box-name]             # Attach to box's tmux session
trex attach [box-name] [window]    # Attach to specific window
trex ls                            # List all boxes
trex ps                            # List all processes

# Sub-boxes
trex sub "name" -- command         # Create temporary sub-box
trex sub "name" -c config.yml      # Create sub-box from config
trex unsub [sub-box-name]          # Remove sub-box

# Communication
trex send [box] "message"          # Send message to box
trex ask [box] "query"             # Ask box for response
trex broadcast "message"           # Broadcast to all boxes

# Environment
trex env [box]                     # Show box environment
trex env [box] set KEY=VALUE       # Set env var
trex env [box] load .env.prod      # Load env file

# History
trex history [box]                 # Show command history
trex history --failed              # Show failed commands
trex history --last-week           # Time-based filter
trex replay [session-id]           # Replay a session

# Config
trex init                          # Create trex.yml template
trex validate                      # Validate config
trex config show                   # Show merged config

# Clipboard (cross-machine)
trex copy                          # Copy tmux buffer to clipboard
trex paste                         # Paste from clipboard

# Sync (if Turso enabled)
trex sync push                     # Push state to cloud
trex sync pull                     # Pull state from cloud
trex sync status                   # Show sync status
```

---

## Keybindings (Proposed)

Home row focused, vim-style:

```
# Box navigation
Ctrl-t t       - Show box tree
Ctrl-t h/j/k/l - Navigate boxes (vim directions)
Ctrl-t [1-9]   - Jump to box N

# Window navigation (within box)
Ctrl-t n       - Next window
Ctrl-t p       - Previous window
Ctrl-t c       - Create window
Ctrl-t x       - Close window

# Actions
Ctrl-t r       - Restart current window/box
Ctrl-t s       - Show status
Ctrl-t m       - Send message
Ctrl-t /       - Search/filter

# Copy/paste
Ctrl-t y       - Copy (yank)
Ctrl-t p       - Paste
```

---

## Roadmap

### MVP (v0.1)

- [ ] Basic box management (create, start, stop, list)
- [ ] Directory-based auto-detection (simple patterns)
- [ ] YAML config support
- [ ] Tmux wrapper (create sessions/windows)
- [ ] Local SQLite state
- [ ] Basic CLI commands (start, stop, attach, tree)
- [ ] Environment loading (.env support)

### v0.2

- [ ] Process monitoring and auto-restart
- [ ] Ruby DSL config support
- [ ] Sub-box creation
- [ ] Log management
- [ ] History tracking

### v0.3

- [ ] Inter-box messaging
- [ ] Advanced auto-detection (pattern-based)
- [ ] Cross-machine clipboard
- [ ] Keybinding system

### v1.0

- [ ] Turso cloud sync (optional)
- [ ] Full history querying
- [ ] Session replay
- [ ] Production ready

### Future

- [ ] AI agent integration (Claude sub-box spawning)
- [ ] Advanced monitoring/dashboards
- [ ] Plugin system
- [ ] Desktop replacement mode

---

## Open Questions

1. **Name**: Settled on "bx" - ultra-minimal, follows modern CLI tool patterns.
2. **Scope**: Start with MVP or build more upfront?
3. **Cloud dependency**: Turso as v1 feature or optional from start?
4. **Auto-detection**: How smart in MVP? Pattern matching or actual AI?
5. **Inter-box protocol**: Files, named pipes, SQLite pub/sub, or HTTP?
6. **UI**: Pure tmux orchestration or custom TUI overlay?

---

## Similar Tools (Comparison)

| Tool | What it does | What it misses |
|------|--------------|----------------|
| **tmuxinator** | Config-based tmux sessions | No process mgmt, no auto-detect, no hierarchy |
| **sesh** | Smart session switching with zoxide | No process mgmt, no state tracking |
| **pm2** | Process manager with monitoring | Not terminal-based, Node.js focused, no hierarchy |
| **workflowy** | Hierarchical outliner | Not for processes/terminals |
| **i3/tmux** | Window/session management | No process lifecycle, no auto-detection |

**bx** = All of the above, unified, Unix-style, Ruby-powered.

---

## Getting Started (Future)

```bash
# Install
gem install trex

# Initialize
cd ~/projects/myapp
trex init

# Edit config
$EDITOR trex.yml

# Start
trex start

# Attach
trex attach

# Navigate with Ctrl-t t (tree view)
```

---

## References

- [tmuxinator](https://github.com/tmuxinator/tmuxinator) - Inspiration for config
- [sesh](https://github.com/joshmedeski/sesh) - Inspiration for smart switching
- [pm2](https://pm2.keymetrics.io/) - Inspiration for process management
- [workflowy](https://workflowy.com/) - Inspiration for hierarchical thinking
- [./ai/CODE.md](./ai/CODE.md) - Ruby patterns and philosophy
- [./ai/WRITING.md](./ai/WRITING.md) - Communication style
- [Constitution](./.specify/memory/constitution.md) - Project principles

---

## License

TBD

---

**Current Status**: Design phase. Seeking feedback on scope, architecture, and name.

**Next Steps**: Answer open questions → Create feature spec → Build MVP → Ship it.
