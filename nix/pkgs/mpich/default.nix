{ stdenv, fetchurl, python, perl, gfortran }:

let version = "3.2"; in
stdenv.mkDerivation {
  name = "mpich-${version}";

  src = fetchurl {
    url = "http://www.mpich.org/static/downloads/${version}/mpich-${version}.tar.gz";
    sha256 = "1p537ljp9ylvhmrq7gqq2g2vzhkdhp9gjzzkmxy7ngb9dfd6fy07";
  };

  configureFlags = "--enable-shared --enable-sharedlib";

  buildInputs = [ python perl gfortran ];
  propagatedBuildInputs = stdenv.lib.optional (stdenv ? glibc) stdenv.glibc;

  meta = {
    description = "Implementation of the Message Passing Interface (MPI) standard";

    longDescription = ''
      MPICH is a free high-performance and portable implementation of
      the Message Passing Interface (MPI) standard.
    '';
    homepage = https://www.mpich.org/;
    license = "";

    maintainers = [ ];
    platforms = stdenv.lib.platforms.unix;
  };
}
