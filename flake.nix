{
  description = "pleme-io workspace orchestration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    fleet = {
      url = "github:pleme-io/fleet";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, fleet, ... }:
    flake-utils.lib.eachSystem ["aarch64-darwin" "x86_64-linux" "aarch64-linux"] (system:
    let
      pkgs = import nixpkgs { inherit system; };
      fleetBin = "${fleet.packages.${system}.default}/bin/fleet";
      ws = "$PWD";

      mkApp = name: script: {
        type = "app";
        program = toString (pkgs.writeShellScript "ws-${name}" ''
          set -euo pipefail
          ${script}
        '');
      };

      fleetYaml = pkgs.writeText "workspace-fleet.yaml" ''{"flows":{"gem-publish-all":{"description":"Publish all pangea gems (DAG order)","steps":[{"action":{"command":"cd pangea-core && gem build pangea-core.gemspec && gem push pangea-core-*.gem","type":"shell"},"id":"pangea-core"},{"action":{"command":"cd pangea-aws && gem build pangea-aws.gemspec && gem push pangea-aws-*.gem","type":"shell"},"depends_on":["pangea-core"],"id":"pangea-aws"},{"action":{"command":"cd pangea-akeyless && gem build pangea-akeyless.gemspec && gem push pangea-akeyless-*.gem","type":"shell"},"depends_on":["pangea-core"],"id":"pangea-akeyless"},{"action":{"command":"cd pangea-kubernetes && gem build pangea-kubernetes.gemspec && gem push pangea-kubernetes-*.gem","type":"shell"},"depends_on":["pangea-core"],"id":"pangea-kubernetes"}]}}}'';

      mkFleetApp = flowName: mkApp "flow-${flowName}" ''
        cd ${ws}
        [ ! -f fleet.yaml ] && cp ${fleetYaml} fleet.yaml
        ${fleetBin} flow run ${flowName} "$@"
      '';

    in {
      apps = {
        # Git status across all repos
        git-status = mkApp "git-status" ''
          echo "Git status:"
          echo "--------------------------------------------"
          cd ${ws}
          for dir in */; do
            repo="''${dir%/}"
            if [ -d "$repo/.git" ]; then
              status=$(${pkgs.git}/bin/git -C "$repo" status --short 2>/dev/null)
              branch=$(${pkgs.git}/bin/git -C "$repo" branch --show-current 2>/dev/null)
              if [ -z "$status" ]; then
                printf "  %-30s %-10s clean\n" "$repo" "$branch"
              else
                lines=$(echo "$status" | wc -l | tr -d ' ')
                printf "  %-30s %-10s %s changed\n" "$repo" "$branch" "$lines"
              fi
            fi
          done
        '';

        # Update all repo flake.locks
        flake-update-all = mkApp "flake-update-all" ''
          echo "Updating flake.locks..."
          cd ${ws}
          for dir in */; do
            repo="''${dir%/}"
            if [ -d "$repo" ] && [ -f "$repo/flake.nix" ]; then
              echo "==> $repo"
              cd ${ws}/$repo && ${pkgs.nix}/bin/nix flake update 2>&1 | tail -1
            fi
          done
          echo "Done."
        '';

        # Update, commit, push all flake.locks
        flake-update-commit-push = mkApp "flake-update-commit-push" ''
          echo "Updating, committing, pushing flake.locks..."
          cd ${ws}
          for dir in */; do
            repo="''${dir%/}"
            if [ -d "$repo" ] && [ -f "$repo/flake.nix" ]; then
              cd ${ws}/$repo
              ${pkgs.nix}/bin/nix flake update 2>/dev/null
              changed=$(${pkgs.git}/bin/git status --short flake.lock 2>/dev/null)
              if [ -n "$changed" ]; then
                echo "==> $repo"
                ${pkgs.git}/bin/git add flake.lock
                ${pkgs.git}/bin/git commit -m "Update flake.lock" 2>/dev/null
                ${pkgs.git}/bin/git push origin main 2>/dev/null
              fi
            fi
          done
          echo "Done."
        '';

        # Run tests across all repos
        test-all = mkApp "test-all" ''
          echo "Running tests..."
          cd ${ws}
          failed=0
          for repo in pangea-architectures pangea-core pangea-aws; do
            if [ -d "$repo" ] && [ -f "$repo/flake.nix" ]; then
              echo "==> $repo"
              cd ${ws}/$repo && ${pkgs.nix}/bin/nix run .#test 2>/dev/null && echo "    passed" || { echo "    FAILED"; failed=$((failed + 1)); }
            fi
          done
          for repo in inspec-akeyless inspec-aws-k3s inspec-k3s-cis inspec-nixos-baseline; do
            if [ -d "$repo" ]; then
              echo "==> $repo"
              cd ${ws}/$repo && ${pkgs.ruby}/bin/ruby -Itest/unit -e "Dir.glob('test/unit/*_test.rb').each{|f| require File.expand_path(f)}" 2>/dev/null && echo "    passed" || { echo "    FAILED"; failed=$((failed + 1)); }
            fi
          done
          [ $failed -eq 0 ] && echo "All passed." || { echo "$failed FAILED."; exit 1; }
        '';

        # Build all pangea gems
        gem-build-all = mkApp "gem-build-all" ''
          echo "Building all pangea gems..."
          cd ${ws}
          for gem in pangea-core pangea-aws pangea-akeyless pangea-azure pangea-cloudflare pangea-datadog pangea-gcp pangea-hcloud pangea-splunk pangea-kubernetes; do
            if [ -d "$gem" ] && [ -f "$gem/$gem.gemspec" ]; then
              echo "==> Building $gem"
              cd ${ws}/$gem && ${pkgs.ruby}/bin/gem build $gem.gemspec
            fi
          done
          echo "All gems built."
        '';

        # Publish all pangea gems in dependency order
        gem-publish-all = mkApp "gem-publish-all" ''
          echo "Publishing all pangea gems..."
          cd ${ws}
          echo "==> pangea-core (root dependency)"
          cd ${ws}/pangea-core && ${pkgs.ruby}/bin/gem build pangea-core.gemspec && ${pkgs.ruby}/bin/gem push pangea-core-*.gem
          for gem in pangea-aws pangea-akeyless pangea-azure pangea-cloudflare pangea-datadog pangea-gcp pangea-hcloud pangea-splunk pangea-kubernetes; do
            if [ -d "${ws}/$gem" ] && [ -f "${ws}/$gem/$gem.gemspec" ]; then
              echo "==> $gem"
              cd ${ws}/$gem && ${pkgs.ruby}/bin/gem build $gem.gemspec && ${pkgs.ruby}/bin/gem push $gem-*.gem
            fi
          done
          echo "All gems published."
        '';

        # Show gem publish status
        gem-status = mkApp "gem-status" ''
          echo "Gem publish status:"
          echo "--------------------------------------------"
          for gem in pangea-core pangea-aws pangea-akeyless pangea-azure pangea-cloudflare pangea-datadog pangea-gcp pangea-hcloud pangea-splunk pangea-kubernetes; do
            if [ -d "${ws}/$gem" ]; then
              local_ver=$(${pkgs.ruby}/bin/ruby -e "Dir.glob('${ws}/' + '$gem' + '/lib/*/version.rb').each{|f| c=File.read(f); puts \$1 if c=~/VERSION.*?['\"]([^'\"]+)/}" 2>/dev/null)
              published=$(${pkgs.ruby}/bin/gem search -r "^$gem$" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -o '([^)]*)' | tr -d '()' || echo "NOT_PUBLISHED")
              printf "  %-22s local=%-8s published=%s\n" "$gem" "''${local_ver:-?}" "$published"
            fi
          done
        '';

        # Bump a gem version
        gem-bump = mkApp "gem-bump" ''
          gem_name="''${1:-}"
          new_version="''${2:-}"
          [ -z "$gem_name" ] || [ -z "$new_version" ] && { echo "Usage: nix run .#gem-bump -- <gem> <version>"; exit 1; }
          cd ${ws}/$gem_name
          version_file=$(find lib -name "version.rb" | head -1)
          ${pkgs.gnused}/bin/sed -i "s/VERSION = .*/VERSION = %($new_version).freeze/" "$version_file"
          ${pkgs.git}/bin/git add "$version_file"
          ${pkgs.git}/bin/git commit -m "Bump version to $new_version"
          echo "$gem_name bumped to $new_version"
        '';


        # Fleet flow apps
        flow-list = mkApp "flow-list" ''
          cd ${ws}
          [ ! -f fleet.yaml ] && cp ${fleetYaml} fleet.yaml
          ${fleetBin} flow list
        '';
        flow-gem-publish-all = mkFleetApp "gem-publish-all";
      };
    });
}
