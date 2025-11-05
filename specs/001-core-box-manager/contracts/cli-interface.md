# CLI Interface Contract: T-Rex MVP

**Date**: 2025-10-29
**Version**: 1.0.0 (MVP)
**Format**: Text-based CLI following Unix conventions

## Overview

T-Rex CLI follows Unix philosophy:
- Commands via argv
- Output to stdout (normal), stderr (errors)
- Exit codes: 0 (success), 1 (error), 2 (usage error)
- Support `--json` flag for machine-readable output
- Support `--help` on all commands

---

## Command: `trex init`

**Purpose**: Initialize a new box from current directory

**Usage**:
```bash
trex init [NAME] [OPTIONS]
```

**Arguments**:
- `NAME` - Box name (optional, defaults to directory name)

**Options**:
- `--path PATH` - Initialize box at specific path (default: current directory)
- `--no-config` - Skip creating config file (use auto-detection only)
- `--json` - Output JSON instead of human-readable text

**Behavior**:
1. Check if path already has a box (error if exists)
2. Create box entry in database
3. Generate default `trex.yml` (unless `--no-config`)
4. Run auto-detection and suggest commands

**Output** (human-readable):
```
Initialized box 'myapp' at /home/user/projects/myapp

Auto-detected:
  - Node.js project (package.json found)
  - Suggested command: npm run dev

Config created at ./trex.yml
Edit configuration and run: trex start
```

**Output** (JSON with `--json`):
```json
{
  "box_id": 1,
  "name": "myapp",
  "path": "/home/user/projects/myapp",
  "config_file": "/home/user/projects/myapp/trex.yml",
  "detected_type": "nodejs",
  "suggested_commands": ["npm run dev"]
}
```

**Exit Codes**:
- `0` - Success
- `1` - Box already exists, path doesn't exist, or permission denied
- `2` - Invalid arguments

---

## Command: `trex start`

**Purpose**: Start a box (create tmux session and launch processes)

**Usage**:
```bash
trex start [BOX_NAME] [OPTIONS]
```

**Arguments**:
- `BOX_NAME` - Name of box to start (optional if in box directory)

**Options**:
- `--attach` - Attach to tmux session after starting
- `--no-attach` - Don't attach (default)
- `--json` - Output JSON

**Behavior**:
1. Resolve box (by name or current directory)
2. Load configuration (YAML or auto-detect)
3. Check if already running (error if running)
4. Create tmux session
5. Create window for each process
6. Launch processes with environment loaded
7. Setup process monitoring hooks
8. Update box state to 'running'

**Output** (human-readable):
```
Starting box 'myapp'...

✓ Created tmux session 'trex-myapp'
✓ Window 'server' started (PID 12345)
✓ Window 'worker' started (PID 12346)

Box 'myapp' is running.

Attach with: trex attach myapp
View status: trex status myapp
```

**Output** (JSON):
```json
{
  "box_id": 1,
  "name": "myapp",
  "state": "running",
  "tmux_session": "trex-myapp",
  "processes": [
    {"window": "server", "pid": 12345, "command": "./script/server"},
    {"window": "worker", "pid": 12346, "command": "bundle exec sidekiq"}
  ],
  "started_at": 1698624000
}
```

**Exit Codes**:
- `0` - Success
- `1` - Box not found, already running, or start failed
- `2` - Invalid arguments

---

## Command: `trex stop`

**Purpose**: Stop a running box (terminate processes and kill tmux session)

**Usage**:
```bash
trex stop [BOX_NAME] [OPTIONS]
```

**Arguments**:
- `BOX_NAME` - Name of box to stop (optional if in box directory)

**Options**:
- `--force` - Force kill if graceful shutdown fails
- `--timeout SECONDS` - Graceful shutdown timeout (default: 10)
- `--json` - Output JSON

**Behavior**:
1. Resolve box
2. Send SIGTERM to all processes
3. Wait up to timeout seconds
4. Send SIGKILL if still running (if `--force`)
5. Kill tmux session
6. Update box state to 'stopped'

**Output** (human-readable):
```
Stopping box 'myapp'...

✓ Stopped process 'server' (PID 12345)
✓ Stopped process 'worker' (PID 12346)
✓ Killed tmux session 'trex-myapp'

Box 'myapp' stopped.
```

**Output** (JSON):
```json
{
  "box_id": 1,
  "name": "myapp",
  "state": "stopped",
  "stopped_processes": [
    {"window": "server", "pid": 12345, "exit_code": 0},
    {"window": "worker", "pid": 12346, "exit_code": 0}
  ],
  "stopped_at": 1698624100
}
```

**Exit Codes**:
- `0` - Success
- `1` - Box not found, not running, or stop failed
- `2` - Invalid arguments

---

## Command: `trex restart`

**Purpose**: Restart a box (stop + start)

**Usage**:
```bash
trex restart [BOX_NAME] [OPTIONS]
```

**Arguments**:
- `BOX_NAME` - Name of box to restart

**Options**:
- `--attach` - Attach after restart
- `--json` - Output JSON

**Behavior**:
- Equivalent to: `trex stop BOX_NAME && trex start BOX_NAME`

**Output**: Combination of stop and start outputs

**Exit Codes**: Same as stop/start

---

## Command: `trex status`

**Purpose**: Show status of one or all boxes

**Usage**:
```bash
trex status [BOX_NAME] [OPTIONS]
```

**Arguments**:
- `BOX_NAME` - Name of specific box (optional, shows all if omitted)

**Options**:
- `--json` - Output JSON

**Behavior**:
1. Query box state from database
2. Check tmux session existence
3. Check process PIDs (alive/dead)
4. Calculate uptime

**Output** (human-readable, single box):
```
Box: myapp
Status: running
Uptime: 2h 15m
Session: trex-myapp

Processes:
  server    running  PID 12345  uptime 2h15m  restarts 0
  worker    running  PID 12346  uptime 2h15m  restarts 0
```

**Output** (human-readable, all boxes):
```
Boxes (3 total, 2 running):

  myapp       running   2h15m   2 processes
  frontend    running   1h30m   1 process
  worker      stopped   -       0 processes
```

**Output** (JSON):
```json
{
  "box_id": 1,
  "name": "myapp",
  "state": "running",
  "uptime_seconds": 8100,
  "tmux_session": "trex-myapp",
  "processes": [
    {
      "window": "server",
      "state": "running",
      "pid": 12345,
      "uptime_seconds": 8100,
      "restart_count": 0
    },
    {
      "window": "worker",
      "state": "running",
      "pid": 12346,
      "uptime_seconds": 8100,
      "restart_count": 0
    }
  ]
}
```

**Exit Codes**:
- `0` - Success
- `1` - Box not found
- `2` - Invalid arguments

---

## Command: `trex tree`

**Purpose**: Display hierarchical tree of all boxes

**Usage**:
```bash
trex tree [OPTIONS]
```

**Options**:
- `--json` - Output JSON
- `--running` - Show only running boxes
- `--stopped` - Show only stopped boxes

**Behavior**:
1. Query all boxes from database
2. Build parent-child tree
3. Display with tree characters

**Output** (human-readable):
```
Boxes (5 total)

├── api (running, 3 processes)
│   ├── logs (running, 1 process)
│   └── debug (stopped)
├── frontend (running, 2 processes)
└── worker (stopped)
```

**Output** (JSON):
```json
{
  "boxes": [
    {
      "id": 1,
      "name": "api",
      "state": "running",
      "process_count": 3,
      "children": [
        {"id": 2, "name": "logs", "state": "running", "process_count": 1, "children": []},
        {"id": 3, "name": "debug", "state": "stopped", "process_count": 0, "children": []}
      ]
    },
    {
      "id": 4,
      "name": "frontend",
      "state": "running",
      "process_count": 2,
      "children": []
    },
    {
      "id": 5,
      "name": "worker",
      "state": "stopped",
      "process_count": 0,
      "children": []
    }
  ]
}
```

**Exit Codes**:
- `0` - Success

---

## Command: `trex attach`

**Purpose**: Attach to a box's tmux session

**Usage**:
```bash
trex attach [BOX_NAME] [WINDOW_NAME]
```

**Arguments**:
- `BOX_NAME` - Name of box (required)
- `WINDOW_NAME` - Specific window to attach to (optional)

**Behavior**:
1. Resolve box and verify running
2. Execute `tmux attach-session -t {session}`
3. If WINDOW_NAME specified, select that window first

**Output**: None (hands control to tmux)

**Exit Codes**:
- `0` - Success (after detaching from tmux)
- `1` - Box not found or not running

---

## Command: `trex sub`

**Purpose**: Create a sub-box within current box

**Usage**:
```bash
trex sub NAME -- COMMAND [OPTIONS]
```

**Arguments**:
- `NAME` - Sub-box name
- `COMMAND` - Command to run (after `--`)

**Options**:
- `--temporary` - Auto-delete when process completes (default)
- `--permanent` - Keep sub-box after process completes
- `--parent BOX` - Explicit parent box (default: current box)

**Behavior**:
1. Resolve parent box
2. Create sub-box with parent_id set
3. Inherit parent environment
4. Create tmux window in parent session
5. Launch command

**Output**:
```
Created sub-box 'analyze-logs' under 'api'

Window: trex-api:3 (analyze-logs)
PID: 12347
Temporary: yes (will auto-delete on exit)

Attach with: trex attach api analyze-logs
```

**Exit Codes**:
- `0` - Success
- `1` - Parent box not found or not running
- `2` - Invalid arguments

---

## Command: `trex delete`

**Purpose**: Delete a box and all its state

**Usage**:
```bash
trex delete BOX_NAME [OPTIONS]
```

**Arguments**:
- `BOX_NAME` - Name of box to delete

**Options**:
- `--force` - Skip confirmation prompt
- `--keep-logs` - Don't delete log files
- `--json` - Output JSON

**Behavior**:
1. Stop box if running
2. Prompt for confirmation (unless `--force`)
3. Delete box from database (cascades to processes, env vars, history)
4. Delete log files (unless `--keep-logs`)
5. Delete config file if exists

**Output**:
```
Warning: This will delete box 'myapp' and all its data.
  - 2 processes
  - 3 environment variables
  - 1,234 history entries
  - Log files (~50MB)

Continue? [y/N]: y

Deleted box 'myapp'.
```

**Exit Codes**:
- `0` - Success
- `1` - Box not found or deletion failed
- `2` - User cancelled

---

## Command: `trex env`

**Purpose**: Manage environment variables for a box

**Usage**:
```bash
trex env BOX_NAME [SUBCOMMAND]
```

**Subcommands**:
- `trex env BOX_NAME` - Show all env vars
- `trex env BOX_NAME set KEY=VALUE` - Set env var
- `trex env BOX_NAME unset KEY` - Remove env var
- `trex env BOX_NAME load FILE` - Load vars from file

**Output** (show):
```
Environment for 'myapp' (5 variables):

  RAILS_ENV=development (source: file)
  DATABASE_URL=postgres://... (source: file)
  REDIS_URL=redis://localhost (source: explicit)
  PATH=/usr/local/bin:... (source: parent)
  HOME=/home/user (source: default)
```

**Exit Codes**:
- `0` - Success
- `1` - Box not found or operation failed
- `2` - Invalid arguments

---

## Command: `trex history`

**Purpose**: Query command history

**Usage**:
```bash
trex history [BOX_NAME] [OPTIONS]
```

**Arguments**:
- `BOX_NAME` - Filter by box (optional)

**Options**:
- `--failed` - Show only failed commands (exit code != 0)
- `--last-week` - Show commands from last 7 days
- `--last-day` - Show commands from last 24 hours
- `--limit N` - Limit results (default: 50)
- `--json` - Output JSON

**Output**:
```
Command history (last 50 entries):

2025-10-29 14:23:15  myapp     ./script/server        exit 0   2m15s
2025-10-29 14:20:00  myapp     bundle exec sidekiq    exit 1   5s
2025-10-29 14:15:30  frontend  npm run dev            exit 0   10m30s
```

**Exit Codes**:
- `0` - Success
- `1` - Query failed
- `2` - Invalid arguments

---

## Command: `trex logs`

**Purpose**: Show or tail process logs

**Usage**:
```bash
trex logs BOX_NAME [WINDOW_NAME] [OPTIONS]
```

**Arguments**:
- `BOX_NAME` - Box name
- `WINDOW_NAME` - Window/process name (optional, shows all if omitted)

**Options**:
- `--follow` - Tail logs (like `tail -f`)
- `--lines N` - Show last N lines (default: 50)
- `--errors` - Show stderr only

**Output**: Log file contents

**Exit Codes**:
- `0` - Success
- `1` - Box or window not found

---

## Command: `trex config`

**Purpose**: View or validate box configuration

**Usage**:
```bash
trex config [BOX_NAME] [SUBCOMMAND]
```

**Subcommands**:
- `trex config BOX_NAME show` - Display config
- `trex config BOX_NAME validate` - Validate config file
- `trex config BOX_NAME edit` - Open config in $EDITOR

**Output** (show):
```yaml
name: myapp
windows:
  - name: server
    command: ./script/server
    restart: true
    max_restarts: 3
```

**Exit Codes**:
- `0` - Success (validation passed)
- `1` - Box not found or validation failed
- `2` - Invalid arguments

---

## Global Options

All commands support:
- `--help` - Show command help
- `--version` - Show T-Rex version
- `--json` - JSON output (where applicable)
- `--verbose` - Verbose output (debugging)
- `--quiet` - Suppress non-error output

---

## Exit Code Summary

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Runtime error (box not found, operation failed, etc.) |
| 2 | Usage error (invalid arguments, missing required args) |

---

## JSON Output Format

All commands with `--json` follow this structure:
```json
{
  "success": true,
  "data": { /* command-specific data */ },
  "error": null
}
```

Or on error:
```json
{
  "success": false,
  "data": null,
  "error": {
    "message": "Box 'myapp' not found",
    "code": "BOX_NOT_FOUND"
  }
}
```

---

## Contract Tests

CLI contract tests verify:
1. All commands accept `--help` and `--json`
2. Exit codes match specification
3. JSON output is valid and matches schema
4. Human-readable output is properly formatted
5. Error messages are clear and actionable
6. Commands work from any directory (when box name provided)
7. Commands work from box directory (without explicit name)
