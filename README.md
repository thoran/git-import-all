# git-import-all

## Description

Turns a directory of numbered revisions into a git repository, one commit per revision, with each commit's message and date taken from the project's CHANGELOG.

It is for projects whose history predates their repository: where each version was kept as a numbered directory rather than as a commit, and that history is worth recovering rather than discarding.

For each revision in turn, `git-import-all`:

1. Clears the repository's contents (`rm -rf`), leaving dotfiles alone.
2. Copies in that revision's contents (`cp -r`).
3. Stages everything, removals included (`git add -A`).
4. Commits, taking the message and the date from the CHANGELOG entry at the same index.


## Installation

### 0. Have a recent version of Ruby installed

### 1. Manually

```shell
git clone https://github.com/thoran/git-import-all
cp ./git-import-all/bin/git-import-all to your preferred executable path
chmod +x /path/to/git-import-all
```


## Usage

Run it from within the repository, giving it the revisions root:

```shell
$ cd ~/path/to/repo
$ git-import-all ~/path/to/revisions/root/
```

The revisions root holds directories named `0`, `1`, `2` and so on, each a complete snapshot of the project at that point. Only numbered directories are taken as revisions: anything else in the revisions root, whether a stray file or a directory named otherwise, is passed over.

Where the repository does not exist yet, run `git-boot` first, so that the history begins from a parentless `.gitignore` commit and real work is never the root.

Dotfiles are left alone, the glob not matching them. A `.gitignore` therefore survives every revision, and stray `.DS_Store` files never enter the repository.


## Where the messages come from

The CHANGELOG is read from the highest numbered revision which has one, and its entries are matched to revisions **by position**: the oldest entry belongs to revision `0`, the next to revision `1`, and so on. Each commit message is the entry's version and summary; each commit's date is the entry's date.

Because the matching is positional, an entry too few or too many shifts every message below it onto the wrong revision, and each entry would still be perfectly well formed. The import therefore refuses to run unless the number of entries and the number of revisions agree.


## CHANGELOG formats

Entries are dispatched to a named format, and exactly one must match. Nothing matching, or more than one matching, stops the import rather than producing a plausible but wrong message. Two are recognised.

### 1. Dated heading

The date is the heading; the version and summary sit on the first line of the body:

```
## 20260726

0.2.0: Addressbook displaynames.

1. ~ CardDAV#addressbooks: now returns the filtered resources.
```

### 2. Versioned heading

The version appears in the heading itself, in any of its parenthesised, bracketed or dashed forms:

```
## 2.3.2 (20260418): Add Sequel examples to README.
## [0.19.0] - 2026-07-19, complete the fundamentals model wrapping
## 0.0.0 — 2026-04-04
```

Each version takes its own heading, even where two versions share a date.


## Related tools

`git-boot` creates the repository before the import, beginning it with a parentless `.gitignore` commit so that real work is never the root, and so remains rewritable later.

`changelogger` is needed only where a CHANGELOG is missing. It reads the `Changes:` blocks from each revision's script header, falling back to a structural diff where a revision has none, and writes a cumulative CHANGELOG into each revision directory. Its output is a starting point to be edited, not a finished record.

Once the history is in, neither this tool nor `changelogger` is needed again: subsequent work is ordinary commits, and the CHANGELOG is written directly.


## Bootstrapping

This repository's own history was produced by running `git-import-all` over its own revisions, on 6 August 2026: thirty-two commits spanning 2014 to 2026, from a tool which until then had never been used upon itself.

Its CHANGELOG was itself reconstructed. From 0.1.0 onward the entries came from the `Changes:` blocks in each revision's script header, which are the original record. For 0.0.0 to 0.0.14 no such blocks exist, those headers carrying only a name, a date and a version, so those entries were written from the diffs between consecutive revisions, which show a fortnight in May 2014 spent getting the copy-and-commit loop right.


## Contributing

1. Fork it: `https://github.com/thoran/git-import-all/fork`
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Create a new pull request


## License

MIT
