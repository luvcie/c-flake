{ lib
, llvmPackages
, cmake
, gcc
, googletest
}:

llvmPackages.stdenv.mkDerivation rec {

  meta = with lib; {
    description = "untitled-c-project";
    platforms = with platforms; linux;
  };

  pname = "untitled-c-project";
  version = "0.1.0";

  src = ./.;

  # Developer-time dependencies
  nativeBuildInputs = [
    cmake
    gcc
  ];

  # Compile-time and run-time dependencies
  buildInputs = [
  ];

  # Filepaths for library source code
  GOOGLE_TEST_INCLUDE_DIR = googletest;

  # Flags to pass to CMake
  cmakeFlags = [
    "-DENABLE_TESTING=ON"
    "-DENABLE_INSTALL=ON"
    "-DGOOGLE_TEST_INCLUDE_DIR=${GOOGLE_TEST_INCLUDE_DIR}"
  ];

  # GTest configuration
  GTEST_COLOR = 1;
  GTEST_PRINT_TIME = 0;
}
