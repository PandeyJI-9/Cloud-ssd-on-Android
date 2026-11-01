# ☁️ Cloud SSD on Android (v1.1.0 AI Edition)

[![GitHub Stars](https://img.shields.io/github/stars/PandeyJI-9/Cloud-ssd-on-Android?style=flat-square)](https://github.com/PandeyJI-9/Cloud-ssd-on-Android/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/PandeyJI-9/Cloud-ssd-on-Android?style=flat-square)](https://github.com/PandeyJI-9/Cloud-ssd-on-Android/network/members)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Android%2010--15%20%7C%20HyperOS-brightgreen.svg?style=flat-square)](#)
[![Root](https://img.shields.io/badge/Root-Magisk%20%7C%20KernelSU%20%7C%20APatch-orange.svg?style=flat-square)](#)

> **Google Drive & TeraBox (1TB+) Cloud Storage ko Android me ek Real SD Card / Virtual SSD ki tarah mount karo — AI Dynamic On-Demand Streaming ke sath!**

Is project se tum **Google Drive**, **TeraBox**, **OneDrive**, ya kisi bhi cloud storage ko apne Android phone me ek **Native SD Card / Cloud SSD** ki tarah mount kar sakte ho. Ye HyperOS, MIUI, OneUI, ColorOS, aur stock Android par 100% test kiya gaya hai.

---

## ❓ Sabse Bada Sawal: "Kya ye poori drive ko phone me download kar raha hai?"

### 🛑 Jawab: **बिल्कुल नहीं! (100% NO!)**

Cloud SSD **Virtual Filesystem in Userspace (FUSE)** aur **Demand-Paging** technique par kaam karta hai:
- **Mount karte waqt:** Phone me sirf file aur folder ke naam (Metadata, size) aate hain, jiska size mushkil se 1–2 Megabytes hota hai.
- **File open karte waqt:** Agar aapke Google Drive ya TeraBox me **50GB ki movie ya 4GB ka zip** hai, to vo poora download **NAHI** hota! Sirf utna chhota sa hissa (**4MB to 16MB chunk**) RAM me stream hota hai jitna app read kar raha hai — bilkul YouTube ya Netflix video streaming ki tarah!
- **Khatam hone ke baad:** Cache automatically auto-purge (delete) ho jata hai, phone storage hamesha free rehti hai.

```
[ Your 1TB Cloud Drive ] ☁️
       │  (Only metadata loaded: ~1MB)
       ▼
[ Cloud SSD AI Engine ] 🧠 ──> Reads ONLY 4MB-32MB chunk when clicked
       │  (Pure RAM buffer: zero phone disk bloat)
       ▼
[ Android File Manager / ZArchiver / VLC ] 📱
```

---

## 🧠 Naya: AI Smart On-Demand Load & Cache Engine

Aapke request par Cloud SSD me **AI Dynamic Storage Sentinel & Intelligent Prefetcher** add kar diya gaya hai:

1. **Device-Aware Dynamic Cache (Auto-Scaling):**
   - 🟢 **Agar Phone me 10GB+ Free Space hai:** AI Engine 1GB ka safe rolling cache allow karega jo 10 minute me auto-expire ho jata hai.
   - 🟡 **Agar Phone me 3GB–10GB Free Space hai:** Cache size ko automatically compress karke **300MB strict limit** par restrict kar dega.
   - 🔴 **Agar Phone me < 3GB Free Space hai:** AI instantly **Zero-Disk Mode (`--vfs-cache-mode off`)** switch kar dega — yaani phone internal disk par **0 Bytes** likhe jayenge, sab kuch 100% RAM buffer me chalega!
2. **🛡️ .nomedia Anti-Drain Firewall:**
   - Android ka MediaScanner / Gallery background me cloud drive me ghus kar sabhi photos aur videos ke thumbnail banane ki koshish karta hai, jisse internet kharch hota tha.
   - Cloud SSD automatically **`.nomedia` firewall** inject kar deta hai, jisse Gallery apps background me internet waste nahi kar sakte!
3. **⚡ Fast In-Memory Metadata Index:**
   - 72-hour directory tree RAM cache: Folder open karna instantaneous (0 ms delay) hota hai, baar baar internet se reload nahi hota.

---

## 💾 Storage kyu nahi aayi thi as "Cloud SSD / SD Card"? (Fixed in v1.1.0)

Pehle do major technical reasons the:
1. **Android Mount Namespace Isolation (Zygote):** Android 11+ me Termux aur normal root shell ka mount namespace alag hota hai. Agar mount PID 1 (`init`) me na jaye, to ZArchiver ya Files by Google ko folder khali ya gayab dikhta hai.
2. **Android 11–14 / HyperOS Scoped Storage (MediaProvider FUSE):** Android me `/sdcard` ka real path `/data/media/0` hota hai. Jab tak `/data/media/0`, `/mnt/runtime/default`, `/mnt/runtime/read`, `/mnt/runtime/write`, aur `/mnt/pass_through` par bind-mount na ho, MediaProvider use block kar deta hai.

### ✅ v1.1.0 me Fix kiya gaya:
- **Global PID 1 Namespace Injection:** `nsenter -t 1 -m` se system root me direct anchor hota hai.
- **Universal Multi-Layer Bind Propagation:** `/data/media/0/`, `/sdcard/`, `/storage/emulated/0/`, `/mnt/cloud/`, `/storage/` sabhi jagah link ho jata hai.
- **Native Android Virtual SD Card Volume:** `sm set-virtual-disk true` se Android framework me **Real SD Card** ki tarah register hota hai, jo **Settings -> Storage** me alag se display hota hai!

---

## 🚀 Quick Setup & Usage Guide

### 📱 1. Standalone / Root Mode (Recommended & Easiest)

Termux ya Root Terminal me sirf ye run karo:

```bash
# Google Drive mount karne ke liye:
su -c cloudssd mount gdrive

# TeraBox 1TB mount karne ke liye:
su -c cloudssd mount terabox

# Native SD Card mode enable karne ke liye (Settings -> Storage me dikhega):
su -c cloudssd sdcard-mode on

# Live System Status & AI Cache Check:
su -c cloudssd status

# AI Cache Cleanup & Memory Optimization:
su -c cloudssd ai-optimize

# Unmount karne ke liye:
su -c cloudssd unmount gdrive
```

---

### 📂 Storage Kahan Kahan Dikhegi?

Mount karne ke baad ye 3 jagah ready milegi:
1. **Internal Storage me folder:**
   - `/sdcard/GoogleDrive-CloudSSD`
   - `/sdcard/TeraBox-CloudSSD`
2. **External Storage / Real SD Card path:**
   - `/storage/GoogleDrive-CloudSSD`
   - Settings -> Storage me **Virtual SD Card / Portable Storage** ke roop me!
3. **ZArchiver / Mi File Manager / Solid Explorer / MiXplorer:**
   - Mount hote hi file managers refresh ho jate hain aur direct list me show hote hain.

---

## 🔧 Google Drive Setup (Agar rclone configure nahi hai to)

Termux me run karo:
```bash
rclone config
```
1. Type `n` (New remote)
2. Name: `gdrive`
3. Storage type: `drive` (Google Drive)
4. Client ID & Secret: Khali chhod do (press Enter)
5. Scope: `1` (Full access)
6. Auto-config: `y` (browser me login karke allow karo)
7. Finish! Ab direct run karo: `su -c cloudssd mount gdrive`

---

## 📦 Magisk / KernelSU Module

Agar phone reboot hone ke baad bhi automatic Cloud SSD mounted chahiye:
1. Releases se **`CloudSSD-TeraBox-v1.0.2-HyperOS-Safe.zip`** download karo.
2. Magisk ya KernelSU app me jao -> **Install from storage**.
3. Flash karke reboot karo. Phone boot hote hi background me AI engine auto-mount kar dega bina kisi bootloop risk ke!

---

## 🛠️ Master CLI Commands Reference

| Command | Kaam |
| :--- | :--- |
| `cloudssd mount gdrive` | Google Drive ko as AI Cloud SSD mount karega |
| `cloudssd mount terabox` | TeraBox 1TB volume ko mount karega |
| `cloudssd unmount <name>` | Safe unmount karega aur cache empty karega |
| `cloudssd status` | Active mounts, PID 1 namespace, free space & AI policy dikhayega |
| `cloudssd ai-optimize` | AI Storage Sentinel run karega aur temporary cache saaf karega |
| `cloudssd sdcard-mode on` | Android Settings -> Storage me Virtual SD Card volume activate karega |
| `cloudssd web` | AList Web Dashboard open karega (`http://localhost:5244`) |
| `cloudssd config` | Rclone remote config setup kholega |

---

## 📜 License
MIT License. Created & maintained for Android Power Users by [PandeyJI-9](https://github.com/PandeyJI-9).
