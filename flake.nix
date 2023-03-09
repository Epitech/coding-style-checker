{
  description = "Print EPITECH's coding style compliance report";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    vera.url = "github:Epitech/banana-vera";
    vera.flake = false;
    ruleset.url = "git+ssh://git@github.com/Epitech/banana-coding-style-checker.git";
    ruleset.flake = false;
  };
  outputs = { self, nixpkgs, vera, ruleset, ... }@inputs:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in
    {
      packages.x86_64-linux.vera = pkgs.stdenv.mkDerivation {
        pname = "vera++";
        version = "1.3.0";

        src = vera;

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
      packages.x86_64-linux.report = pkgs.writeShellScriptBin "cs" ''
        start_time=$(date +%s%3N)

        if [ -z "$1" ]; then
            project_dir=$(pwd)
        else
            project_dir="$1"
        fi

        echo "Running norm in $project_dir"
        files=$(find "$project_dir"  \
            -type f                  \
            -not -path "*/.git/*"    \
            -not -path "*/.idea/*"   \
            -not -path "*/.vscode/*" \
            -not -path "bonus/*"     \
            -not -path "tests/*"     \
            -not -path "/*build/*"   \
        )

        echo "Checking $(echo $files | wc -w) files"
        # shellcheck disable=SC2046
        output=$(${self.packages.x86_64-linux.vera}/bin/vera++ \
            --profile epitech                                  \
            --root ${ruleset}/vera                             \
            -d $(echo "$files" | tr '\n' ' ')                  \
        )

        if [ -z "$output" ]; then
            echo "No issue found."
        else
            escaped_path=$(echo $project_dir | sed 's/\//\\\//g')
            echo "$output" | sed "s/$escaped_path\///g"
            echo "Found $(echo "$output" | grep -c "$") issues"
        fi
        end_time=$(date +%s%3N)
        echo "Ran in $((end_time - start_time))ms"
      '';
      packages.x86_64-linux.default = self.packages.x86_64-linux.report;

      apps.x86_64-linux.vera = {
        type = "app";
        program = "${self.packages.x86_64-linux.vera}/bin/vera++";
      };
      apps.x86_64-linux.report = {
        type = "app";
        program = "${self.packages.x86_64-linux.report}/bin/cs";
      };
      apps.x86_64-linux.default = self.apps.x86_64-linux.report;
    };
}

