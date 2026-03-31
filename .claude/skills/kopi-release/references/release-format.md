# Kopi Release Notes Format

## Required shape

```md
## Kopi vX.Y.Z - Subtitle

**Kopi X.Y.Z** short introductory paragraph summarizing the release.

---

### Clipboard History
- ...

### Quick Panel
- ...

### Image Support
- ...

### Settings
- ...

### Quality
- ...

### Install
Download **Kopi-vX.Y.Z.dmg** below, open it, and drag Kopi to your Applications folder.
```

## Rules

- Keep the top heading at `##`.
- Keep the intro as one bold lead-in sentence or paragraph.
- Insert a horizontal rule `---` before the section list.
- Use `###` headings for sections.
- Use flat bullet lists under each section.
- Include only sections that have real content, but preserve the same overall tone and hierarchy.
- End with the `### Install` block.

## When in doubt

Inspect the latest release directly:

```bash
gh release view --json body
```
