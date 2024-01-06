{ root, pkgs }:

with builtins;

let

    # This is the internal implementation of tree walking
    # Returns a nested attrset with derivations for each file,
    # which are expected to be extracted and built somewhow.
    walkTree = { path, root, nameFilter, fileToDrv }: let

        children = readDir path;
        mkPath = k: "${path}/${k}";
        whenDir = k: walkTree { inherit root nameFilter fileToDrv; path = mkPath k; };
        whenFile = k:

            let

                # Read content at evaluation to avoid pulling whole tree as dependency
                content = readFile (mkPath k);

                # Remove context from string to avoid pulling whole tree as dependency
                dir = unsafeDiscardStringContext (
                    replaceStrings
                    [ "${root}" ]
                    [ "" ]
                    (toString path)
                );

                _k = substring 0 (sub (stringLength k) 3) k;

            # Return a derivation
            in fileToDrv { inherit content dir; name = "${_k}.html"; };

    in

        mapAttrs (

            k: v:

                # Recurse into directories
                if (v == "directory")
                then whenDir k
                else

                    # Terminate on files
                    if ( v == "regular")
                    && nameFilter k
                    then whenFile k
                    else null

        ) children;

    # Implementation of fileToDrv
    mdToHtml = import ./mdToHtml.nix { inherit pkgs; };

    # Utility to filter by file extensions
    hasExtension = ext: k: match "(.*?).${ext}" k != null;

    # Utility for checking if attrset is a derivation
    isDerivation = attr: attr ? type && attr.type == "derivation";

    # An example of putting it all together
    # TODO: expose nameFilter and fileToDrv in flake
    buildSite = root: let

        tree = walkTree {
            inherit root;
            path = root;
            fileToDrv = mdToHtml;
            nameFilter = hasExtension "md";
        };

        # Extract directory derivations from the tree
        drvs = pkgs.lib.attrsets.collect isDerivation tree;

        # Fixed output derivations for assets like CSS and JS
        assets = let
            imports = pkgs.callPackage ./imports.nix {};
        in
            map (
                # Need to turn files into dirs with files
                # TODO: make this a little less terrible
                # Maybe at least inline external CSS in static
                file: pkgs.runCommand "linkAssets" {} ''

                    mkdir -p $out/nix/store
                    cp -r ${file.outPath} $out/nix/store

                ''
            ) (pkgs.lib.attrsets.collect isDerivation imports);


        # Put them all as symlinks in one directory
        # Requires the derivations to be directories
        in pkgs.symlinkJoin {
            name = "all";
            paths = drvs ++ assets;
        };

    site = buildSite root;

in

    # Returns a mirrored root directory tree, but with HTML instead of Md
    # Also adding mdToHtml for editing inside a Nix repl! See editSite.nix
    site // { inherit mdToHtml; }

