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
