# Rocs

Rocs is an attempt at constructing
"reproducible while editable" docs,
powered by Nix and web browsers.

## Example

To add to your repository,
if you are using flakes

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

To build docs in this repository

```sh
nix build github:kowale/rocs -vv
```

The `result` is a symlink to the web root.
You can open `result/index.html` in a browser,
or serve it over HTTP.

```
python3 -m http.server 8000 -d result/
```

We can realise it with tar or cp
if we need real files to deploy.

```sh
tar czfh result.tar.gz result/
```

If you change one file,
only it will need a rebuild.

1. `/` - pure, minimal HTML and CSS (no JS)
2. `/_/` - side-by-side live editing (with JS)
3. `/nix/store` - dependencies and assets

## How does it work?

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

As mentioned, `/_/` stores
an intermediate HTML representation
that provides side-by-side live editing.
This can be useful for live demos,
contributions from non-technical people,
and debugging final HTML in `/`.
I would like to add fallback URLs as an importmap
so that if `/nix/store` is missing,
it will still render, impurely.

Going into a devShell of buildSide derivation
brings you into a shell with buildPhase.
REPL can be used to rebuild a page proper.
See /lib/editSite.nix for an example.

## Why web browsers?

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
Then I need to keep the container image,
and I can only compose them from a limited number of layers.

## Issues

On first run, sometimes I get this

```
README.html
[0608/155004.523967:ERROR:bus.cc(407)] Failed to connect to the bus: Failed to connect to socket /run/dbus/system_bus_socket: No such file or directory
[0608/155004.525476:ERROR:bus.cc(407)] Failed to connect to the bus: Failed to connect to socket /run/dbus/system_bus_socket: No such file or directory
[0608/155004.525516:ERROR:bus.cc(407)] Failed to connect to the bus: Failed to connect to socket /run/dbus/system_bus_socket: No such file or directory
Fontconfig error: No writable cache directories
Fontconfig error: No writable cache directories
Fontconfig error: No writable cache directories
Fontconfig error: No writable cache directories
[0608/155004.528611:INFO:config_dir_policy_loader.cc(118)] Skipping mandatory platform policies because no policy file was found at: /etc/chromium/policies/managed
[0608/155004.528627:INFO:config_dir_policy_loader.cc(118)] Skipping recommended platform policies because no policy file was found at: /etc/chromium/policies/recommended
[0608/155004.543066:WARNING:bluez_dbus_manager.cc(248)] Floss manager not present, cannot set Floss enable/disable.
Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...
[0608/155004.577461:WARNING:sandbox_linux.cc(436)] InitializeSandbox() called with multiple threads in process gpu-process.
127.0.0.1 - - [08/Jun/2024 15:50:04] "GET /irClean.html HTTP/1.1" 200 -
[0608/155004.693809:INFO:CONSOLE(8)] "Error parsing a meta element's content: ';' is not a valid key-value pair separator. Please use ',' instead.", source: http://0.0.0.0:8000/irClean.html (8)
127.0.0.1 - - [08/Jun/2024 15:50:04] "GET /nix/store/b47sgp0q2m2pqvavd9kisp1jnzpc8zzw-sunburst.min.css HTTP/1.1" 200 -
127.0.0.1 - - [08/Jun/2024 15:50:04] "GET /nix/store/45rfwqpr6mjkaj5a6i16zckzh9cg6byi-style.css HTTP/1.1" 200 -
127.0.0.1 - - [08/Jun/2024 15:50:04] "GET /nix/store/lg8sycxbp06f23jgb606xqgzh2jcpa37-source/katex.min.css HTTP/1.1" 200 -
127.0.0.1 - - [08/Jun/2024 15:50:04] "GET /nix/store/s3p5fx7x826q2n60ssbxv9gr29zqiymd-highlight.min.js HTTP/1.1" 200 -
127.0.0.1 - - [08/Jun/2024 15:50:04] "GET /nix/store/lg8sycxbp06f23jgb606xqgzh2jcpa37-source/katex.min.js HTTP/1.1" 200 -
127.0.0.1 - - [08/Jun/2024 15:50:04] "GET /nix/store/lg8sycxbp06f23jgb606xqgzh2jcpa37-source/contrib/auto-render.min.js HTTP/1.1" 200 -
127.0.0.1 - - [08/Jun/2024 15:50:04] "GET /nix/store/83hgh13grvg42rrljbrwfhfn1067i9kq-commonmark.min.js HTTP/1.1" 200 -
127.0.0.1 - - [08/Jun/2024 15:50:04] "GET /nix/store/j8wrxj09v5p1s8pvl9r340nyw31pkck3-nix.min.js HTTP/1.1" 200 -
[0608/155004.753192:INFO:CONSOLE(173)] "Running effect", source: http://0.0.0.0:8000/irClean.html (173)
```

Not sure which of these is the error,
as it seems different thread keeps logging
after the actual error is thrown.
Re-running the build fixes it forever.
Very weird, I'll try to make it single-threaded
and debug further :P

