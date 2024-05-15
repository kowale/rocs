{ lib, fetchurl, fetchzip, runCommand, writers }:

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

