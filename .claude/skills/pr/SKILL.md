---
name: pr
description: Create or update a pull request. Use when the user wants to create a PR, submit changes for review, or merge their work. Handles git operations, tests, CI monitoring, and PR creation.
---

# Create Pull Request

You are creating or updating a pull request. Follow these steps in order.

## Step 1: Check for Uncommitted Changes

Run `git status` to check for uncommitted changes. If there are changes:
- Stage and commit them with a clear, descriptive message
- Push to the remote branch

## Step 2: Review and Update Documentation

Check if any changes in this PR require documentation updates:
- New features or commands
- Changed setup/installation steps
- New environment variables or configuration
- API changes that affect usage
- Changes to ARCHITECTURE.md if architectural patterns changed

If updates are needed, make them and commit before proceeding.

## Step 3: Run Analysis and Tests

Run these checks and **ensure they pass**:

1. **Dart analysis**: Execute `flutter analyze` - no warnings or errors allowed
2. **Unit tests**: Execute `flutter test` - all tests must pass
3. **Build check**: Execute `flutter build apk --debug` to verify build works (Android)

**STOP if any checks fail.** Fix the failures and re-run until all pass. Do not proceed to PR creation with failing checks.

## Step 4: Create the PR

Once checks pass:

1. Push any remaining commits to the remote branch
2. Create the PR using `gh pr create` with:
   - Clear title describing the change
   - Description with:
     - Summary of changes
     - Related issue number (e.g., "Closes #1")
     - Test plan

## Step 5: Post-PR Review and Monitoring

After the PR is created, **actively monitor** and address feedback:

1. **Self code review**: Review the PR diff using `gh pr diff` and look for:
   - Code duplication that could be extracted (DRY principle)
   - Patterns that don't match ARCHITECTURE.md conventions
   - Missing error handling (Either types)
   - Domain logic leaking into wrong layers
   - Missing const constructors

   **Apply good refactoring opportunities** you identify. Add comments for any issues found.
2. **Wait for CI**: Monitor GitHub Actions for completion using `gh pr checks`
3. **Check for warnings**: Review action logs AND annotations for any warnings
4. **Monitor for AI reviews**: Actively poll for CodeRabbit and Copilot reviews to complete
   - Use `gh pr checks` - wait until reviews show complete
   - Use `gh pr view <number> --comments` to check for bot comments
   - Keep checking every 30-60 seconds until reviews are complete
5. **Address all comments immediately**: When comments appear:
   - Read each comment carefully
   - **If addressing**: Add a thumbs up reaction, then make the fix
   - **If not addressing**: Reply to the comment explaining why
   - Commit, push, and verify the fix resolves the comment
6. **Verify CI passes**: After all fixes, ensure all checks pass

**Do not stop monitoring until**: All AI reviews are complete, all comments are addressed, and CI is green.

## Step 6: Manual Testing (Required Before Merge)

Once CI is green and all comments are addressed:

1. **Notify the user**: Tell them to run `flutter run` and test the changes
2. **Wait for approval**: Do NOT merge until the user explicitly approves
3. **If feedback given**: Make fixes, commit, push, and repeat from Step 5
4. **If approved**: Proceed to merge with `gh pr merge --squash --delete-branch`

**Exception**: Skip manual testing for documentation-only PRs - merge immediately.
