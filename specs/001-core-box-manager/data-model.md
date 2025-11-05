# Data Model: Core Box Manager (T-Rex MVP)

**Date**: 2025-10-29
**Phase**: 1 - Design & Contracts
**Status**: Complete

## Overview

This document defines the data model for T-Rex, including entities, relationships, validation rules, and state transitions. Based on the "Key Entities" section from spec.md and research decisions.

---

## Entity: Box

**Purpose**: Represents a project or workspace with multiple processes/windows

###Fields

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY, AUTO | Unique box identifier |
| `name` | TEXT | UNIQUE, NOT NULL | Human-readable box name (e.g., "api", "frontend") |
| `path` | TEXT | NOT NULL | Absolute path to project directory |
| `parent_id` | INTEGER | FOREIGN KEY → boxes(id), NULL for root | Parent box for sub-boxes (NULL for top-level) |
| `machine` | TEXT | NOT NULL, DEFAULT hostname | Hostname where box runs |
| `state` | TEXT | NOT NULL, DEFAULT 'stopped' | Current state: stopped, starting, running, stopping, crashed |
| `config_hash` | TEXT | NULL | SHA256 of config file (detects changes) |
| `created_at` | INTEGER | NOT NULL, DEFAULT unix_timestamp | Unix timestamp of creation |
| `last_active` | INTEGER | NULL | Unix timestamp of last activity |

### Relationships

- **Parent-Child**: `parent_id` → `boxes(id)` (self-referencing, CASCADE DELETE)
  - Root boxes have `parent_id = NULL`
  - Sub-boxes inherit environment from parents
  - Deleting parent deletes all children

- **Has-Many Processes**: One box contains multiple processes
- **Has-Many Env Vars**: One box has multiple environment variables
- **Has-Many History Entries**: One box accumulates history

### Validation Rules

1. **Name uniqueness**: No two boxes can have the same name (enforced by UNIQUE constraint)
2. **Path exists**: Path must be valid directory at box creation time
3. **Parent validation**: parent_id must reference existing box (or NULL)
4. **State transitions**: Must follow valid state machine (see below)
5. **No circular parentage**: Cannot set parent_id that creates cycle

### State Transitions

```
stopped → starting → running
running → stopping → stopped
running → crashed (on unexpected termination)
crashed → starting (on restart attempt)
*any* → stopped (on user-initiated stop)
```

**State definitions**:
- `stopped`: Box not running, no tmux session exists
- `starting`: Box is launching processes, tmux session being created
- `running`: All processes active, tmux session exists
- `stopping`: Graceful shutdown in progress
- `crashed`: One or more critical processes failed

### Indexes

- `idx_boxes_parent` on `parent_id` (tree traversal queries)
- `idx_boxes_state` on `state` (filter by running/stopped)
- `idx_boxes_machine` on `machine` (multi-machine support in future)

---

## Entity: Process

**Purpose**: Represents a running command within a box (one per tmux window)

### Fields

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY, AUTO | Unique process identifier |
| `box_id` | INTEGER | FOREIGN KEY → boxes(id), NOT NULL | Box this process belongs to |
| `command` | TEXT | NOT NULL | Full command string to execute |
| `pid` | INTEGER | NULL | OS process ID (NULL if not running) |
| `tmux_window` | TEXT | NULL | Tmux target (session:window.pane) |
| `state` | TEXT | NOT NULL, DEFAULT 'stopped' | Current state: stopped, starting, running, crashed |
| `started_at` | INTEGER | NULL | Unix timestamp when process started |
| `stopped_at` | INTEGER | NULL | Unix timestamp when process stopped |
| `exit_code` | INTEGER | NULL | Last exit code (NULL if never ran) |
| `restart_count` | INTEGER | NOT NULL, DEFAULT 0 | Number of auto-restart attempts |

### Relationships

- **Belongs-To Box**: `box_id` → `boxes(id)` (CASCADE DELETE)
- **Has-Many History Entries**: Process execution creates history records

### Validation Rules

1. **Box exists**: box_id must reference existing box
2. **Command non-empty**: command string must have content
3. **State consistency**: If state is 'running', pid and tmux_window must be set
4. **Restart limit**: restart_count should not exceed configured max (default 3)
5. **Timestamps**: started_at must be ≤ stopped_at if both set

### State Transitions

```
stopped → starting → running
running → crashed (on non-zero exit)
crashed → starting (auto-restart, if count < max)
running → stopped (clean exit or user stop)
```

**State definitions**:
- `stopped`: Process not running
- `starting`: Process launching (tmux window being created)
- `running`: Process active with valid PID
- `crashed`: Process exited with non-zero code

### Indexes

- `idx_processes_box` on `box_id` (list all processes for a box)
- `idx_processes_state` on `state` (find crashed processes for restart)

---

## Entity: Environment

**Purpose**: Represents environment variables for a box with source tracking

### Fields

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY, AUTO | Unique env var identifier |
| `box_id` | INTEGER | FOREIGN KEY → boxes(id), NOT NULL | Box this variable belongs to |
| `key` | TEXT | NOT NULL | Environment variable name (e.g., "RAILS_ENV") |
| `value` | TEXT | NOT NULL | Environment variable value |
| `source` | TEXT | NOT NULL | Source: 'file', 'parent', 'explicit', 'default' |

### Relationships

- **Belongs-To Box**: `box_id` → `boxes(id)` (CASCADE DELETE)

### Validation Rules

1. **Unique per box**: (box_id, key) must be unique (UNIQUE constraint)
2. **Key format**: Keys should match env var naming conventions ([A-Z_][A-Z0-9_]*)
3. **Source values**: Must be one of: 'file', 'parent', 'explicit', 'default'

### Inheritance Logic

Environment variables are resolved hierarchically:
1. Load all ancestor boxes' env vars (recursive query)
2. Apply in order: grandparent → parent → current
3. Child values override parent values with same key
4. Source tracking shows where value came from

**Source definitions**:
- `file`: Loaded from .env file in project directory
- `parent`: Inherited from parent box
- `explicit`: Set via CLI command (trex env set)
- `default`: System defaults (e.g., PATH augmentation)

### Indexes

- `idx_env_box` on `box_id` (get all vars for a box)

---

## Entity: History Entry

**Purpose**: Records all command executions across all boxes for auditing/debugging

### Fields

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY, AUTO | Unique history entry identifier |
| `box_id` | INTEGER | FOREIGN KEY → boxes(id), NOT NULL | Box where command ran |
| `command` | TEXT | NOT NULL | Full command string executed |
| `output` | TEXT | NULL | Last N lines of output (configurable, default 100) |
| `started_at` | INTEGER | NOT NULL, DEFAULT unix_timestamp | Unix timestamp when command started |
| `duration_ms` | INTEGER | NULL | Execution duration in milliseconds |
| `exit_code` | INTEGER | NULL | Command exit code |
| `machine` | TEXT | NOT NULL | Hostname where command executed |

### Relationships

- **Belongs-To Box**: `box_id` → `boxes(id)` (CASCADE DELETE)

### Validation Rules

1. **Box exists**: box_id must reference existing box
2. **Command non-empty**: command string must have content
3. **Duration positive**: duration_ms must be ≥ 0 if set
4. **Output length**: output truncated to prevent bloat (last 100 lines)

### Query Patterns

Common history queries:
```sql
-- All commands for a box
SELECT * FROM history WHERE box_id = ? ORDER BY started_at DESC;

-- Failed commands
SELECT * FROM history WHERE exit_code != 0 ORDER BY started_at DESC;

-- Commands in time range
SELECT * FROM history
WHERE started_at BETWEEN ? AND ?
ORDER BY started_at DESC;

-- Longest-running commands
SELECT * FROM history
ORDER BY duration_ms DESC
LIMIT 10;
```

### Indexes

- `idx_history_box` on `box_id` (filter by box)
- `idx_history_started` on `started_at` (time-range queries)
- `idx_history_exit` on `exit_code` (find failures)

---

## Entity: Message

**Purpose**: Enables inter-box communication (send/ask commands)

### Fields

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY, AUTO | Unique message identifier |
| `from_box` | INTEGER | FOREIGN KEY → boxes(id), NOT NULL | Sender box |
| `to_box` | INTEGER | FOREIGN KEY → boxes(id), NOT NULL | Recipient box |
| `message` | TEXT | NOT NULL | Message content |
| `sent_at` | INTEGER | NOT NULL, DEFAULT unix_timestamp | Unix timestamp when sent |
| `read` | INTEGER | NOT NULL, DEFAULT 0 | Boolean: 0=unread, 1=read |

### Relationships

- **From Box**: `from_box` → `boxes(id)` (CASCADE DELETE)
- **To Box**: `to_box` → `boxes(id)` (CASCADE DELETE)

### Validation Rules

1. **Both boxes exist**: from_box and to_box must reference existing boxes
2. **No self-messaging**: from_box != to_box (enforced in application layer)
3. **Message non-empty**: message content must exist

### Query Patterns

```sql
-- Unread messages for a box
SELECT * FROM messages
WHERE to_box = ? AND read = 0
ORDER BY sent_at ASC;

-- Mark message as read
UPDATE messages SET read = 1 WHERE id = ?;
```

### Indexes

- `idx_messages_to` on `(to_box, read)` (find unread messages efficiently)

---

## Entity: Configuration

**Purpose**: Represents box configuration (not stored in DB, loaded from file)

**Note**: Configuration lives in YAML files (`trex.yml`), not in SQLite. This entity describes the in-memory representation.

### Structure

```ruby
class Configuration
  attr_reader :name, :windows, :env_vars, :hooks

  # windows: Array<WindowConfig>
  #   - name: String
  #   - command: String
  #   - restart: Boolean
  #   - max_restarts: Integer
  #   - temporary: Boolean
  #   - depends_on: String (window name)
  #   - env: Hash<String, String>
  #
  # env_vars: Hash<String, String>
  #
  # hooks: Hash<Symbol, Proc>
  #   - :on_start
  #   - :on_stop
  #   - :on_restart
end
```

### Validation Rules

1. **Name present**: Configuration must have a name
2. **Window names unique**: No duplicate window names
3. **Dependency validity**: depends_on must reference existing window
4. **Command non-empty**: Each window must have a command

### Config Hash

`config_hash` in Box entity is SHA256 of YAML file content:
```ruby
config_hash = Digest::SHA256.hexdigest(IO.binread("#{path}/trex.yml"))
```

Detects when config changes (prompts user to restart box).

---

## Relationships Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         Box                                  │
│  - id, name, path, parent_id, machine, state                │
│  - config_hash, created_at, last_active                     │
└────┬──────────────────┬──────────────────┬─────────────────┘
     │                  │                  │
     │ 1:N              │ 1:N              │ 1:N
     ▼                  ▼                  ▼
┌────────────┐    ┌────────────┐    ┌───────────────┐
│  Process   │    │Environment │    │    History    │
│  - box_id  │    │  - box_id  │    │   - box_id    │
│  - command │    │  - key     │    │   - command   │
│  - pid     │    │  - value   │    │   - exit_code │
│  - state   │    │  - source  │    │   - duration  │
└────────────┘    └────────────┘    └───────────────┘

         Box (self-referencing)
           │
           │ parent_id → id
           ▼
         Box (sub-box)

┌────────────────────────────────────────────────────────────┐
│                        Message                              │
│  - from_box (FK → boxes)                                   │
│  - to_box (FK → boxes)                                     │
│  - message, sent_at, read                                  │
└────────────────────────────────────────────────────────────┘
```

---

## Data Integrity Rules

### Cascade Deletes

- Deleting a box deletes all its: processes, env vars, history, messages (both sent and received)
- Deleting a parent box deletes all sub-boxes recursively

### Concurrent Access

- Use file locking (`~/.trex/state.lock`) for critical sections
- SQLite WAL mode for concurrent reads
- Transactions for multi-table updates

### Data Retention

- History: Keep all entries (user can manually clean)
- Messages: Auto-delete read messages >30 days old (future enhancement)
- Logs: Rotate when >100MB per box

---

## Migration Strategy

### Initial Schema

Create database on first run:
```ruby
if !test(?e, "#{ENV['HOME']}/.trex/master.db")
  create_database_from_schema
end
```

### Schema Versioning

Store schema version in metadata table:
```sql
CREATE TABLE schema_version (
  version INTEGER PRIMARY KEY
);
INSERT INTO schema_version VALUES (1);
```

Check version on startup, run migrations if needed.

### Future Migrations

When schema changes:
1. Increment version
2. Write migration SQL
3. Apply migration with transaction + rollback support

---

## Summary

Data model supports:
- Hierarchical box organization (parent/child)
- Process lifecycle tracking with state machines
- Environment inheritance with source tracking
- Complete command history with filtering
- Inter-box messaging
- Configuration change detection
- Concurrent access via locking
- Data integrity via foreign keys and cascades

All entities map to functional requirements in spec.md. Schema optimized for common query patterns (tree traversal, status checks, history filtering).
