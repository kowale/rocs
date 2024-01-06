# Rocs

Rocs is an attempt at constructing
"reproducible while editable" docs,
powered by Nix and web browsers.

## Example

To build docs in this repository

```sh
nix build github:kowale/rocs -vv
```

Result is made of symlinks,
but we can realise it with tar or cp
if we need real files to deploy.

```sh
tar czfh result.tar.gz result/
```

Or we can serve files directly
from the Nix store in Python.

```sh
nix run github:kowale/rocs -L
```

Running these again will be instant,
thanks to flake evaluation caching.
If you change one file,
only it will need a rebuild.
Now, you can visit localhost:8985
to see three top-level directories.

1. /static --- pure, minimal HTML
2. /dynamic --- side-by-side live editing
3. /nix/store --- dependencies and assets

## How this works

Nix reads a Git repository at evaluation.
Each Markdown file becomes a derivation
addressed by its content and path.
I remove the string context from path
to avoid depending on the whole tree.
Otherwise changing a single file
rebuilds every other file.

You implement fileToDrv
that builds that one file.
For instance, run `cmark` on it.
The output should be a directory subtree
that contains the processed file.
For example, a/b/c.md becomes a/b/c.html.

As fileToDrv is a Nix expression,
it can do evaluation prior to build.
For instance, template Markdown into HTML
that renders itself with JavaScript.

The output is a derivation
that depends on all subtrees.
For instance, a symlink join
or a browser to render DOM
and evaluate JavaScript.

## Live preview

As mentioned, /dynamic stores
an intermediate HTML representation
that provides side-by-side live editing.
This can be useful for live demos,
contributions from non-technical people,
and debugging final HTML in /static.
I would like to add fallback URLs as an importmap
so that if /nix/store is missing,
it will still render, impurely.

Going into a devShell of buildSide derivation
brings you into a shell with buildPhase.
REPL can be used to rebuild a page proper.
See /lib/editSite.nix for an example.

## Why browsers?

Browsers are great at manipulating the DOM.
It's easy to save the final DOM with a headless browser.
High-quality libraries like CommonMark, Highlight, or KaTeX
are already implemented and tested for browser JavaScript.
They sometimes run in Node or Deno, but not really.

## Why Nix?

Nix is great at specifying build dependencies
such that they are truly reproducible
and don't break over time.
If I depend on Chromium in Nix,
it will build or substitute
a concrete snapshot of every input,
down to libc, in a strong sandbox.

If I depend on Chromium in Docker,
I get a binary blob with no context,
dynamically linked to some arbitrary stuff,
which image maintainer carefully arranged
with imperative apt-get incantations.
It may be repeatable for a few months,
but will eventually stop building.
Then I need to keep the container image.
And mind you, there is virtually no deduplication between images.
There are layers, but there can be only 42.

