# Menu Bar Monitor
<img width="102" height="67" alt="menubar-icon-screenshot" src="https://github.com/user-attachments/assets/08901261-44a3-4124-9c8a-8d924aa24dfe" />
<img width="327" height="277" alt="menubar-menu-screenshot" src="https://github.com/user-attachments/assets/dca80fde-cfd8-40b1-b836-c8d7e62c32c4" />


A tiny native macOS menu-bar app for monitoring system resources with no third-party dependencies.

- Left bar: aggregate CPU use; amber from 80% and red from 98%.
- Right bar: memory use; native label color under normal pressure, yellow under warning pressure, and red under critical pressure.
- All values try to update every ~2 seconds, with a 200ms tolerance so macOS can group wake-ups and save power, making this app as efficient as possible.
- The memory row shows the current percentage before its used and total values.
- If memory pressure cannot be read, the menu says "pressure unavailable".
- Clicking the meter shows precise CPU and memory details, a Launch at Login toggle, Activity Monitor, and a Quit command.
- Memory values follow macOS's convention: binary GiB values displayed as GB, so 48 GB of physical memory is shown as 48.00 GB.

## Build and run

Requires macOS 13 or newer and a Swift 6.2+ toolchain (Xcode 26+ or compatible Command Line Tools).

Build and install with:

```sh
make app
```

This installs an ad hoc signed bundle at `~/Applications/Menu Bar Monitor.app`; it is not Developer ID signed or notarized. Launch it from Finder or Spotlight, then enable **Launch at Login** from its menu if desired.

Run the tests with:

```sh
make test
```

Format Swift source with `make format`. GitHub Actions runs formatting checks, tests, and a release build on macOS.

## License

[0BSD](LICENSE).
