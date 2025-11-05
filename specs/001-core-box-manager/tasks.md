# Tasks: Core Box Manager (bx MVP)

**Input**: Design documents from `/specs/001-core-box-manager/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Test-First Development is **REQUIRED** per constitution (Principle III). Integration and contract tests written before implementation.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single Ruby gem**: `lib/bx/`, `bin/`, `tests/`, `config/`
- Paths shown below follow standard Ruby gem structure per plan.md

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [X] T001 Create Ruby gem directory structure with lib/bx/, bin/, tests/, vendor/, config/ directories
- [X] T002 Symlink tc testing framework: ln -s ~/gh/ahoward/tc vendor/tc for rapid co-evolution (dogfooding first real-world use)
- [X] T003 Create Gemfile with dependencies: main (~>6.2), sqlite3 (~>1.6), fattr (~>2.4), map (~>6.6), lockfile (~>2.1), dotenv (~>2.8)
- [X] T004 Create bx.gemspec with gem metadata and dependency specifications
- [X] T005 [P] Create Rakefile with default test task (requires vendor/tc/lib/tc.rb)
- [X] T006 [P] Create lib/bx.rb main module file with VERSION constant, libdir method, and load pattern
- [X] T007 [P] Create bin/bx executable entry point with proper shebang and require
- [X] T008 Create config/schema.sql with complete SQLite schema (boxes, processes, env_vars, history, messages tables)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T009 [P] Create lib/bx/state_manager.rb with database initialization, connection pooling, and WAL mode
- [X] T010 [P] Create lib/bx/tmux_wrapper.rb with methods for session/window management via shell commands
- [X] T011 Verify tmux installed and accessible (add to state_manager initialization check)
- [X] T012 [P] Create tests/test_helper.rb with tc framework setup (require_relative '../vendor/tc/lib/tc') and teardown for test database and tmux cleanup
- [X] T013 [P] Create lib/bx/version.rb with VERSION constant guard and accessor method

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Basic Box Management (Priority: P1) 🎯 MVP

**Goal**: Enable box creation, starting, stopping, and status checking with tmux session orchestration

**Independent Test**: Create a project directory, initialize box, start/stop it, verify tmux sessions created/destroyed correctly. User Story 1 alone delivers value by replacing manual tmux management.

### Tests for User Story 1 (REQUIRED per constitution) ⚠️

> **NOTE: Write these tests FIRST using tc framework, ensure they FAIL before implementation**

- [ ] T014 [P] [US1] Write tc integration test for box initialization in tests/integration/test_box_lifecycle.rb (TC.testing block, test init creates database entry and config)
- [ ] T015 [P] [US1] Write tc integration test for box start in tests/integration/test_box_lifecycle.rb (test tmux session creation)
- [ ] T016 [P] [US1] Write tc integration test for box stop in tests/integration/test_box_lifecycle.rb (test graceful shutdown and session cleanup)
- [ ] T017 [P] [US1] Write tc integration test for box status in tests/integration/test_box_lifecycle.rb (test state queries)
- [ ] T018 [P] [US1] Write tc integration test for box tree view in tests/integration/test_box_lifecycle.rb (test hierarchical display)
- [ ] T019 [P] [US1] Write tc contract test for CLI init command in tests/contract/test_cli_commands.rb (test args, options, exit codes)
- [ ] T020 [P] [US1] Write tc contract test for CLI start/stop/status commands in tests/contract/test_cli_commands.rb
- [ ] T021 [P] [US1] Write tc contract test for tmux integration in tests/contract/test_tmux_integration.rb (test session/window creation)

**Run tests - verify ALL FAIL** (RED phase)

### Implementation for User Story 1

- [ ] T022 [P] [US1] Create lib/bx/box.rb with Box class including create, start, stop, status, and tree methods
- [ ] T023 [P] [US1] Implement box state transitions (stopped → starting → running → stopped) in lib/bx/box.rb
- [ ] T024 [US1] Implement Box.create method with database insertion and validation in lib/bx/box.rb
- [ ] T025 [US1] Implement Box#start method integrating tmux_wrapper for session creation in lib/bx/box.rb
- [ ] T026 [US1] Implement Box#stop method with graceful shutdown and session cleanup in lib/bx/box.rb
- [ ] T027 [US1] Implement Box#status method querying process states and uptime in lib/bx/box.rb
- [ ] T028 [US1] Implement Box.tree method for hierarchical display with parent-child relationships in lib/bx/box.rb
- [ ] T029 [US1] Create lib/bx/cli.rb with Main DSL and init mode for box initialization
- [ ] T030 [US1] Implement start mode in lib/bx/cli.rb calling Box#start with attach option support
- [ ] T031 [US1] Implement stop mode in lib/bx/cli.rb calling Box#stop with force/timeout options
- [ ] T032 [US1] Implement status mode in lib/bx/cli.rb displaying box state and processes
- [ ] T033 [US1] Implement tree mode in lib/bx/cli.rb rendering hierarchical box view
- [ ] T034 [US1] Add error handling and validation for all Box operations in lib/bx/box.rb
- [ ] T035 [US1] Add JSON output support (--json flag) to all CLI modes in lib/bx/cli.rb

**Run tests - verify ALL PASS** (GREEN phase)

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently. You have a working MVP!

---

## Phase 4: User Story 2 - Auto-Detection of Project Type (Priority: P2)

**Goal**: Automatically detect project types (Node.js, Ruby, Docker, Procfile) and suggest/run appropriate commands without manual configuration

**Independent Test**: Create projects with package.json, Gemfile, docker-compose.yml and verify correct auto-detection. Delivers value by eliminating configuration for standard projects.

### Tests for User Story 2 (REQUIRED per constitution) ⚠️

- [ ] T036 [P] [US2] Write integration test for Node.js detection in tests/integration/test_auto_detection.rb (package.json with scripts)
- [ ] T037 [P] [US2] Write integration test for Ruby detection in tests/integration/test_auto_detection.rb (Gemfile + script/server)
- [ ] T038 [P] [US2] Write integration test for Procfile parsing in tests/integration/test_auto_detection.rb (multi-process definitions)
- [ ] T039 [P] [US2] Write integration test for Docker detection in tests/integration/test_auto_detection.rb (docker-compose.yml)
- [ ] T040 [P] [US2] Write integration test for no-pattern fallback in tests/integration/test_auto_detection.rb (prompt user)

**Run tests - verify ALL FAIL** (RED phase)

### Implementation for User Story 2

- [ ] T041 [P] [US2] Create lib/bx/detector.rb with Detector class and detect_commands entry point
- [ ] T042 [P] [US2] Implement detect_nodejs method in lib/bx/detector.rb (parse package.json scripts)
- [ ] T043 [P] [US2] Implement detect_ruby method in lib/bx/detector.rb (check Gemfile + script/* files)
- [ ] T044 [P] [US2] Implement parse_procfile method in lib/bx/detector.rb (parse name:command format)
- [ ] T045 [P] [US2] Implement detect_docker method in lib/bx/detector.rb (check docker-compose.yml)
- [ ] T046 [US2] Integrate detector into Box#start method (check for trex.yml, fallback to auto-detect) in lib/bx/box.rb
- [ ] T047 [US2] Update CLI init mode to show auto-detected commands in lib/bx/cli.rb
- [ ] T048 [US2] Add prompt_user_for_command fallback when no pattern matches in lib/bx/detector.rb

**Run tests - verify ALL PASS** (GREEN phase)

**Checkpoint**: At this point, User Stories 1 AND 2 both work independently. Auto-detection functional!

---

## Phase 5: User Story 3 - Process Monitoring and Auto-Restart (Priority: P3)

**Goal**: Monitor running processes, detect crashes, and automatically restart up to configured maximum

**Independent Test**: Start box with crashing process, verify auto-restart behavior and max restart limit. Delivers reliability for long-running sessions.

### Tests for User Story 3 (REQUIRED per constitution) ⚠️

- [ ] T049 [P] [US3] Write integration test for crash detection in tests/integration/test_process_monitoring.rb (non-zero exit code)
- [ ] T050 [P] [US3] Write integration test for auto-restart in tests/integration/test_process_monitoring.rb (process restarted after crash)
- [ ] T051 [P] [US3] Write integration test for max restart limit in tests/integration/test_process_monitoring.rb (stop after 3 crashes)
- [ ] T052 [P] [US3] Write integration test for manual stop no-restart in tests/integration/test_process_monitoring.rb (user-initiated stop)
- [ ] T053 [P] [US3] Write integration test for status with uptime/restart_count in tests/integration/test_process_monitoring.rb

**Run tests - verify ALL FAIL** (RED phase)

### Implementation for User Story 3

- [ ] T054 [P] [US3] Create lib/bx/process.rb with Process class and state management
- [ ] T055 [P] [US3] Implement process state transitions (stopped → starting → running → crashed) in lib/bx/process.rb
- [ ] T056 [US3] Implement crash detection via tmux hooks (pane-died event) in lib/bx/tmux_wrapper.rb
- [ ] T057 [US3] Implement periodic health check loop (5s interval) in lib/bx/process.rb
- [ ] T058 [US3] Implement auto-restart logic with restart_count tracking in lib/bx/process.rb
- [ ] T059 [US3] Add max_restarts configuration (default 3) in lib/bx/box.rb
- [ ] T060 [US3] Distinguish user-initiated stop from crash (add stopped_by field) in lib/bx/process.rb
- [ ] T061 [US3] Update Box#status to show uptime, restart_count, exit_code per process in lib/bx/box.rb
- [ ] T062 [US3] Add process monitoring initialization in Box#start in lib/bx/box.rb

**Run tests - verify ALL PASS** (GREEN phase)

**Checkpoint**: All user stories 1-3 should now be independently functional. Process monitoring active!

---

## Phase 6: User Story 4 - Environment Variable Management (Priority: P4)

**Goal**: Load environment variables from .env files and support hierarchical inheritance from parent to child boxes

**Independent Test**: Create box with .env file, create sub-box, verify inheritance and override behavior. Delivers hierarchical configuration management.

### Tests for User Story 4 (REQUIRED per constitution) ⚠️

- [ ] T063 [P] [US4] Write integration test for .env file loading in tests/integration/test_environment.rb (variables loaded into windows)
- [ ] T064 [P] [US4] Write integration test for parent-child inheritance in tests/integration/test_environment.rb (child inherits parent env)
- [ ] T065 [P] [US4] Write integration test for child override in tests/integration/test_environment.rb (child value overrides parent)
- [ ] T066 [P] [US4] Write integration test for env query with sources in tests/integration/test_environment.rb (show source tracking)

**Run tests - verify ALL FAIL** (RED phase)

### Implementation for User Story 4

- [ ] T067 [P] [US4] Create lib/bx/environment.rb with Environment class and source tracking
- [ ] T068 [P] [US4] Implement .env file loading using dotenv gem in lib/bx/environment.rb
- [ ] T069 [US4] Implement recursive environment query (WITH RECURSIVE CTE) in lib/bx/environment.rb
- [ ] T070 [US4] Implement environment inheritance with parent override logic in lib/bx/environment.rb
- [ ] T071 [US4] Add env_vars table management (insert, query by box_id) in lib/bx/state_manager.rb
- [ ] T072 [US4] Integrate environment loading into Box#start (load before process creation) in lib/bx/box.rb
- [ ] T073 [US4] Pass environment variables to tmux windows in lib/bx/tmux_wrapper.rb (tmux setenv)
- [ ] T074 [US4] Implement CLI env mode for querying/setting variables in lib/bx/cli.rb
- [ ] T075 [US4] Add source tracking display (file/parent/explicit/default) to CLI env mode in lib/bx/cli.rb

**Run tests - verify ALL PASS** (GREEN phase)

**Checkpoint**: User Stories 1-4 independently functional. Environment management complete!

---

## Phase 7: User Story 5 - Sub-Box Creation (Priority: P5)

**Goal**: Allow creation of temporary or permanent sub-boxes within running boxes for long-running tasks or experiments

**Independent Test**: Create sub-box with command, detach/reattach, verify environment inheritance, test temporary auto-removal. Delivers novel AI agent integration capability.

### Tests for User Story 5 (REQUIRED per constitution) ⚠️

- [ ] T076 [P] [US5] Write integration test for sub-box creation in tests/integration/test_sub_boxes.rb (child box with parent_id set)
- [ ] T077 [P] [US5] Write integration test for detach/reattach in tests/integration/test_sub_boxes.rb (tmux window persistence)
- [ ] T078 [P] [US5] Write integration test for temporary sub-box cleanup in tests/integration/test_sub_boxes.rb (auto-delete on exit)
- [ ] T079 [P] [US5] Write integration test for permanent sub-box persistence in tests/integration/test_sub_boxes.rb (survives process exit)
- [ ] T080 [P] [US5] Write integration test for sub-box environment inheritance in tests/integration/test_sub_boxes.rb (parent env passed down)

**Run tests - verify ALL FAIL** (RED phase)

### Implementation for User Story 5

- [ ] T081 [US5] Add temporary flag support to Box.create method in lib/bx/box.rb
- [ ] T082 [US5] Implement sub-box creation with parent_id setting in lib/bx/box.rb
- [ ] T083 [US5] Add window creation within existing session for sub-boxes in lib/bx/tmux_wrapper.rb
- [ ] T084 [US5] Implement automatic cleanup for temporary sub-boxes on process exit in lib/bx/process.rb
- [ ] T085 [US5] Verify environment inheritance works for sub-boxes (use parent box environment) in lib/bx/environment.rb
- [ ] T086 [US5] Implement CLI sub mode for creating sub-boxes with `-- COMMAND` syntax in lib/bx/cli.rb
- [ ] T087 [US5] Add --temporary and --permanent flags to CLI sub mode in lib/bx/cli.rb

**Run tests - verify ALL PASS** (GREEN phase)

**Checkpoint**: All user stories 1-5 independently functional. Sub-box feature working!

---

## Phase 8: User Story 6 - Command History Tracking (Priority: P6)

**Goal**: Record all command executions with metadata (timestamp, duration, exit code, machine) and provide queryable history

**Independent Test**: Run commands in boxes, query history by various filters (box, time, exit code), verify records match execution. Delivers debugging and audit trail capability.

### Tests for User Story 6 (REQUIRED per constitution) ⚠️

- [ ] T088 [P] [US6] Write integration test for history recording in tests/integration/test_history.rb (commands logged with metadata)
- [ ] T089 [P] [US6] Write integration test for query by box in tests/integration/test_history.rb (filter by box_id)
- [ ] T090 [P] [US6] Write integration test for query by exit code in tests/integration/test_history.rb (failed commands only)
- [ ] T091 [P] [US6] Write integration test for query by time range in tests/integration/test_history.rb (last week filter)

**Run tests - verify ALL FAIL** (RED phase)

### Implementation for User Story 6

- [ ] T092 [P] [US6] Create lib/bx/history.rb with History class and recording methods
- [ ] T093 [US6] Implement history recording in Process class (on start and stop) in lib/bx/process.rb
- [ ] T094 [US6] Add history table queries (by box, by time, by exit code) in lib/bx/history.rb
- [ ] T095 [US6] Capture command output (last 100 lines) for history in lib/bx/history.rb
- [ ] T096 [US6] Calculate and store duration_ms for each execution in lib/bx/history.rb
- [ ] T097 [US6] Implement CLI history mode with filtering options in lib/bx/cli.rb
- [ ] T098 [US6] Add --failed, --last-week, --last-day flags to CLI history mode in lib/bx/cli.rb
- [ ] T099 [US6] Add JSON output support for history queries in lib/bx/cli.rb

**Run tests - verify ALL PASS** (GREEN phase)

**Checkpoint**: All 6 user stories independently functional and tested!

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T100 [P] Implement CLI restart mode (stop + start) in lib/bx/cli.rb
- [ ] T101 [P] Implement CLI attach mode for tmux session attachment in lib/bx/cli.rb
- [ ] T102 [P] Implement CLI delete mode for box removal with confirmation in lib/bx/cli.rb
- [ ] T103 [P] Implement CLI logs mode for log tailing in lib/bx/cli.rb
- [ ] T104 [P] Implement CLI config mode (show/validate/edit) in lib/bx/cli.rb
- [ ] T105 [P] Add global --help, --version, --json, --verbose options to all CLI modes in lib/bx/cli.rb
- [ ] T106 [P] Create log rotation logic (100MB per box, 10MB file limit) in lib/bx/box.rb
- [ ] T107 [P] Add file locking with Lockfile gem in lib/bx/state_manager.rb (5s timeout)
- [ ] T108 [P] Implement config file validation (YAML structure check) in lib/bx/box.rb
- [ ] T109 [P] Add config_hash detection for configuration changes in lib/bx/box.rb
- [ ] T110 [P] Create README.md with installation, quickstart, and usage examples
- [ ] T111 [P] Add error handling for tmux not installed in lib/bx/state_manager.rb
- [ ] T112 [P] Add error handling for SQLite database corruption in lib/bx/state_manager.rb
- [ ] T113 [P] Performance test: Verify tree view <2s for 100+ boxes
- [ ] T114 [P] Performance test: Verify history queries <1s for 10K+ entries
- [ ] T115 [P] Run all integration tests end-to-end to verify cross-story compatibility
- [ ] T116 [P] Code cleanup and refactoring per constitution patterns (section markers, guard clauses, etc.)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Foundational phase completion
  - User stories CAN proceed in parallel if staffed (independent implementations)
  - Or sequentially in priority order: P1 → P2 → P3 → P4 → P5 → P6
- **Polish (Phase 9)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Depends ONLY on Foundational - No dependencies on other stories
- **User Story 2 (P2)**: Depends ONLY on Foundational - Integrates with US1 but independently testable
- **User Story 3 (P3)**: Depends ONLY on Foundational + Process entity from US1
- **User Story 4 (P4)**: Depends ONLY on Foundational - Works with US1 boxes
- **User Story 5 (P5)**: Depends ONLY on Foundational + Box entity from US1 + Environment from US4
- **User Story 6 (P6)**: Depends ONLY on Foundational + Process entity from US1

**Key insight**: Stories 1, 2, 4 are fully independent. Stories 3, 5, 6 have light dependencies but are still independently testable.

### Within Each User Story

- **Tests FIRST** (RED phase): Write all tests, verify they fail
- **Implementation** (GREEN phase): Implement until tests pass
- **Refactor** (REFACTOR phase): Clean up code
- Complete each story fully before moving to next

### Parallel Opportunities

- **Setup tasks**: T003-T008 can run in parallel (different files) - T002 (symlink) should run first but is very fast
- **Foundational tasks**: T009-T010, T012-T013 can run in parallel
- **Within each story**: All test tasks marked [P] can run together
- **Between stories**: After Foundational, stories 1, 2, 4 can be developed in parallel by different developers
- **Polish tasks**: T100-T116 can mostly run in parallel (different files/concerns)

---

## Parallel Example: User Story 1

```bash
# RED Phase: Write all tc tests in parallel
Task T014: tests/integration/test_box_lifecycle.rb (init test with TC.testing)
Task T015: tests/integration/test_box_lifecycle.rb (start test)
Task T016: tests/integration/test_box_lifecycle.rb (stop test)
Task T017: tests/integration/test_box_lifecycle.rb (status test)
Task T018: tests/integration/test_box_lifecycle.rb (tree test)
Task T019: tests/contract/test_cli_commands.rb (init contract)
Task T020: tests/contract/test_cli_commands.rb (start/stop/status contracts)
Task T021: tests/contract/test_tmux_integration.rb (tmux contract)

# GREEN Phase: Parallel implementation where possible
Task T022: lib/bx/box.rb (Box class - independent)
Task T023: lib/bx/box.rb (state transitions - depends on T022)
...then sequential as dependencies require
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T008) - includes vendoring tc framework
2. Complete Phase 2: Foundational (T009-T013) - CRITICAL GATE
3. Complete Phase 3: User Story 1 (T014-T035)
   - Write tc tests first (T014-T021) → verify FAIL
   - Implement (T022-T035) → verify PASS
4. **STOP and VALIDATE**: Test User Story 1 end-to-end independently
5. You now have a working MVP! Can deploy/demo basic box management

**MVP Delivers**: Box init, start, stop, status, tree - replacing manual tmux session management with `bx` CLI, symlinked tc framework for rapid co-evolution dogfooding

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready (T001-T013)
2. Add User Story 1 → Test independently → Deploy/Demo (**MVP!**)
3. Add User Story 2 → Test independently → Deploy/Demo (auto-detection added)
4. Add User Story 3 → Test independently → Deploy/Demo (reliability added)
5. Add User Story 4 → Test independently → Deploy/Demo (environment mgmt added)
6. Add User Story 5 → Test independently → Deploy/Demo (sub-boxes added)
7. Add User Story 6 → Test independently → Deploy/Demo (history added)
8. Add Polish → Final release (full feature set)

Each story adds incremental value without breaking previous stories.

### Parallel Team Strategy

With multiple developers after Foundational phase completes:

- **Developer A**: User Story 1 (T014-T035)
- **Developer B**: User Story 2 (T036-T048)
- **Developer C**: User Story 4 (T063-T075)

Stories 1, 2, 4 are fully independent and can proceed in parallel. Stories 3, 5, 6 can follow once their light dependencies (Box/Process/Environment entities) exist.

---

## Notes

- **[P] tasks** = Different files, no dependencies on incomplete work, safe to parallelize
- **[Story] labels** = Map tasks to user stories for traceability and independent testing
- **Test-First is NON-NEGOTIABLE** per constitution - RED before GREEN
- Each user story phase should be complete and independently testable
- Stop at any checkpoint to validate story independence
- Avoid cross-story dependencies that break independent testing
- Commit after each task or logical group
- All file paths are explicit for LLM execution

---

## Task Summary

- **Total Tasks**: 115
- **Setup Phase**: 7 tasks
- **Foundational Phase**: 5 tasks (CRITICAL GATE)
- **User Story 1 (P1)**: 22 tasks (8 tests + 14 implementation)
- **User Story 2 (P2)**: 13 tasks (5 tests + 8 implementation)
- **User Story 3 (P3)**: 14 tasks (5 tests + 9 implementation)
- **User Story 4 (P4)**: 13 tasks (4 tests + 9 implementation)
- **User Story 5 (P5)**: 12 tasks (5 tests + 7 implementation)
- **User Story 6 (P6)**: 12 tasks (4 tests + 8 implementation)
- **Polish Phase**: 17 tasks

**Parallel Opportunities**: 58 tasks marked [P] (50% of total)

**Independent Test Criteria**:
- US1: Init/start/stop box, verify tmux session lifecycle
- US2: Create Node.js/Ruby/Docker projects, verify auto-detection
- US3: Start crashing process, verify auto-restart up to limit
- US4: Create box with .env, create sub-box, verify inheritance
- US5: Create sub-box, detach/reattach, verify temporary cleanup
- US6: Run commands, query history by filters, verify records

**Suggested MVP Scope**: Phase 1 + Phase 2 + Phase 3 (User Story 1 only) = 34 tasks
