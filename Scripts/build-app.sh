#!/bin/zsh

set -euo pipefail

project_dir="${0:A:h:h}"
applications_dir="$HOME/Applications"
app_dir="$applications_dir/Menu Bar Monitor.app"
contents_dir="$app_dir/Contents"

cd "$project_dir"
swift build -c release

mkdir -p "$applications_dir" "$contents_dir/MacOS"
cp "$project_dir/.build/release/MenuBarMonitor" "$contents_dir/MacOS/MenuBarMonitor"
cp "$project_dir/Resources/Info.plist" "$contents_dir/Info.plist"

codesign --force --sign - "$app_dir"
echo "$app_dir"
