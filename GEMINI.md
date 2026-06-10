# RailTrack Project Instructions

## Release & Versioning Workflow

- **Changelog Integrity:**
    - Maintain all pending changes in the `[Unreleased]` section of `CHANGELOG.md` during development.
    - Only move entries into a versioned section when performing an official remote release.
- **Build Management:**
    - Increment the **Build Number** (Project Version) for every build sent to the device for testing.
    - Only increment the **Version Number** (Marketing Version) when officially pushing changes to GitHub.
- **Authorization:**
    - **Pushing:** NEVER perform a `git push` without the explicit phrase **"TOOTHBRUSH"**.
