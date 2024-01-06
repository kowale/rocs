# This is an implementation of fileToDrv
# content is raw string of what's inside the file
# name is the target name like "thing.html"
# dir is the target location like "some/where"
# Returns derivation for "some/where/thing.html"

{ pkgs }:

{ content, name, dir }:

let

    css = ''
        html {
            background: #fff;
        }


        body {
            line-height: 1.5;
            margin: 0 auto;
            padding: 1em;
            font-family: sans-serif;
        }

        pre {
            overflow-x: auto;
        }

        img {
            max-width: 100%;
            margin: 0 auto;
            display: block;
        }

        footer {
            padding-top: 1em;
            text-align: center;
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

        .vertical {
            width: 100%;
            height: 100em;
        }
    '';

    iconSvgXml = ''
        <svg
            xmlns=%22http://www.w3.org/2000/svg%22
            viewBox=%220 0 100 100%22
        >
        <text y=%22.9em%22 font-size=%2290%22>🎒</text>
        </svg>
    '';

    # TODO: add sha384 of files to their integrity field
    imports = pkgs.callPackage ./imports.nix {};

    htmlTemplate = content: cleanUp: ''

        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta http-equiv="content-type" content="text/html; charset=utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
        <link rel="icon" href="data:image/svg+xml,${iconSvgXml}">
        <title></title>

        <link rel="stylesheet" href="${imports."sunburst.min.css".outPath}">
        <link rel="stylesheet" href="${imports."katex".outPath}/katex.min.css">

        <style>
        ${css}
        </style>
        </head>
        <body>
        <div class="container">
        <textarea ${if cleanUp then "hidden" else ""} type="text/markdown" id="content-md">
        ${content}
        </textarea>
        <div id="content-html"></div>
        </div>
        <footer>Built with <a href="https://github.com/kowale/rocs">rocs</a></footer>

        ${if cleanUp then "" else ''<div class="vertical"></div>''}

        <script id="hl-load" src="${imports."highlight.min.js".outPath}"></script>
        <script id="katex-load" src="${imports."katex".outPath}/katex.min.js"></script>
        <script id="katex-auto-render-load" src="${imports."katex".outPath}/contrib/auto-render.min.js"></script>
        <script id="cmark-load" src="${imports."commonmark.min.js".outPath}"></script>
        <script id="hl-nix-load" src="${imports."nix.min.js".outPath}"></script>

        <script id="effect">

            const reader = new commonmark.Parser({smart: true})
            const writer = new commonmark.HtmlRenderer({ softbreak: " " })

            const effect = () => {

                console.log("Running effect")

                const content = document.querySelector("#content-md").value
                const parsed = reader.parse(content)
                const rendered = writer.render(parsed)

                document.querySelector("#content-html").innerHTML = rendered
                const firstHeading = document.querySelector("#content-html").querySelector("h1")
                document.title = firstHeading.innerText

                hljs.highlightAll()

                renderMathInElement(
                    document.body,
                    {
                        delimiters: [
                            {left: "$$", right: "$$", display: true},
                            {left: "$", right: "$", display: false},
                        ],
                        throwOnError: true
                    }
                )
            }

            effect()

            if (${if cleanUp then "false" else "true"}) {
                setInterval(effect, 500)
            }
        </script>

        <script id="clean-up">
            <!-- Clean up -->
            if (${if cleanUp then "true" else "false"}) {
                document.querySelector("#effect").remove()
                document.querySelector("#content-md").remove()
                document.querySelector("#cmark-load").remove()
                document.querySelector("#hl-nix-load").remove()
                document.querySelector("#hl-load").remove()
                document.querySelector("#katex-auto-render-load").remove()
                document.querySelector("#katex-load").remove()
                document.querySelector("#clean-up").remove()
            }
        </script>
        </body>
        </html>
    '';

in

    pkgs.stdenv.mkDerivation {

        inherit content name dir;

        ir = htmlTemplate content false;
        irClean = htmlTemplate content true;

        # Stop asking cache for builds
        allowSubstitutes = false;

        # Content may be too big for env
        passAsFile = [ "content" "ir" "irClean" ];

        nativeBuildInputs = with pkgs; [
            chromium
        ];

        # Chromium reads impure location at runtime
        FONTCONFIG_FILE="${pkgs.fontconfig.out}/etc/fonts/fonts.conf";
        FONTCONFIG_PATH="${pkgs.fontconfig.out}/etc/fonts/";

        buildCommand = ''

            mkdir -p $out/dynamic/$dir
            mkdir -p $out/static/$dir

            cp $irPath ir.html
            cp $irCleanPath irClean.html

            cp ir.html $out/dynamic/$dir/$name

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
                irClean.html > $out/static/$dir/$name

        '';
    }
