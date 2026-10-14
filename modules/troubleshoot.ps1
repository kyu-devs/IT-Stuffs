# ============================================================
# ONYX IT DEPARTMENT TECH TOOLS - Custom Problem Solver (Module 14)
# Describe your problem, get step-by-step fix suggestions.
# Hardware diagnostics activate when software fixes fail.
# ============================================================

$host.UI.RawUI.WindowTitle = "ONYX IT DEPARTMENT TECH TOOLS - Custom Problem Solver"

# == Helpers ===================================================================

function Write-Header {
    param([string]$Title)
    $bar = "   +-------------------------------------------------------------------------------------------------+"
    $pad = " " * [Math]::Max(0, [Math]::Floor((97 - $Title.Length) / 2))
    $extra = if (($Title.Length % 2) -ne 0) { " " } else { "" }
    Write-Host ""
    Write-Host $bar -ForegroundColor Green
    Write-Host ("   |" + $pad + $Title + $pad + $extra + " |") -ForegroundColor Green
    Write-Host $bar -ForegroundColor Green
    Write-Host ""
}

function Write-Step {
    param([int]$Num, [string]$Desc)
    Write-Host ("   [" + $Num + "] " + $Desc) -ForegroundColor Cyan
}

function Write-Info  { param([string]$Msg) Write-Host ("   [*] " + $Msg) -ForegroundColor Green   }
function Write-Warn  { param([string]$Msg) Write-Host ("   [!] " + $Msg) -ForegroundColor Yellow  }
function Write-Done  { param([string]$Msg) Write-Host ("   [+] " + $Msg) -ForegroundColor Green   }
function Write-Fail  { param([string]$Msg) Write-Host ("   [-] " + $Msg) -ForegroundColor Red     }
function Write-Skip  { param([string]$Msg) Write-Host ("   [~] " + $Msg) -ForegroundColor DarkGray }

function Ask-Confirm {
    param([string]$Question)
    Write-Host ""
    Write-Host ("   [?] " + $Question + " [Y/N] : ") -ForegroundColor Yellow -NoNewline
    $ans = (Read-Host).Trim().ToUpper()
    return ($ans -eq "Y")
}

function Pause-Return {
    Write-Host ""
    Write-Host "   Press ENTER to continue..." -ForegroundColor DarkGray
    Read-Host | Out-Null
}

function Run-Step {
    param(
        [int]$Num,
        [string]$Desc,
        [string]$Reason,
        [scriptblock]$Action,
        [switch]$RequiresReboot
    )
    Write-Host ""
    Write-Host "   -----------------------------------------------------------------------------" -ForegroundColor DarkGreen
    Write-Step -Num $Num -Desc $Desc
    Write-Host ("   Reason : " + $Reason) -ForegroundColor DarkGray
    if ($RequiresReboot) {
        Write-Warn "This step may require a restart to take full effect."
    }
    if (Ask-Confirm "Apply this fix?") {
        try {
            & $Action
            Write-Done "Done."
        } catch {
            Write-Fail ("Error: " + $_.Exception.Message)
        }
    } else {
        Write-Skip "Skipped."
    }
}

# == Hardware Checklist Display and Interactive Diagnostics ====================

function Show-HardwareChecks {
    param(
        [array]$Checks,
        [string]$Category
    )

    Write-Host ""
    Write-Host "   +=============================================================================================+" -ForegroundColor Yellow
    Write-Host "   |                     [!] HARDWARE DIAGNOSTICS & PHYSICAL ISOLATION CHECKS                    |" -ForegroundColor Yellow
    Write-Host "   +=============================================================================================+" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Notice: Software diagnostics and adjustments did not resolve this problem." -ForegroundColor White
    Write-Host "   When Windows configuration and drivers are healthy, the root cause is almost always PHYSICAL." -ForegroundColor White
    Write-Host ("   Category: " + $Category) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   Let us walk through the physical hardware troubleshooting checklist step by step:" -ForegroundColor Cyan
    Write-Host ""

    $resolved = $false
    for ($i = 0; $i -lt $Checks.Count; $i++) {
        $c = $Checks[$i]
        Write-Host "   ---------------------------------------------------------------------------------------------" -ForegroundColor DarkGreen
        Write-Host ("   [Physical Check " + ($i+1) + "/" + $Checks.Count + "] " + $c.Check) -ForegroundColor Yellow
        Write-Host ("   Guidance : " + $c.Detail) -ForegroundColor White
        Write-Host ""

        Write-Host "   [?] Did this physical check identify or resolve the problem? [Y/N] : " -ForegroundColor Yellow -NoNewline
        $ans = (Read-Host).Trim().ToUpper()
        if ($ans -eq "Y") {
            Write-Host ""
            Write-Done ("ROOT CAUSE IDENTIFIED: " + $c.Check)
            Write-Host "   Physical issue identified. The component was fixed or verified to need repair/replacement." -ForegroundColor Green
            Write-Host ""
            $resolved = $true
            Pause-Return
            break
        } else {
            Write-Skip "Not resolved by this check. Proceeding to next hardware test..."
        }
    }

    if (-not $resolved) {
        Write-Host ""
        Write-Host "   +---------------------------------------------------------------------------------------------+" -ForegroundColor Red
        Write-Host "   |                                   FINAL HARDWARE VERDICT                                    |" -ForegroundColor Red
        Write-Host "   +---------------------------------------------------------------------------------------------+" -ForegroundColor Red
        Write-Host "   [!] Both software repairs and physical isolation checks have been exhausted." -ForegroundColor Red
        Write-Host "   [>] Primary Conclusion: Component hardware failure detected." -ForegroundColor Yellow
        Write-Host "       The related hardware component (e.g. monitor panel, GPU, RAM, drive, or motherboard)" -ForegroundColor White
        Write-Host "       likely has internal electrical or physical damage and requires repair or replacement." -ForegroundColor White
        Write-Host ""
        Pause-Return
    }
}

# â”€â”€ Hardware Diagnostic Checklists â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
# Physical troubleshooting steps triggered whenever software fixes fail to resolve the issue.

$HardwareChecklists = @{
    "Monitor / Screen Flickering" = @(
        @{
            Check  = "Perform the Monitor OSD (On-Screen Display) Menu Test"
            Detail = "Press the physical MENU button on the monitor bezel. Observe: Does the monitor built-in OSD menu itself flicker?`n        -> If YES: The monitor internal panel, LED backlight driver, or power inverter board is FAILING. Replace monitor.`n        -> If NO: The monitor panel is completely healthy! The fault is the cable, GPU port, or graphics card."
        }
        @{
            Check  = "Check and re-seat video cables at both ends (HDMI / DisplayPort / VGA)"
            Detail = "Unplug both ends of the display cable. Inspect for bent, recessed, or oxidized pins. Blow out port dust and reconnect firmly. (Tighten thumbscrews if using VGA/DVI)."
        }
        @{
            Check  = "Swap the display cable with a certified high-speed cable"
            Detail = "Degraded or cheap cables cannot maintain handshake bandwidth at higher resolutions/refresh rates, causing intermittent blackouts or flicker. Test with a known-good cable."
        }
        @{
            Check  = "Test with an alternative GPU port or motherboard video output"
            Detail = "If your GPU has multiple DisplayPort or HDMI jacks, switch ports. A damaged port or solder crack on the GPU bracket causes signal drops."
        }
        @{
            Check  = "Power off, unplug PC, and re-seat the dedicated GPU in its PCIe slot"
            Detail = "A GPU that has sagged or has oxidized PCIe gold fingers will lose signal continuity. Remove card, blow out PCIe slot, reseat firmly, and re-connect 6/8-pin PCIe power cables."
        }
        @{
            Check  = "Cross-test the monitor on a laptop or secondary PC"
            Detail = "Connect the monitor to another device. If it flickers there too, the monitor hardware is 100% defective. If it works smoothly, the original PC graphics card is faulty."
        }
        @{
            Check  = "Check power outlet, surge protector, and ground loop interference"
            Detail = "Heavy inductive loads (air conditioners, refrigerators, laser printers) on the same electrical circuit or ungrounded outlets induce line noise that flickers monitors."
        }
    )

    "Slow / Freezing Computer" = @(
        @{
            Check  = "Inspect cooling fans and heatsink dust buildup (Thermal Throttling)"
            Detail = "Clogged dust on CPU/GPU heatsinks causes severe thermal throttling where the CPU downclocks to 0.79 GHz to prevent melting. Clean with compressed air."
        }
        @{
            Check  = "Inspect CPU cooler mounting pressure and thermal compound"
            Detail = "Dry thermal paste, loose plastic push-pins, or a failed AIO liquid pump causes instant 95C+ temps and sudden freeze-ups under light load."
        }
        @{
            Check  = "RAM stick reseating and single-stick isolation test"
            Detail = "Power off, remove all RAM modules. Clean gold contacts with an eraser. Test booting with one stick at a time in memory slot 2 to isolate a defective stick."
        }
        @{
            Check  = "Listen for physical clicking, grinding, or chirping from mechanical hard drives"
            Detail = "Head parking clicks or mechanical grinding indicate an imminent head crash and physical platter damage. Back up data immediately."
        }
        @{
            Check  = "Inspect SATA / NVMe physical connection"
            Detail = "Loose SATA data/power cables or an unseated M.2 NVMe drive causes CRC bus transfer errors that freeze the entire operating system for 30-60 seconds."
        }
        @{
            Check  = "Inspect Power Supply (PSU) voltages and motherboard capacitors"
            Detail = "Failing 12V rails or bulging/leaking electrolytic capacitor tops cause voltage sags, leading to hardware lockups under load."
        }
    )

    "No Internet / Network Connection" = @(
        @{
            Check  = "Verify RJ-45 physical link and activity LEDs"
            Detail = "Look at the Ethernet port on the back of the PC. A solid green/amber light means physical link is established. No light = dead cable, dead port, or dead switch port."
        }
        @{
            Check  = "Swap network patch cable with a certified Cat5e / Cat6 cable"
            Detail = "Internal copper wire breaks or broken RJ-45 retention clips prevent physical gigabit negotiation."
        }
        @{
            Check  = "Connect to a different switch port or router LAN port"
            Detail = "Individual switch ports can get burned out by electrical surges. Move the cable to another port on the router."
        }
        @{
            Check  = "Perform a 30-second modem and router power cycle"
            Detail = "Unplug power from both modem and router for 30 seconds. Plug modem in first, wait for downstream lock, then power on the router."
        }
        @{
            Check  = "Inspect Wi-Fi external antennas and internal M.2 antenna leads"
            Detail = "Ensure external dipole antennas are screwed tight. On laptops, verify the tiny gold U.FL antenna leads have not popped off the M.2 Wi-Fi card."
        }
        @{
            Check  = "Test with a USB-to-Ethernet or USB Wi-Fi dongle"
            Detail = "If an external USB adapter connects instantly, the onboard motherboard NIC has suffered hardware failure."
        }
    )

    "Blue Screen of Death (BSOD)" = @(
        @{
            Check  = "Test RAM modules individually with MemTest86"
            Detail = "Faulty RAM cells corrupt kernel structures randomly. Boot a MemTest86 USB drive and test each RAM stick individually to locate the defective module."
        }
        @{
            Check  = "Inspect storage drive for physical bad sectors (S.M.A.R.T.)"
            Detail = "A failing SSD NAND flash controller or HDD surface error corrupts critical OS files, causing PAGE_FAULT_IN_NONPAGED_AREA or KERNEL_DATA_INPAGE_ERROR."
        }
        @{
            Check  = "Reseat graphics card and verify PCIe 6/8-pin power cables"
            Detail = "Insufficient power delivery or poor PCIe contact triggers VIDEO_TDR_FAILURE or WHEA_UNCORRECTABLE_ERROR."
        }
        @{
            Check  = "Inspect motherboard VRM circuitry and capacitors"
            Detail = "Look for scorch marks or bulging capacitors around the CPU socket. Damaged VRMs cause unstable Vcore voltage."
        }
        @{
            Check  = "Test with an alternative known-good Power Supply (PSU)"
            Detail = "An aging power supply with high ripple voltage causes sudden kernel panics across random subsystems."
        }
    )

    "Printer Not Working" = @(
        @{
            Check  = "Inspect USB / Network cable and test a rear motherboard USB port"
            Detail = "Avoid unpowered USB hubs or loose front-case ports. Plug directly into the rear I/O panel."
        }
        @{
            Check  = "Check physical printer hardware status screen and error LEDs"
            Detail = "Look for blinking amber warning lights, door/cover ajar indicators, or optical sensor flags."
        }
        @{
            Check  = "Inspect paper feed tray, pickup rollers, and paper path for micro-jams"
            Detail = "Torn slivers of paper or foreign objects (paperclips) physically prevent the pickup roller from cycling."
        }
        @{
            Check  = "Print a standalone hardware test page directly using printer buttons"
            Detail = "Power on printer and hold the Resume/Feed button for 5 seconds. If the hardware self-test fails, the printer itself is broken."
        }
        @{
            Check  = "Inspect and clean ink/toner electrical contact pads"
            Detail = "Remove cartridges and inspect the copper electrical contacts on both cartridge and carriage for ink residue. Clean with isopropyl alcohol."
        }
    )

    "No Sound / Audio Problems" = @(
        @{
            Check  = "Inspect 3.5mm audio jack physical seating and port color (Light Green)"
            Detail = "Push the 3.5mm plug firmly until you feel a positive mechanical click. Half-inserted plugs produce silence or ground hum."
        }
        @{
            Check  = "Test rear motherboard audio jack instead of front case panel"
            Detail = "Front case headphone jacks frequently break internally or experience wire ground interference inside the case."
        }
        @{
            Check  = "Cross-test speakers or headphones on a mobile phone or another device"
            Detail = "Quickly confirms whether the speaker amplifier, internal voice coil, or cable has failed."
        }
        @{
            Check  = "Inspect speaker external power brick and physical volume knob"
            Detail = "Verify active desktop speakers are receiving power and that the physical potentiometer switch is turned on."
        }
        @{
            Check  = "Inspect internal motherboard HD_AUDIO front-panel header"
            Detail = "Open the case and verify the 9-pin HD_AUDIO cable from the front panel is firmly plugged onto the motherboard header pins."
        }
    )

    "High Disk Usage / Low Disk Space" = @(
        @{
            Check  = "Inspect mechanical HDD for surface degradation and head thrashing"
            Detail = "When mechanical drives encounter weak or bad sectors, the drive firmware repeatedly retries reading, locking disk usage at 100%."
        }
        @{
            Check  = "Replace SATA data cable and switch motherboard SATA port"
            Detail = "Degraded SATA cables trigger UltraDMA CRC errors, causing Windows to demote disk transfer mode down to slow PIO mode."
        }
        @{
            Check  = "Upgrade mechanical hard drive (HDD) to a Solid State Drive (SSD)"
            Detail = "Modern Windows 10/11 is architected around SSD 4K random read speeds. Mechanical HDDs will almost always bottleneck at 100% activity."
        }
    )

    "Application Crashing / Not Responding" = @(
        @{
            Check  = "Test RAM modules for memory bit-flips"
            Detail = "Defective RAM addresses cause applications to crash the moment data is allocated in that memory range."
        }
        @{
            Check  = "Monitor real-time GPU and CPU temperatures during application load"
            Detail = "Heavy 3D or compute apps spike thermal load; overheating triggers an immediate GPU crash back to desktop."
        }
        @{
            Check  = "Check storage drive S.M.A.R.T. health for bad sectors"
            Detail = "If application executable or DLL files reside on failing disk sectors, reading them triggers instant app termination."
        }
    )

    "High CPU Usage" = @(
        @{
            Check  = "Verify CPU cooling fan is spinning and heatsink fins are clear"
            Detail = "If the CPU fan is dead or clogged with dust, the processor drops into emergency clock speed (down to 800 MHz), maxing out CPU % on tiny tasks."
        }
        @{
            Check  = "Verify CPU cooler mounting pressure and thermal paste"
            Detail = "Loose cooler brackets or dried paste prevent heat transfer from the integrated heat spreader, causing thermal throttling."
        }
        @{
            Check  = "Verify 4/8-pin CPU EPS 12V power connector seating"
            Detail = "Ensure the dedicated CPU auxiliary power cable at the top-left of the motherboard is firmly locked in."
        }
    )

    "Keyboard / Mouse Not Working" = @(
        @{
            Check  = "Plug directly into rear motherboard USB ports"
            Detail = "Avoid unpowered external USB hubs, monitors, or loose front-panel ports that suffer from voltage sag."
        }
        @{
            Check  = "Test keyboard/mouse on a secondary computer"
            Detail = "Confirm whether the device controller, cable, or internal PCB has suffered physical failure."
        }
        @{
            Check  = "For wireless devices: replace batteries and re-pair USB 2.4GHz receiver"
            Detail = "Low battery voltage causes dropped keystrokes, erratic cursor skipping, or periodic connection drops."
        }
        @{
            Check  = "Inspect USB connector pins for physical damage, bent pins, or lint"
            Detail = "Use a flashlight to inspect USB ports. Bent connector pins prevent data handshake with the USB host controller."
        }
    )

    "General / Unrecognized Issues" = @(
        @{
            Check  = "Inspect all physical cable connections and power plugs"
            Detail = "Verify power cords, display cables, and peripheral connections are firmly seated without cable strain."
        }
        @{
            Check  = "Perform a power discharge (flea power drain)"
            Detail = "Shut down PC, unplug AC power cord, hold the PC power button for 30 seconds to drain motherboard capacitors, reconnect power."
        }
        @{
            Check  = "Clean internal dust buildup from fans, heatsinks, and power supply"
            Detail = "Thermal buildup causes erratic system behavior across CPU, GPU, and RAM."
        }
        @{
            Check  = "Minimal hardware boot test"
            Detail = "Disconnect all external USB devices, secondary drives, and sound devices. Boot with only monitor, keyboard, and mouse."
        }
    )
}

# â”€â”€ Problem Definitions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
# Each problem entry:
#   Keywords  = string[] matched against user input (any match triggers)
#   Title     = display name
#   Intro     = brief explanation of the issue
#   Steps     = array of hashtables { Desc, Reason, Action, RequiresReboot }

$Problems = @(

    # â”€â”€ MONITOR / SCREEN FLICKERING â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    @{
        Keywords = @("monitor","flicker","flickering","screen flicker","display flicker","blinking screen","blink","screen blink","screen flash")
        Title    = "Monitor / Screen Flickering"
        Intro    = "Screen flickering is usually caused by an incompatible display driver, incorrect refresh rate, a misbehaving app or Windows shell component."
        Steps    = @(
            @{
                Desc   = "Check current display refresh rate"
                Reason = "A refresh rate mismatch (e.g. monitor rated 60 Hz but set to 59 Hz) can trigger flicker."
                Action = {
                    $mon = Get-CimInstance -ClassName Win32_VideoController | Select-Object Name, CurrentRefreshRate, VideoModeDescription
                    $mon | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host "   $_" -ForegroundColor Green }
                    Write-Info "If CurrentRefreshRate looks wrong, change it manually in Display Settings > Advanced Display."
                }
            }
            @{
                Desc   = "Detect apps causing flickering (Task Manager method)"
                Reason = "If the Task Manager toolbar does NOT flicker but the rest of the screen does, a third-party app is the culprit."
                Action = {
                    Write-Info "Opening Task Manager..."
                    Start-Process taskmgr.exe
                    Write-Host ""
                    Write-Warn "Observe: Does the Task Manager's title bar flicker along with the rest of the screen?"
                    Write-Host "   - If YES  -> the issue is likely a DRIVER or Windows shell problem (continue below)." -ForegroundColor Cyan
                    Write-Host "   - If NO   -> a background app is causing it. Check for recently installed apps and uninstall them." -ForegroundColor Cyan
                    Pause-Return
                }
            }
            @{
                Desc         = "Update / reinstall display driver via Device Manager"
                Reason       = "An outdated or corrupt GPU driver is the #1 cause of monitor flickering."
                RequiresReboot = $true
                Action       = {
                    Write-Info "Opening Device Manager for display adapters..."
                    Start-Process devmgmt.msc
                    Write-Host ""
                    Write-Host "   Steps to follow in Device Manager:" -ForegroundColor Cyan
                    Write-Host "   1. Expand 'Display adapters'." -ForegroundColor Cyan
                    Write-Host "   2. Right-click your GPU and choose 'Update driver'." -ForegroundColor Cyan
                    Write-Host "   3. Choose 'Search automatically' first." -ForegroundColor Cyan
                    Write-Host "   4. If no update found, visit your GPU vendor website:" -ForegroundColor Cyan
                    Write-Host "      NVIDIA : https://www.nvidia.com/en-us/drivers/" -ForegroundColor Green
                    Write-Host "      AMD    : https://www.amd.com/en/support" -ForegroundColor Green
                    Write-Host "      Intel  : https://www.intel.com/content/www/us/en/download-center/home.html" -ForegroundColor Green
                    Pause-Return
                }
            }
            @{
                Desc         = "Disable Hardware-Accelerated GPU Scheduling (HAGS)"
                Reason       = "HAGS can cause flickering on older monitors or unsupported GPU-monitor combinations."
                RequiresReboot = $true
                Action       = {
                    $path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
                    $cur  = (Get-ItemProperty -Path $path -Name "HwSchMode" -ErrorAction SilentlyContinue).HwSchMode
                    Write-Info "Current HAGS registry value: $cur  (2 = Enabled, 1 = Disabled)"
                    if ($cur -eq 2) {
                        Set-ItemProperty -Path $path -Name "HwSchMode" -Value 1 -Type DWord -Force
                        Write-Done "HAGS disabled. A restart is required."
                    } else {
                        Write-Done "HAGS is already disabled. No change made."
                    }
                }
            }
            @{
                Desc   = "Disable Desktop Window Manager animations (reduce shell flicker)"
                Reason = "Disabling DWM transparency and animations can stop flicker caused by composition glitches."
                Action = {
                    # Turn off transparency effects
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -Type DWord -Force
                    # Disable animations
                    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0" -Force
                    # Disable visual effects
                    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord -Force
                    Write-Done "Transparency and DWM animations disabled."
                    Write-Info "Sign out and sign back in to apply."
                }
            }
            @{
                Desc   = "Check power plan (prevent display power-saving flicker)"
                Reason = "Aggressive power saving can cause the display link to drop momentarily, causing flicker."
                Action = {
                    Write-Info "Setting power plan to Balanced and disabling display sleep..."
                    powercfg -change -monitor-timeout-ac 0
                    powercfg -change -monitor-timeout-dc 0
                    Write-Done "Monitor timeout set to Never (AC and DC)."
                }
            }
            @{
                Desc   = "Check for Windows Shell Experience Host issues"
                Reason = "ShellExperienceHost.exe is a known cause of flicker when it crashes or uses excessive resources."
                Action = {
                    $proc = Get-Process -Name "ShellExperienceHost" -ErrorAction SilentlyContinue
                    if ($proc) {
                        Write-Info "ShellExperienceHost is running. CPU: $($proc.CPU) | Memory: $([Math]::Round($proc.WorkingSet64/1MB, 1)) MB"
                        if ($proc.CPU -gt 10) {
                            Write-Warn "High CPU usage detected on ShellExperienceHost. Restarting it..."
                            Stop-Process -Name "ShellExperienceHost" -Force -ErrorAction SilentlyContinue
                            Start-Sleep -Seconds 2
                            Write-Done "Process restarted by Windows automatically."
                        } else {
                            Write-Done "ShellExperienceHost looks healthy."
                        }
                    } else {
                        Write-Skip "ShellExperienceHost not currently running."
                    }
                }
            }
            @{
                Desc         = "Run System File Checker (sfc /scannow)"
                Reason       = "Corrupted Windows system files can cause display rendering issues and flickering."
                RequiresReboot = $false
                Action       = {
                    Write-Warn "This may take several minutes..."
                    Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Verb RunAs -Wait
                    Write-Done "SFC scan complete. Check output for any errors."
                }
            }
            @{
                Desc   = "Suggest physical checks"
                Reason = "Hardware causes like a loose cable or failing backlight cannot be fixed by software."
                Action = {
                    Write-Host ""
                    Write-Host "   Physical checklist:" -ForegroundColor Cyan
                    Write-Host "   [?] Is the monitor cable (HDMI/DisplayPort/VGA) firmly plugged in at both ends?" -ForegroundColor Green
                    Write-Host "   [?] Try swapping the cable with a known good one." -ForegroundColor Green
                    Write-Host "   [?] Try plugging into a different port on the GPU." -ForegroundColor Green
                    Write-Host "   [?] Test the monitor on a different computer to rule out a faulty panel." -ForegroundColor Green
                    Write-Host "   [?] Check for loose or damaged connectors at the back of the monitor." -ForegroundColor Green
                    Write-Host ""
                    Write-Info "If the monitor still flickers on another PC, the display itself may need to be replaced."
                    Pause-Return
                }
            }
        )
    }

    # â”€â”€ SLOW / FREEZING PC â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    @{
        Keywords = @("slow","sluggish","lag","lagging","freeze","freezing","hanging","hang","unresponsive","speed","performance","loading slow","taking long")
        Title    = "Slow / Freezing Computer"
        Intro    = "Slowness can be caused by high CPU/RAM usage, full disk, malware, startup bloat, or degraded storage health."
        Steps    = @(
            @{
                Desc   = "Show current CPU, RAM, and disk usage"
                Reason = "Identifying the bottleneck (CPU, RAM, or disk) determines the fix direction."
                Action = {
                    $cpu  = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
                    $os   = Get-CimInstance Win32_OperatingSystem
                    $ramUsedGB  = [Math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 1)
                    $ramTotalGB = [Math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
                    $disk = Get-PSDrive C
                    $diskUsedGB = [Math]::Round(($disk.Used) / 1GB, 1)
                    $diskFreeGB = [Math]::Round(($disk.Free) / 1GB, 1)
                    Write-Host ""
                    Write-Host "   CPU  Usage : $cpu %" -ForegroundColor Green
                    Write-Host "   RAM  Usage : $ramUsedGB GB / $ramTotalGB GB" -ForegroundColor Green
                    Write-Host "   Disk (C:)  : $diskUsedGB GB used, $diskFreeGB GB free" -ForegroundColor Green
                    if ($diskFreeGB -lt 10) { Write-Warn "Low disk space! Less than 10 GB free on C: drive." }
                    if ($ramUsedGB / $ramTotalGB -gt 0.85) { Write-Warn "RAM usage above 85%! Consider closing apps or upgrading RAM." }
                    if ($cpu -gt 80) { Write-Warn "CPU usage is very high. Check Task Manager for runaway processes." }
                }
            }
            @{
                Desc   = "Kill top CPU-consuming processes (interactive)"
                Reason = "A runaway process can peg the CPU or RAM, slowing down everything else."
                Action = {
                    Write-Info "Top 5 CPU-consuming processes:"
                    Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 Name, Id, CPU, @{N="RAM(MB)";E={[Math]::Round($_.WorkingSet64/1MB,1)}} | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host "   $_" -ForegroundColor Green }
                    Write-Host "   Enter a Process ID to kill it, or press ENTER to skip: " -ForegroundColor Yellow -NoNewline
                    $pid2kill = (Read-Host).Trim()
                    if ($pid2kill -match "^\d+$") {
                        Stop-Process -Id ([int]$pid2kill) -Force -ErrorAction SilentlyContinue
                        Write-Done "Process $pid2kill terminated."
                    } else {
                        Write-Skip "No process killed."
                    }
                }
            }
            @{
                Desc   = "Clear temporary files and system cache"
                Reason = "Accumulated junk files fill up the disk and slow down read/write operations."
                Action = {
                    Write-Info "Cleaning temp folders..."
                    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
                    Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Done "Temp files cleared."
                }
            }
            @{
                Desc         = "Disable non-essential startup programs"
                Reason       = "Too many startup apps eat RAM on boot and keep the CPU busy in the background."
                RequiresReboot = $true
                Action       = {
                    Write-Info "Opening Startup tab in Task Manager..."
                    Start-Process "taskmgr.exe"
                    Write-Host "   -> Go to the 'Startup apps' tab and disable anything you don't need at boot." -ForegroundColor Cyan
                    Pause-Return
                }
            }
            @{
                Desc   = "Check disk health (S.M.A.R.T.)"
                Reason = "A failing hard drive can cause extreme slowness, freezes, and data loss."
                Action = {
                    Get-CimInstance Win32_DiskDrive | Select-Object Model, Status, Size, InterfaceType | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host "   $_" -ForegroundColor Green }
                    Write-Info "Status 'OK' means the drive reports no errors. Run a full CHKDSK if you suspect a failing drive."
                }
            }
            @{
                Desc   = "Flush standby memory (RAM cleanup)"
                Reason = "Windows sometimes holds RAM in standby longer than needed. Flushing frees it immediately."
                Action = {
                    Write-Info "Triggering .NET garbage collection to free standby RAM..."
                    [System.GC]::Collect()
                    [System.GC]::WaitForPendingFinalizers()
                    [System.GC]::Collect()
                    Write-Done "Memory flush complete."
                }
            }
            @{
                Desc         = "Enable High Performance power plan"
                Reason       = "Balanced or Power Saver plans throttle the CPU. High Performance ensures max clock speeds."
                RequiresReboot = $false
                Action       = {
                    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
                    Write-Done "High Performance power plan activated."
                }
            }
            @{
                Desc   = "Run SFC system file check"
                Reason = "Corrupted Windows system files can cause mysterious slowness and instability."
                Action = {
                    Write-Warn "Running SFC... This may take several minutes."
                    Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Verb RunAs -Wait
                    Write-Done "SFC scan complete."
                }
            }
        )
    }

    # â”€â”€ NO INTERNET / NETWORK â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    @{
        Keywords = @("no internet","internet not working","wifi not working","cant connect","no network","network issue","connection","no connection","dns","cant browse","website not loading","limited connectivity","limited connection")
        Title    = "No Internet / Network Connection"
        Intro    = "Network issues are commonly caused by a stale DHCP lease, corrupted Winsock, bad DNS, or a firewall rule."
        Steps    = @(
            @{
                Desc   = "Ping test to check connectivity layers"
                Reason = "Pinging different hops reveals whether the problem is local (gateway), ISP, or DNS."
                Action = {
                    $targets = @(@{Name="Local Gateway";Addr="192.168.1.1"},@{Name="Google DNS";Addr="8.8.8.8"},@{Name="Cloudflare DNS";Addr="1.1.1.1"},@{Name="Google.com";Addr="google.com"})
                    foreach ($t in $targets) {
                        $r = Test-Connection -ComputerName $t.Addr -Count 2 -Quiet -ErrorAction SilentlyContinue
                        $status = if ($r) { "REACHABLE" } else { "UNREACHABLE" }
                        $color  = if ($r) { "Green" } else { "Red" }
                        Write-Host "   $($t.Name.PadRight(20)) ($($t.Addr.PadRight(15))) : $status" -ForegroundColor $color
                    }
                }
            }
            @{
                Desc   = "Flush DNS cache"
                Reason = "A stale DNS cache can prevent websites from resolving even when the internet is working."
                Action = { ipconfig /flushdns | Out-Null; Write-Done "DNS cache flushed." }
            }
            @{
                Desc   = "Release and renew IP address"
                Reason = "An expired or conflicted DHCP lease can block internet access."
                Action = {
                    ipconfig /release | Out-Null
                    Start-Sleep -Seconds 2
                    ipconfig /renew  | Out-Null
                    Write-Done "IP address released and renewed."
                    ipconfig | Select-String "IPv4|Default Gateway|Subnet" | ForEach-Object { Write-Host "   $_" -ForegroundColor Green }
                }
            }
            @{
                Desc         = "Reset Winsock catalog and TCP/IP stack"
                Reason       = "A corrupted Winsock or TCP/IP stack is a common cause of 'limited connectivity' or no access."
                RequiresReboot = $true
                Action       = {
                    netsh winsock reset | Out-Null
                    netsh int ip reset   | Out-Null
                    Write-Done "Winsock and TCP/IP stack reset. A restart is required."
                }
            }
            @{
                Desc   = "Switch DNS to Cloudflare (1.1.1.1)"
                Reason = "ISP DNS servers can go down or be slow. Cloudflare provides a fast, reliable alternative."
                Action = {
                    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.InterfaceDescription -notlike "*Loopback*" } | Select-Object -First 1
                    if ($adapter) {
                        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses ("1.1.1.1", "1.0.0.1") -ErrorAction SilentlyContinue
                        Write-Done "DNS set to Cloudflare (1.1.1.1 / 1.0.0.1) on $($adapter.Name)."
                    } else {
                        Write-Fail "No active network adapter found."
                    }
                }
            }
            @{
                Desc         = "Reset Windows Firewall to default"
                Reason       = "A misconfigured firewall can silently block all outgoing traffic."
                RequiresReboot = $false
                Action       = {
                    netsh advfirewall reset | Out-Null
                    Write-Done "Windows Firewall reset to defaults."
                }
            }
            @{
                Desc   = "Disable and re-enable the network adapter"
                Reason = "Sometimes the adapter gets stuck in a bad state. A soft-reset fixes it."
                Action = {
                    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.InterfaceDescription -notlike "*Loopback*" } | Select-Object -First 1
                    if ($adapter) {
                        Disable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
                        Start-Sleep -Seconds 3
                        Enable-NetAdapter  -Name $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
                        Write-Done "Adapter '$($adapter.Name)' toggled."
                    } else {
                        Write-Fail "No active adapter found."
                    }
                }
            }
        )
    }

    # â”€â”€ BLUE SCREEN / BSOD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    @{
        Keywords = @("blue screen","bsod","bluescreen","blue screen of death","stop error","kernel panic","crash","system crash","reboot loop","restart loop")
        Title    = "Blue Screen of Death (BSOD)"
        Intro    = "BSODs are triggered by driver faults, RAM errors, corrupted system files, or failing storage."
        Steps    = @(
            @{
                Desc   = "Read latest BSOD stop code from Event Log"
                Reason = "The stop code tells you exactly which component caused the crash."
                Action = {
                    Write-Info "Scanning System event log for BSOD events (Event ID 1001)..."
                    $evts = Get-WinEvent -FilterHashtable @{LogName='System'; Id=1001} -MaxEvents 5 -ErrorAction SilentlyContinue
                    if ($evts) {
                        $evts | ForEach-Object {
                            Write-Host "   [$($_.TimeCreated)] $($_.Message.Substring(0,[Math]::Min(300,$_.Message.Length)))" -ForegroundColor Green
                        }
                    } else {
                        Write-Skip "No recent BSOD entries found in System log."
                        Write-Info "Try checking: Event Viewer > Windows Logs > System (filter by Critical/Error)"
                    }
                }
            }
            @{
                Desc   = "Check for memory dump file"
                Reason = "A minidump file contains the exact driver and code that caused the crash."
                Action = {
                    $dumpPath = "C:\Windows\Minidump"
                    if (Test-Path $dumpPath) {
                        $dumps = Get-ChildItem $dumpPath -Filter "*.dmp" | Sort-Object LastWriteTime -Descending | Select-Object -First 5
                        if ($dumps) {
                            Write-Info "Latest minidump files:"
                            $dumps | Format-Table Name, LastWriteTime, Length -AutoSize | Out-String | ForEach-Object { Write-Host "   $_" -ForegroundColor Green }
                            Write-Info "Analyze these with WinDbg or upload to https://osronline.com/ for a free crash analysis."
                        } else {
                            Write-Skip "No minidump files found in $dumpPath."
                        }
                    } else {
                        Write-Skip "Minidump folder does not exist. Crash dumps may be disabled."
                    }
                }
            }
            @{
                Desc   = "Run System File Checker + DISM repair"
                Reason = "Corrupted Windows system files can cause BSOD crashes."
                Action = {
                    Write-Warn "This will take several minutes..."
                    DISM /Online /Cleanup-Image /RestoreHealth
                    sfc /scannow
                    Write-Done "SFC and DISM completed."
                }
            }
            @{
                Desc         = "Update all drivers (Device Manager)"
                Reason       = "Outdated or incompatible drivers are the leading cause of BSODs."
                RequiresReboot = $true
                Action       = {
                    Start-Process devmgmt.msc
                    Write-Info "Device Manager opened. Right-click devices with yellow warnings and update their drivers."
                    Pause-Return
                }
            }
            @{
                Desc   = "Schedule Windows Memory Diagnostic (RAM test)"
                Reason = "Faulty RAM is a major BSOD cause and only a hardware test can confirm it."
                Action = {
                    if (Ask-Confirm "Schedule RAM test on next reboot? (PC will restart)") {
                        mdsched.exe
                    }
                }
            }
            @{
                Desc   = "Check disk for errors (read-only pass)"
                Reason = "Bad sectors on the boot drive can trigger kernel-level crashes."
                Action = {
                    Write-Info "Running read-only CHKDSK on C:..."
                    chkdsk C: /scan
                }
            }
        )
    }

    # â”€â”€ PRINTER NOT WORKING â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    @{
        Keywords = @("printer","print","printing","printer not working","cant print","printer offline","stuck print","print queue","spooler")
        Title    = "Printer Not Working"
        Intro    = "Printer issues usually stem from a stuck print queue, crashed Spooler service, or driver problems."
        Steps    = @(
            @{
                Desc   = "Restart the Print Spooler service"
                Reason = "The Spooler manages all print jobs. Restarting it clears stuck queues and resets the service."
                Action = {
                    Stop-Service -Name spooler -Force -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 2
                    Remove-Item "C:\Windows\System32\spool\PRINTERS\*" -Recurse -Force -ErrorAction SilentlyContinue
                    Start-Service -Name spooler -ErrorAction SilentlyContinue
                    Write-Done "Print Spooler restarted and print queue cleared."
                }
            }
            @{
                Desc   = "List all installed printers and their status"
                Reason = "Confirms which printers are visible to Windows and their current status."
                Action = {
                    Get-Printer | Select-Object Name, Type, DriverName, PortName, PrinterStatus | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host "   $_" -ForegroundColor Green }
                }
            }
            @{
                Desc   = "Set a printer as default"
                Reason = "Apps may try printing to the wrong printer if the default is not set."
                Action = {
                    $printers = Get-Printer | Select-Object -ExpandProperty Name
                    if ($printers.Count -eq 0) { Write-Fail "No printers installed."; return }
                    for ($i=0;$i -lt $printers.Count;$i++) { Write-Host "   [$($i+1)] $($printers[$i])" -ForegroundColor Cyan }
                    Write-Host ""
                    Write-Host "   Enter number to set as default (or ENTER to skip): " -ForegroundColor Yellow -NoNewline
                    $sel = (Read-Host).Trim()
                    if ($sel -match "^\d+$" -and [int]$sel -ge 1 -and [int]$sel -le $printers.Count) {
                        Set-Printer -Name $printers[[int]$sel - 1] -Default -ErrorAction SilentlyContinue
                        Write-Done "$($printers[[int]$sel - 1]) set as default."
                    } else {
                        Write-Skip "No change made."
                    }
                }
            }
            @{
                Desc         = "Reinstall printer driver"
                Reason       = "A corrupted driver is a common cause of 'Printer Offline' or failed print jobs."
                RequiresReboot = $true
                Action       = {
                    Start-Process "printui.exe" -ArgumentList "/s /t2"
                    Write-Info "Print Server Properties opened. Go to the Drivers tab to remove and reinstall drivers."
                    Pause-Return
                }
            }
            @{
                Desc   = "Enable File and Printer Sharing firewall rules"
                Reason = "If sharing a printer on a network, firewall rules must allow printer traffic."
                Action = {
                    netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes
                    Write-Done "File and Printer Sharing firewall rules enabled."
                }
            }
        )
    }

    # â”€â”€ AUDIO / NO SOUND â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    @{
        Keywords = @("no sound","audio","sound not working","muted","no audio","speaker","headphone","volume","audio not working","sound problem")
        Title    = "No Sound / Audio Problems"
        Intro    = "Sound issues are usually caused by a muted device, wrong default playback device, or a corrupted audio driver."
        Steps    = @(
            @{
                Desc   = "List audio devices and check if they are enabled"
                Reason = "The wrong or disabled device can silence all audio output."
                Action = {
                    Get-CimInstance Win32_SoundDevice | Select-Object Name, Status, DeviceID | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host "   $_" -ForegroundColor Green }
                    Write-Info "Open Sound settings to set the correct default playback device."
                    Start-Process ms-settings:sound
                }
            }
            @{
                Desc   = "Restart Windows Audio service"
                Reason = "The audio service sometimes crashes silently, killing all sound."
                Action = {
                    Restart-Service -Name "AudioSrv" -Force -ErrorAction SilentlyContinue
                    Restart-Service -Name "AudioEndpointBuilder" -Force -ErrorAction SilentlyContinue
                    Write-Done "Audio services restarted."
                }
            }
            @{
                Desc         = "Update audio driver"
                Reason       = "An outdated Realtek, Intel, or NVIDIA audio driver is a common cause of no-sound issues."
                RequiresReboot = $true
                Action       = {
                    Start-Process devmgmt.msc
                    Write-Info "Device Manager opened. Expand 'Sound, video and game controllers' and update your audio driver."
                    Pause-Return
                }
            }
            @{
                Desc   = "Run the Windows Audio troubleshooter"
                Reason = "Windows has a built-in audio fixer that can automatically resolve common problems."
                Action = {
                    Start-Process msdt.exe -ArgumentList "/id AudioPlaybackDiagnostic"
                    Write-Info "Audio troubleshooter launched. Follow the on-screen steps."
                    Pause-Return
                }
            }
        )
    }

    # â”€â”€ HIGH DISK USAGE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    @{
        Keywords = @("disk usage","disk 100","100 disk","high disk","disk full","storage full","c drive full","no space","disk space","out of space")
        Title    = "High Disk Usage / Low Disk Space"
        Intro    = "100% disk usage or a nearly full drive can make Windows crawl. Common causes: Windows Search, Superfetch, or insufficient free space."
        Steps    = @(
            @{
                Desc   = "Show current disk usage summary"
                Reason = "Identifies how much space is used on each partition."
                Action = {
                    Get-CimInstance Win32_LogicalDisk | Select-Object Caption, @{N="Used(GB)";E={[Math]::Round(($_.Size-$_.FreeSpace)/1GB,1)}}, @{N="Free(GB)";E={[Math]::Round($_.FreeSpace/1GB,1)}}, @{N="Total(GB)";E={[Math]::Round($_.Size/1GB,1)}} | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host "   $_" -ForegroundColor Green }
                }
            }
            @{
                Desc   = "Disable SysMain (Superfetch)"
                Reason = "Superfetch can spike disk usage on slower HDDs by constantly pre-loading apps."
                Action = {
                    Stop-Service -Name SysMain -Force -ErrorAction SilentlyContinue
                    Set-Service  -Name SysMain -StartupType Disabled
                    Write-Done "SysMain (Superfetch) stopped and disabled."
                }
            }
            @{
                Desc   = "Disable Windows Search indexing"
                Reason = "The search indexer causes heavy disk I/O, especially on spinning HDDs."
                Action = {
                    Stop-Service -Name WSearch -Force -ErrorAction SilentlyContinue
                    Set-Service  -Name WSearch -StartupType Disabled
                    Write-Done "Windows Search indexer stopped and disabled."
                }
            }
            @{
                Desc   = "Clear temp files and Windows cache"
                Reason = "Frees hidden disk space from temp directories and Windows Update cache leftovers."
                Action = {
                    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
                    Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Done "Temp files cleared."
                }
            }
            @{
                Desc   = "Run Disk Cleanup (GUI)"
                Reason = "Disk Cleanup removes delivery optimization files, recycle bin, thumbnails, and more."
                Action = {
                    Start-Process cleanmgr.exe -ArgumentList "/sagerun:1"
                    Write-Info "Disk Cleanup launched. Select all categories and click OK."
                    Pause-Return
                }
            }
            @{
                Desc   = "Find the 20 largest files on C:"
                Reason = "Large files (old backups, ISO images) are often the real culprits for low space."
                Action = {
                    Write-Warn "Scanning C: drive... This may take a minute."
                    Get-ChildItem -Path "C:\" -Recurse -File -ErrorAction SilentlyContinue |
                        Sort-Object Length -Descending | Select-Object -First 20 |
                        Select-Object FullName, @{N="Size(MB)";E={[Math]::Round($_.Length/1MB,1)}} |
                        Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host "   $_" -ForegroundColor Green }
                }
            }
        )
    }

    # â”€â”€ APP CRASHES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    @{
        Keywords = @("app crash","application crash","program crash","program not responding","not responding","keeps crashing","app not opening","program freezes","software crash","crashes")
        Title    = "Application Crashing / Not Responding"
        Intro    = "App crashes can be caused by missing Visual C++ runtimes, corrupted app files, insufficient RAM, or a GPU driver bug."
        Steps    = @(
            @{
                Desc   = "Check Application event log for crash details"
                Reason = "The Application log records exact error codes and faulting module names for crashes."
                Action = {
                    Write-Info "Scanning last 10 Application errors..."
                    Get-WinEvent -FilterHashtable @{LogName='Application'; Level=2} -MaxEvents 10 -ErrorAction SilentlyContinue |
                        Select-Object TimeCreated, ProviderName, Message |
                        ForEach-Object { Write-Host "   [$($_.TimeCreated)] $($_.ProviderName) - $($_.Message.Substring(0,[Math]::Min(200,$_.Message.Length)))" -ForegroundColor Green }
                }
            }
            @{
                Desc   = "Repair Microsoft Visual C++ Redistributables"
                Reason = "Most Windows applications depend on Visual C++ runtimes. Missing/corrupted runtimes cause instant crashes."
                Action = {
                    Write-Info "Installed Visual C++ Redistributables:"
                    Get-Package | Where-Object { $_.Name -like "*Visual C++*" } | Select-Object Name, Version | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host "   $_" -ForegroundColor Green }
                    Write-Info "Download all runtimes from: https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist"
                    Pause-Return
                }
            }
            @{
                Desc   = "Run Windows App Troubleshooter"
                Reason = "Built-in troubleshooter can detect and repair common Windows Store app problems."
                Action = {
                    Start-Process msdt.exe -ArgumentList "/id WindowsUpdateDiagnostic"
                    Pause-Return
                }
            }
            @{
                Desc   = "Re-register all Windows Store apps"
                Reason = "Corrupted Windows app packages can be fixed by re-registering them."
                Action = {
                    Write-Warn "Re-registering all AppX packages..."
                    Get-AppXPackage -AllUsers | ForEach-Object {
                        Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction SilentlyContinue
                    }
                    Write-Done "AppX packages re-registered."
                }
            }
            @{
                Desc   = "Run SFC scan to fix corrupted system files"
                Reason = "Corrupted system DLLs shared across apps can cause random crash patterns."
                Action = {
                    Write-Warn "Running SFC... May take several minutes."
                    Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Verb RunAs -Wait
                    Write-Done "SFC scan complete."
                }
            }
        )
    }

    # â”€â”€ HIGH CPU â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    @{
        Keywords = @("high cpu","cpu 100","100 cpu","cpu usage","cpu high","processor","overheating","cpu hot","hot cpu","cpu maxed")
        Title    = "High CPU Usage"
        Intro    = "100% CPU is caused by a runaway process, antivirus scans, Windows Update, or malware."
        Steps    = @(
            @{
                Desc   = "Show top CPU-consuming processes"
                Reason = "Identifies the exact process causing the CPU spike."
                Action = {
                    Write-Info "Top 10 CPU processes:"
                    Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Name, Id, CPU, @{N="RAM(MB)";E={[Math]::Round($_.WorkingSet64/1MB,1)}} | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host "   $_" -ForegroundColor Green }
                }
            }
            @{
                Desc   = "Disable SysMain (Superfetch) and Windows Search"
                Reason = "These services can spike CPU, especially during indexing or pre-loading."
                Action = {
                    Stop-Service SysMain,WSearch -Force -ErrorAction SilentlyContinue
                    Write-Done "SysMain and WSearch stopped."
                }
            }
            @{
                Desc         = "Configure Windows Update to run at low priority"
                Reason       = "Windows Update can silently max the CPU. Changing its priority gives headroom."
                RequiresReboot = $false
                Action       = {
                    Start-Process ms-settings:windowsupdate
                    Write-Info "Windows Update settings opened. Schedule update times for off-hours."
                    Pause-Return
                }
            }
            @{
                Desc   = "Scan for malware (Windows Defender quick scan)"
                Reason = "Malware and cryptominers are designed to steal CPU cycles silently."
                Action = {
                    Write-Info "Starting Windows Defender quick scan..."
                    Start-Process "C:\Program Files\Windows Defender\MpCmdRun.exe" -ArgumentList "-Scan -ScanType 1" -Wait -ErrorAction SilentlyContinue
                    Write-Done "Scan complete. Check Windows Security for results."
                }
            }
            @{
                Desc         = "Set power plan to Balanced (prevents thermal throttling loops)"
                Reason       = "High Performance mode on a throttled/overheating CPU causes oscillating CPU spikes."
                RequiresReboot = $false
                Action       = {
                    powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e
                    Write-Done "Power plan set to Balanced."
                }
            }
        )
    }

    # â”€â”€ KEYBOARD / MOUSE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    @{
        Keywords = @("keyboard","mouse","not typing","key not working","keyboard not working","mouse not working","cursor","keys stuck","double typing","sticky key","input")
        Title    = "Keyboard / Mouse Not Working"
        Intro    = "Input device failures are usually driver, USB controller, or HID service issues."
        Steps    = @(
            @{
                Desc   = "Restart HID service (Human Interface Device)"
                Reason = "The HID service manages all keyboard and mouse communication. Restarting it refreshes input."
                Action = {
                    Restart-Service HidServ -Force -ErrorAction SilentlyContinue
                    Write-Done "HID service restarted."
                }
            }
            @{
                Desc   = "Unplug and replug the device (USB reset)"
                Reason = "A simple unplug-replug forces Windows to re-enumerate the USB device."
                Action = {
                    Write-Info "Please physically unplug your keyboard/mouse USB cable, wait 5 seconds, and plug it back in."
                    Write-Host "   Press ENTER when done..." -ForegroundColor Yellow
                    Read-Host | Out-Null
                    Write-Done "USB device should now be re-detected."
                }
            }
            @{
                Desc         = "Update HID/USB drivers via Device Manager"
                Reason       = "An outdated USB hub or HID driver can cause intermittent input failures."
                RequiresReboot = $true
                Action       = {
                    Start-Process devmgmt.msc
                    Write-Info "Device Manager opened. Expand 'Human Interface Devices' and 'Universal Serial Bus controllers'. Update any flagged devices."
                    Pause-Return
                }
            }
            @{
                Desc   = "Disable Sticky Keys and Filter Keys"
                Reason = "Accessibility features like Sticky Keys and Filter Keys can make the keyboard seem unresponsive."
                Action = {
                    Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value "506" -Force
                    Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "Flags" -Value "122" -Force
                    Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\ToggleKeys" -Name "Flags" -Value "58" -Force
                    Write-Done "Sticky Keys, Filter Keys, and Toggle Keys disabled."
                }
            }
        )
    }

)

# â”€â”€ Unknown Problem Fallback â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
$FallbackSteps = @(
    @{
        Desc   = "Run System File Checker"
        Reason = "A general repair to fix corrupted system files that may be causing your problem."
        Action = { Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Verb RunAs -Wait; Write-Done "SFC complete." }
    }
    @{
        Desc   = "Run DISM online repair"
        Reason = "DISM repairs the Windows component store, which underlies most system functions."
        Action = { DISM /Online /Cleanup-Image /RestoreHealth; Write-Done "DISM complete." }
    }
    @{
        Desc   = "Open Event Viewer for clues"
        Reason = "The event log almost always has an entry around the time your problem occurred."
        Action = { Start-Process eventvwr.msc; Write-Info "Look for Red (Error) or Yellow (Warning) entries under Windows Logs > System and Application."; Pause-Return }
    }
    @{
        Desc   = "Run Windows troubleshooter for general issues"
        Reason = "The built-in troubleshooter can detect common Windows configuration problems."
        Action = { Start-Process ms-settings:troubleshoot; Pause-Return }
    }
)


# == Hardware Checklist Menu (Direct Access) ===================================

function Show-HardwareMenu {
    while ($true) {
        Clear-Host
        Write-Header "ONYX IT DEPARTMENT TECH TOOLS - Physical Hardware Checklists"
        Write-Host "   Select a hardware category to view its physical inspection checklist:" -ForegroundColor DarkGray
        Write-Host ""
        $cats = @(
            "Monitor / Screen Flickering",
            "Slow / Freezing Computer",
            "No Internet / Network Connection",
            "Blue Screen of Death (BSOD)",
            "Printer Not Working",
            "No Sound / Audio Problems",
            "High Disk Usage / Low Disk Space",
            "Application Crashing / Not Responding",
            "High CPU Usage",
            "Keyboard / Mouse Not Working",
            "General / Unrecognized Issues"
        )

        for ($i = 0; $i -lt $cats.Count; $i++) {
            Write-Host ("   [" + ($i+1) + "] " + $cats[$i]) -ForegroundColor Cyan
        }
        Write-Host ""
        Write-Host "   [0] Back to Problem Solver" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host ("   Select category [1-" + $cats.Count + "] : ") -ForegroundColor Yellow -NoNewline
        $sel = (Read-Host).Trim()
        if ($sel -eq "0" -or $sel -eq "") { break }
        if ($sel -match "^\d+$") {
            $idx = [int]$sel - 1
            if ($idx -ge 0 -and $idx -lt $cats.Count) {
                $chosenCat = $cats[$idx]
                Clear-Host
                Write-Header ("Hardware Inspection: " + $chosenCat)
                Show-HardwareChecks -Checks $HardwareChecklists[$chosenCat] -Category $chosenCat
            }
        }
    }
}

# == Main Loop =================================================================

function Find-Problem {
    param([string]$Input)
    $lower = $Input.ToLower()
    foreach ($p in $Problems) {
        foreach ($kw in $p.Keywords) {
            if ($lower -contains $kw -or $lower -like ("*" + $kw + "*")) {
                return $p
            }
        }
    }
    return $null
}

while ($true) {
    Clear-Host
    Write-Header "ONYX IT DEPARTMENT TECH TOOLS - Custom Problem Solver"

    Write-Host "   Describe your problem in plain English and I will suggest fixes step by step." -ForegroundColor DarkGray
    Write-Host "   If software repairs do not resolve the issue, hardware diagnostics will activate." -ForegroundColor DarkCyan
    Write-Host "   Examples: monitor is flickering | no internet | pc is very slow | printer not working" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   Supported categories:" -ForegroundColor DarkGray
    @("Monitor Flickering","Slow / Freezing PC","No Internet","Blue Screen (BSOD)","Printer Not Working","No Sound","High Disk Usage","App Crashing","High CPU","Keyboard / Mouse") | ForEach-Object {
        Write-Host ("   - " + $_) -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host "   [HW] Physical Hardware Diagnostic Checklists (Direct Access)" -ForegroundColor Green
    Write-Host "   [0]  Back to Main Menu" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "   Enter your problem: " -ForegroundColor Yellow -NoNewline
    $userInput = (Read-Host).Trim()

    if ($userInput -eq "0" -or $userInput -eq "") { break }

    if ($userInput.ToLower() -eq "hw" -or $userInput.ToLower() -eq "hardware") {
        Show-HardwareMenu
        continue
    }

    $matched = Find-Problem -Input $userInput

    Clear-Host

    if ($matched) {
        Write-Header ("Detected Problem: " + $matched.Title)
        Write-Host ("   " + $matched.Intro) -ForegroundColor DarkGray
        Write-Host ""
        Write-Host ("   Found " + $matched.Steps.Count + " software diagnostic and repair step(s).") -ForegroundColor Green
        Write-Host "   I will walk you through each one and ask before applying it." -ForegroundColor Green

        $steps = $matched.Steps
        for ($i = 0; $i -lt $steps.Count; $i++) {
            $s = $steps[$i]
            $reboot = if ($s.RequiresReboot) { $true } else { $false }
            Run-Step -Num ($i+1) -Desc $s.Desc -Reason $s.Reason -Action $s.Action -RequiresReboot:$reboot
        }

        Write-Host ""
        Write-Host "   -----------------------------------------------------------------------------" -ForegroundColor DarkGreen
        Write-Done "All software diagnostic and repair steps have been executed."
        Write-Host ""

        $solved = Ask-Confirm "Did any of these software fixes resolve the issue?"
        if (-not $solved) {
            $hwChecks = $null
            if ($HardwareChecklists.ContainsKey($matched.Title)) {
                $hwChecks = $HardwareChecklists[$matched.Title]
            } else {
                $hwChecks = $HardwareChecklists["General / Unrecognized Issues"]
            }
            Show-HardwareChecks -Checks $hwChecks -Category $matched.Title
        } else {
            Write-Host ""
            Write-Done "SUCCESS: Problem confirmed resolved by software configuration/repairs."
            Write-Host "   No hardware inspection is required." -ForegroundColor Green
            Write-Host ""
            Pause-Return
        }

    } else {
        Write-Header "Problem Not Recognized"
        Write-Warn "I could not match your description to a specific known problem."
        Write-Host ("   Your input: " + $userInput) -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "   Running general diagnostic steps instead..." -ForegroundColor Green

        for ($i = 0; $i -lt $FallbackSteps.Count; $i++) {
            $s = $FallbackSteps[$i]
            Run-Step -Num ($i+1) -Desc $s.Desc -Reason $s.Reason -Action $s.Action
        }

        Write-Host ""
        Write-Done "General diagnostic steps complete."
        Write-Host ""

        $solved = Ask-Confirm "Did the general software steps resolve your problem?"
        if (-not $solved) {
            Show-HardwareChecks -Checks $HardwareChecklists["General / Unrecognized Issues"] -Category "Unrecognized Problem"
        } else {
            Write-Host ""
            Write-Done "SUCCESS: Problem confirmed resolved."
            Write-Host ""
            Pause-Return
        }

        Write-Host ""
        Write-Warn "Tip: Try rephrasing. Example keywords that work:"
        @("monitor flickering","no internet","slow pc","bsod","printer offline","no sound","disk full","app crash","high cpu","keyboard not working") | ForEach-Object {
            Write-Host ("   - " + $_) -ForegroundColor DarkGray
        }
    }

    Write-Host ""
    Write-Host "   Press ENTER to troubleshoot another problem (or type 0 + ENTER to exit)..." -ForegroundColor DarkGray
    $again = (Read-Host).Trim()
    if ($again -eq "0") { break }
}

