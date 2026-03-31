---
name: kopi-release
description: Prepare, publish, and verify releases for the Kopi app repository. Use when asked to bump a Kopi version, write or update Kopi release notes, create a Kopi git tag, publish a Kopi release, rerun the Kopi release workflow, or fix the body/title/assets of a workflow-generated GitHub release.
---

# Kopi Release

Prepare Kopi releases in the repository root. Treat the GitHub Actions `Release` workflow as the source of truth for the GitHub release object and DMG asset.

## Workflow

1. Inspect release state before changing anything.
   - Check `git status --short`.
   - Check `.github/workflows/release.yml`.
   - Check the latest release body when formatting is ambiguous:
     - `gh release view --json body` (latest) or `gh release view vX.Y.Z --json body`

2. Prepare release metadata first.
   - Update the version in Xcode: open `Kopi/Kopi.xcodeproj`, select the Kopi target > General > Version and Build.
   - Alternatively, update `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `Kopi/Kopi.xcodeproj/project.pbxproj` directly.
   - Update `CHANGELOG.md`.
   - Create or update `docs/releases/notes/X.Y.Z.md`.
   - If the release needs planning notes, keep them in `docs/releases/plans/X.Y.Z.md`.

3. Write release notes using the Kopi format.
   - Read `references/release-format.md`.
   - Keep the title, intro paragraph, horizontal rule, `###` sections, and install block style consistent.

4. Verify before publishing when code changed.
   - Run `xcodebuild -project Kopi/Kopi.xcodeproj -scheme Kopi -configuration Debug -destination 'platform=macOS' build`.
   - Run `xcodebuild -project Kopi/Kopi.xcodeproj -scheme Kopi -configuration Debug -destination 'platform=macOS' -only-testing KopiTests test`.

5. Publish in this order.
   - Commit the release changes.
   - Create an annotated tag: `git tag -a vX.Y.Z -m "Kopi X.Y.Z"`.
   - Push `main`.
   - Push the tag.

6. Do not manually create the GitHub release.
   - Pushing the tag triggers `.github/workflows/release.yml`.
   - Wait for the workflow to finish and create the DMG plus release object.
   - Use `gh run list` or `gh run watch <run-id>` to monitor it.

7. After the workflow-created release exists, apply the curated notes.
   - Run:
     - `gh release edit vX.Y.Z --title "Kopi X.Y.Z" --notes-file docs/releases/notes/X.Y.Z.md`
   - Verify:
     - `gh release view vX.Y.Z --json name,body,url,assets`
   - Confirm the DMG asset name matches `Kopi-vX.Y.Z.dmg`.

## Recovery

If someone manually created the release before the workflow:

1. Delete the manual release:
   - `gh release delete vX.Y.Z --yes`
2. Rerun the tag-triggered `Release` workflow.
3. Wait for it to recreate the release and asset.
4. Reapply the curated title and notes with `gh release edit`.

## Finish

- Report the release URL.
- Report the workflow run URL when relevant.
- Confirm whether the working tree is clean.
