{
  description = "Print EPITECH's coding style compliance report";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    vera-fork.url = "github:Epitech/banana-vera";
    vera-fork.flake = false;
    ruleset.url = "git+ssh://git@github.com/Epitech/banana-coding-style-checker.git";
    ruleset.flake = false;
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, vera-fork, ruleset, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem
      (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        rec {
          packages = flake-utils.lib.flattenTree rec {
            vera = pkgs.stdenv.mkDerivation {
              pname = "vera++";
              version = "1.3.0";

              src = vera-fork;

              nativeBuildInputs = [ pkgs.cmake ];
              buildInputs = [
                pkgs.python3
                (pkgs.boost.override { enablePython = true; python = pkgs.python3; })
                pkgs.tcl
              ];

              cmakeFlags = [
                "-DVERA_LUA=OFF"
                "-DVERA_USE_SYSTEM_BOOST=ON"
                "-DPANDOC=OFF"
              ];
            };
            report = (pkgs.writeShellScriptBin "cs" ''
              start_time=$(date +%s)

              if [ -z "$1" ]; then
                  project_dir=$(pwd)
              else
                  project_dir="$1"
              fi

              echo "Running norm in $project_dir"
              count=$(find "$project_dir"     \
                -type f                       \
                -not -path "*/.git/*"         \
                -not -path "*/.idea/*"        \
                -not -path "*/.vscode/*"      \
                -not -path "bonus/*"          \
                -not -path "tests/*"          \
                -not -path "/*build/*"        \
                | ${packages.vera}/bin/vera++ \
                --profile epitech             \
                --root ${ruleset}/vera        \
                --error                       \
                2>&1                          \
                | sed "s|$project_dir/||"     \
                | tee /dev/stdout | wc -l
              )
              
              echo "Found $count issues"
              end_time=$(date +%s)
              echo "Ran in $((end_time - start_time))s"
              if [ $count -gt 0 ]; then
                  exit 1
              fi
              exit 0
            '');
            default = report;
          };

          apps.vera.type = "app";
          apps.vera.program = "${packages.vera}/bin/vera++";

          apps.report.type = "app";
          apps.report.program = "${packages.report}/bin/cs";
          apps.default = apps.report;
        });
}

