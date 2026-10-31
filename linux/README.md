# Linux (Connor's Raspberry Pi bridge)

This is a Linux host port of Connor's original **Raspberry Pi USB → Wi-Fi → FTC Control Hub** bridge. It uses the existing `pi/` firmware, `ftc-bridge` Bash CLI, and `mcp/server.py`. **It does not use the Android phone relay** in `android/`.

```text
Linux laptop (internet stays on normal Wi-Fi)
    | USB data cable / USB Ethernet
Raspberry Pi Zero 2 W (10.12.194.1)
    | Wi-Fi (Control Hub network)
REV Control Hub (192.168.43.1)
```

## Requirements

- Linux with Bash and USB Ethernet support (Ubuntu/Debian recommended); Raspberry Pi Zero 2 W or another Pi supported by Connor's original setup.
- A Pi SD card already prepared with **Connor's macOS `flash.sh`**. Linux flashing is **not** implemented here; this port starts with an already-provisioned Pi.
- Android SDK Platform-Tools (`adb`), OpenSSH client, Python 3, Perl, `ip`, `ping`, `tar`, and SHA-256 utilities. Android Studio or a compatible JDK is needed to build/upload FTC code.
- Optional: `uv` for the existing MCP server; `xdg-open` to launch Panels and tuning pages automatically.

## Install

From the repository root:

```bash
bash linux/install.sh
```

The installer creates `~/.local/bin/ftc-bridge` as a symlink to **the existing root `ftc-bridge` script**, creates a local SSH key if needed, checks dependencies, and offers MCP registration if `uv` is installed. It neither flashes the Pi nor changes your network configuration.

Make sure `~/.local/bin` is in your `PATH` (log out/in or add it to your shell startup file).

## Connect the Pi

1. Connect the Pi's **USB data** port to the Linux computer. Keep the laptop's own Wi-Fi connected to the internet.
2. Linux should recognize a USB Ethernet adapter (often named `enx...` or `usb0`). Set that adapter to **Automatic (DHCP)**. The Pi's shared USB network provides a host address in `10.12.194.0/24`; the Pi is `10.12.194.1`.
3. Check with `ip -4 addr`, `nmcli device` (if using NetworkManager), and `ping -c 1 -W 2 10.12.194.1`. If no address appears, reconnect/activate the USB Ethernet connection using NetworkManager's GUI or `nmcli` and leave IPv4 on automatic DHCP. Do **not** share your laptop's internet connection to the Pi.
4. Run `ftc-bridge key`. On a computer already authorized to use this Pi, run `ftc-bridge add-key "<that Linux public key>"`. Each computer has its own key.
5. Run `ftc-bridge health`, then `ftc-bridge robots` or `ftc-bridge add comp 12345-RC` followed by `ftc-bridge use comp` to choose a robot. The Control Hub Wi-Fi password is requested, not stored in your command history.

Use the existing commands:

```bash
ftc-bridge status
ftc-bridge upload comp
ftc-bridge logs --errors
ftc-bridge panels
ftc-bridge tuning
ftc-bridge data pull
ftc-bridge update-pi
```

The Control Hub is available to Android Studio through `adb connect 10.12.194.1:5555` when the Pi is on the robot's Wi-Fi. `ftc-bridge upload` handles the connection automatically.

## Linux-specific changes

The root `ftc-bridge` script now detects Linux and selects the Linux SDK path, XDG data/state directories, `sha256sum`, GNU `stat`, GNU `tar`, `ping -W`, `ip`, and `xdg-open`, while preserving Connor's original macOS behavior. The Pi code, its IP addresses, SSH transport, Sloth hot reload, backup logic, robot data, and MCP API are unchanged.

## Notes

- No Linux desktop/tray app is provided; use the command line or Connor's existing MCP server.
- `ftc-bridge update-pi` updates the *same* Pi software as macOS and Windows.
- FTC match rules still apply: disconnect the Pi from the robot's Wi-Fi before a match (`ftc-bridge disconnect`).
- This Linux path is newly added and not yet end-to-end tested with a physical Pi and Control Hub.
