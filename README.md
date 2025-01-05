# Rocs

Really silly docs and/or static site generator (SSG) in Nix.

## Render in a headless web browser

Each source file is rendered to HTML
by opening a template (see `lib/mdToHtml.nix`)
in a headless Chromium, in a Nix build sandbox.
It works surprisingly well, apart from all the horrors.
The final result contains no JS whatsoever,
including for highlight.js and KaTeX.
To avoid heavy re-rendering of all files on any change,
source files are evaluated into independent derivations
using forbidden magic of `unsafeDiscardStringContext`.

Directory structure mirrors that of the repository,
For example, `docs/hello.md` is rendered to `docs/hello.html`.
`README.html` is duplicated to `index.html` for every level.
If you need auto-discovered page index, do so in pre-commit.

> I would like to render with Firefox/Gecko
> but I couldn't get it to work :( Soon TM

## Dependencies served at `/nix/store`

Dependencies defined in `./lib/imports.nix`
are vendored at `/nix/store`
(that is, copied to `$out/nix/store`).
This includes both runtime CSS or images
and build JS (not pulled in final HTML).

## Build environment served at `/_`

Naturally, build environment is shipped as well, why not.
Template is instructed to not remove its build logic,
and rendered paths are prepended with an underscore (`_`).
For example, `docs/hello.md` goes to `docs/_/hello.html`.
In particular, all paths can be "edited" by adding `_` in URL.

## Usage

To build this repository directly

```
nix build github:kowale/rocs -vv -L
```

You can then open `result/index.html` in a browser,
or serve with `python -m http.server -d result`.
`result` is a symlink, so need `tar` to get real files

```
tar czfh result.tar.gz result/
```

A minimal flake for your repository could be

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
        packages.${system}.docs = rocs.lib.buildSite {
            inherit pkgs;
            root = ./.;
        };
    }
}
```

