# Menu Bar Monitor

A tiny native macOS menu-bar app with no third-party dependencies.

- Left bar: aggregate CPU use; amber from 80% and red from 98%.
- Right bar: memory use; native label color under normal pressure, yellow under warning pressure, and red under critical pressure.
- Both bars are 4 points wide, separated by a 3-point gap, and update every 2 seconds.
- The memory row shows the current percentage before its used and total values.
- Clicking the meter shows precise CPU, total memory, app memory, wired memory, compressed memory, cached files, and swap usage plus a Quit command.
- Memory values follow macOS's convention: binary GiB values displayed as GB, so 48 GB of physical memory is shown as 48.00 GB.

## Build and run

Requires macOS 13 or newer and Xcode Command Line Tools.

Each build installs the signed app bundle at `~/Applications/Menu Bar Monitor.app`. Launch it directly from Finder or Spotlight. To launch it at login, add the app under **System Settings → General → Login Items**.

Developers can rebuild and replace the installed app with `make app`.

Run the tests with:

```sh
make test
```
