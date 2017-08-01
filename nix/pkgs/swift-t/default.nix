{ stdenv, fetchurl, fetchgit,
  autoconf, automake,
  jdk, ant,
  mpich,
  zsh,
  which, # which is used in the manual autoconf program detect
  zlib, swig, tcl,
  vim, # for the xxd command
  perl
}:

with stdenv.lib;

let
  version = "1.3";

in stdenv.mkDerivation rec {
  name = "swift-t-${version}";

  src1 = fetchurl {
    url = "http://swift-lang.github.io/swift-t/downloads/swift-t-${version}.tar.gz" ;
    sha256 = "0hvbjkjz2xm401n3xh85ilhww6digr8syjzckszhzgl3bl0pybbb";
  };

  src = fetchgit {
    	url  = "/home/bnikolic/oss/swift-t/" ;
      	rev = "7a47c03e67e6853d66de48ef06c17ff4119bee8d" ;
	sha256 = "168qbhxanlh5chnrc93md03dsnf9piicdqm4pn18pvr6339p3lfz";
  };  

  buildInputs = [autoconf automake jdk ant zsh mpich which zlib swig tcl vim perl];

  configurePhase = ''
        cp dev/build/swift-t-settings.sh.template   dev/build/swift-t-settings.sh
        substituteInPlace dev/build/swift-t-settings.sh --replace "SWIFT_T_PREFIX=/tmp/swift-t-install" "SWIFT_T_PREFIX=$out"
	# Remove when mpich3	
	#substituteInPlace exm-settings.sh --replace "MPI_VERSION=3" "MPI_VERSION=2"
  ''	;

  buildPhase = "./dev/build/rebuild-all.sh ";

  installPhase = " ";
  
  enableParallelBuilding = true;

  meta = {
    homepage = http://swift-lang.org/Swift-T/index.php;
  };
}

