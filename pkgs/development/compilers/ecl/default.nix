{lib, stdenv, fetchurl, fetchpatch
, libtool, autoconf, automake
, texinfo
, gmp, mpfr, libffi, makeWrapper
, noUnicode ? false
, gcc
, threadSupport ? true
, useBoehmgc ? false, boehmgc
}:
let
  s = # Generated upstream information
  rec {
    baseName="ecl";
    version="21.2.1";
    name="${baseName}-${version}";
    url="https://common-lisp.net/project/ecl/static/files/release/${name}.tgz";
    sha256="000906nnq25177bgsfndiw3iqqgrjc9spk10hzk653sbz3f7anmi";
  };
  nativeBuildInputs = [
    libtool autoconf automake texinfo makeWrapper
  ];
  propagatedBuildInputs = [
    libffi gmp mpfr gcc
    # replaces ecl's own gc which other packages can depend on, thus propagated
  ] ++ lib.optionals useBoehmgc [
    # replaces ecl's own gc which other packages can depend on, thus propagated
    boehmgc
  ];
in
stdenv.mkDerivation {
  inherit (s) version;
  pname = s.baseName;
  inherit nativeBuildInputs propagatedBuildInputs;

  src = fetchurl {
    inherit (s) url sha256;
  };

  patches = [
    # https://gitlab.com/embeddable-common-lisp/ecl/-/merge_requests/1
    (fetchpatch {
      url = "https://git.sagemath.org/sage.git/plain/build/pkgs/ecl/patches/write_error.patch?h=9.2";
      sha256 = "0hfxacpgn4919hg0mn4wf4m8r7y592r4gw7aqfnva7sckxi6w089";
    })
  ];

  configureFlags = [
    (if threadSupport then "--enable-threads" else "--disable-threads")
    "--with-gmp-incdir=${lib.getDev gmp}/include"
    "--with-gmp-libdir=${lib.getLib gmp}/lib"
    "--with-libffi-incdir=${lib.getDev libffi}/include"
    "--with-libffi-libdir=${lib.getLib libffi}/lib"
  ] ++ lib.optionals useBoehmgc [
    "--with-libgc-incdir=${lib.getDev boehmgc}/include"
    "--with-libgc-libdir=${lib.getLib boehmgc}/lib"
  ] ++ lib.optional (!noUnicode) "--enable-unicode";

  hardeningDisable = [ "format" ];

  postInstall = ''
    sed -e 's/@[-a-zA-Z_]*@//g' -i $out/bin/ecl-config
    wrapProgram "$out/bin/ecl" --prefix PATH ':' "${
      lib.makeBinPath [
        gcc                   # for the C compiler
        gcc.bintools.bintools # for ar
      ]
    }"
  '';

  meta = with lib; {
    description = "Lisp implementation aiming to be small, fast and easy to embed";
    homepage = "https://common-lisp.net/project/ecl/";
    license = licenses.mit ;
    maintainers = [ maintainers.raskin ];
    platforms = platforms.unix;
    changelog = "https://gitlab.com/embeddable-common-lisp/ecl/-/raw/${s.version}/CHANGELOG";
  };
}
