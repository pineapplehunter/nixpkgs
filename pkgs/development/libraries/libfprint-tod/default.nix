{ lib
, libfprint
, fetchFromGitLab
}:

# for the curious, "tod" means "Touch OEM Drivers" meaning it can load
# external .so's.
libfprint.overrideAttrs ({ postPatch ? "", ... }: let
  version = "1.94.6";
in  {
  pname = "libfprint-tod";
  inherit version;

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "3v1n0";
    repo = "libfprint";
    rev = "v${version}+tod1";
    sha256 = "sha256-Ce56BIkuo2MnDFncNwq022fbsfGtL5mitt+gAAPcO/Y=";
  };

  postPatch = ''
    ${postPatch}
    patchShebangs ./tests/*.py ./tests/*.sh ./libfprint/tod/tests/*.sh
  '';


  meta = with lib; {
    homepage = "https://gitlab.freedesktop.org/3v1n0/libfprint";
    description = "A library designed to make it easy to add support for consumer fingerprint readers, with support for loaded drivers";
    license = licenses.lgpl21;
    platforms = platforms.linux;
    maintainers = with maintainers; [ grahamc pineapplehunter ];
  };
})
