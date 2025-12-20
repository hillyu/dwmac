#!/bin/bash
cd "$(dirname "$0")"
source ./script/setup.sh

rebuild=1
while test $# -gt 0; do
    case $1 in
        --dont-rebuild) rebuild=0; shift ;;
        *) echo "Unknown option $1"; exit 1 ;;
    esac
done

if test $rebuild == 1; then
    ./build-release.sh
fi

PATH="$PATH:$(brew --prefix)/bin"
export PATH

brew list dwmac-dev-user/dwmac-dev-tap/dwmac-dev > /dev/null 2>&1 && brew uninstall dwmac-dev-user/dwmac-dev-tap/dwmac-dev # Compatibility. Drop after a while
brew list hillyu/local-tap/dwmac-dev > /dev/null 2>&1 && brew uninstall hillyu/local-tap/dwmac-dev
brew list dwmac > /dev/null 2>&1 && brew uninstall dwmac
which brew-install-path > /dev/null 2>&1 || brew install hillyu/tap/brew-install-path

# Override HOMEBREW_CACHE. Otherwise, homebrew refuses to "redownload" the snapshot file
# Maybe there is a better way, I don't know
rm -rf /tmp/dwmac-from-sources-brew-cache
HOMEBREW_CACHE=/tmp/dwmac-from-sources-brew-cache brew install-path ./.release/dwmac-dev.rb

rm -rf "$(brew --prefix)/Library/Taps/dwmac-dev-user" # Compatibility. Drop after a while
