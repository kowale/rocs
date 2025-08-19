# Rocs

Really silly docs/blog/whatever static site generator (SSG) in Nix.

## Usage

An example deployment of this repository

```
pushd $(mktemp -d)
nix build github:kowale/rocs -vv -L
python -m http.server -d result
popd
```

A minimal flake example (see flake.nix for more)

```nix
{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        rocs.url = "github:kowale/rocs";
    };
    outputs = { self, nixpkgs, rocs, ... } @ inputs:
    let
        system = "x86_64-linux";
        pkgs = import nixpkgs { inherit system; };

    in {
        packages.${system}.default = rocs.lib.buildSite {
            inherit pkgs;
            root = self.outPath;
        };
    }
}
```

## How does it work

### Render in a headless web browser

Each source file is rendered to HTML
by opening a template (see lib/mdToHtml.nix)
in a headless Chromium, in a Nix build sandbox.
It works surprisingly well, apart from all the horrors.
The final result contains no JS whatsoever,
including for highlight.js and KaTeX.
To avoid heavy re-rendering of all files on any change,
source files are evaluated into independent derivations
using forbidden magic of `unsafeDiscardStringContext`.

```nix
# Remove context from string to avoid pulling whole tree as dependency
dir = unsafeDiscardStringContext (
  replaceStrings
  [ "${root}" ]
  [ "" ]
  (toString path)
);
```

Directory structure mirrors that of the repository.
For example, hello.md is rendered to hello.html.
In an attempt to support directories,
README.html is copied to index.html, if it exists.
Need auto-discovered page index? Generate in pre-commit.

> I would like to render with Firefox/Gecko
> but I couldn't get it to work :( Soon TM

### Dependencies served at `/nix/store` path

Dependencies defined in `./lib/imports.nix`
are vendored at `/nix/store`
(that is, copied to `$out/nix/store`).
This includes both runtime CSS or images
and build JS (not pulled in final HTML).

### Build environment served at `/_`

Naturally, build environment is shipped as well, why not.
Template is instructed to not remove its build logic,
and rendered paths are prepended with an underscore (`_`).
For example, `docs/hello.md` goes to `docs/_/hello.html`.
In particular, all paths can be "edited" by adding `_` in URL.

