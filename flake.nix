{
  description = "THU Daily Health Report Script";

  inputs = {
    nixpkgs.url = github:poscat0x04/nixpkgs/dev;
    flake-utils.url = github:poscat0x04/flake-utils;
  };

  outputs = { self, nixpkgs, flake-utils }: {
    overlay = final: prev: {
      thu-checkin = prev.writers.writePython3 "thu-checkin.py" {
        libraries = with prev.python3Packages; [ pytesseract requests pillow ];
        flakeIgnore = [ "E221" "E111" "E501" ];
      } (builtins.readFile ./thu-checkin.py);
    };
    nixosModules.thu-checkin = { config, lib, pkgs, ... }: let
      cfg = config.services.thu-checkin;
      configEnv = cfg.config;
      configFile = pkgs.writeText "thu-checkin.env" (lib.concatStrings (lib.mapAttrsToList (name: value: "${name}=${value}\n") configEnv));
    in {
      options.services.thu-checkin = {
        enable = lib.mkEnableOption "THU checkin service";

        config = with lib; with types; mkOption {
          type = attrsOf str;
          default = {};
        };
      };
      config = lib.mkIf cfg.enable {
        systemd = {
          services.thu-checkin = {
            after = [ "network-online.target" ];
            serviceConfig = {
              Type = "oneshot";
              EnvironmentFile = [ configFile ];
              ExecStart = "${pkgs.thu-checkin}";
            };
          };
          timers.thu-checkin = {
            wantedBy = [ "timers.target" ];
            timerConfig = {
              RandomizedDelaySec = "1m";
              OnCalendar = "*-*-* 7:00:00 CST";
              Persistent = true;
            };
          };
        };
      };
    };
  } // flake-utils.eachDefaultSystem (system: let
    pkgs = import nixpkgs { inherit system; overlays = [ self.overlay ]; };
  in {
    packages = {
      inherit (pkgs) thu-checkin;
    };
    devShell = with pkgs; mkShell {
      buildInputs = [
        python3Packages.pytesseract
        python3Packages.requests
        python3Packages.pillow
      ];
    };
  });
}
