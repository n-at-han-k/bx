# Feature Specification: Core Box Manager (bx MVP)

**Feature Branch**: `001-core-box-manager`
**Created**: 2025-10-29
**Status**: Draft
**Input**: User description: "Build tmux session manager (bx) with box-of-boxes paradigm, process management, environment orchestration, and hierarchical organization"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Basic Box Management (Priority: P1)

As a developer with multiple projects, I want to organize each project as a "box" with multiple terminal windows so that I can easily start, stop, and navigate my entire development environment without manually managing tmux sessions.

**Why this priority**: Core foundation. Without box creation and management, nothing else works. This is the minimum viable product.

**Independent Test**: Can be fully tested by creating a project directory, initializing a box, starting/stopping it, and verifying tmux sessions are created/destroyed correctly. Delivers immediate value by replacing manual tmux session management.

**Acceptance Scenarios**:

1. **Given** a project directory at `~/projects/myapp`, **When** I run the initialize command, **Then** a box configuration is created for that project
2. **Given** a box configuration exists, **When** I start the box, **Then** a tmux session is created with windows defined in the configuration
3. **Given** a running box, **When** I request the box status, **Then** I see which windows are running and their current state
4. **Given** a running box, **When** I stop the box, **Then** all associated tmux windows are cleanly terminated
5. **Given** multiple boxes exist, **When** I list all boxes, **Then** I see a hierarchical tree view of all boxes and their states

---

### User Story 2 - Auto-Detection of Project Type (Priority: P2)

As a developer, I want the system to automatically detect how to run my project based on common patterns (package.json, Gemfile, Procfile, etc.) so that I don't have to manually configure every project.

**Why this priority**: Major usability win. Reduces friction from "configure everything" to "just works" for standard projects. Makes the tool feel intelligent without requiring AI.

**Independent Test**: Can be tested by creating projects with different tech stacks (Node.js, Ruby, Docker) and verifying the system correctly identifies and runs the appropriate commands. Delivers value by eliminating configuration for 80% of projects.

**Acceptance Scenarios**:

1. **Given** a directory with `package.json` containing a "dev" script, **When** I start the box without configuration, **Then** the system runs `npm run dev` automatically
2. **Given** a directory with `Gemfile` and `./script/server`, **When** I start the box, **Then** the system runs `bundle exec ./script/server`
3. **Given** a directory with `Procfile`, **When** I start the box, **Then** the system parses the Procfile and creates one window per process definition
4. **Given** a directory with `docker-compose.yml`, **When** I start the box, **Then** the system offers to run docker-compose up
5. **Given** a directory with no recognizable patterns, **When** I try to start the box, **Then** the system prompts me to create a configuration or specify what to run

---

### User Story 3 - Process Monitoring and Auto-Restart (Priority: P3)

As a developer, I want my processes to automatically restart if they crash so that my development environment stays running even when individual services fail.

**Why this priority**: Reliability feature. Makes the tool production-grade and PM2-like. Essential for long-running development sessions.

**Independent Test**: Can be tested by starting a box with a process that crashes, then verifying it automatically restarts up to a configured limit. Delivers value by preventing "dead" development environments.

**Acceptance Scenarios**:

1. **Given** a running process in a box, **When** the process exits with non-zero code, **Then** the system automatically restarts it
2. **Given** a process has crashed 3 times, **When** it crashes a 4th time, **Then** the system stops auto-restart and alerts the user
3. **Given** multiple processes in a box, **When** one crashes, **Then** only that process restarts, others continue running
4. **Given** a user manually stops a process, **When** they stop it, **Then** the system does not auto-restart it
5. **Given** processes are running, **When** I check their status, **Then** I see uptime, restart count, and exit codes for each

---

### User Story 4 - Environment Variable Management (Priority: P4)

As a developer, I want to load environment variables from files and have child boxes inherit parent environments so that I can manage configuration hierarchically without duplication.

**Why this priority**: Essential for real projects. Every modern app needs environment configuration. Hierarchical inheritance is a key differentiator.

**Independent Test**: Can be tested by creating a box with .env file, starting it, and verifying child windows inherit the environment plus any overrides. Delivers value by eliminating manual environment management.

**Acceptance Scenarios**:

1. **Given** a `.env` file exists in the project directory, **When** I start a box, **Then** all environment variables from the file are loaded into every window
2. **Given** a parent box has environment variables set, **When** I create a sub-box, **Then** the sub-box inherits all parent environment variables
3. **Given** a sub-box inherits parent environment, **When** I set additional variables in the sub-box, **Then** those variables are added without affecting the parent
4. **Given** conflicting environment variables between parent and child, **When** I start the child, **Then** child variables override parent variables
5. **Given** a box is running, **When** I query its environment, **Then** I see all variables with their sources (file, parent, explicit)

---

### User Story 5 - Sub-Box Creation (Priority: P5)

As a developer or AI agent, I want to spawn temporary or permanent sub-contexts within a box so that I can run long-running analysis, log tailing, or experiments that are re-attachable and properly isolated.

**Why this priority**: Novel feature that enables AI agent integration. Not strictly required for MVP but demonstrates unique value proposition.

**Independent Test**: Can be tested by creating a sub-box with a long-running command, detaching, reattaching, and verifying it's still running with proper environment inheritance. Delivers value for AI agents and advanced users.

**Acceptance Scenarios**:

1. **Given** a running box, **When** I create a sub-box with a command, **Then** a new tmux window is created running that command in a child context
2. **Given** a sub-box is running, **When** I detach from it, **Then** the process continues running in the background
3. **Given** a detached sub-box, **When** I reattach to it, **Then** I can interact with the running process as if I never detached
4. **Given** a temporary sub-box, **When** the process completes, **Then** the sub-box is automatically removed
5. **Given** a permanent sub-box, **When** the process completes, **Then** the sub-box persists and can be restarted

---

### User Story 6 - Command History Tracking (Priority: P6)

As a developer, I want a searchable history of all commands run in all boxes so that I can query what ran, when it ran, and on which machine.

**Why this priority**: Powerful debugging and auditing feature. Lower priority than core functionality but high value for power users.

**Independent Test**: Can be tested by running commands in boxes, then querying history by box, date, success/failure, and verifying results match actual execution. Delivers value for debugging and audit trails.

**Acceptance Scenarios**:

1. **Given** commands are executed in a box, **When** they complete, **Then** each command is recorded with timestamp, duration, and exit code
2. **Given** history exists, **When** I query by box name, **Then** I see all commands run in that box sorted by time
3. **Given** history exists, **When** I query by exit code, **Then** I see only commands that failed (or succeeded)
4. **Given** history exists, **When** I query by time range, **Then** I see only commands run within that period
5. **Given** commands run on different machines, **When** I query history, **Then** I see which machine each command ran on

---

### Edge Cases

- What happens when a box configuration file is invalid or corrupted?
- How does the system handle tmux not being installed or unavailable?
- What happens when two boxes try to use the same tmux session name?
- How does the system behave when a process fails to start due to port conflicts?
- What happens when environment variable files contain syntax errors?
- How does the system handle extremely long-running processes (days/weeks)?
- What happens when the user's home directory runs out of disk space for logs?
- How does the system handle processes that spawn their own child processes?

## Requirements *(mandatory)*

### Functional Requirements

**Box Lifecycle Management**:

- **FR-001**: System MUST allow users to initialize a new box from a directory path
- **FR-002**: System MUST allow users to start a box, creating all configured windows and processes
- **FR-003**: System MUST allow users to stop a box, cleanly terminating all processes
- **FR-004**: System MUST allow users to restart a box (stop + start)
- **FR-005**: System MUST allow users to delete a box and its associated state
- **FR-006**: System MUST provide a status command showing current state of all boxes or a specific box

**Box Discovery and Navigation**:

- **FR-007**: System MUST display a hierarchical tree view of all boxes and sub-boxes
- **FR-008**: System MUST allow users to list all running processes across all boxes
- **FR-009**: System MUST allow users to attach to a running box's tmux session
- **FR-010**: System MUST allow users to attach to a specific window within a box

**Auto-Detection**:

- **FR-011**: System MUST detect `package.json` files and recognize npm/yarn scripts
- **FR-012**: System MUST detect `Gemfile` files and look for common Ruby execution patterns
- **FR-013**: System MUST detect `Procfile` files and parse process definitions
- **FR-014**: System MUST detect `docker-compose.yml` files and offer docker-compose commands
- **FR-015**: System MUST detect `./script/*` directories and identify runnable scripts
- **FR-016**: System MUST gracefully handle projects with no recognizable patterns by prompting for configuration

**Process Management**:

- **FR-017**: System MUST monitor running processes and record their state (running, stopped, crashed)
- **FR-018**: System MUST automatically restart processes that exit with non-zero codes
- **FR-019**: System MUST respect a configurable maximum restart count per process
- **FR-020**: System MUST track process uptime, restart count, and exit codes
- **FR-021**: System MUST distinguish between user-initiated stops and crashes
- **FR-022**: System MUST capture and store process output (stdout and stderr)

**Environment Management**:

- **FR-023**: System MUST load environment variables from `.env` files in project directories
- **FR-024**: System MUST support hierarchical environment inheritance (child boxes inherit from parents)
- **FR-025**: System MUST allow child boxes to override parent environment variables
- **FR-026**: System MUST track the source of each environment variable (file, parent, explicit)
- **FR-027**: System MUST allow users to query the effective environment of any box

**Sub-Box Management**:

- **FR-028**: System MUST allow users to create sub-boxes within existing boxes
- **FR-029**: System MUST allow sub-boxes to be marked as temporary or permanent
- **FR-030**: System MUST automatically remove temporary sub-boxes when their processes complete
- **FR-031**: System MUST allow detaching from and reattaching to sub-boxes
- **FR-032**: System MUST ensure sub-boxes inherit parent environment and state

**History and Logging**:

- **FR-033**: System MUST record all commands executed in boxes with timestamp, duration, exit code, and machine name
- **FR-034**: System MUST allow users to query history by box name
- **FR-035**: System MUST allow users to query history by time range
- **FR-036**: System MUST allow users to filter history by exit code (success/failure)
- **FR-037**: System MUST persist history across system restarts
- **FR-038**: System MUST centralize logs for all processes in a queryable format

**Configuration**:

- **FR-039**: System MUST support YAML configuration files for box definitions
- **FR-040**: System MUST allow configuration files to specify multiple windows with commands
- **FR-041**: System MUST allow configuration files to specify environment variables per window
- **FR-042**: System MUST validate configuration files before starting boxes
- **FR-043**: System MUST provide helpful error messages for invalid configurations

**State Persistence**:

- **FR-044**: System MUST persist box state across tool restarts
- **FR-045**: System MUST detect when box configurations have changed and prompt for restart
- **FR-046**: System MUST maintain a database of boxes, processes, and history locally
- **FR-047**: System MUST handle concurrent access to state (multiple CLI invocations)

### Key Entities

- **Box**: Represents a project or workspace. Has a name, directory path, state (running/stopped), parent box reference (for sub-boxes), configuration, and collection of windows/processes. Each box maps to a tmux session or window depending on hierarchy level.

- **Process**: Represents a running command within a box. Has command string, PID, tmux window identifier, start time, stop time, exit code, restart count, and current state (running/stopped/crashed).

- **Environment**: Represents environment variables for a box. Has key-value pairs, source information (file, parent, explicit), and inheritance relationships. Hierarchical - child boxes inherit parent environments.

- **History Entry**: Represents a command execution record. Has command string, box reference, timestamp, duration, exit code, machine hostname, and output snippet (last N lines).

- **Configuration**: Represents box setup. Has box name, window definitions (name + command), environment variables, process restart policies, and lifecycle hooks. Can be YAML file, auto-detected, or default.

- **Window**: Represents a tmux window within a box. Has name, associated process, box reference, tmux identifier, and temporary/permanent flag. One window per process (no splits).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can start a box from a directory with a recognized project type (package.json, Gemfile, etc.) in under 10 seconds without configuration
- **SC-002**: Users can create, start, stop, and delete boxes with 3 or fewer commands
- **SC-003**: Process crashes are detected and restarted within 2 seconds
- **SC-004**: Users can navigate between 10+ boxes using keyboard shortcuts in under 5 seconds
- **SC-005**: Environment variable changes are reflected in child boxes immediately upon creation
- **SC-006**: Command history queries return results in under 1 second for 10,000+ history entries
- **SC-007**: Sub-boxes can be created and attached to within 3 seconds
- **SC-008**: 90% of common project types (Node.js, Ruby, Python, Docker) are auto-detected correctly
- **SC-009**: Box state persists correctly across system reboots and tool restarts
- **SC-010**: Users can view hierarchical box tree with 100+ boxes in under 2 seconds
- **SC-011**: Zero data loss for running processes when the tool restarts
- **SC-012**: Configuration validation catches 95% of common errors before attempting to start a box

## Assumptions

- Users have tmux installed and accessible in their PATH
- Users are running on Unix-like systems (Linux, macOS) - Windows/WSL support deferred
- Users understand basic terminal and tmux concepts
- Storage space for logs and history is available (~100MB minimum)
- Users have read/write access to their home directory for state storage
- Default restart policy is 3 attempts before giving up (configurable later)
- Environment files use standard key=value format (dotenv compatible)
- Auto-detection patterns cover Node.js (npm/yarn), Ruby (bundle/gem), Python (pip/poetry), Docker (compose), and generic scripts
- Local-only deployment (no cloud sync) for MVP
- Single-machine use case (SSH/cross-machine support deferred to later versions)
- Process output is captured but not streamed in real-time (tailing is manual via tmux attach)
