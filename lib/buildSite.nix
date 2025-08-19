{ root, pkgs, rootDir ? "", local ? "", emoji ? "🎒", css ? "", js ? "" }:

with builtins;

let

  # This is the internal implementation of tree walking
  # Returns a nested attrset with derivations for each file,
  # which are expected to be extracted and built somewhow.
  walkTree = { path, root, nameFilter, fileToDrv }:
    let

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

          # TODO: generalise to more than .md lol
          nameWithoutMd = substring 0 (sub (stringLength k) 3) k;

          # Return a derivation
        in
        fileToDrv {
          inherit content rootDir dir;
          name = "${nameWithoutMd}.html";
        };

    in

    mapAttrs
      (

        k: v:

          # Recurse into directories
          if (v == "directory")
          then whenDir k
          else

          # Terminate on files
            if (v == "regular")
              && nameFilter k
            then whenFile k
            else null

      )
      children;

  # Utility to filter by file extensions
  hasExtension = ext: k: match "(.*?).${ext}" k != null;

  # Utility for checking if attrset is a derivation
  isDerivation = attr: attr ? type && attr.type == "derivation";

  # Add local dependecies/assets
  # Import paths relative to root
  # If you include the whole root,
  # you will lose atomic rebuilds per file
  # (as each file will depend on all other files)
  addLocal = path: pkgs.runCommand "addLocal" { } ''
    mkdir -p $out
    ${if path == "" then "echo cp" else "cp"} -r ${toString root}/${path} $out
  '';

  # Fixed output derivations
  imports = pkgs.callPackage ./imports.nix { };

  # Implementation of fileToDrv
  mdToHtml = import ./mdToHtml.nix { inherit pkgs root emoji css js; };

  # An example of putting it all together
  # TODO: expose nameFilter and fileToDrv in flake
  buildSite = root:
    let

      tree = walkTree {
        inherit root;
        path = root;
        fileToDrv = mdToHtml;
        nameFilter = hasExtension "md";
      };

      # Extract directory derivations from the tree
      drvs = pkgs.lib.attrsets.collect isDerivation tree;

      # Put them all as symlinks in one directory
      # Requires the derivations to be directories
    in
    pkgs.symlinkJoin {
      name = "all";
      paths = drvs ++ imports ++ [ (addLocal local) ];
    };

  site = buildSite root;

in

# Returns a mirrored root directory tree, but with HTML instead of Md
  # Also adding mdToHtml for editing inside a Nix repl! See editSite.nix
site // { inherit mdToHtml; }

