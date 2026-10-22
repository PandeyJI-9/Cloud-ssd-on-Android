# ☁️ Cloud SSD on Android

[![GitHub Stars](https://img.shields.io/github/stars/PandeyJI-9/Cloud-ssd-on-Android?style=flat-square)](https://github.com/PandeyJI-9/Cloud-ssd-on-Android/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/PandeyJI-9/Cloud-ssd-on-Android?style=flat-square)](https://github.com/PandeyJI-9/Cloud-ssd-on-Android/network/members)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Linux-brightgreen.svg?style=flat-square)](#)
[![Root](https://img.shields.io/badge/Root-Magisk%20%7C%20KernelSU%20%7C%20APatch-orange.svg?style=flat-square)](#)
[![Termux](https://img.shields.io/badge/Environment-Termux%20(F--Droid)-black.svg?style=flat-square)](#)

> **TeraBox 1TB Cloud Storage ko Android me ek Virtual SSD ki tarah mount karo — Zero Internal Storage impact ke sath!**

Is project se tum TeraBox ke 1TB free cloud storage ko apne phone me ek **external drive / virtual SSD** ki tarah mount kar sakte ho. Ye Termux aur Rooted devices (Magisk / KernelSU / APatch) dono par perfectly kaam karta hai.

---

## 📑 Table of Contents
1. [✨ Key Features](#-key-features)
2. [🏗️ System Architecture](#️-system-architecture)
3. [🎯 Best Use-Cases (What Works Best)](#-best-use-cases-what-works-best)
4. [📋 Prerequisites](#-prerequisites)
5. [📱 How to Extract TeraBox Cookie on Mobile (No PC Required)](#-how-to-extract-terabox-cookie-on-mobile-no-pc-required)
6. [🚀 Installation Guide](#-installation-guide)
   - [Method 1: Termux Setup (Quick & Direct)](#method-1-termux-setup-quick--direct)
   - [Method 2: Magisk/KernelSU Module (Permanent Reboot Mount)](#method-2-magiskkernelsu-module-permanent-reboot-mount)
7. [🛠️ Project & Scripts Structure](#️-project--scripts-structure)
8. [🤖 GitHub Actions Automated Cloud Builder](#-github-actions-automated-cloud-builder)
9. [❓ Troubleshooting & FAQ](#-troubleshooting--faq)

---

## ✨ Key Features

- 💾 **1TB (1024 GB) Virtual Storage:** TeraBox free tier ko direct storage drive ki tarah mount karta hai.
- 🛡️ **Zero Internal Storage Waste:** `--vfs-cache-mode off` policy use hoti hai, jisse phone ki internal flash memory ka ek bhi GB buffer ya cache me waste nahi hota.
- 🔄 **Global Mount Namespace Injection:** `nsenter -t 1 -m` aur `su -mm` se Android ke PID 1 (Init) me mount inject hota hai, jisse **ZArchiver, Solid Explorer, MiXplorer, aur Emulators** sabhi ko drive alag se dikhti hai.
- ⚡ **Reboot Persistence:** Magisk / KernelSU late-start service phone reboot hone ke baad internet connect hote hi drive ko auto-mount kar deti hai.
- ☁️ **No Phone Overheating:** Bhari build ya binary compilation phone par nahi hoti; GitHub Actions cloud runners par automatic package ho jata hai.

---

## 🏗️ System Architecture

TeraBox official WebDAV provide nahi karta, isliye humne robust 3-Tier architecture design kiya hai:

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

## 🎯 Best Use-Cases (What Works Best)

| Use Case | Status | Kitna Smooth Hai? |
| :--- | :---: | :--- |
| **Retro & Emulator ROMs (PPSSPP, GBA, PS1, NDS, RetroArch)** | ✅ **YES** | 🔥 **Super Smooth:** ROM start hote hi RAM me load ho jati hai (10MB–700MB). Ek baar load hone ke baad zero lag! |
| **Media Streaming (VLC, MX Player, Nova)** | ✅ **YES** | 🔥 **Flawless:** 1080p/720p Movies, Anime, FLAC music phone storage bina bhare sequential stream hote hain. |
| **File Archiving / Backups / ISOs** | ✅ **YES** | ⭐ **Excellent:** Photos, APK collections, aur badi files direct 1TB cloud me store rahengi. |
| **Heavy 3D Android Games (Genshin, BGMI) installed directly** | ❌ **NO** | 🛑 Android OS security (`noexec`), `dlopen` requirements, aur network latency ke kaaran heavy games internal storage mangte hain. |

---

## 📋 Prerequisites

1. **Android Device:** Rooted (Magisk, KernelSU, ya APatch) recommended for permanent mount across all apps. Termux-only non-root bhi chalega Termux apps ke liye.
2. **Termux App:** [F-Droid](https://f-droid.org/en/packages/com.termux/) ya GitHub releases wala Termux install karo (Play Store version outdated hai).
3. **TeraBox Account:** Free 1TB account.

---

## 📱 How to Extract TeraBox Cookie on Mobile (No PC Required)

1. Apne phone me **Kiwi Browser** ya **Firefox Nightly** install karo (jo extensions support karta hai).
2. Chrome Web Store se **Cookie-Editor** extension add karo.
3. [terabox.com](https://www.terabox.com) par jao aur login karo.
4. Cookie-Editor extension icon par tap karo.
5. Cookie list me se `ndus` cookie (ya full Cookie string) copy kar lo.
6. AList setup ke dauran is cookie ko paste kar dena.

---

## 🚀 Installation Guide

### Method 1: Termux Setup (Quick & Direct)

#### Step 1: Repo Clone & Dependency Installation
Termux open karo aur run karo:
```bash
# Repo clone karo
git clone https://github.com/PandeyJI-9/Cloud-ssd-on-Android.git cloud-ssd
cd cloud-ssd

# Dependencies (Rclone, FUSE3, AList ARM64 binary) install karo
bash scripts/install_dependencies_termux.sh
```

#### Step 2: AList Middleware Start Karo
```bash
bash scripts/start_alist.sh
```
Screen par ye details dikhayi dengi:
- **Web UI URL:** `http://127.0.0.1:5244`
- **Default Username:** `admin`
- **Default Password:** `admin123` *(change karne ke liye: `alist admin set YOUR_PASS`)*

#### Step 3: AList me TeraBox Link Karo
1. Mobile browser me `http://localhost:5244` open karo aur login karo.
2. Sidebar me **Manage -> Storages -> Add** par jao.
3. **Driver**: `TeraBox` select karo.
4. **Mount Path**: `/terabox`
5. **Cookie**: Apni copy ki hui TeraBox `ndus` cookie paste karo.
6. **Download API**: `Crack` select karo.
7. **Save** par click karo. Status **work** aana chahiye!

#### Step 4: Rclone WebDAV Configure Karo
Termux me run karo:
```bash
rclone config
```
Ye simple options select karo:
- `n` (New remote)
- Name: `terabox`
- Storage type: `webdav`
- URL: `http://127.0.0.1:5244/dav`
- Vendor: `other`
- User: `admin`
- Password: `y` (AList ka password enter karo)
- Baki options me `Enter` press karte jao jab tak finish na ho jaye.

#### Step 5: Mount Execute Karo
```bash
bash scripts/mount_terabox.sh
```
Ab apna **ZArchiver**, **Solid Explorer**, ya **MiXplorer** open karo:
`/sdcard/TeraBox-CloudSSD` par tumhara 1TB Cloud SSD ready hai!

Unmount karne ke liye:
```bash
bash scripts/unmount_terabox.sh
```

---

### Method 2: Magisk/KernelSU Module (Permanent Reboot Mount)

Agar tum chahte ho ki **phone switch off ya restart hone ke baad bhi Cloud SSD automatically mount rahe**:

1. Humne ready-made Magisk module template banaya hai: [`magisk_module/`](magisk_module/).
2. Ye module Android boot hone ke baad:
   - Wi-Fi/Mobile internet connect hone ka wait karega.
   - Background me AList service ko boot karega.
   - Android ke **PID 1 Global Mount Namespace (`nsenter -t 1 -m`)** me mount karega taaki phone ki sabhi apps (Emulators, File Managers) ko ye drive permanently dikhe.
3. Flashable `.zip` GitHub Actions se direct download kiya ja sakta hai (Neeche section dekho).

---

## 🛠️ Project & Scripts Structure

```
Cloud-ssd-on-Android/
├── README.md                           # Main Documentation & Step-by-Step Guide
├── docs/
│   ├── BRUTAL_TRUTH_VS_YT_MYTHS.md     # Technical breakdown of Latency vs Speed
│   └── REVERSE_ENGINEERING_TERABOX.md  # TeraBox API internals & REA architecture
├── scripts/
│   ├── install_dependencies_termux.sh  # Automated AList + Rclone installer for Termux
│   ├── start_alist.sh                  # AList background service runner
│   ├── mount_terabox.sh               # Optimized Rclone FUSE mounter (Zero cache)
│   ├── unmount_terabox.sh             # Clean unmount script
│   └── push_to_github.sh              # 1-Click GitHub push helper
├── magisk_module/
│   ├── module.prop                     # Magisk/KernelSU Module metadata
│   ├── service.sh                      # Universal boot service (Survives reboot)
│   └── customize.sh                    # Installation hook
└── .github/
    └── workflows/
        └── ci_and_build.yml            # GitHub Actions (Builds Magisk zip on cloud runners)
```

---

## 🤖 GitHub Actions Automated Cloud Builder

Phone ko garam kiye bina ya heavy build chalaye bina:
- Har release/tag par GitHub Actions cloud runners par ARM64 binaries fetch karke **All-in-One Flashable Magisk ZIP (`CloudSSD-TeraBox-ARM64-v1.0.0.zip`)** build kar dega.
- Tum simply repo ke **Releases** tab se zip download karke Magisk / KernelSU app me flash kar sakte ho!

---

## ❓ Troubleshooting & FAQ

#### Q: File Manager me folder khali (empty) dikh raha hai?
- Root permission verify karo. Non-root user sirf Termux terminal me files dekh sakta hai. Sabhi apps me dekhne ke liye `nsenter -t 1 -m` ya Magisk module zaroori hai.

#### Q: TeraBox Cookie expire ho gayi to kya karein?
- Browser se naya `ndus` cookie nikal kar AList dashboard (`http://localhost:5244`) me **Storages -> TeraBox -> Edit** karke update kar do.

#### Q: Phone ki internal storage use to nahi hogi?
- Bilkul nahi! Mount flag `--vfs-cache-mode off` set hai. Data direct RAM buffer me stream hota hai, storage me nahi.

---

## 📜 License
MIT License. Created & maintained for power users by [PandeyJI-9](https://github.com/PandeyJI-9).
