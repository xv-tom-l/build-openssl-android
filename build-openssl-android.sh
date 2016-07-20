#!/bin/bash -e

OPENSSL_VERSION=${1:-"1.0.1j"}
OPENSSL_TARBALL=openssl-${OPENSSL_VERSION}.tar.gz
OPENSSL_DIR=openssl-${OPENSSL_VERSION}
OPENSSL_BUILD_LOG=openssl-${OPENSSL_VERSION}.log

# Download setenv_android.sh
if [ ! -e setenv-android.sh ]; then 
	echo "Downloading setenv_android.sh..."
	curl -# -o setenv-android.sh http://wiki.openssl.org/images/7/70/Setenv-android.sh
	chmod a+x setenv-android.sh
fi

# Download openssl source
if [ ! -e ${OPENSSL_TARBALL} ]; then
	echo "Downloading openssl-${OPENSSL_VERSION}.tar.gz..."
	curl -# -O https://www.openssl.org/source/${OPENSSL_TARBALL}
fi

# Verify the source file
if [ ! -e ${OPENSSL_TARBALL}.sha1 ]; then
	echo -n "Verifying...	"
	curl -o ${OPENSSL_TARBALL}.sha1 -s https://www.openssl.org/source/${OPENSSL_TARBALL}.sha1
	CHECKSUM=`cat ${OPENSSL_TARBALL}.sha1`
	ACTUAL=`shasum ${OPENSSL_TARBALL} | awk '{ print \$1 }'`
	if [ "x$ACTUAL" == "x$CHECKSUM" ]; then
		echo "OK"
	else
		echo "FAIL"
		rm -f ${OPENSSL_TARBALL}
		rm -f ${OPENSSL_TARBALL}.sha1
		return 1
	fi
fi

# Untar the file
if [ ! -e ${OPENSSL_DIR} ]; then
	tar zxf ${OPENSSL_TARBALL}
fi

# Setup the environment
. ./setenv-android.sh

# Build
echo "Compiling..."
cd ${OPENSSL_DIR}
perl -pi -e 's/install: all install_docs install_sw/install: install_docs install_sw/g' Makefile.org
./config shared -no-ssl2 -no-ssl3 -no-comp -no-hw -no-engine --openssldir=/usr/local/ssl/$ANDROID_API > ../${OPENSSL_BUILD_LOG}
make depend >> ../${OPENSSL_BUILD_LOG} 
make all >> ../${OPENSSL_BUILD_LOG}

# Installing
echo "Installing..."
sudo -E make install CC=$ANDROID_TOOLCHAIN/arm-linux-androideabi-gcc RANLIB=$ANDROID_TOOLCHAIN/arm-linux-androideabi-ranlib  >> ../${OPENSSL_BUILD_LOG}
