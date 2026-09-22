# grokbot-nixos

> [Grok Bot](https://cursor.com/download/bot) on NixOS, wrapping the official
> Linux AppImage. A GitHub Action bumps the pin when a new stable build ships.

Grok Bot publishes Linux AppImage, `.deb`, and `.rpm` builds. This flake
takes the AppImage and wraps it in an FHS environment. The current pin is in
`sources.json`.

- [Try it without installing](#try-it-without-installing)
- [Add it to your flake](#add-it-to-your-flake)
- [Updating](#updating)
- [License](#license)

## Try it without installing

```sh
nix run github:aijorgenson/grokbot-nixos
```

The flake imports nixpkgs with `allowUnfree` so that build is permitted.
Grok Bot itself is unfree.

`nix run` does not install the desktop file, so `grokbot://` and `sand://`
login links will not route back to the app until it is installed (the module
below, Home Manager, or `nix profile install`).

## Add it to your flake

Grok Bot is unfree, so your NixOS config already needs
`nixpkgs.config.allowUnfree = true`. After that, the module is one line.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    grok-bot = {
      url = "github:aijorgenson/grokbot-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, grok-bot, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        grok-bot.nixosModules.default
      ];
    };
  };
}
```

### Or just the package

```nix
{ pkgs, grok-bot, ... }:
{
  environment.systemPackages = [ grok-bot.packages.${pkgs.system}.default ];
}
```

(Pass `grok-bot` through `specialArgs` if the module file is not the flake's
`outputs`.)

Linux only: `x86_64-linux` and `aarch64-linux`.

## Updating

`sources.json` pins the AppImage URL and hash for each Linux arch. A
scheduled Action queries the stable download API once a day, and when the
version moved, runs `./update-package.sh`, builds, and pushes straight to
`main`.

The API still lists this app as `sand`. `downloadUrl` is the AppImage.

Requirements for the Action:

- **Settings → Actions → General → Workflow permissions** = "Read and write
  permissions"
- If `main` is protected, allow `github-actions[bot]` to push

Trigger it by hand from the Actions tab ("Run workflow").

### Manual

```sh
./update-package.sh
```

It fetches latest stable for `linux-x64` and `linux-arm64`, refuses to
update if those versions diverge, prefetches hashes, writes `sources.json`,
and `nix build`s. Nothing is committed.

## License

The Nix expressions and scripts in this repo are [MIT](LICENSE). That covers
the packaging only.

Grok Bot itself is proprietary (Nix `unfree`). This flake does not ship the
AppImage; Nix downloads it at build time. This project is unofficial and not
affiliated with xAI or Anysphere.

---

> Built and tested on `x86_64-linux`.
