#!/bin/bash
cd "$(dirname "$0")"
source ./script/setup.sh

./build-debug.sh -Xswiftc -warnings-as-errors
./run-swift-test.sh

./.debug/dwmac -h > /dev/null
./.debug/dwmac --help > /dev/null
./.debug/dwmac -v | grep -q "0.0.0-SNAPSHOT SNAPSHOT"
./.debug/dwmac --version | grep -q "0.0.0-SNAPSHOT SNAPSHOT"

./format.sh
./generate.sh
./script/check-uncommitted-files.sh

echo
echo "✅ All tests have passed successfully"
