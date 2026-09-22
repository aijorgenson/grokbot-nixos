{
  lib,
  stdenv,
  fetchurl,
  appimageTools,
}:

let
  sourcesJson = lib.importJSON ./sources.json;
  pname = "grok-bot";
  inherit (sourcesJson) version;
  src =
    sourcesJson.sources.${stdenv.hostPlatform.system}
      or (throw "grokbot-nixos: unsupported system ${stdenv.hostPlatform.system}");
  appimage = fetchurl { inherit (src) url hash; };
  appimageContents = appimageTools.extract {
    inherit pname version;
    src = appimage;
  };
in
appimageTools.wrapType2 {
  inherit pname version;
  src = appimage;

  # libsecret is the one Electron extra wrapType2's default FHS set does not
  # always include; Grok Bot uses it for login/keychain.
  extraPkgs = pkgs: [ pkgs.libsecret ];

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/grok-bot.desktop \
      $out/share/applications/grok-bot.desktop
    sed -i -E \
      -e 's|^Exec=.*|Exec=grok-bot %U|' \
      -e 's|^Icon=.*|Icon=grok-bot|' \
      $out/share/applications/grok-bot.desktop

    install -Dm444 ${appimageContents}/usr/share/icons/hicolor/512x512/apps/grok-bot.png \
      $out/share/pixmaps/grok-bot.png

    for size in 16 24 32 48 64 128 256 512; do
      icon="${appimageContents}/usr/share/icons/hicolor/''${size}x''${size}/apps/grok-bot.png"
      if [ -f "$icon" ]; then
        install -Dm444 "$icon" \
          "$out/share/icons/hicolor/''${size}x''${size}/apps/grok-bot.png"
      fi
    done

    # wrapType2 execs the binary and skips AppRun. The published desktop entry
    # always launches with --no-sandbox, and Electron registers grokbot:// and
    # sand:// against CHROME_DESKTOP. Keep both on the command users actually run.
    mv $out/bin/grok-bot $out/bin/.grok-bot-bwrap
    cat > $out/bin/grok-bot <<EOF
    #!/bin/sh
    export CHROME_DESKTOP="\''${CHROME_DESKTOP:-grok-bot.desktop}"
    exec $out/bin/.grok-bot-bwrap --no-sandbox "\$@"
    EOF
    chmod +x $out/bin/grok-bot
  '';

  meta = {
    description = "Grok Bot desktop agent";
    homepage = "https://x.ai";
    downloadPage = "https://cursor.com/download/bot";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "grok-bot";
  };
}
