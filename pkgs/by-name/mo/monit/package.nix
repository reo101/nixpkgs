{
  lib,
  stdenv,
  fetchurl,
  darwin,
  bison,
  flex,
  zlib,
  libxcrypt,
  usePAM ? stdenv.hostPlatform.isLinux,
  pam,
  useSSL ? true,
  openssl,
}:

stdenv.mkDerivation rec {
  pname = "monit";
  version = "5.35.0";

  src = fetchurl {
    url = "https://mmonit.com/monit/dist/monit-${version}.tar.gz";
    sha256 = "sha256-l2DDqihhH8FDhmZUCs4A1XKk8pdCo6VG1lYodEr19HQ=";
  };

  nativeBuildInputs =
    [
      bison
      flex
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      darwin.apple_sdk.frameworks.DiskArbitration
      darwin.apple_sdk.frameworks.System
    ];

  buildInputs =
    [
      zlib.dev
      libxcrypt
    ]
    ++ lib.optionals useSSL [ openssl ]
    ++ lib.optionals usePAM [ pam ];

  configureFlags =
    [
      (lib.withFeature usePAM "pam")
    ]
    ++ (
      if useSSL then
        [
          "--with-ssl-incl-dir=${openssl.dev}/include"
          "--with-ssl-lib-dir=${lib.getLib openssl}/lib"
        ]
      else
        [
          "--without-ssl"
        ]
    )
    ++ lib.optionals (stdenv.hostPlatform != stdenv.buildPlatform) [
      # will need to check both these are true for musl
      "libmonit_cv_setjmp_available=yes"
      "libmonit_cv_vsnprintf_c99_conformant=yes"
    ];

  meta = {
    homepage = "https://mmonit.com/monit/";
    description = "Monitoring system";
    license = lib.licenses.agpl3Plus;
    maintainers = with lib.maintainers; [
      raskin
      wmertens
      ryantm
    ];
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    mainProgram = "monit";
  };
}
