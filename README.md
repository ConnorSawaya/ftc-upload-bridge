# FTC Upload Bridge

Upload FTC robot code **without disconnecting your computer from its internet Wi-Fi**. The original design uses a Raspberry Pi as a USB-to-Wi-Fi bridge; an additional Windows/Android-phone route is available when you don't have a Pi.

```text
Pi route (macOS / Windows / Linux):
Laptop ──USB networking──► Raspberry Pi ──robot Wi-Fi──► REV Control Hub
                           10.12.194.1:5555              192.168.43.1:5555

Android route (Windows):
Laptop ──USB ADB forwarding──► Android / Termux ──robot Wi-Fi──► REV Control Hub
        127.0.0.1:15555                                   192.168.43.1:5555
```

> **Testing status:** The Pi path has not been verified end-to-end with a Control Hub. The Android/Sonim path has successfully established ADB connectivity to a Control Hub, but robot app deployment and dashboard streaming have not yet been verified.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/screenshot-dark.png">
  <img alt="The FTC Bridge menu bar app: robot health, a crash alert, adding a robot, and settings" src="docs/screenshot-light.png">
</picture>


## Choose your setup

| Computer | Relay device | Where to start | What is available |
|---|---|---|---|
| macOS | Raspberry Pi | [Mac setup](#macos-setup-pi-bridge) | Menu-bar app, CLI, MCP |
| Windows | Raspberry Pi | [Windows Pi setup](#windows-pi-setup) | CLI, MCP |
| Linux | Raspberry Pi | [Linux setup](linux/README.md) | CLI, MCP; no Linux desktop app |
| Windows | Android phone | [Android setup](android/README.md) | ADB relay for Android Studio; separate from the Pi CLI |

**The two routes are alternatives, not components of the same setup.** The Pi route runs Connor's `pi/adb-forward.py`, `ftc-hub`, and SSH-based `ftc-bridge` commands. The Android route runs `socat` inside Termux and uses `android/connect.ps1` on Windows. It does **not** require a Raspberry Pi or run Connor's Pi management commands.

The computer stays on its usual internet Wi-Fi; the **relay device** joins the Control Hub's Wi-Fi. Neither route provides general internet access to the robot.

## How the Pi bridge works

The Pi appears to the laptop as a USB Ethernet device. On the USB link, the Pi answers at `10.12.194.1`; on its Wi-Fi interface, it connects to the Control Hub network. The Pi forwards ADB TCP port `5555` to the Control Hub, while `ftc-hub` manages saved robot networks and reports their health.

The host-side `ftc-bridge` command uses SSH to manage the Pi, then uses the forwarded ADB connection for uploads, logs, configuration backups, telemetry data, Panels, and Pedro tuning. The Pi firmware and Python relay in `pi/` are shared across macOS, Windows, and Linux; the host installers differ.

**Pi flashing:** The existing `flash.sh` prepares Raspberry Pi OS Lite, cloud-init configuration, SSH access, USB networking, and the bridge services. It currently runs on **macOS**; Windows and Linux Pi clients assume a Pi card has already been prepared.

## Parts
- Raspberry Pi Zero 2 W (a Pi 4 or Pi 5 also works, through its USB-C port; the Pi 5 also has 5 GHz Wi-Fi)
- microSD card, 16–32 GB
- USB-C to micro-USB **data** cable (charge-only cables won't work)

## macOS setup (Pi bridge)

This is Connor's original setup and is also the way to prepare an SD card for Windows or Linux users.

1. `./install.sh`: builds the menu bar app, installs the `ftc-bridge` command, and adds the AI tools to Claude Code, Codex, OpenCode and the Claude desktop app if you have them (it asks first).
2. `brew install --cask raspberry-pi-imager`
3. Put the SD card in the Mac and run `./flash.sh`. Type which disk to erase.
4. Put the card in the Pi. Plug the Pi's **middle** micro-USB port (labelled USB, not PWR) into the Mac. Wait ~3 minutes the first time.
5. Save your robots: in the menu bar app, **Add robot**, pick your robot from the list, type its Wi-Fi password, **Save & Connect**. Or in the terminal: `ftc-bridge add comp 12345-RC` (asks for the password).

## Windows Pi setup
Teammates on Windows can use the Pi too, from a terminal and AI apps (there's no tray app; the SD card is made on a Mac).
1. Install Android Studio, and Raspberry Pi's USB driver: `rpi-usb-gadget-driver-setup.exe` from the [rpi-usb-gadget releases](https://github.com/raspberrypi/rpi-usb-gadget/releases).
2. In the repo folder: `powershell -ExecutionPolicy Bypass -File windows\install.ps1`. It puts `ftc-bridge` on your PATH, adds the AI tools, and makes this PC's key.
3. The Pi only lets in computers it knows. The installer copies this PC's key; whoever set up the Pi runs `ftc-bridge add-key "<that key>"` once, with the Pi plugged in.
4. Then the same `ftc-bridge` commands work, e.g. `ftc-bridge status`, `ftc-bridge upload comp`.

Don't turn on Internet Connection Sharing for the Pi.

## Linux Pi setup

Linux uses Connor's existing Pi firmware and `ftc-bridge` Bash CLI, with Linux-specific tools and paths. It has **no desktop app** and does **not** use the Android phone relay.

1. Prepare the SD card using the existing macOS `flash.sh`.
2. From the repository root on Linux, run `bash linux/install.sh`.
3. Connect the Pi through its USB data port and make sure the Linux USB Ethernet interface receives an address in `10.12.194.0/24` via DHCP.
4. Authorize the Linux machine's `ftc-bridge key` on the Pi using a computer that already has access.
5. Use `ftc-bridge health` to verify connectivity.

See **[linux/README.md](linux/README.md)** for setup commands, troubleshooting, and current limitations. The Linux path has not been tested end-to-end on physical hardware.

## Android phone bridge (Windows, no Pi)

This is a separate option when you want to use an Android phone instead of a Raspberry Pi.

1. On the phone, enable USB debugging, authorize the Windows PC, install [Termux](https://f-droid.org/packages/com.termux/), and install `socat` in Termux.
2. Connect the **phone** to the Control Hub's Wi-Fi. Keep the **Windows PC** connected to your regular internet Wi-Fi.
3. Plug the phone into the computer using a USB data cable.
4. From the repository root, run:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\android\connect.ps1
   ```

5. After the connection succeeds, select `127.0.0.1:15555` as the Control Hub ADB target in Android Studio.

The script sets up USB ADB forwarding and a Termux TCP relay. It is **not** a port of the Pi management CLI and does not provide its upload/backup/robot-selection features automatically.

**Important:** Some phones route traffic to the robot's local address over cellular instead of its Wi-Fi. Check the Android routing table before changing settings. Disabling mobile data can disrupt calling or other phone services on some phones, so don't assume calls will remain available; restore mobile data after testing. The script does not toggle mobile data automatically.

See **[android/README.md](android/README.md)** for the exact routing checks, relay behavior, and limitations.

## Using the Pi bridge (each session)

1. Plug in the Pi and turn on the robot. On macOS the menu-bar app shows connectivity; on Windows and Linux use `ftc-bridge health`.
2. Choose the robot (`ftc-bridge robots`, then `ftc-bridge use NAME`) and confirm it is the right Control Hub.
3. From the FTC robot project folder, run `ftc-bridge upload` (or select the Control Hub in Android Studio and press Run). Without the app, connect ADB with `adb connect 10.12.194.1:5555`.

**Different robot?** Select it in the Mac app or use `ftc-bridge use practice`. Never assume a saved robot name means the Pi is connected to the right hub; verify with `ftc-bridge health`.

## macOS menu-bar app
| Icon | Meaning |
|---|---|
| radio waves | Connected to the robot |
| radio waves, crossed out | Pi plugged in, robot not reachable (robot off, or none chosen) |
| plug | Pi not plugged in |

The **Health** card shows the Wi-Fi signal and channel, whether the robot app and adb answer, whether it's the same hub this robot had before (so you don't upload to the wrong robot), and a **Test** button for the real upload speed.

While it's open, the app records the robot's log to `~/Library/Logs/ftc-bridge/robot.log`, so the log commands and AI tools read it instantly, and uploads add a marker so "everything since the last upload" is one command.

If robot code throws, freezes, or crashes the app, you get a notification with the error and the line in your code, and a **Copy error** button for pasting into an AI chat.

**Open Panels** opens the robot's Panels dashboard (telemetry, graphs, OpMode control, Limelight) in your browser at `http://localhost:8001`, through the Pi. The robot code needs Panels.

The ⚙ button has settings (open at login, robot name in the menu bar, connect Android Studio, notifications, crash alerts), **Back up robot**, and Pi controls: **Disconnect from robot**, **Restart Pi**, **Shut down Pi**.

## Robot data (BridgeLog)
Copy `robot/BridgeLog.java` into your `TeamCode` folder (in `org.firstinspires.ftc.teamcode`). From then on every OpMode run is recorded on the robot by itself, 25 times a second, as one CSV per run: time, init/run phase, each motor's power, position and velocity, battery voltage, and a goBILDA Pinpoint's position and heading if you have one. Add anything else with one line in your loop, e.g. `BridgeLog.put("aimError", error);`.

```
ftc-bridge data                     list runs on the robot
ftc-bridge data pull                copy the newest run to this computer (about a second)
ftc-bridge data summary             min / max / mean of every column, and how long it ran
```
AI tools: `robot_data_runs`, `robot_data_summary`, `robot_data_rows` (pick columns and a time window).

It reads the hubs with its own bulk reads, so it doesn't change what your OpMode reads, but it does add some hub traffic: set `BridgeLog.hz` lower, or `BridgeLog.enabled = false`, if your loop timing matters more.

## Pi bridge terminal command (for you or an AI agent)

The commands in this section require the **Raspberry Pi route**. They are not commands for the Android/Termux relay.

```
ftc-bridge status               which robot the Pi is on, and whether it answers
ftc-bridge robots               saved robots (name, Wi-Fi name)
ftc-bridge scan                 nearby Wi-Fi networks
ftc-bridge add NAME WIFI_NAME   save a robot; password from stdin (asked if you're typing)
ftc-bridge use NAME             switch to that robot
ftc-bridge forget NAME          delete a saved robot
ftc-bridge disconnect           take the Pi off the robot's Wi-Fi
ftc-bridge reboot | shutdown    restart or shut down the Pi
ftc-bridge update-pi            update the Pi's software from this computer
ftc-bridge pi-log               how the Pi's last run ended (shows what it was doing if it froze), and how often the USB link went dead
ftc-bridge key                  this computer's public key
ftc-bridge add-key "KEY"        let another computer (e.g. a teammate's PC) use the Pi
ftc-bridge health               signal, channel, robot app, adb, and whether it's the same hub as before
ftc-bridge speedtest            real upload speed to the robot
ftc-bridge upload [NAME]        send code to the robot (run in the robot project); uses Sloth if the project has it
ftc-bridge upload --full [NAME] full install + app restart (after changing libraries); backs up the robot first
ftc-bridge test                 run the TeamCode unit tests (no robot needed)
ftc-bridge logs [--errors] [--since-mark] [N]   the robot's recent log; --since-mark: since the last upload or mark
ftc-bridge search PATTERN       search the robot's log
ftc-bridge crashes [N]          crashes and exceptions in the robot's recent log
ftc-bridge mark TEXT            put a marker in the log (e.g. "starting intake test")
ftc-bridge record               record the robot's log on this Mac (the app does this for you)
ftc-bridge backup               save the robot's configs and app to this Mac (newest 5 kept per robot)
ftc-bridge backups              list backups
ftc-bridge restore ROBOT/TIME   put a backup back on the robot
ftc-bridge panels [--stop]      open the robot's Panels dashboard at http://localhost:8001
ftc-bridge tuning [--stop]      open Pedro Pathing's AutoTune page at http://localhost:10158 (Foresight and the other tuners)
ftc-bridge adb ARGS...          any adb command, sent to the robot through the Pi
```
An agent passes the password on stdin, so it isn't in the command line:
`printf '%s\n' 'the-password' | ftc-bridge add comp 12345-RC`

## AI apps (MCP)

The existing MCP server controls Connor's **Pi-based** `ftc-bridge` CLI. It does not automatically operate the Android-phone bridge.

`mcp/server.py` gives AI apps these tools: `status`, `health`, `list_robots`, `scan`, `use_robot`, `upload`, `run_tests`, `logs`, `search_logs`, `mark_log`, `crashes`, `speed_test`, `backup`, `list_backups`, `restore_backup`, `open_panels`, `open_tuning`, `read_telemetry` (live Panels values), `robot_data_runs`, `robot_data_summary`, `robot_data_rows`, `pi_log`, `update_pi`, `disconnect`. `install.sh` sets it up; to do it by hand, it needs [uv](https://docs.astral.sh/uv/) (`brew install uv`):

**Claude Code:**
```bash
claude mcp add --scope user ftc-bridge -- uv run /path/to/ftc-pi-bridge/mcp/server.py
```

**Claude desktop app:** add to `~/Library/Application Support/Claude/claude_desktop_config.json`, then restart the app:
```json
{ "mcpServers": { "ftc-bridge": { "command": "/opt/homebrew/bin/uv", "args": ["run", "/path/to/ftc-pi-bridge/mcp/server.py"] } } }
```

**Codex:** add to `~/.codex/config.toml`:
```toml
[mcp_servers.ftc-bridge]
command = "uv"
args = ["run", "/path/to/ftc-pi-bridge/mcp/server.py"]
```

Paste this into your robot repo's `CLAUDE.md` / `AGENTS.md`:
> To upload robot code: run `ftc-bridge robots` and make sure you know which robot the user means (ask if unclear). Then run `ftc-bridge upload <name>` from the project root. If it fails, run `ftc-bridge status` and report what it says.

## Updating

Run `git pull` to get the latest scripts. On macOS, rerun `./install.sh` to rebuild the menu-bar app. On Linux, rerun `bash linux/install.sh` as needed; Windows users can rerun `windows/install.ps1`.

On the **Pi route**, use `ftc-bridge pi-version` to compare the installed firmware with the repository and `ftc-bridge update-pi` when an update is needed. On macOS the app can also offer the update. Updating Pi software does not require reflashing the SD card. The Android phone route has no Pi firmware to update.

## Troubleshooting

Start with the connection path you are actually using. Running commands from the other path won't fix it.

| Symptom | Pi bridge (macOS / Windows / Linux) | Android bridge (Windows) |
|---|---|---|
| Relay not detected | Check the USB data cable and USB network adapter. Try `ping 10.12.194.1`; run `ftc-bridge health`. | Check `adb devices -l` for an **authorized USB phone** before attempting the robot connection. |
| Laptop internet stops working | Don't turn on Internet Sharing/Connection Sharing for the Pi; the USB link should not become the default internet route. | Leave Windows on its usual internet Wi-Fi; the phone joins the robot Wi-Fi. |
| Robot unavailable | Run `ftc-bridge status` and `ftc-bridge health`; check the saved robot's SSID and Pi Wi-Fi connection. | Check that the phone is on the robot Wi-Fi and that Termux's relay is running; consult [Android routing checks](android/README.md#android-mobile-data-routing). |
| ADB not connecting | After Pi/robot connectivity is healthy, try `adb connect 10.12.194.1:5555`. | First confirm the phone appears in `adb devices`, then run `android/connect.ps1`. The robot target is `127.0.0.1:15555`, not the phone's serial. |
| Upload failed | Run `ftc-bridge health`, verify the target robot, then try `ftc-bridge upload --full` if Sloth hot reload is unsuitable for the change. | ADB connectivity has been verified, but full deployment has not; check Android Studio's build/deploy output rather than assuming the relay succeeded. |

**Useful Pi checks:**

```bash
ftc-bridge health
ftc-bridge robots
ftc-bridge status
ftc-bridge pi-version
adb devices -l
```

**Useful Android checks (Windows PowerShell):**

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb devices -l
& $adb connect 127.0.0.1:15555
```

A phone appearing in the first command proves only Windows-to-phone ADB. A target `127.0.0.1:15555` shown as `device` after the relay starts is the separate robot connection.

## Things to know
- **On a Pi Zero 2 W, the robot must be on 2.4 GHz.** It can't see 5 GHz. Control Hubs ship on 2.4 GHz, but events may ask you to use 5 GHz; there, use the normal USB cable.
- **Before a match, disconnect the Pi** (⚙ → Disconnect from robot, `ftc-bridge disconnect`, or unplug it). Rule R704.C: only the Driver Station may be on the robot's Wi-Fi during a match.
- **Shut down the Pi before unplugging it** (⚙ → Shut down Pi) to protect the SD card.
- **Don't turn on macOS Internet Sharing for the Pi.** The Pi changes its address when you do.
- **The USB link can go dead by itself** (seen with a Mac after 10-25 minutes: the Pi keeps running, but the computer can't reach it until the cable is pulled). The Pi now catches that: it re-plugs the link in software, then again, and if the computer still isn't back it restarts itself, like pulling the cable. Back within about 1-3 minutes. The app tells you: **The Pi stopped answering**, then **The Pi is back**. `ftc-bridge pi-log` shows how often it happened and what it took.
- **Debugging the Pi:** `ssh -i ~/.ssh/ftcpi ftc@10.12.194.1`. The app's own log (the Pi coming and going, notifications sent) is `~/Library/Logs/ftc-bridge/app.log`.

## What's in here
| File | Does |
|---|---|
| `flash.sh` | Writes Raspberry Pi OS Lite plus the files below onto the SD card |
| `pi/adb-forward.py` | Forwards port 5555 from the USB link to the robot at `192.168.43.1:5555` |
| `pi/no-gateway.conf` | Keeps the Mac's internet on its own Wi-Fi |
| `pi/ftc-hub` | Saves and switches robots on the Pi |
| `install.sh` | Sets everything up on a Mac |
| `ftc-bridge` | The terminal command |
| `mcp/server.py` | The MCP server for AI apps |
| `mac/` | The FTC Bridge menu bar app |
| `windows/` | Windows Pi client and installer |
| `linux/` | Linux installer and setup instructions for the same Pi bridge |
| `android/` | Separate Windows-to-Android-phone relay and its instructions |
| `robot/BridgeLog.java` | Drop-in recorder for your robot code |

## License
MIT
