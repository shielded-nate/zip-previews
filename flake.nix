{
  description = "ZIPomatic – render ZIPs from multiple repositories/branches to GitHub Pages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    multimarkdown6 = {
      url = "github:zcash/MultiMarkdown-6/543434c9df78b6be9e8125ff19a5e6934dc8ba82";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      multimarkdown6,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        mmd = multimarkdown6.packages.${system}.default;

        # Pin docutils and rst2html5 to the versions used by zcash/zips.
        docutils = pkgs.python3Packages.docutils.overridePythonAttrs (old: rec {
          version = "0.21.2";
          src = pkgs.fetchPypi {
            pname = "docutils";
            inherit version;
            hash = "sha256-OmsYcy7fGC2qPNEndbuzOM9WkUaPke7rEJ3v9uv6mG8=";
          };
        });

        rst2html5 = pkgs.python3Packages.buildPythonPackage rec {
          pname = "rst2html5";
          version = "2.0.1";
          pyproject = true;

          src = pkgs.fetchPypi {
            inherit pname version;
            hash = "sha256-MJmYyF+rAo8vywGizNyIbbCvxDmCYueVoC6pxNDzKuk=";
          };

          build-system = [ pkgs.python3Packages.poetry-core ];

          dependencies = [
            docutils
            pkgs.python3Packages.genshi
            pkgs.python3Packages.pygments
          ];

          postInstall = ''
            cp rst2html5_.py $out/${pkgs.python3.sitePackages}/
          '';

          doCheck = false;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            # Rendering tools required by forks' render.sh / Makefile
            rst2html5
            pkgs.python3Packages.pygments
            pkgs.pandoc
            mmd
            pkgs.perl

            # Build tooling
            pkgs.gnumake
            pkgs.git

            # Python (used by render-to-gh-pages.sh for index.html generation
            # and by forks' links_and_dests.py)
            pkgs.python3
            pkgs.python3Packages.beautifulsoup4
            pkgs.python3Packages.html5lib
            pkgs.python3Packages.certifi

            # Standard shell utilities
            pkgs.bash
            pkgs.coreutils
            pkgs.gnused
            pkgs.gnugrep
            pkgs.findutils
          ];

          shellHook = ''
            echo "ZIPomatic rendering environment"
            echo ""
            echo "Run ./render-to-gh-pages.sh to render all fork ZIPs and publish to gh-pages."
          '';
        };
      }
    );
}
