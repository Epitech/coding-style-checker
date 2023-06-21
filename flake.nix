{
  description = "Print EPITECH's coding style compliance report";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ruleset.url = "git+ssh://git@github.com/Epitech/banana-coding-style-checker.git";
    ruleset.flake = false;
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, ruleset, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem
      (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        rec {
          packages = flake-utils.lib.flattenTree rec {
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
                | ${pkgs.banana-vera}/bin/vera++ \
                --profile epitech             \
                --root ${ruleset}/vera        \
                --error                       \
                2>&1                          \
                | sed "s|$project_dir/||"     \
                | tee /dev/stderr | wc -l
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

          apps.report.type = "app";
          apps.report.program = "${packages.report}/bin/cs";
          apps.default = apps.report;
        });
}

