#!/bin/bash
# Copyright (C) 1994, 1995, 1996, 1997, 1998, 1999, 2000, 2001, 2002,
# 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Free Software
# Foundation, Inc.
# This Makefile.in is free software; the Free Software Foundation
# gives unlimited permission to copy and/or distribute it,
# with or without modifications, as long as this notice is preserved.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY, to the extent permitted by law; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE.

set -e

PWD=`pwd`
GITREPO="git://github.com/clearscene/opendias.git"
LOCALREPO="clearscene-src-opendias"
DEPTH=`uname -m | sed 's/x86_//;s/i[3-6]86/32/' `
VERSION=`head -1 debian/changelog | sed -e s/.*\(// -e s/\).*//`
ARCH=`uname -i`
if [ -f /etc/lsb-release ]; then 
  . /etc/lsb-release
  OS=$DISTRIB_ID
elif [ -f /etc/debian_version ]; then 
  OS=Debian
elif [ -f /etc/redhat-release ]; then 
  OS=Fedora
elif [ -f /etc/issues ]; then 
  OS=parseToGuess
else 
  echo `uname -s` 
fi

#===========================

clean() {
  # remove logs and temperary build file
  rm -f opendias-*.rpm
  rm -f opendias_*.dsc
  rm -f opendias_*.tar.gz
  rm -f opendias_*.build
  rm -f opendias_*.changes
  rm -f opendias_*.deb
  rm -f opendias/debian/*.log
  rm -f opendias/debian/opendias.debhelper.log
  rm -f opendias/debian/opendias.substvars
  rm -fr opendias/debian/opendias
  rm -fr opendias/debian/files
  rm -fr redhat/opendias
}

distclean() {
  # cleanup source and build files
  clean
  rm -rf opendias
}

refreshsource() {
  distclean
  # Get back to a known place and then get the source
  if test -f ../opendias-${VERSION}.tar.gz ; then
    # Expand a tarball if available
    echo Expanding the tarball ../opendias-${VERSION}.tar.gz
    tar -zxvf ../opendias-${VERSION}.tar.gz
    mv opendias-${VERSION} opendias
  elif test -d ../${LOCALREPO} ; then
    # Otherwise copy a local checkout of code
    echo Copying from ../${LOCALREPO}
    cp -r ../${LOCALREPO} opendias
  else
    # Finally, last resport, goto github and get a fresh clone
    echo Cloning from ${GITREPO}
    git clone ${GITREPO} 
  fi
}

buildsource() {
  # Build the source
  cd opendias
  autoreconf -iv
  ./configure --prefix=/usr --enable-force_var_at_root 
  make clean
  make
  cd ../
}

packagedeb() {
  # make a deb package from built source
  if [ "$OS" != "Ubuntu" ]; then
    echo Building a DEB is not supported in this platform 
    exit
  else
    cp -r debian opendias
    cd opendias
    debuild -uc -us
    cd ../
  fi
}

packagerpm() {
  # make an rpm package from built source
  if [ "$OS" == "Fedora" ] || [ "$OS" == "Ubuntu" ]; then 
    for DIR in `cat redhat/dirs`; do
      mkdir -p redhat/opendias/${DIR}
    done
    redhat/rules
    #rpmbuild --buildroot=${PWD}'/redhat/opendias' -bb --target i386 'redhat/opendias.spec'
    rpmbuild --buildroot=${PWD}'/redhat/opendias' -bb 'redhat/opendias.spec'
  else 
    echo Building an RPM is not supported in this platform
    exit 0
  fi 
}

checkversionbreakout() {
  echo You have just built the application from its sources.
  echo The sources latest version is:
  head -1 opendias/ChangeLog
  echo 
  echo Where the package you\'re about to build has a last changelog entry of:
  head -1 debian/changelog
  echo 
  echo -n Do you want to update the version in the debian/Changelog and .spec file? \[ Y \| n \] 
  read
  if [ "$REPLY" != "N" ] && [ "$REPLY" != "n" ]; then
    echo -e Exiting. You can continue by issuing the command \n ./build.sh $RESTART
    exit
  fi
}

builddeb() {
  # make and build an deb package from nothing
  refreshsource
  buildsource
  RESTART="packagedeb"
  checkversionbreakout
  packagedeb
}

buildrpm() {
  # make and build an rpm package from nothing
  refreshsource
  buildsource
  RESTART="packagerpm"
  checkversionbreakout
  packagerpm
}

#=============================

case "$1" in
  help)
    echo all - default action - blat everything and build everything \(same as buildall\)
    echo clean - remove logs and temperary build files
    echo distclean - cleanup source and build files
    echo cleansource - put the source back to a non built state
    echo refreshsource - distclean, then get fresh sources
    echo buildsource - build the sources
    echo packageXXX - Generate a XXX package from build sources \[rpm, deb, all\]
    echo buildXXX - get, build and generate a XXX package from nothing \[rpm, deb, all\]
    echo 
    echo Running ${OS} ${ARCH} ${DEPTH}bit
  ;;

  clean)
    clean
  ;;

  distclean)
    distclean
  ;;

  cleansource)
    # Put the source back to a non built state
    clean
    cd opendias
    make clean
    cd ../
  ;;

  refreshsource)
    refreshsource
  ;;

  buildsource)
    buildsource
  ;;

  packagedeb)
    packagedeb
  ;;

  packagerpm)
    packagerpm
  ;;

  packageall)
    # package both deb and rpm from a built source
    packagedeb
    packagerpm
  ;;

  builddeb)
    builddeb
  ;;

  buildrpm)
    buildrpm
  ;;

  all|buildall)
    # Default action - blat everything, and build everything.
    # Make and build a deb and rpm from nothing
    refreshsource
    buildsource
    RESTART="packageall"
    checkversionbreakout
    packagedeb
    packagerpm
  ;;

  *)
  echo "Unknown command. Try $N help" >&2
  exit 1
  ;;

esac

