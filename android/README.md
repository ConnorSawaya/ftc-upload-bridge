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
- If Android routes Termux traffic through mobile data instead of robot Wi-Fi,
  temporarily disable mobile data while developing. Cellular voice calls normally still work.
- The robot Wi-Fi must be connected for real deployments. The relay can start
  while the robot is powered off, but `adb connect` will not work yet.
- The phone-to-robot network and Limelight/telemetry paths are not yet tested
  end-to-end on the Sonim XP3plus 5G. Verify on a robot before relying on it.
