{ lib, writeText, fetchurl, fetchzip, runCommand, writers }:

# TODO: compute sha384 automatically and include it in integrity tags in JS

let

    isDerivation = attr: attr ? type && attr.type == "derivation";

    imports = {
        "commonmark.min.js" = fetchurl {
            url = "https://cdn.jsdelivr.net/npm/commonmark@0.30.0/dist/commonmark.min.js";
            hash = "sha256-cD2xuX9OMhddLCJbtZuKlUzmGZLYw5r5RvVbXbg5rrg=";
        };

        "highlight.min.js" = fetchurl {
            url = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.7.0/highlight.min.js";
            hash = "sha256-nxnOvB1EQa4fD/xpakJii5+GX+XZne2h8ejNW+yHiIg=";
        };

        "nix.min.js" = fetchurl {
            url = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.7.0/languages/nix.min.js";
            hash = "sha256-LXIWEQkYROqA3pp/1pDGE2xjV/FXwPNu31MNs5WIDaA=";
        };

        "sunburst.min.css" = fetchurl {
            url = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.7.0/styles/sunburst.min.css";
            hash = "sha256-qGnQxbNlKCkWnK1Id+F6TjMlICugQxiYTEd0pHPcKzE=";
        };

        "live.js" = fetchurl {
            url = "https://livejs.com/live.js";
            hash = "sha256-IWoV9K31CrpyoyNuuhaX04CMMbtqXyrFtOCW/FU/Is4=";
        };

        katex = fetchzip {
            url = "https://github.com/KaTeX/KaTeX/releases/download/v0.16.9/katex.tar.gz";
            hash = "sha256-Nca52SW4Q0P5/fllDFQEaOQyak7ojCs0ShlqJ1mWZOM=";
        };

        "style.css" = writeText "style.css" ''
            /*
            TODO: clean-up
            https://www.joshwcomeau.com/css/custom-css-reset/
            https://piccalil.li/blog/a-more-modern-css-reset/
            */

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

            /*
            body, h1, h2, h3, h4, p,
            figure, blockquote, dl, dd {
              margin-block-end: 0;
            }
            */

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

            nav {
              max-width: 35em;
              margin: 0 auto;
            }

            /* https://www.reasonable.work/colors/#colors */

            * {
              --c1: #f7f1ff;
              --c2: #e2e2e2;
              --c3: #0094b4;
              --c4: #007590;
              --c5: #3e3e3e;
              --c6: #222222;
            }

            body {
              color: var(--c2);
              background: var(--c5);
            }

            a {
              color: var(--c1);
              text-decoration: underline;
            }

            a:hover {
              color: var(--c5);
              background: var(--c1);
              text-decoration: none;
            }

            textarea {
              color: var(--c1);
              background: var(--c6);
            }

            blockquote {
              color: var(--c1);
              background: var(--c6);
            }

            blockquote > p {
              padding: 1em;
            }

            pre > code {
              font-family: monospace !important;
              background: var(--c6) !important;
            }

            /* TODO: integrate with above */

            body {
                color: var(--c2);
                background: var(--c6);
                font-family: sans-serif;
            }

            code {
                font-size: 1.2em;
                color: var(--c1);
            }

            textarea {
              font-size: 1.2em;
              font-family: monospace;
              color: var(--c1);
              background: var(--c5);
            }

            blockquote {
              color: var(--c1);
              background: var(--c5);
              border-left: 0.5em solid var(--c2);
              margin: 0;
              margin-left: 1em;
            }

            blockquote > p {
              padding: 0.5em;
            }

            pre > code {
              background: black !important;
            }

            a {
              color: var(--c1);
              text-decoration: underline var(--c2) 1px;
              word-break: break-word;
              word-wrap: break-word;
            }

            a:hover {
              color: var(--c5);
              background: var(--c1);
              text-decoration: none;
            }

            table, th, td {
              border: 1px solid;
              padding: 1px;
              text-align: center;
            }

            ul, ol {
              margin: 0;
              padding-left: 0em;
              margin-left: 2em;
            }

        '';
    };

    linkedImports = map (
        # Need to turn files into dirs with files
        # TODO: make this a little less terrible
        # Maybe at least inline external CSS in static
        file: runCommand "linkImports" {} ''

            mkdir -p $out/nix/store
            cp -r ${file.outPath} $out/nix/store

        ''
    ) (lib.attrsets.collect isDerivation imports);

    linkSelf = (runCommand "linkSelf" {} ''
        mkdir -p $out/nix/store
        cp -r ${
            (writers.writeJSON "imports.json" imports).outPath
        } $out/nix/store
    '') // { inherit imports; };

in

    [ linkSelf ] ++ linkedImports

