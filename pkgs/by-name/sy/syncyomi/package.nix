{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  buildGoModule,
  nodejs_20,
  pnpm_10,
  fetchPnpmDeps,
  pnpmConfigHook,
}:
buildGoModule (finalAttrs: {
  pname = "syncyomi";
  version = "1.1.4";

  src = fetchFromGitHub {
    owner = "syncyomi";
    repo = "syncyomi";
    tag = "v${finalAttrs.version}";
    hash = "sha256-pU3zxzixKoYnJsGpfvC/SVWIu0adsaiiVcLn0IZe64w=";
  };

  vendorHash = "sha256-fzPEljXFskr1/qzTsnASFNNc+8vA7kqO21mhMqwT44w=";

  env.web = stdenvNoCC.mkDerivation (finalAttrsWeb: {
    pname = "${finalAttrs.pname}-web";
    inherit (finalAttrs) src version;
    sourceRoot = "${finalAttrsWeb.src.name}/web";

    env.pnpmRoot = ".";
    env.pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrsWeb)
        pname
        version
        src
        sourceRoot
        ;
      pnpm = pnpm_10;
      fetcherVersion = 2;
      hash = "sha256-jZi2b+Ng3ebz1xCuEJ+yg52RQTxTytiIanAwq/TH6Xc=";
    };

    nativeBuildInputs = [
      nodejs_20
      pnpmConfigHook
      pnpm_10
    ];

    buildPhase = ''
      runHook preBuild
      pnpm run build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -r dist $out
      runHook postInstall
    '';
  });

  preConfigure = ''
    cp -r $web/. web/dist/
  '';

  ldflags = [
    "-s"
    "-w"
    "-X main.version=v${finalAttrs.version}"
    "-X main.commit=${finalAttrs.src.rev}"
  ];

  postInstall = lib.optionalString (!stdenvNoCC.hostPlatform.isDarwin) ''
    mv $out/bin/SyncYomi $out/bin/syncyomi
  '';

  meta = {
    description = "Open-source project to synchronize Tachiyomi manga reading progress and library across multiple devices";
    homepage = "https://github.com/syncyomi/syncyomi";
    changelog = "https://github.com/syncyomi/syncyomi/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.gpl2Only;
    maintainers = with lib.maintainers; [
      eriedaberrie
      reo101
    ];
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    mainProgram = "syncyomi";
  };
})
