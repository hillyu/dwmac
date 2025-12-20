#!/bin/bash
cd "$(dirname "$0")"
source ./script/setup.sh

build_version="0.0.0-SNAPSHOT"
codesign_identity="-"
while test $# -gt 0; do
    case $1 in
        --build-version) build_version="$2"; shift 2;;
        --codesign-identity) codesign_identity="$2"; shift 2;;
        *) echo "Unknown option $1" > /dev/stderr; exit 1 ;;
    esac
done

#############
### BUILD ###
#############

./build-docs.sh
./build-shell-completion.sh

./generate.sh --ignore-shell-parser
# ./script/check-uncommitted-files.sh
./generate.sh --build-version "$build_version" --codesign-identity "$codesign_identity" --generate-git-hash --ignore-shell-parser

swift build -c release --product dwmac -Xswiftc -warnings-as-errors # CLI

# todo: make xcodebuild use the same toolchain as swift
# toolchain="$(plutil -extract CFBundleIdentifier raw ~/Library/Developer/Toolchains/swift-6.1-RELEASE.xctoolchain/Info.plist)"
# xcodebuild -toolchain "$toolchain" \
# Unfortunately, Xcode 16 fails with:
#     2025-05-05 15:51:15.618 xcodebuild[4633:13690815] Writing error result bundle to /var/folders/s1/17k6s3xd7nb5mv42nx0sd0800000gn/T/ResultBundle_2025-05-05_15-51-0015.xcresult
#     xcodebuild: error: Could not resolve package dependencies:
#       <unknown>:0: warning: legacy driver is now deprecated; consider avoiding specifying '-disallow-use-new-driver'
#     <unknown>:0: error: unable to execute command: <unknown>

rm -rf .release && mkdir .release

xcode_configuration="Release"
xcodebuild -version
xcodebuild-pretty .release/xcodebuild.log clean build \
    -scheme Dwmac \
    -destination "generic/platform=macOS" \
    -configuration "$xcode_configuration" \
    -derivedDataPath .xcode-build

# git checkout .

cp -r ".xcode-build/Build/Products/$xcode_configuration/Dwmac.app" .release
cp -r .build/release/dwmac .release

################
### SIGN CLI ###
################

codesign -s "$codesign_identity" .release/dwmac

################
### VALIDATE ###
################

expected_layout=$(cat <<EOF
.release/Dwmac.app
.release/Dwmac.app/Contents
.release/Dwmac.app/Contents/_CodeSignature
.release/Dwmac.app/Contents/_CodeSignature/CodeResources
.release/Dwmac.app/Contents/MacOS
.release/Dwmac.app/Contents/MacOS/Dwmac
.release/Dwmac.app/Contents/Resources
.release/Dwmac.app/Contents/Resources/default-config.toml
.release/Dwmac.app/Contents/Resources/AppIcon.icns
.release/Dwmac.app/Contents/Resources/Assets.car
.release/Dwmac.app/Contents/Info.plist
.release/Dwmac.app/Contents/PkgInfo
EOF
)

if test "$expected_layout" != "$(find .release/Dwmac.app)"; then
    echo "!!! Expect/Actual layout don't match !!!"
    find .release/Dwmac.app
    exit 1
fi

check-universal-binary() {
    if ! file "$1" | grep --fixed-string -q "Mach-O universal binary with 2 architectures: [x86_64:Mach-O 64-bit executable x86_64] [arm64"; then
        echo "$1 is not a universal binary"
        # exit 1
    fi
}

check-contains-hash() {
    hash=$(git rev-parse HEAD)
    if ! strings "$1" | grep --fixed-string "$hash" > /dev/null; then
        echo "$1 doesn't contain $hash"
        exit 1
    fi
}

check-universal-binary .release/Dwmac.app/Contents/MacOS/Dwmac
check-universal-binary .release/dwmac

check-contains-hash .release/Dwmac.app/Contents/MacOS/Dwmac
check-contains-hash .release/dwmac

codesign -v .release/Dwmac.app
codesign -v .release/dwmac

############
### PACK ###
############

mkdir -p ".release/Dwmac-v$build_version/manpage" && cp .man/*.1 ".release/Dwmac-v$build_version/manpage"
cp -r ./legal ".release/Dwmac-v$build_version/legal"
cp -r .shell-completion ".release/Dwmac-v$build_version/shell-completion"
cd .release
    mkdir -p "Dwmac-v$build_version/bin" && cp -r dwmac "Dwmac-v$build_version/bin"
    cp -r Dwmac.app "Dwmac-v$build_version"
    zip -r "Dwmac-v$build_version.zip" "Dwmac-v$build_version"
cd -

#################
### Brew Cask ###
#################
for cask_name in dwmac dwmac-dev; do
    ./script/build-brew-cask.sh \
        --cask-name "$cask_name" \
        --zip-uri ".release/Dwmac-v$build_version.zip" \
        --build-version "$build_version"
done
