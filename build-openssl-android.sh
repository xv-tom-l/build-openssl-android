#!/bin/bash -e

#
#This shell script will download the env setup for android as well the source code from GitHub
#
#Usage ./build-openssl.sh 1_0_2h
#
#
TAG_NAME=${1:-"1_0_2h"}
OPENSSL_VERSION=${TAG_NAME}
OPENSSL_DIR=openssl-${OPENSSL_VERSION}
today=`date +%Y-%m-%d.%H_%M_%S`
OPENSSL_BUILD_LOG=openssl-${OPENSSL_VERSION}-${today}.log

reset=`tput sgr0`
red=`tput setaf 1`
green=`tput setaf 2`

# Download setenv_android.sh
downloadingSetEnv(){
	if [ ! -e setenv-android.sh ]; then
		echo "${green}Downloading setenv_android.sh...${reset}"
		curl -# -o setenv-android.sh https://wiki.openssl.org/images/7/70/Setenv-android.sh
		chmod a+x setenv-android.sh
	fi
}

validateSettings(){
	if [ -z "$ANDROID_NDK_ROOT" ] || [ ! -d "$ANDROID_NDK_ROOT" ]; then
	  echo "${red}ANDROID_NDK_ROOT is not a valid path, please declare a valid path${reset}"
	  exit 1
	fi

	validateGIT
}

#Checking if GIT is available
validateGIT(){
	hash git 2>/dev/null || { echo >&2 "${red}I require git but it's not installed.  Aborting.${reset}"; exit 1; }
}


# Download openssl source from git
cloneRepository(){
  OUT=0
  if [ ! -d "$OPENSSL_DIR" ]; then
      echo "${green}Cloning Openssl v${OPENSSL_VERSION}...${reset}"
      git clone git://git.openssl.org/openssl.git ${OPENSSL_DIR}
      OUT=$?
  else
    echo "${green}A folder for the given Openssl version already exists: ${OPENSSL_DIR} ${reset}"
  fi

	if [ $OUT -gt 0 ];then
			echo "${red}Error during Cloning process ${reset}"
			removeDir
			exit 1
	else
		  androidSetup
			cd ${OPENSSL_DIR}
			windowsSetup
	fi
}


#in case this a windows setup we need to double confirm this
windowsSetup(){
	git config core.autocrlf false
	git config core.eol lf
	git checkout .
}

androidSetup(){
	echo "${green}Setting up android build environment...${reset}"
	. ./setenv-android.sh
}


removeDir(){
	rm -rf $OPENSSL_DIR
}

#Checking specific TAG/Version of Openssl
verifyTag(){
	echo "${green}Checking tag ${TAG_NAME}...${reset}"
	git ls-remote --tags 2>/dev/null | grep $TAG_NAME 1>/dev/null
	if [ "$?" == 0 ]; then
	   echo "${green}Git tag $TAG_NAME exists.${reset}"
	else
	   echo "${red}Git tag $TAG_NAME does not exist.${reset}"
		 cd ..
		 removeDir
		 exit 1
	fi
}


checkoutTag(){
		verifyTag
    echo "${green}Checking out the specific TAG (${TAG_NAME})...${reset}"
		#we should be already inside openssl dir ($OPENSSL_DIR)
		git checkout tags/OpenSSL_${TAG_NAME}
}


# Building for android
build(){
	echo "${green}Compiling Openssl (${OPENSSL_VERSION})...${reset}"
	perl -pi -e 's/install: all install_docs install_sw/install: install_docs install_sw/g' Makefile.org
	./config shared -no-ssl2 -no-ssl3 -no-comp -no-hw -no-engine --openssldir=/usr/local/ssl/$ANDROID_API > ../${OPENSSL_BUILD_LOG}
	make depend >> ../${OPENSSL_BUILD_LOG}
	make all >> ../${OPENSSL_BUILD_LOG}
}

# Installing in the toolchain of the ANDROID_NDK_ROOT
install(){
	echo "${green}Installing in Android NDK Toolchain PATH : ${ANDROID_TOOLCHAIN} ${reset}"
	sudo -E make install CC=$ANDROID_TOOLCHAIN/arm-linux-androideabi-gcc RANLIB=$ANDROID_TOOLCHAIN/arm-linux-androideabi-ranlib  >> ../${OPENSSL_BUILD_LOG}
	PHYS_DIR=`pwd -P`
	echo "${green}All done, log can be view it at : ${PHYS_DIR}/${OPENSSL_BUILD_LOG}  ${reset}"
}

#Main process
validateSettings
downloadingSetEnv
cloneRepository
checkoutTag
build
install
exit 0
