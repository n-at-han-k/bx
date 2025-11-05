-- bx SQLite Schema
-- Generated: 2025-11-05
-- Version: 0.1.0

-- Enable foreign key constraints
PRAGMA foreign_keys = ON;

-- Enable WAL mode for better concurrency
PRAGMA journal_mode = WAL;

-- ============================================================================
-- TABLE: boxes
-- Purpose: Represents projects/workspaces with hierarchical organization
-- ============================================================================
CREATE TABLE IF NOT EXISTS boxes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE NOT NULL,
  path TEXT NOT NULL,
  parent_id INTEGER,
  machine TEXT NOT NULL DEFAULT 'localhost',
  state TEXT NOT NULL DEFAULT 'stopped',
  config_hash TEXT,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  last_active INTEGER,
  FOREIGN KEY (parent_id) REFERENCES boxes(id) ON DELETE CASCADE,
  CHECK (state IN ('stopped', 'starting', 'running', 'stopping', 'crashed'))
);

CREATE INDEX IF NOT EXISTS idx_boxes_parent ON boxes(parent_id);
CREATE INDEX IF NOT EXISTS idx_boxes_state ON boxes(state);
CREATE INDEX IF NOT EXISTS idx_boxes_machine ON boxes(machine);

-- ============================================================================
-- TABLE: processes
-- Purpose: Represents running commands within boxes (one per tmux window)
-- ============================================================================
CREATE TABLE IF NOT EXISTS processes (
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
  FOREIGN KEY (box_id) REFERENCES boxes(id) ON DELETE CASCADE,
  CHECK (state IN ('stopped', 'starting', 'running', 'crashed'))
);

CREATE INDEX IF NOT EXISTS idx_processes_box ON processes(box_id);
CREATE INDEX IF NOT EXISTS idx_processes_state ON processes(state);

-- ============================================================================
-- TABLE: env_vars
-- Purpose: Environment variables with source tracking and hierarchical inheritance
-- ============================================================================
CREATE TABLE IF NOT EXISTS env_vars (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  box_id INTEGER NOT NULL,
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  source TEXT NOT NULL,
  FOREIGN KEY (box_id) REFERENCES boxes(id) ON DELETE CASCADE,
  UNIQUE(box_id, key),
  CHECK (source IN ('file', 'parent', 'explicit', 'default'))
);

CREATE INDEX IF NOT EXISTS idx_env_box ON env_vars(box_id);

-- ============================================================================
-- TABLE: history
-- Purpose: Command execution records with metadata for audit/debugging
-- ============================================================================
CREATE TABLE IF NOT EXISTS history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  box_id INTEGER NOT NULL,
  command TEXT NOT NULL,
  output TEXT,
  started_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  duration_ms INTEGER,
  exit_code INTEGER,
  machine TEXT NOT NULL DEFAULT 'localhost',
  FOREIGN KEY (box_id) REFERENCES boxes(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_history_box ON history(box_id);
CREATE INDEX IF NOT EXISTS idx_history_started ON history(started_at);
CREATE INDEX IF NOT EXISTS idx_history_exit ON history(exit_code);

-- ============================================================================
-- TABLE: messages
-- Purpose: Inter-box communication for coordination and messaging
-- ============================================================================
CREATE TABLE IF NOT EXISTS messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  from_box INTEGER NOT NULL,
  to_box INTEGER NOT NULL,
  message TEXT NOT NULL,
  sent_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  read INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (from_box) REFERENCES boxes(id) ON DELETE CASCADE,
  FOREIGN KEY (to_box) REFERENCES boxes(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_messages_to ON messages(to_box, read);
