<!--
Sync Impact Report:
- Version: Initial → 1.0.0
- Ratification: 2025-10-29
- Principles Added:
  * I. Simple Beats Clever
  * II. Libraries Over Frameworks
  * III. Test-First Development
  * IV. Natural Representation
  * V. Direct Communication
- Templates Status:
  ✅ plan-template.md - Constitution Check section aligned
  ✅ spec-template.md - User scenarios and requirements align with principles
  ✅ tasks-template.md - Test-first workflow and task organization align
- Follow-up TODOs: None
-->

# T-Rex Constitution

## Core Principles

### I. Simple Beats Clever

**MUST**: Choose the simplest solution that solves the problem. Complexity requires explicit justification.

**MUST**: Prefer composition over inheritance. Duck typing over protocols. Direct implementation over abstraction layers.

**MUST NOT**: Add frameworks, dependencies, or architectural patterns without measuring the problem first.

**Rationale**: After 143 gems and 30 years of Ruby code, the pattern is clear - simple solutions survive, clever ones become technical debt. Every abstraction layer is a cognitive tax on future maintainers.

### II. Libraries Over Frameworks

**MUST**: Build features as standalone libraries first. Every library must be:
- Self-contained and independently testable
- Documented with clear purpose
- Exposable via CLI with text in/out protocol (stdin/args → stdout, errors → stderr)
- Able to support both JSON and human-readable formats

**MUST NOT**: Create organizational-only libraries or libraries without clear standalone value.

**Rationale**: Libraries compose, frameworks constrain. A good library solves one problem well and can be used anywhere. This mirrors the Unix philosophy - small tools that do one thing well.

### III. Test-First Development (NON-NEGOTIABLE)

**MUST**: Follow Red-Green-Refactor cycle strictly:
1. Write tests
2. Get user approval on tests
3. Verify tests fail (RED)
4. Implement until tests pass (GREEN)
5. Refactor (REFACTOR)

**MUST**: Write integration tests for:
- New library contracts
- Contract changes
- Inter-service communication
- Shared schemas

**MUST NOT**: Write implementation before tests. Ever.

**Rationale**: Tests define behavior. Writing implementation first creates confirmation bias - you test what you built, not what you should have built. Tests fail first or they're not tests.

### IV. Natural Representation

**MUST**: Keep all outputs (code, writing, photography) as natural and true-to-life as possible.

**MUST**: Prefer direct, honest representation over processed or embellished versions.

**MUST NOT**: Add artificial drama, over-processing, or manipulation unless it serves the core truth.

**Rationale**: "Each grain of cognitive dissonance in the code moves the solution farther away." This applies to writing and photography too. Natural representation builds trust and reduces maintenance overhead.

### V. Direct Communication

**MUST**: Write code, documentation, and prose that is:
- Direct and to the point
- Honest about limitations
- Free of corporate speak and buzzwords
- Scannable (short paragraphs, clear structure)

**MUST**: Use lowercase in personal/contemplative writing for authenticity.

**MUST NOT**: Hide behind passive voice, use 10 words when 3 will do, or write before testing/verifying.

**Rationale**: Communication overhead kills projects. Direct communication is faster to write, faster to read, and harder to misinterpret. The goal is clarity and honesty, not polish.

## Development Workflow

### Code Organization

**MUST**: Follow the standard library structure:
```ruby
module LibraryName
  # Version with guard
  LibraryName::VERSION = '1.2.3' unless defined? LibraryName::VERSION

  # Explicit dependency declaration
  def LibraryName.dependencies
    {
      'map' => [ 'map', '~> 6.6', '>= 6.6.0' ]
    }
  end

  # Controlled load pattern
  def LibraryName.libdir(*args, &block)
    # implementation
  end
end
```

**MUST**: Use section markers for visual organization:
```ruby
# constants
#
# class methods
#
# instance setup
#
# public interface
#
# private stuff
#
```

### File Operations

**MUST**: Use atomic writes for state files:
1. Write to temp file
2. Move to final location
3. Clean up temp in ensure block

**MUST**: Use binary I/O (IO.binread, IO.binwrite) for file operations to avoid encoding issues.

**MUST**: Use `test()` kernel method for file checks (test(?s, path), test(?e, path), test(?d, path)) instead of File.exist?, File.file?, etc.

### Error Handling

**MUST**: Use guard clauses and early returns:
```ruby
def method
  return nil unless condition
  # rest of method
end
```

**MUST**: Provide bang variants (method!) that raise on failure alongside safe variants that return nil.

**MUST NOT**: Catch exceptions you can't handle meaningfully.

### Testing Philosophy

**MUST**: Make scripts executable and testable:
```ruby
if $0 == __FILE__
  # CLI usage / inline tests
end
```

**MUST**: Focus on integration tests over unit tests. Test real usage, not mocked scenarios.

**MUST**: Keep test assertions simple and clear. If testy (78 lines of code) can handle it, use that level of simplicity.

## Writing Standards

### Technical Writing

**MUST**: Structure technical posts as:
1. **TL;DR** - One sentence summary
2. **The Problem** - What conventional wisdom gets wrong
3. **Evidence** - Code, data, methodology
4. **Reasoning** - Show your math/logic
5. **Conclusion** - What actually works
6. **Practical Application** - How to use this

**MUST**: Include actual, runnable code examples.

**MUST**: Show methodology and link to source code/results.

### General Writing

**MUST**: Use short paragraphs (1-3 sentences).

**MUST**: Start with the point. No fluff, no filler.

**MUST**: Challenge conventional wisdom when evidence supports it.

**MUST**: Be honest about work-in-progress and limitations.

**MUST NOT**: Use buzzwords (leverage → use, utilize → use, in order to → to).

### Style Notes

**SHOULD**: Use deliberate misspellings for humor and hacker aesthetic when appropriate.

**SHOULD**: Use emojis strategically (e.g., 🐍 for Python/pythong).

**SHOULD**: Cross-reference related work to build connected body of knowledge.

**MUST NOT**: "Fix" apparent typos without asking first - assume intentionality.

## Photography Standards

### Philosophy

**MUST**: Keep photography as natural and true-to-life as possible.

**MUST**: Prioritize story over technical perfection, specs, or engagement metrics.

**MUST**: Document real experiences, not staged or artificial moments.

**MUST NOT**: Use excessive HDR, oversaturation, or artificial drama.

### Subject Approach

**SHOULD**: Focus on:
- Natural landscapes (mountains, deserts, wilderness)
- Adventure documentation (bike touring, skiing, mountaineering)
- Dogs being dogs
- People in context (documentary style, not portraits)

**MUST**: Provide environmental context - wide angles showing place, not isolated subjects.

### Processing

**MUST**: Minimal processing workflow:
1. Does it look like what you saw?
2. Correct exposure/white balance
3. Maybe slight contrast/clarity
4. Crop if needed
5. Ship it

**MUST NOT**: Spend hours in Photoshop, chase Instagram aesthetics, or manipulate for trends.

## Technology Constraints

### Dependencies

**MUST**: Keep dependencies minimal and explicit.

**MUST**: Declare dependencies in code:
```ruby
def LibraryName.dependencies
  { 'gem_name' => [ 'gem_name', '~> version', '>= specific' ] }
end
```

**MUST**: Use local paths for development when available:
```ruby
%w[ro map rego].each do |lib|
  if test(?e, File.expand_path("~/gh/ahoward/#{ lib }"))
    gem lib, path: "~/gh/ahoward/#{ lib }"
  else
    gem lib, git: "https://github.com/ahoward/#{ lib }"
  end
end
```

### Performance

**MUST**: Measure before optimizing. Premature optimization is the root of all evil.

**MAY**: Optimize when:
- You have actual measurements showing a problem
- Parallel processing helps I/O bound work
- Simple wins exist (test() vs File.exist?, IO.binread vs File.read)

**MUST NOT**: Sacrifice readability for unmeasured speed gains.

### Concurrency

**MUST**: Use proper locking for shared state:
1. File lock (cross-process)
2. Mutex (cross-thread)
3. Load state
4. Do work
5. Save state (in ensure)

**SHOULD**: Use Parallel gem for I/O bound work with appropriate thread/process counts.

## Observability

**MUST**: Text I/O ensures debuggability. All CLI tools must:
- Accept input via stdin or args
- Write normal output to stdout
- Write errors to stderr
- Support both JSON and human-readable formats

**MUST**: Use structured logging for services.

**MUST**: Include `if $0 == __FILE__` blocks for direct script execution and testing.

## Versioning & Breaking Changes

**MUST**: Use MAJOR.MINOR.PATCH semantic versioning:
- **MAJOR**: Breaking changes or backward incompatible changes
- **MINOR**: New features, additions, expansions
- **PATCH**: Bug fixes, clarifications, non-semantic refinements

**MUST**: Guard version constants:
```ruby
LibraryName::VERSION = '1.2.3' unless defined? LibraryName::VERSION
```

**MUST**: Provide version accessor:
```ruby
def LibraryName.version
  LibraryName::VERSION
end
```

## Governance

### Amendment Process

**MUST**: Constitution amendments require:
1. Documentation of rationale
2. Analysis of impact on existing code/projects
3. Migration plan for breaking changes
4. Update of this constitution with new version number

**MUST**: Version this constitution per semantic versioning rules:
- MAJOR: Backward incompatible governance/principle removals or redefinitions
- MINOR: New principle/section added or materially expanded guidance
- PATCH: Clarifications, wording, typo fixes, non-semantic refinements

### Compliance Review

**MUST**: All PRs and reviews verify compliance with these principles.

**MUST**: Justify any complexity that violates "Simple Beats Clever" in plan.md Complexity Tracking section.

**MUST**: Document why simpler alternatives were rejected when adding:
- Additional projects beyond necessary minimum
- Architectural patterns (Repository, Service Layer, etc.)
- New frameworks or heavy dependencies
- Abstraction layers

### Runtime Development

**SHOULD**: Reference `./ai/CODE.md`, `./ai/WRITING.md`, and `./ai/PHOTOGRAPHY.md` for detailed runtime guidance during development.

**SHOULD**: Keep this constitution high-level and principles-focused. Detailed patterns live in ./ai/ directory.

### Final Authority

This constitution supersedes all other practices. When in doubt:

1. Read your existing code (143 gems worth)
2. Follow patterns that appear everywhere
3. Keep it simple
4. Test by running it
5. Ship it

> "Simple beats clever. Every. Single. Time."

**Version**: 1.0.0 | **Ratified**: 2025-10-29 | **Last Amended**: 2025-10-29
