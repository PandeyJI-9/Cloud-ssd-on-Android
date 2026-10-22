# ☁️ Cloud SSD: TeraBox 1TB Mount on Android (Root & Termux)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Linux-brightgreen.svg)](#)
[![Root](https://img.shields.io/badge/Root-Magisk%20%7C%20KernelSU%20%7C%20APatch-orange.svg)](#)
[![Termux](https://img.shields.io/badge/Environment-Termux%20(F--Droid)-black.svg)](#)
[![CI Build](https://img.shields.io/badge/GitHub%20Actions-Automated%20Build-blue.svg)](#)

> **No Sugar-Coating, 10000% Raw Technical Reality & Working Implementation**  
> Is repo me TeraBox 1TB free cloud storage ko Android me **Virtual Cloud SSD** ki tarah mount karne ka complete, tested framework aur architecture diya gaya hai.

---

## 📑 Table of Contents
1. [⚡ The Brutal Reality: YouTube Myths vs Computer Science](#-the-brutal-reality-youtube-myths-vs-computer-science)
2. [🎯 What Works vs What Will Crash (Feasibility Matrix)](#-what-works-vs-what-will-crash-feasibility-matrix)
3. [🏗️ Cloud SSD Architecture on Android](#️-cloud-ssd-architecture-on-android)
4. [🔍 Reverse Engineering TeraBox & REA Tool](#-reverse-engineering-terabox--rea-tool)
5. [🚀 Complete Step-by-Step Installation Guide](#-complete-step-by-step-installation-guide)
   - [Method 1: Termux Setup (Quick & Direct)](#method-1-termux-setup-quick--direct)
   - [Method 2: Magisk/KernelSU Module (Permanent Reboot Setup)](#method-2-magiskkernelsu-module-permanent-reboot-setup)
   - [How to get TeraBox Cookie on Mobile](#how-to-get-terabox-cookie-on-mobile-without-pc)
6. [🛠️ Scripts & Project Structure](#️-scripts--project-structure)
7. [🤖 GitHub Actions Support (Zero Phone Heating)](#-github-actions-support-zero-phone-heating)
8. [🚀 How to Push this Project to Your GitHub](#-how-to-push-this-project-to-your-github)

---

## ⚡ The Brutal Reality: YouTube Myths vs Computer Science

YouTubers jo dikhate hain ki *"Bhai bina phone/PC storage use kare 100GB ka GTA V ya Genshin Impact Cloud SSD se chala diya"*, uske piche ka **asli sach (No Sugar-Coating)** samjho:

```
+-----------------------------------------------------------------------------------------+
|                                    THE YOUTUBE ILLUSION                                 |
|                                                                                         |
|  [ YouTuber's Claim ]                                                                   |
|  "Game cloud me installed hai, phone ki 1 MB storage bhi use nahi ho rahi!"             |
|                                                                                         |
|  [ Reality Behind the Scenes ]                                                          |
|  Rclone Flag: --vfs-cache-mode full                                                     |
|  --> Rclone silently downloads game chunks into Local Internal Storage (Cache Folder)!  |
|  --> Internal storage par hi 30-60 GB download hota rehta hai background me.            |
|  --> Agar cache band kar doge (--vfs-cache-mode off), to game CRASH ho jayega!         |
+-----------------------------------------------------------------------------------------+
```

### 1. Latency (Ping) Difference: 0.1ms vs 200ms
* **Local Phone Storage (UFS 3.1 / UFS 4.0):** 
  - Latency: **< 0.05 milliseconds**
  - Speed: **2,000 MB/s - 4,200 MB/s**
  - Random 4K Reads: **100,000+ IOPS**
* **TeraBox Cloud Storage (over HTTP API):**
  - Latency: **150ms - 300ms** per request
  - Free Speed: **100 KB/s - 400 KB/s** (Throttled by TeraBox servers)
  - Random 4K Reads: **< 10 IOPS**

**Kya hota hai jab game chalta hai?**  
Game engine (Unreal Engine / Unity) har second hazaaron 3D textures, sounds, aur shader chunks load karta hai.
- Agar local SSD par 50MB texture load hona hai: **0.02 second** lagta hai.
- Agar TeraBox Free Tier (250 KB/s) par 50MB texture bina cache load hoga: **200 seconds (~3.3 MINUTES)** lagte hain!
- Android OS ka Watchdog detect karega ki UI thread freeze ho gaya hai aur instant **ANR (Application Not Responding) Crash** de dega!

### 2. Android OS Security & Filesystem Restrictions
1. **SELinux & Native Code (`dlopen`):**
   Android native apps/games (`.so` libraries) ko run karne ke liye Linux kernel `PROT_EXEC` (execute permission) mangta hai. Android me user FUSE mounts par security reasons se `noexec` enforce rehta hai. Isliye directly `.apk` ya uski libraries cloud FUSE par install karke execute nahi ki ja sakti.
2. **Mount Namespaces (Why mounts disappear for other apps):**
   Android har application ko Zygote se ek alag **Mount Namespace** me spawn karta hai. Agar tum Termux me standard tarike se mount karoge, to wo **sirf Termux ko dikhega**; ZArchiver, Gallery, File Manager, ya kisi game ko folder khali (empty) dikhega.
   Is problem ko solve karne ke liye **Root Namespace Injection (`nsenter -t 1 -m` ya `su -mm`)** zaroori hai.

---

## 🎯 What Works vs What Will Crash (Feasibility Matrix)

| Use Case | Kya Chalega? | Kitna Practical Hai? | Kyon? |
| :--- | :---: | :---: | :--- |
| **Retro & Emulator ROMs (PPSSPP, GBA, PS1, N64, RetroArch)** | ✅ **100% YES** | 🔥 **Best Experience** | ROM pura RAM me load ho jata hai (10MB-700MB). Ek baar load hone ke baad koi lag nahi. |
| **Movie / Anime / Music Streaming (VLC, MX Player)** | ✅ **100% YES** | 🔥 **Flawless** | Video players sequential buffering use karte hain. 1080p/720p movies bina phone storage bhare stream hongi. |
| **File Archiving / Backup / Unrar on demand** | ✅ **100% YES** | ⭐ **Excellent** | Cloud SSD me alag drive banke dikhega, 1TB free storage for photos/ISOs/backups. |
| **Lightweight PC Games (Visual Novels, Turn-based via Winlator)** | ⚠️ **Partial** | 🟡 **Condition Applied** | Agar asset streaming heavy nahi hai to chal jayega. |
| **Heavy Android Games (Genshin, BGMI, CoD) directly on Cloud** | ❌ **IMPOSSIBLE** | 🛑 **Zero Viability** | Random 4K I/O stall, 300ms latency, TeraBox 250KB/s speed limit se 10 second me game ANR crash marega. |
| **PC Games (GTA V, Cyberpunk via Mobox/Winlator) with 0% Cache** | ❌ **IMPOSSIBLE** | 🛑 **Zero Viability** | Winlator freeze ho jayega loading screen par hi. Cache on karoge to phone ka internal storage bhar jayega. |

---

## 🏗️ Cloud SSD Architecture on Android

TeraBox ka koi direct official WebDAV ya Linux mount support nahi hai. Humne iske liye 3-tier production architecture design kiya hai:

```
+-------------------------------------------------------------------------------+
|                             ANDROID USER SPACE                                |
|  [ File Manager / ZArchiver ]   [ Emulators (PPSSPP) ]   [ Video Players ]    |
|                \                           |                         /        |
|                 +--------------------------+------------------------+         |
|                                            |                                  |
|                                    Access via Mount Point                     |
|                           /sdcard/TeraBox-CloudSSD                            |
+--------------------------------------------|----------------------------------+
                                             |
+--------------------------------------------v----------------------------------+
|                          FUSE LAYER (Rclone Daemon)                           |
|  * Mount Engine: rclone mount --allow-other --dir-cache-time 24h              |
|  * Cache Policy: Zero Local Disk Cache (--vfs-cache-mode off)                 |
|  * Namespace: Injected into Android Global PID 1 Init Namespace (`nsenter`)   |
+--------------------------------------------|----------------------------------+
                                             | (Localhost HTTP/WebDAV Loopback)
+--------------------------------------------v----------------------------------+
|                      MIDDLEWARE LAYER (AList Daemon)                          |
|  * Runs locally on port 5244 (http://127.0.0.1:5244/dav)                      |
|  * Handles TeraBox Cookie Session, Token Refresh & Anti-Bot Protection        |
+--------------------------------------------|----------------------------------+
                                             | (Encrypted HTTPS REST API)
+--------------------------------------------v----------------------------------+
|                         REMOTE TERABOX CLOUD SERVERS                          |
|  * 1,024 GB (1 TB) Free Storage Volume                                        |
+-------------------------------------------------------------------------------+
```

---

## 🔍 Reverse Engineering TeraBox & REA Tool

Humne **REA (Reverse Engineer Anything)** (`morluto/rea`) framework aur API analysis use kiya hai:
1. **Session Cookie (`ndus`):** TeraBox user login state ko `ndus=...` cookie me verify karta hai.
2. **Tokens (`bdstoken` & `jsToken`):** CSRF verification tokens.
3. **Download URL Generation:** Web API `/api/download` request leti hai `fs_id` ke sath aur direct CDN mirror URL return karti hai.
4. **Anti-Bot Throttling:** Multi-thread parallel download ke dauran TeraBox user-agent verification mangta hai. AList is sabko internally bridge karta hai.

---

## 🚀 Complete Step-by-Step Installation Guide

### Prerequisite Checklist:
- [x] Android device (Rooted with Magisk, KernelSU, ya APatch for permanent mount; non-root user for Termux only).
- [x] Termux app (F-Droid version, Google Play Store version nahi).
- [x] TeraBox Account (1TB Free).

---

### Method 1: Termux Setup (Quick & Direct)

#### Step 1: Termux Packages & AList Install
Termux open karo aur ye commands run karo:
```bash
# Repo clone karo
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git cloud-ssd
cd cloud-ssd

# Dependencies aur AList ARM64 binary auto-install karo
bash scripts/install_dependencies_termux.sh
```

#### Step 2: AList Background Service Start Karo
```bash
bash scripts/start_alist.sh
```
Ab Termux me show hoga:
- **Dashboard URL:** `http://127.0.0.1:5244`
- **Username:** `admin`
- **Default Password:** `admin123` *(agar change karna ho: `alist admin set YOUR_PASSWORD`)*

#### Step 3: AList me TeraBox Mount Karo
1. Phone ke Chrome/Firefox browser me jao aur open karo: `http://localhost:5244`
2. Login karo (`admin` / `admin123`).
3. Sidebar me **Manage** par click karo -> **Storages** -> **Add**.
4. **Driver**: `TeraBox` select karo.
5. **Mount Path**: `/terabox`
6. **Cookie**: Apni TeraBox ki cookie paste karo (Neeche cookie guide dekho).
7. **Download API**: `Crack` select karo.
8. **Save** par click karo. Status **work** aana chahiye!

#### Step 4: Rclone WebDAV Remote Configure Karo
Termux me run karo:
```bash
rclone config
```
Ye options choose karo:
- `n` (New remote)
- Name: `terabox`
- Storage type: `webdav`
- URL: `http://127.0.0.1:5244/dav`
- Vendor: `other`
- User: `admin`
- Password: `y` (enter your AList password)
- Baaki sab settings ke liye `Enter` press karte jao.

#### Step 5: Mount Execute Karo (Zero Internal Storage Impact!)
```bash
bash scripts/mount_terabox.sh
```
Ab apne phone ka **ZArchiver**, **Solid Explorer**, ya **MiXplorer** open karo:
Tumhe `/sdcard/TeraBox-CloudSSD` me tumhari 1TB cloud storage dikhayi degi!

Unmount karne ke liye:
```bash
bash scripts/unmount_terabox.sh
```

---

### Method 2: Magisk/KernelSU Module (Permanent Reboot Setup)

Agar tum chahte ho ki **phone restart hone ke baad bhi Cloud SSD automatically mount rahe** aur har app me visible rahe:

1. Humne ready-to-use Magisk module structure banaya hai: `magisk_module/`.
2. Module automatically:
   - Wi-Fi/Internet connect hone ka wait karega.
   - Background me AList start karega.
   - Android ke **Global Mount Namespace (`nsenter -t 1 -m`)** me mount karega taaki sabhi applications ko drive permanently dikhe!
3. Flashable ZIP GitHub Actions me automatic build ho jata hai (Neeche dekho).

---

### How to get TeraBox Cookie on Mobile (Without PC)

1. Apne phone me **Kiwi Browser** ya **Firefox Nightly** install karo (jo extensions support karta hai).
2. Chrome Web Store se **"Cookie-Editor"** extension install karo.
3. `terabox.com` par jao aur login karo.
4. Cookie-Editor extension par tap karo aur **Export as Header String** ya `ndus` cookie copy kar lo.
5. AList ke Dashboard me paste kar do.

---

## 🛠️ Scripts & Project Structure

```
/workspace/cloud-ssd/
├── README.md                           # Complete Guide & Architectural Reality
├── docs/
│   ├── BRUTAL_TRUTH_VS_YT_MYTHS.md     # Deep dive into Latency, Bandwidth & Cache
│   └── REVERSE_ENGINEERING_TERABOX.md  # TeraBox API, Token mechanics & REA details
├── scripts/
│   ├── install_dependencies_termux.sh  # Automated setup for Termux (AList + Rclone)
│   ├── start_alist.sh                  # AList background service runner
│   ├── mount_terabox.sh               # Optimized Rclone FUSE mounting script
│   ├── unmount_terabox.sh             # Clean unmount & process killer
│   └── push_to_github.sh              # 1-Click push automation script for GitHub
├── magisk_module/
│   ├── module.prop                     # Magisk/KernelSU Module metadata
│   ├── service.sh                      # Universal boot service script (Global NS)
│   └── customize.sh                    # Installation hook
└── .github/
    └── workflows/
        └── ci_and_build.yml            # GitHub Actions workflow for zero-phone-load builds
```

---

## 🤖 GitHub Actions Support (Zero Phone Heating)

Humne `.github/workflows/ci_and_build.yml` configure kar diya hai:
* Ye phone par koi heavy compilation nahi karega.
* GitHub ke cloud runners par ARM64 binaries automatically download karke **Flashable Magisk ZIP (`CloudSSD-TeraBox-ARM64-v1.0.0.zip`)** build kar dega.
* Releases section me direct download link mil jayega!

---

## 🚀 How to Push this Project to Your GitHub

### Option 1: Direct 1-Line Script (Easiest)
Workspace me helper script run karo:
```bash
bash scripts/push_to_github.sh <YOUR_GITHUB_USERNAME> <YOUR_REPO_NAME> <YOUR_TOKEN>
```

### Option 2: Manual Git Commands
```bash
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git branch -M main
git push -u origin main
```
