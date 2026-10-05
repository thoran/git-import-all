# NOTES (for a future working session)

## git add -A silently drops gitignored files from the import

**The lack.** main()'s import loop does `git add -A`, which honours gitignore. Any
file present in a revision that matches a global (`~/.config/git/ignore`) or repo
ignore is therefore never staged and never committed — silently. The imported
history comes out *less complete than the revision directories it was built from*,
with nothing said.

**The context.** Importing the Browser library (0.10.0, this repo at v0.15.2), three
binary test fixtures — ChromiumBased_history.sqlite, FirefoxBased_places.sqlite,
Safari_history.sqlite — were dropped from every commit because a machine-wide
`*.sqlite` line in ~/.config/git/ignore matched them. The repo's tests passed only
because the working tree happened to still hold the untracked files; a fresh clone
would have failed. It was caught by chance, diffing a commit against its source
revision, not by the tool.

**The proposed fix.** An importer's job is to reproduce the revision directories
faithfully; ambient ignore rules are about working repos, not reconstructed history.
So:
  - `git add -A -f` in the import loop — force past ignores, capturing exactly what
    the revision holds. (Preferred.)
  - Or, less aggressive: `git add -A`, then report what gitignore skipped, so the
    silence becomes a visible line.

This is new behaviour, so a minor (0.16.0). Add a test: a revision containing a file
matching a gitignore pattern should still end up committed.
