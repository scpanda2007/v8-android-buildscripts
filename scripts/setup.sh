#!/bin/bash -e

GCLIENT_SYNC_ARGS="--reset --with_branch_head"
while getopts 'r:s' opt; do
  case ${opt} in
    r)
      GCLIENT_SYNC_ARGS+=" --revision ${OPTARG}"
      ;;
    s)
      GCLIENT_SYNC_ARGS+=" --no-history"
      ;;
  esac
done
shift $(expr ${OPTIND} - 1)

source $(dirname $0)/env.sh

# Install NDK
function installNDK() {
  pushd .
  cd "${V8_DIR}"
  wget -q https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux-x86_64.zip
  unzip -q android-ndk-${NDK_VERSION}-linux-x86_64.zip
  rm -f android-ndk-${NDK_VERSION}-linux-x86_64.zip
  popd
}

if [[ ! -d "${DEPOT_TOOLS_DIR}" || ! -f "${DEPOT_TOOLS_DIR}/gclient" ]]; then
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "${DEPOT_TOOLS_DIR}"
  patch "${DEPOT_TOOLS_DIR}/update_depot_tools" < "${PATCHES_DIR}/update_depot_tools_r.patch"
fi

fetch v8

if [[ ${MKSNAPSHOT_ONLY} = "1" ]]; then
  gclient sync ${GCLIENT_SYNC_ARGS}
  exit 0
fi

if [[ ${PLATFORM} = "ios" ]]; then
  gclient sync --deps=ios ${GCLIENT_SYNC_ARGS}
  exit 0
fi

if [[ ${PLATFORM} = "android" ]]; then
  
  echo "target_os = ['android']" >> .gclient  
  sudo bash -c 'v8/build/install-build-deps-android.sh'

  # Workaround to install missing sysroot
  gclient sync
  
  # not need to install ndk right now, just try to use default
  installNDK
  exit 0
fi
