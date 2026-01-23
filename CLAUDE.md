# Claude Code Instructions

## Project Overview
WOD (Workout of the Day) Timer app built with Flutter using Domain-Driven Design (DDD) architecture.

## Workflow Rules

### Always Create PR After Completing Issues
When finishing work on any GitHub issue or sprint:
1. Create a feature branch if not already on one
2. Commit all changes with a descriptive message
3. Push to remote
4. **Run `/pr` skill** to create the pull request, run tests, monitor CI, and merge

Never leave completed work uncommitted or without a PR.

## Architecture
See `ARCHITECTURE.md` for DDD patterns, layer responsibilities, and coding conventions.

## GitHub Issues
See `GITHUB_ISSUES.md` for the project backlog organized by sprint.

## Testing
- Run `flutter test` for unit tests
- Run `flutter analyze` for static analysis
- All tests must pass before creating PRs
