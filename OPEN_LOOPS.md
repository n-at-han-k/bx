# Open Loops

**Purpose**: Track important decisions, temporary states, and items requiring follow-up that must not be forgotten.

**Format**: Date-stamped entries with status, context, and next actions.

---

## Active Loops

### [OPEN] tc Testing Framework: Symlink vs. Vendoring

**Date**: 2025-11-05
**Status**: 🟡 Active (using symlinks for now)
**Context**:
- Currently symlinking tc from `~/gh/ahoward/tc -> vendor/tc` for rapid co-evolution
- This is tc's first real-world deployment ("dogfooding")
- Allows instant iteration on both T-Rex and tc simultaneously

**Decision Point**:
May switch to vendoring or gem dependency later once tc stabilizes

**Files Affected**:
- `specs/001-core-box-manager/research.md:369` (Decision 9)
- `specs/001-core-box-manager/tasks.md:28` (T002)
- `specs/001-core-box-manager/quickstart.md:18` (Setup)

**Next Actions**:
- [ ] Monitor tc stability during T-Rex MVP development
- [ ] Decide: Keep symlink, vendor tc, or publish as gem
- [ ] Update all docs when decision is made
- [ ] Consider creating tc gem if it proves useful beyond T-Rex

**Notes**:
- Symlink approach enables true dogfooding
- Changes to tc are instant (no copy/sync needed)
- Risk: Breaks if tc repo location changes
- Benefit: Forces us to improve tc as we use it

---

## Resolved Loops

### [RESOLVED] Project Naming: T-Rex → bx

**Date**: 2025-11-05
**Status**: 🟢 Resolved
**Context**:
- Original name was "T-Rex (Placeholder Name)" per README header
- Analyzed naming options: boxman, boxd, boxer, tmbox, bx
- Selected **bx** for ultra-minimal, modern CLI tool aesthetic

**Decision**:
Final naming convention:
- **CLI Command**: `bx` (e.g., `bx init`, `bx start`)
- **Ruby Module**: `BX` (all caps, following Ruby IO/GC convention)
- **Gem Name**: `bx`
- **File Paths**: `~/.bx/`
- **Display Name**: bx (lowercase in prose)

**Files Updated** (2025-11-05):
- README.md - Header, examples, all references (~40 lines)
- specs/001-core-box-manager/spec.md - Header (~5 lines)
- specs/001-core-box-manager/plan.md - Paths, module names (~60 lines)
- specs/001-core-box-manager/tasks.md - All task descriptions (~120 lines)
- specs/001-core-box-manager/quickstart.md - Module, examples (~100 lines)
- specs/001-core-box-manager/research.md - Paths, error messages (~15 lines)
- CLAUDE.md - Header, metadata (~5 lines)

**Rationale**:
- Ultra-minimal (2 chars) follows modern CLI pattern (rg, fd, bat)
- Constitution-aligned: Simple, direct, no cleverness
- Zero collision risk in Ruby/tmux domain
- Fast to type, easy to remember

**Resolution Date**: 2025-11-05

---

---

## Deferred Loops

*None yet*

---

## Template for New Entries

```markdown
### [STATUS] Brief Description

**Date**: YYYY-MM-DD
**Status**: 🔴 Blocked | 🟡 Active | 🟢 Resolved | ⚪ Deferred
**Context**: Why this matters, background information

**Decision Point**: What needs to be decided or resolved

**Files Affected**:
- path/to/file.ext:line_number (description)

**Next Actions**:
- [ ] Action item 1
- [ ] Action item 2

**Notes**:
Additional context, risks, benefits, or considerations
```
