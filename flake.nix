{
  description = "Managed workspace: code/github/pleme-io";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    fleet = {
      url = "github:pleme-io/fleet";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
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

      fleetYaml = pkgs.writeText "workspace-fleet.yaml" ''{"flows":{"gem-publish-all":{"description":"Publish all pangea gems (DAG order)","steps":[{"action":{"command":"cd pangea-core && gem build pangea-core.gemspec && gem push pangea-core-*.gem","type":"shell"},"id":"pangea-core"},{"action":{"command":"cd pangea-aws && gem build pangea-aws.gemspec && gem push pangea-aws-*.gem","type":"shell"},"depends_on":["pangea-core"],"id":"pangea-aws"},{"action":{"command":"cd pangea-akeyless && gem build pangea-akeyless.gemspec && gem push pangea-akeyless-*.gem","type":"shell"},"depends_on":["pangea-core"],"id":"pangea-akeyless"},{"action":{"command":"cd pangea-azure && gem build pangea-azure.gemspec && gem push pangea-azure-*.gem","type":"shell"},"depends_on":["pangea-core"],"id":"pangea-azure"},{"action":{"command":"cd pangea-cloudflare && gem build pangea-cloudflare.gemspec && gem push pangea-cloudflare-*.gem","type":"shell"},"depends_on":["pangea-core"],"id":"pangea-cloudflare"},{"action":{"command":"cd pangea-datadog && gem build pangea-datadog.gemspec && gem push pangea-datadog-*.gem","type":"shell"},"depends_on":["pangea-core"],"id":"pangea-datadog"},{"action":{"command":"cd pangea-gcp && gem build pangea-gcp.gemspec && gem push pangea-gcp-*.gem","type":"shell"},"depends_on":["pangea-core"],"id":"pangea-gcp"},{"action":{"command":"cd pangea-hcloud && gem build pangea-hcloud.gemspec && gem push pangea-hcloud-*.gem","type":"shell"},"depends_on":["pangea-core"],"id":"pangea-hcloud"},{"action":{"command":"cd pangea-splunk && gem build pangea-splunk.gemspec && gem push pangea-splunk-*.gem","type":"shell"},"depends_on":["pangea-core"],"id":"pangea-splunk"},{"action":{"command":"cd pangea-kubernetes && gem build pangea-kubernetes.gemspec && gem push pangea-kubernetes-*.gem","type":"shell"},"depends_on":["pangea-core"],"id":"pangea-kubernetes"}]}}}'';

      mkFleetApp = flowName: mkApp "flow-${flowName}" ''
        cd ${ws}
        [ ! -f fleet.yaml ] && cp ${fleetYaml} fleet.yaml
        ${fleetBin} flow run ${flowName} "$@"
      '';

    in {
      apps = {
        # Update all repo flake.locks (via tend)
        flake-update-all = mkApp "flake-update-all" ''
          tend flake-update --workspace pleme-io
        '';

        # Repo status for pleme-io (via tend)
        tend-status = mkApp "tend-status" ''
          tend status --workspace pleme-io
        '';

        # Build all pangea gems
        gem-build-all = mkApp "gem-build-all" ''
          PANGEA_WORKSPACE=$PWD pangea-gems build
        '';

        # Bump a gem version
        gem-bump = mkApp "gem-bump" ''
          PANGEA_WORKSPACE=$PWD pangea-gems bump "$@"
        '';

        # List all managed pangea gems
        gem-list = mkApp "gem-list" ''
          pangea-gems list
        '';

        # Publish all pangea gems in dependency order
        gem-publish-all = mkApp "gem-publish-all" ''
          PANGEA_WORKSPACE=$PWD pangea-gems publish
        '';

        # Show gem publish status
        gem-status = mkApp "gem-status" ''
          PANGEA_WORKSPACE=$PWD pangea-gems status
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
