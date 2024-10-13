{
  buildNpmPackage,
  lib,
  fetchFromGitHub,
  electron,
  makeDesktopItem,
  super-productivity,
  copyDesktopItems,
  npm-lockfile-fix,
  nix-update-script,
  stdenv,
}:

buildNpmPackage rec {
  pname = "super-productivity";
  version = "10.0.10";

  src = fetchFromGitHub {
    owner = "johannesjo";
    repo = "super-productivity";
    rev = "v${version}";
    hash = "sha256-Ho5Sm4KHwVwDfQ0l6sxpgd0iVWlocU5esEpDKH11ITk=";

    postFetch = ''
      ${lib.getExe npm-lockfile-fix} -r $out/package-lock.json
    '';
  };

  npmDepsHash = "sha256-GssB8SjwvfeE/W17ZbkLvfdYvY/yZ/ql20qjqLjtzr8=";
  npmFlags = [ "--legacy-peer-deps" ];
  makeCacheWritable = true;

  ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
  CHROMEDRIVER_SKIP_DOWNLOAD = "true";

  nativeBuildInputs = [ copyDesktopItems ];

  postPatch = ''
    # package.json does not include `core-js`
    # and the comment suggests it is only needed
    # on some mobile platforms
    substituteInPlace src/polyfills.ts \
      --replace-fail "import 'core-js/es/object';" ""
  '';

  buildPhase = ''
    runHook preBuild

    # electronDist needs to be modifiable on Darwin
    cp -r ${electron.dist} electron-dist
    chmod -R u+w electron-dist

    npm run buildFrontend:prod:es6
    npm run electron:build
    npm exec electron-builder -- \
      --dir \
      -c.electronDist=electron-dist \
      -c.electronVersion=${electron.version}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    ${
      if stdenv.isDarwin then
        ''
          mkdir -p $out/Applications
          cp -r dist/mac*/superProductivity.app $out/Applications
        ''
      else
        ''
          mkdir -p $out/share/super-productivity/{app,defaults,static/plugins,static/resources/plugins}
          cp -r app-builds/*-unpacked/{locales,resources{,.pak}} "$out/share/super-productivity/app"

          for size in 16 32 48 64 128 256 512 1024; do
            local sizexsize="''${size}x''${size}"
            mkdir -p $out/share/icons/hicolor/$sizexsize/apps
            cp -v build/icons/$sizexsize.png \
              $out/share/icons/hicolor/$sizexsize/apps/super-productivity.png
          done

          makeWrapper '${lib.getExe electron}' "$out/bin/super-productivity" \
            --add-flags "$out/share/super-productivity/app/resources/app.asar" \
            --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}" \
            --set-default ELECTRON_FORCE_IS_PACKAGED 1 \
            --inherit-argv0
        ''
    }

    runHook postInstall
  '';

  # copied from deb file
  desktopItems = [
    (makeDesktopItem {
      name = "super-productivity";
      desktopName = "superProductivity";
      exec = "super-productivity %u";
      terminal = false;
      type = "Application";
      icon = "super-productivity";
      startupWMClass = "superProductivity";
      comment = builtins.replaceStrings [ "\n" ] [ " " ] super-productivity.meta.longDescription;
      categories = [ "Utility" ];
    })
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "To Do List / Time Tracker with Jira Integration";
    longDescription = ''
      Experience the best ToDo app for digital professionals and get more done!
      Super Productivity comes with integrated time-boxing and time tracking capabilities
      and you can load your task from your calendars and from
      Jira, Gitlab, GitHub, Open Project and others all into a single ToDo list.
    '';
    homepage = "https://super-productivity.com";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [
      offline
      pineapplehunter
    ];
    mainProgram = "super-productivity";
  };
}
