# Android USB bridge for FTC

Use an Android phone instead of a Raspberry Pi to reach the REV Control Hub
without changing the laptop's Wi-Fi. The phone relays ADB over USB and its
connection to the robot's Wi-Fi; **USB tethering and root are not required**.

```
Windows Android Studio <--USB ADB--> phone (Termux + socat) <--Wi-Fi--> Control Hub
          127.0.0.1:15555                                    192.168.43.1:5555
```

## One-time setup

1. Enable **USB debugging** on the phone and approve the laptop in `adb devices`.
2. Sideload [Termux](https://f-droid.org/packages/com.termux/) and open it once.
3. With phone internet available, run `pkg install socat` in Termux.

## Each session

1. Turn on the Control Hub and connect the **phone** to its Wi-Fi. Choose
   *Stay connected* if Android warns that this network has no internet.
2. Leave the **laptop** on its usual internet Wi-Fi; plug in the phone over USB.
3. Run from the repository root in Windows PowerShell:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\android\connect.ps1
   ```

   If several USB phones are connected, add `-PhoneSerial SERIAL`.
   The script opens Termux, starts the TCP relay, configures `adb forward`,
   and runs `adb connect 127.0.0.1:15555`.
4. Select `127.0.0.1:15555` in **Android Studio** and press **Run** repeatedly.

## Android mobile data routing

Some phones (including the Sonim XP3plus 5G) can stay connected to the Control
Hub's Wi-Fi but send traffic to `192.168.43.1` over **cellular data** instead,
because the robot's Wi-Fi has no internet. This causes timeouts even when
`adb devices` can see the phone and the USB port forward exists.

If `adb connect 127.0.0.1:15555` times out, check the route **from Windows
PowerShell** (nothing needs to be typed on the phone):

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb devices                 # identify the USB phone's serial
& $adb -s PHONE_SERIAL shell ip route get 192.168.43.1
```

Replace `PHONE_SERIAL` with the phone serial shown by `adb devices`.
The route should say `dev wlan0` and use an address like `192.168.43.x`.
If it says `dev rmnet_data...`, Android is trying to use cellular instead.

**Only if needed**, temporarily turn off the phone's mobile data:

```powershell
& $adb -s PHONE_SERIAL shell svc data disable
& $adb -s PHONE_SERIAL shell ip route get 192.168.43.1
& $adb connect 127.0.0.1:15555
```

This disables **cellular internet data on the phone**, not the laptop's
internet. Ordinary cellular voice calls and SMS should continue to work;
Wi-Fi calling and MMS can depend on the carrier and connection. The
`connect.ps1` script does **not** change mobile data automatically.

**Restore mobile data when finished**:

```powershell
& $adb -s PHONE_SERIAL shell svc data enable
```

If `dev wlan0` is shown but the robot still times out, check that the Control
Hub is powered on, the phone joined its Wi-Fi, and Termux's `socat` relay is
running.

## Logs and dashboards

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb -s 127.0.0.1:15555 logcat
# When Panels is installed on the robot:
& $adb -s 127.0.0.1:15555 forward tcp:8001 tcp:8001
& $adb -s 127.0.0.1:15555 forward tcp:8002 tcp:8002
# Open http://localhost:8001
```

Panels' Limelight proxy may also require forwarding ports `5800`, `5801`,
`5805`, and `5807` from the Control Hub using the same ADB command pattern.

## Limitations

- **Keep Termux running** while using the bridge. Android battery management
  may stop it in the background; disable battery optimization if needed.
- The script enters the relay command via Android's keyboard-input interface.
  It expects Termux to be at a shell prompt on first launch, with the
  screen unlocked. On subsequent runs it reuses an already-working relay. If that fails,
  enter this command directly into Termux instead:

  ```sh
  socat TCP-LISTEN:15555,bind=127.0.0.1,reuseaddr,fork TCP:192.168.43.1:5555
  ```

  Then rerun the Windows script (the running relay remains active).
- If the relay is running but the robot is off, launching again may type into
  the busy terminal. Stop socat with Ctrl+C before relaunching, or restart Termux.
- The robot Wi-Fi must be connected for real deployments. The relay can start
  while the robot is powered off, but `adb connect` will not work yet.
- The Sonim XP3plus 5G has successfully reached a REV Control Hub through this
  USB-to-Wi-Fi ADB bridge. Actual app deployment and Panels/Limelight streaming
  still need separate testing.
