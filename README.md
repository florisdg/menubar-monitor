# Menu Bar Monitor
<img width="102" height="67" alt="dyn-eafba0c4f9c6905a1b3319901d1e2c01" src="https://github.com/user-attachments/assets/08901261-44a3-4124-9c8a-8d924aa24dfe" />
<img width="327" height="277" alt="file-813ce1750100bb9902ba150755bcdb7d" src="https://github.com/user-attachments/assets/dca80fde-cfd8-40b1-b836-c8d7e62c32c4" />


A tiny native macOS menu-bar app for monitoring system resources with no third-party dependencies.

- Left bar: aggregate CPU use; amber from 80% and red from 98%.
- Right bar: memory use; native label color under normal pressure, yellow under warning pressure, and red under critical pressure.
- Both bars are 4 points wide, separated by a 3-point gap, and update every 2 seconds.
- The memory row shows the current percentage before its used and total values.
- Clicking the meter shows precise CPU and memory details, a Launch at Login toggle, Activity Monitor, and a Quit command.
- Memory values follow macOS's convention: binary GiB values displayed as GB, so 48 GB of physical memory is shown as 48.00 GB.

## Build and run

Requires macOS 13 or newer and Xcode Command Line Tools.

Each build installs the signed app bundle at `~/Applications/Menu Bar Monitor.app`. Launch it directly from Finder or Spotlight. To launch it at login, add the app under **System Settings → General → Login Items**.

Developers can rebuild and replace the installed app with `make app`.

Run the tests with:

```sh
make test
```
