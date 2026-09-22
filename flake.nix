{
  description = "Grok Bot for NixOS, wrapping the official Linux AppImage";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAll =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f (
            import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            }
          )
        );
    in
    {
      packages = forAll (pkgs: rec {
        grok-bot = pkgs.callPackage ./package.nix { };
        default = grok-bot;
      });

      overlays.default = final: prev: {
        grok-bot = final.callPackage ./package.nix { };
      };

      # One-liner NixOS setup: overlay + install. You still need
      # `nixpkgs.config.allowUnfree = true` (Grok Bot's license is unfree).
      nixosModules.default =
        { pkgs, ... }:
        {
          nixpkgs.overlays = [ self.overlays.default ];
          environment.systemPackages = [ pkgs.grok-bot ];
        };
    };
}
