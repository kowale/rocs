path:

with builtins;

# TODO: expose this in flake

let
    outputs = getFlake (toString ./.);

    site = outputs.packages."x86_64-linux".default;

    doc = site.mdToHtml {

        content = ''
            # Hellooo

            Hiiiii
        '';

        dir = "some/where";
        name = "there.html";
    };

in
    site.overrideAttrs (final: prev: {
        paths = prev.paths ++ [ doc ];
    })

