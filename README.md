# build-openssl-android
A simple shell script for building openssl android.

Now that OpenSSL moved from their webpage to a GitHub repository the previous shell script from @xvtom doesn't work anymore, I'm just taking the idea and improving it to make it work with this changes, now we have to deal with tags so basically this script will download the master and then it will try to checkout the tag that you specify (1.0.2h otherwise).


All comments and help are welcome.


Tested on OSX 10.11.5 (El Captain)


## Setup Android Development on Mac OS X

* Install Android SDK and NDK

```
brew install android android-ndk ant makedepend
```

* Edit `~/.bashrc` and add:

```!bash
# Android SDK
export ANDROID_SDK_ROOT=/usr/local/Cellar/android-sdk/23.0.2
export ANDROID_NDK_ROOT=/usr/local/Cellar/android-ndk/r10b
```

* Run

```!bash
source ~/.bashrc
```

## Usage: `./build-openssl-android.sh <version>`
* Build openssl-1.0.2h

```!bash
./build-openssl-android.sh 1_0_2h
```

* Build openssl-1.0.2-beta3

```!bash
./build-openssl-android.sh 1_0_2-beta3
```

## Reference
* http://wiki.openssl.org/index.php/Android
