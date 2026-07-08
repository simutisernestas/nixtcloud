# 🧊 Nixtcloud: Self-Hosted Cloud in One Command

[![NixOS](https://img.shields.io/badge/NixOS-25.11-blue.svg?style=flat-square&logo=nixos)](https://nixos.org)
[![Nextcloud](https://img.shields.io/badge/Nextcloud-32-orange.svg?style=flat-square&logo=nextcloud)](https://nextcloud.com)
[![Raspberry Pi](https://img.shields.io/badge/Raspberry%20Pi-4%20%7C%205-c51a4a.svg?style=flat-square&logo=raspberry-pi)](https://www.raspberrypi.org)
[![NanoPi NEO3](https://img.shields.io/badge/NanoPi-NEO3-green.svg?style=flat-square)](https://www.friendlyelec.com/index.php?route=product/product&product_id=279)
[![P2P: Holesail](https://img.shields.io/badge/P2P-Holesail-purple.svg?style=flat-square)](https://holesail.io)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](https://opensource.org/licenses/GPL-3.0)

**Nixtcloud** turns a Raspberry Pi or NanoPi NEO3 into a privacy-first, zero-config personal cloud — powered by [NixOS](https://nixos.org), [Nextcloud](https://nextcloud.com), and peer-to-peer remote access via [Holesail](https://holesail.io). Built for the self-hosting crowd who want full control without constant babysitting.

---

## 💡 Why Nixtcloud?

> **One command. Full cloud. Private, persistent, and portable.**

- **☁️ Full Nextcloud stack**, pre-configured
- **🔐 End-to-end encrypted remote access**, no port forwarding
- **📦 Plug in USB drives**, they're auto-mounted & usable instantly
- **🔁 Self-healing system** with daily reboots and manually-triggered updates
- **📱 Remote access by QR code**, using Holesail

Perfect for digital minimalists, privacy purists, and anyone fed up with Google Drive.

---

## 🚀 Quick Start

### Build for Raspberry Pi 4

From NixOS:
```bash
nix build --system aarch64-linux github:jjacke13/nixtcloud#packages.aarch64-linux.Rpi4
```

From macOS/Linux:
```bash
nix build --extra-experimental-features nix-command --extra-experimental-features flakes \
  --system aarch64-linux github:jjacke13/nixtcloud#packages.aarch64-linux.Rpi4
```

### Build for Raspberry Pi 5

```bash
nix build --system aarch64-linux github:jjacke13/nixtcloud#packages.aarch64-linux.Rpi5
```

### Build for NanoPi NEO3

```bash
nix build --system aarch64-linux github:jjacke13/nixtcloud#packages.aarch64-linux.Nanopi-neo3
```

> **Note for NanoPi NEO3**: Uses a custom minimal kernel (6.18.3) for faster builds and smaller image size (~2.7GB).

Flash the resulting image to an SD card, boot your device, and visit `https://nixtcloud.local`.

---

## 🧰 What You Need

**Hardware**:
- **Raspberry Pi 4 or 5** (≥ 4GB RAM recommended) - supports WiFi + Ethernet
- **OR NanoPi NEO3** (2GB RAM) - Ethernet only, no WiFi
- SD card (16GB+)
- Ethernet connection
- Optional: USB drives for storage expansion

**Software**:
- [Nix](https://nixos.org/download.html)
- SD flashing tool (`dd`, [Etcher](https://balena.io/etcher), etc.)

---

## 🧭 First Use

After flashing and booting your Raspberry Pi:

1. **Power On & Wait**  
   The first boot configures the system — this can take up to **5 minutes**. DO NOT interrupt it. The Pi will reboot automatically when ready.

2. **Connect via Ethernet**
   Make sure your device is connected to your local network via Ethernet. WiFi is supported on Raspberry Pi only (not available on NanoPi NEO3). WiFi setup requires editing `configuration.nix` and rebuilding.

3. **Detect Hostname**  
   From a computer on the same network, open your browser and go to:
   https://nixtcloud.local

   If that doesn't work:
   - Try `ping nixtcloud.local`
   - Or, find the Pi's IP via your router and visit `https://<ip-address>`

4. **Login to Nextcloud**  
   -  Username: `admin`  
   -  Password: `admin`  
   ⚠️ *Change this password immediately* after first login.

5. **Insert USB Storage (Optional)**  
   If you want to expand storage:
   - Plug in a USB drive
   - Wait ~30 seconds
   - It will show up in Nextcloud as external storage

## 🔐 Secure by Design

  - SSH root login disabled by default
  - Firewall restricts all but essential ports
  - Remote access is encrypted, zero-config, and QR-based
  - No unattended system auto-updates — updates are pulled from GitHub only when you run `updater.sh` yourself

---

## 🔄 What Makes It "Self-Healing"?

- Scheduled **maintenance tasks**
- Manual check and apply of updates (run `sudo bash /etc/nixos/updater.sh`), then reboot
- USB drives auto-mount after 30 seconds
- "Magic files" in Nextcloud let you trigger actions like reboot or regenerate P2P credentials by just deleting a file.

---

## 🔌 Plug & Play External Storage

- Works with ext4, exFAT, FAT32, NTFS
- Auto-detected and mounted
- Appears in Nextcloud as external storage
- Supports multiple partitions per device

---

## 🌍 Remote Access, No Router Hacks Required

Using Holesail:
- Encrypted P2P tunnel
- Credentials delivered as `remote.txt` and a QR image inside your Nextcloud
- Public folder sharing via separate connection string

> Want to access your files while traveling without exposing ports? Done.

---

## ⚙️ Easy Customization

Examples (in `configuration.nix`):

```nix
# WiFi (Raspberry Pi only - NanoPi NEO3 has no WiFi)
networking.wireless.enable = true;
networking.wireless.networks = {
  YourSSID = { psk = "YourPassword"; };
};

# Disable daily reboots
services.cron.systemCronJobs = [];

# Set timezone
time.timeZone = "Europe/Berlin";
```

---

## 🧱 Under the Hood

- **NixOS** for immutability and reproducibility
- **Nextcloud 32**
- **Holesail** for P2P remote access
- Custom systemd services:
  - `startup.service`
  - `mymnt.service`
  - `p2pmagic.service`
  - `p2public.service`
  - `rebooter.service`

```mermaid
graph TD
  A[nextcloud-setup] --> B[startup.service]
  B --> C[mymnt.service]
  B --> D[p2pmagic.service]
  B --> E[p2public.service]
  B --> F[rebooter.service]
```

---

## 🛠️ Troubleshooting

**Can't access `nixtcloud.local`?**
- Try accessing the Pi's IP address directly
- Ensure `avahi`/mDNS is working on your network

**USB drive not showing up?**
- Check if formatted correctly
- Wait 30-45 seconds after plugging in
- Run: `journalctl -u mymnt.service`

**Remote access fails?**
- Make sure Holesail app is installed and working
- Double-check the QR or connection string

---

## 🧪 Local Dev & Testing

```bash
git clone https://github.com/jjacke13/nixtcloud.git
cd nixtcloud

# Build for Raspberry Pi 4
nix build .#packages.aarch64-linux.Rpi4

# Build for Raspberry Pi 5
nix build .#packages.aarch64-linux.Rpi5

# Build for NanoPi NEO3 (faster build, minimal kernel)
nix build .#packages.aarch64-linux.Nanopi-neo3
```

(⚠️ Container-based testing coming soon)

---

## 🙌 Credits

- [Holesail](https://holesail.io) for seamless P2P networking
- [Nextcloud](https://nextcloud.com) for the freedom to host your own cloud
- [NixOS](https://nixos.org) for reproducibility that actually works
- Everyone contributing to open source

---

## 🔧 Live-Editing a Deployed Pi

How to fix a bug on an already-running Nixtcloud device (not a fresh SD-card flash) by editing this repo, pushing it, and rebuilding the device in place over SSH.

### Why This Workflow, Not a Local Edit

The device does **not** carry a flake checkout. `/etc/nixos` on a running box only contains a few files copied in via `environment.etc`:

```
/etc/nixos/adminpass.txt
/etc/nixos/device.txt       # e.g. "Rpi5" - matches the flake output name
/etc/nixos/mounter.sh
/etc/nixos/updater.sh
```

There's no `configuration.nix`/`flake.nix` to edit directly on the device. The system was built from, and can only be rebuilt from, a flake reference — same mechanism `updater.sh` itself uses. So the fix has to happen in a real git checkout of this repo, get pushed somewhere reachable over the internet (a fork works fine, doesn't need to be upstream), and then the device pulls and rebuilds from that reference.

### Prerequisites

- SSH access to the device as `admin` (key-based, if `PasswordAuthentication` has been turned off per the SSH hardening notes elsewhere in this repo)
- The `admin` sudo password (needed for `nixos-rebuild switch` and for reading anything root-only, e.g. `blkid` on raw devices, `dmesg`)
- A git remote you can push to — add your fork if you haven't:
  ```
  git remote add fork git@github.com:<you>/nixtcloud.git
  ```

### Workflow

**1. Diagnose first, over SSH, read-only where possible.**

Most of the useful commands don't need root:
```
ssh admin@<hostname>.local 'systemctl status <service>.service --no-pager -l'
ssh admin@<hostname>.local 'journalctl -u <service>.service -n 80 --no-pager'
ssh admin@<hostname>.local 'lsblk -f'
```
Things that touch raw devices or protected logs need sudo. To run a sudo command over a non-interactive SSH session (no TTY for a password prompt), pipe the password to `sudo -S`:
```
ssh admin@<hostname>.local 'echo "<password>" | sudo -S dmesg -T | tail -60'
```

**2. Make the fix in a real local checkout of this repo** (not on the device) — edit the relevant file(s) under `base/` or `hardware/`, and review before committing:
```
git diff
```

**3. Commit and push to your fork:**
```
git add <changed files>
git commit -m "..."
git push fork main
```

**4. Rebuild and switch the live device, pulling from that fork:**
```
ssh admin@<hostname>.local 'echo "<password>" | sudo -S nixos-rebuild switch --flake github:<you>/nixtcloud#<Device>'
```
`<Device>` must match what's in `/etc/nixos/device.txt` on that box (`Rpi4`, `Rpi5`, or `Nanopi-neo3`).

Note: unlike building fresh on a dev laptop, no `--accept-flake-config` is needed here — the device's own `/etc/nix/nix.conf` (baked in from `nix.settings` in `base/configuration.nix`) already lists `nix-community.cachix.org` as a substituter directly, and `root` is already a trusted Nix user. So `nixos-rebuild switch` run via `sudo` just works without any extra trust prompts.

`nixos-rebuild switch` (not `boot`) activates the new generation immediately — any service whose config changed gets restarted right away.

**5. Verify.**
- Confirm the switch output ends with `Done. The new configuration is /nix/store/...` with no errors.
- Re-check the specific thing you fixed (`systemctl status`, `journalctl`, `lsblk`, whatever applies).
- **If you touched anything SSH/auth-related, open a brand-new SSH connection and confirm it works before closing your existing session** — don't get locked out of your only way in.

### Worked Example From This Repo's History

Two real bugs were fixed on a live, already-deployed box this way:

- **`base/mounter.sh`**: a USB drive that had been reformatted (whole-disk FAT32 → partition table + exFAT) still carried a stale FAT boot-sector signature directly on the raw disk device from before the reformat. `blkid` still detected it, so the mounter tried to mount the raw disk itself as a filesystem alongside its real partition — producing garbled directory listings and I/O errors, even though the actual partition's data was completely healthy. Fix: skip whole-disk devices that already have partitions (`disk_has_partitions` check added to `process_mountable_devices`).
- **`base/configuration.nix`**: added the admin user's SSH public key and disabled `PasswordAuthentication`/`KbdInteractiveAuthentication`, moving SSH to key-only auth.

Both were committed, pushed to a fork, and deployed with `nixos-rebuild switch --flake github:<fork>#Rpi5` directly against the running device — no reflash needed.

A separate issue (first-boot/startup services failing because the device had no internet access on its very first boot, over a year earlier) needed **no config change at all** — just manually restarting those systemd units once connectivity was actually available (`sudo systemctl restart first-boot.service`, then `startup.service`), letting their existing `onSuccess=` chain re-trigger the dependent services normally. Worth checking whether a live retry alone fixes a problem before assuming a code fix and rebuild are necessary — it's the lower-risk option.

### Risk Notes

- This modifies a live production device directly, in place — there's no staging environment. For anything invasive or uncertain, prefer testing the change in a local VM/build first (see this repo's notes on building and testing locally) before pushing it to a device people rely on.
- `nixos-rebuild switch` restarts changed services immediately, which can mean a brief interruption to Nextcloud web access (nginx/phpfpm) or other running services during the switch.
- If a switch goes wrong, `sudo nixos-rebuild switch --rollback` reactivates the previous generation. Older generations are also selectable from the bootloader menu at boot if the system doesn't come up cleanly.