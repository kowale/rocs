/*

This file implements fileToDrv used in buildSite.
Returns a derivation for a composable subtree.
Suppose we want to render ./some/thing.md
to kowale.github.io/rocs/some/thing.html

- `content` is text of ./some/thing.md/
- `rootDir` is where we deploy - rocs/
- `dir` is target location - some/
- `name` is target file name - thing.html

*/

{ pkgs, root, emoji ? "🎒", css ? "" }:

{ content, rootDir, dir, name }:

let

    defaultCss = ''

        /*
        https://www.joshwcomeau.com/css/custom-css-reset/
        https://piccalil.li/blog/a-more-modern-css-reset/
        */

        html {
          --text-color-normal: #0a244d;
          --text-color-light: #8cabd9;
        }

        html[data-theme='dark'] {
          --text-color-normal: hsl(210, 10%, 62%);
          --text-color-light: hsl(210, 15%, 35%);
          --text-color-richer: hsl(210, 50%, 72%);
          --text-color-highlight: hsl(25, 70%, 45%);
        }

        *, *::before, *::after {
          box-sizing: border-box;
        }

        #root, #__next {
          isolation: isolate;
        }

        img, picture, video {
          max-width: 100%;
          margin: 0 auto;
          display: block;
        }

        input, button, textarea, select {
          font: inherit;
        }

        p, h1, h2, h3, h4, h5, h6 {
          overflow-wrap: break-word;
        }

        html {
          -moz-text-size-adjust: none;
          -webkit-text-size-adjust: none;
          text-size-adjust: none;
        }


        body, h1, h2, h3, h4, p,
        figure, blockquote, dl, dd {
          margin-block-end: 0;
        }

        ul[role='list'],
        ol[role='list'] {
          list-style: none;
        }

        h1, h2, h3, h4,
        button, input, label {
          line-height: 1.1;
        }

        h1, h2,
        h3, h4 {
          text-wrap: balance;
        }

        input, button,
        textarea, select {
          font-family: inherit;
          font-size: inherit;
        }

        textarea {
          overflow-y: scroll !important;
          resize: none;
        }

        textarea:not([rows]) {
          min-height: 10em;
          padding: 0.5em;
          margin: 0.5em;
        }

        :target {
          scroll-margin-block: 5ex;
        }

        body {
            line-height: 1.5;
            min-height: 100vh;
            margin: 0 auto;
            padding: 1em;
            font-family: sans-serif;
        }

        #content-md {
            flex: 1;
            width: 50%;
            max-width: 35em;
            overflow: hidden;
            resize: none;
            border: 0;
        }

        #content-html {
            flex: 1;
            max-width: 35em;
            width: 50%;
        }

        .container {
            display: flex;
            flex-direction: row;
            justify-content: center;
            gap: 1em;
        }

    '';

    iconSvgXml = ''
        <svg
            xmlns=%22http://www.w3.org/2000/svg%22
            viewBox=%220 0 100 100%22
        >
        <text y=%22.9em%22 font-size=%2290%22>${emoji}</text>
        </svg>
    '';

    # TODO: add sha384 of files to their integrity field

    imports = (builtins.elemAt (pkgs.callPackage ./imports.nix {}) 0).imports;

    htmlTemplate = { content, rootDir, dir, name, cleanUp }: ''

        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="path" content="${rootDir}${dir}/${name}">
        <meta http-equiv="content-type" content="text/html">
        <meta name="viewport" content="width=device-width; initial-scale=1.0; user-scalable=yes">

        <!-- Generated with https://github.com/kowale/rocs -->

        <title></title>
        <link rel="icon" href="data:image/svg+xml,${iconSvgXml}">
        <link rel="stylesheet" href="${rootDir}${imports."sunburst.min.css".outPath}">
        <link rel="stylesheet" href="${rootDir}${imports."katex".outPath}/katex.min.css">
        <style>
        ${defaultCss}
        ${css}
        </style>
        </head>

        <body>
        <nav>
        <a href="${rootDir}/index.html">${emoji}</a>
        &mdash;
        <a href="${rootDir}${dir}/${name}">${rootDir}${dir}/${name}</a>
        ${if cleanUp then "&mdash;" else ""}
        <a href='${if cleanUp then "${rootDir}_${dir}/${name}" else ""}'>
        ${if cleanUp then "Edit" else ""}
        </a>
        </nav>
        <div class="container">
        <textarea type="text/markdown" id="content-md">
        ${content}
        </textarea>
        <div id="content-html"></div>
        </div>

        ${if cleanUp then ''
        <div style="width: 100%; height: 2em;"></div>
        '' else ''
        <div style="width: 100%; height: 20em;"></div>
        ''}

        ${let prefix = if cleanUp then "" else rootDir; in ''
        <script id="hl-load" src="${prefix}${imports."highlight.min.js".outPath}"></script>
        <script id="katex-load" src="${prefix}${imports."katex".outPath}/katex.min.js"></script>
        <script id="katex-auto-render-load" src="${prefix}${imports."katex".outPath}/contrib/auto-render.min.js"></script>
        <script id="cmark-load" src="${prefix}${imports."commonmark.min.js".outPath}"></script>
        <script id="hl-nix-load" src="${prefix}${imports."nix.min.js".outPath}"></script>
        ''}

        <script id="effect">

            const reader = new commonmark.Parser({smart: true})
            const writer = new commonmark.HtmlRenderer({ softbreak: " " })

            const effect = () => {

                console.log("Running effect")

                // Render CommonMark to HTML
                const content = document.querySelector("#content-md").value
                const parsed = reader.parse(content)
                const rendered = writer.render(parsed)
                document.querySelector("#content-html").innerHTML = rendered

                // Set title from <h1>
                const firstHeading = document.querySelector("#content-html").querySelector("h1")
                if (firstHeading != null) {
                    document.title = firstHeading.innerText
                }

                // Add section anchors
                document.querySelectorAll("h2").forEach( ( h ) => {
                    h.id = h.innerText
                        .toLowerCase()
                        .trim()
                        .normalize('NFD').replace(/[\u0300-\u036f]/g, "")
                        .replace(/[^a-z0-9\s-]/g, ' ').trim()
                        .replace(/[\s-]+/g, '-')
                } )

                // Replace all links to .md with links to .html
                document.querySelectorAll("a").forEach( ( a ) => { a.href = a.href.replace(".md", ".html") } )

                // Highlight
                hljs.configure({ languages: [ "plaintext" ] })
                hljs.highlightAll()

                // KaTeX
                renderMathInElement(
                    document.body,
                    {
                        delimiters: [
                            {left: "$$", right: "$$", display: true},
                            {left: "$", right: "$", display: false},
                            {left: "\\begin{CD}", right: "\\end{CD}", display: true},
                        ],
                        throwOnError: true
                    }
                )
            }

            effect()

            // Refresh every 500ms for live editing
            // "onchange" events only apply after focus is off
            // TODO: use something nicer like CodeMirror
            if (${if cleanUp then "false" else "true"}) {
                setInterval(effect, 500)
            }

            if (${if cleanUp then "true" else "false"}) {

                // Clean up everything
                document.querySelector("#content-md").remove()
                document.querySelector("#cmark-load").remove()
                document.querySelector("#hl-nix-load").remove()
                document.querySelector("#hl-load").remove()
                document.querySelector("#katex-auto-render-load").remove()
                document.querySelector("#katex-load").remove()
                document.querySelector("#effect").remove()

            }
        </script>

        </body>
        </html>
    '';

    importsJoin = pkgs.symlinkJoin { name = "imports"; paths = (pkgs.callPackage ./imports.nix {}); };

in

    pkgs.stdenv.mkDerivation {

        inherit name content rootDir dir importsJoin;

        ir = htmlTemplate { inherit content rootDir dir name; cleanUp = false; };
        irClean = htmlTemplate { inherit content rootDir dir name; cleanUp = true; };

        # Stop asking cache for builds
        allowSubstitutes = false;

        # Content may be too big for env
        passAsFile = [ "content" "ir" "irClean" "importsJoin" ];

        # TODO: firefox
        nativeBuildInputs = with pkgs; [ chromium ];

        # Chromium reads impure location at runtime
        FONTCONFIG_FILE="${pkgs.fontconfig.out}/etc/fonts/fonts.conf";
        FONTCONFIG_PATH="${pkgs.fontconfig.out}/etc/fonts/";

        buildCommand = ''
            set -eou pipefail

            echo $dir $name

            mkdir -p $out/$dir
            mkdir -p $out/_/$dir

            cp $irPath ir.html
            cp $irCleanPath irClean.html
            cp ir.html $out/_/$dir/$name

            ln -s ${toString importsJoin}/nix nix

            ${pkgs.python3}/bin/python3 -m http.server 8000 &

            chromium \
                --no-first-run \
                --no-default-browser-check \
                --user-data-dir=/tmp/chrome-data \
                --disable-extensions \
                --disable-background-networking \
                --disable-background-timer-throttling \
                --disable-backgrounding-occluded-windows \
                --disable-renderer-backgrounding \
                --disable-breakpad \
                --disable-client-side-phishing-detection \
                --disable-crash-reporter \
                --disable-default-apps \
                --disable-dev-shm-usage \
                --disable-device-discovery-notifications \
                --disable-namespace-sandbox \
                --disable-translate \
                --autoplay-policy=no-user-gesture-required \
                --no-sandbox \
                --no-zygote \
                --enable-webgl \
                --disable-dev-shm-usage \
                --disable-gl-drawing-for-tests \
                --hide-scrollbars \
                --mute-audio \
                --no-first-run \
                --disable-infobars \
                --disable-breakpad \
                --disable-setuid-sandbox \
                --disable-features=site-per-process \
                --disable-mobile-emulation \
                --ignore-certificate-errors \
                --disable-web-security \
                --headless \
                --disable-gpu \
                --dump-dom \
                http://0.0.0.0:8000/irClean.html | ${pkgs.sd}/bin/sd 'http://0.0.0.0:8000' "" > tmp

                # Mysteriously Chromium sometimes returns only <html><body></body></html>
                if (( $(cat tmp | wc -c) < 100 )); then
                    exit 1
                fi

                cat tmp > $out/$dir/$name
                ${if (dir == "" && name == "README.html") then "
                    cat tmp > $out/index.html
                " else "" }
                kill $!
        '';
    }
