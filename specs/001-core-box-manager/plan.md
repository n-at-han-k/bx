# Implementation Plan: Core Box Manager (bx MVP)

**Branch**: `001-core-box-manager` | **Date**: 2025-10-29 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-core-box-manager/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Build a tmux session manager (bx) implementing the "box of boxes" paradigm for organizing development environments. Core MVP delivers: (1) box lifecycle management (init, start, stop, status), (2) auto-detection of project types (package.json, Gemfile, Procfile, docker-compose), (3) process monitoring with auto-restart, (4) hierarchical environment variable management, (5) sub-box creation for temporary/permanent tasks, (6) command history tracking. Technical approach: Ruby CLI tool using `main` gem, SQLite for state persistence, direct tmux orchestration via shell commands, `dotenv` for environment management, pattern-matching auto-detection (no AI in MVP).

## Technical Context

**Language/Version**: Ruby 3.x (latest stable, 3.1+)
**Primary Dependencies**:
- `main` - CLI framework (constitution-approved pattern)
- `sqlite3` - Local state storage
- `fattr` - Class-level attributes
- `map` - Enhanced hash data structures
- `lockfile` - File-based locking for state
- `dotenv` - Environment variable loading
- tmux (external, user-installed)

**Storage**: SQLite database at `~/.bx/master.db` for boxes, processes, history, messages, env vars
**Testing**: Integration-focused (constitution requirement), symlinked `tc` framework (dogfooding first use)
**Target Platform**: Unix-like systems (Linux, macOS) - tmux dependency
**Project Type**: Single CLI tool (Ruby gem)
**Performance Goals**:
- Box start/stop: <10 seconds for recognized projects
- Tree view rendering: <2 seconds for 100+ boxes
- History queries: <1 second for 10K+ entries
- Process restart detection: <2 seconds

**Constraints**:
- Local-only (no cloud/network in MVP)
- Single-machine operation
- Requires tmux installed in PATH
- ~100MB storage for logs/history
- Home directory read/write access

**Scale/Scope**:
- Support 100+ boxes per user
- 10,000+ history entries
- Multiple processes per box (typically 2-5)
- Auto-detect 5 project types (Node.js, Ruby, Python, Docker, Procfile)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Simple Beats Clever ✓

- **PASS**: Using direct tmux shell commands vs. wrapping library (simpler)
- **PASS**: Pattern-matching auto-detection vs. AI (simpler for MVP)
- **PASS**: SQLite file storage vs. complex database (simpler)
- **PASS**: Composition over inheritance (Box, Process, Environment as separate entities)
- **PASS**: No unnecessary abstraction layers - direct implementation

### II. Libraries Over Frameworks ✓

- **PASS**: CLI tool is self-contained, independently testable
- **PASS**: Text in/out protocol: commands via CLI args, output to stdout, errors to stderr
- **PASS**: Will support JSON output option (`--json` flag) alongside human-readable
- **PASS**: Clear standalone purpose: manage tmux sessions as boxes
- **NOTE**: Using `main` gem for CLI (constitution-approved pattern from 143 gems)

### III. Test-First Development (NON-NEGOTIABLE) ✓

- **COMMIT**: Will follow Red-Green-Refactor cycle
- **COMMIT**: Integration tests for: box lifecycle, auto-detection patterns, process monitoring, environment inheritance, sub-box creation, history tracking
- **COMMIT**: Contract tests for: CLI commands, tmux interaction, SQLite schema
- **COMMIT**: Tests written first, user-approved, verified to fail before implementation

### IV. Natural Representation ✓

- **PASS**: Direct, honest CLI output (no embellishment)
- **PASS**: Status displays actual state (running/stopped/crashed)
- **PASS**: Error messages show real failures, not processed/hidden

### V. Direct Communication ✓

- **PASS**: CLI help text will be direct and to the point
- **PASS**: Error messages honest about limitations
- **PASS**: No buzzwords in output ("orchestrating" → "starting", "leveraging" → "using")

### Development Workflow Compliance ✓

- **PASS**: Will use standard library structure (VERSION guard, dependencies declaration, libdir pattern)
- **PASS**: Will use section markers (# constants, # class methods, etc.)
- **PASS**: File operations: atomic writes for state, binary I/O, test() for checks
- **PASS**: Error handling: guard clauses, early returns, bang variants
- **PASS**: Will make CLI executable with `if $0 == __FILE__` pattern

### Dependencies ✓

- **PASS**: Minimal dependencies (6 gems, all justified)
- **PASS**: All deps from constitution-approved patterns (main, fattr, map, lockfile)
- **PASS**: Explicit dependency declaration in code

### Versioning ✓

- **PASS**: Will use MAJOR.MINOR.PATCH semantic versioning
- **PASS**: Will guard version constants
- **PASS**: Will provide version accessor method

**GATE RESULT**: ✅ PASS - All constitution requirements met. No complexity violations to justify.

---

**POST-DESIGN RE-EVALUATION** (Phase 1 Complete):

All constitution principles remain satisfied after design phase:

- ✅ **Simple Beats Clever**: Direct SQL queries, simple pattern matching, no ORM
- ✅ **Libraries Over Frameworks**: CLI tool with clear text in/out protocol, JSON support
- ✅ **Test-First**: Integration and contract tests defined in quickstart.md
- ✅ **Natural Representation**: Direct status output, honest error messages
- ✅ **Direct Communication**: Clear CLI commands, no buzzwords in output
- ✅ **Code Organization**: Standard library structure with section markers
- ✅ **Dependencies**: 6 minimal gems (main, sqlite3, fattr, map, lockfile, dotenv)
- ✅ **Versioning**: Semantic versioning with guards planned

Design artifacts (data-model.md, contracts/, quickstart.md) all follow constitution patterns. Ready for implementation.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
└── bx/
    ├── version.rb              # VERSION constant, version accessor
    ├── dependencies.rb         # Explicit dependency declarations
    ├── box.rb                  # Box entity and lifecycle
    ├── process.rb              # Process management and monitoring
    ├── environment.rb          # Environment variable management
    ├── detector.rb             # Auto-detection patterns
    ├── tmux_wrapper.rb         # Tmux command execution
    ├── state_manager.rb        # SQLite state persistence
    ├── history.rb              # Command history tracking
    └── cli.rb                  # Main CLI using 'main' gem

bin/
└── bx                        # Executable entry point

tests/
├── integration/
│   ├── test_box_lifecycle.rb      # Box init/start/stop/delete
│   ├── test_auto_detection.rb     # Pattern matching for projects
│   ├── test_process_monitoring.rb # Auto-restart, crash detection
│   ├── test_environment.rb        # Env loading and inheritance
│   ├── test_sub_boxes.rb          # Sub-box creation/management
│   └── test_history.rb            # History tracking and queries
└── contract/
    ├── test_cli_commands.rb       # CLI interface contracts
    ├── test_tmux_integration.rb   # Tmux interaction contracts
    └── test_sqlite_schema.rb      # Database schema contracts

config/
└── schema.sql              # SQLite database schema

Gemfile                     # Dependency specifications
Rakefile                    # Build tasks
bx.gemspec                # Gem specification
```

**Structure Decision**: Single Ruby gem project. Using standard Ruby gem layout with `lib/` for source, `bin/` for executable, `tests/` for integration and contract tests (no unit tests per constitution - focus on integration). All code under `lib/bx/` module namespace. SQLite schema in `config/` directory. Following constitution-approved patterns for file organization, section markers, and naming.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**No violations** - Constitution check passed all gates. No complexity justifications required.
