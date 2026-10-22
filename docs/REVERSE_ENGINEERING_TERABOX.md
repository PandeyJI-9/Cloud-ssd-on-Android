# 🔍 Reverse Engineering TeraBox API & The REA Framework

> **Context:** User requested deep research on reverse engineering TeraBox, mentioning the viral GitHub tool **REA (Reverse Engineer Anything)** (`morluto/rea`).

---

## 1. What is REA (Reverse Engineer Anything)?

**REA (`morluto/rea`)** ek open-source MCP (Model Context Protocol) server aur CLI tool hai. Iska maqsad AI agents aur developers ko structured capabilities dena hai taaki wo kisi bhi application ke:
1. **Binary files (.apk, .dex, .so, .exe)** ko decompile aur inspect kar sakein.
2. **Network requests (APIs, WebSocket streams, headers, payloads)** ko trace aur reconstruct kar sakein.
3. Systematically break down karke feature ko independent code me reimplement kar sakein bina original source code ke.

Agar TeraBox ke Android app ya web client ko analyze karna ho, REA aur related reverse-engineering tools (Frida, Jadx, mitmproxy) ka workflow is tarah kaam karta hai:

```
+------------------------------------------------------------------------------------+
|                         REVERSE ENGINEERING WORKFLOW (REA)                         |
|                                                                                    |
|  [ TeraBox APK / Web Client ]                                                      |
|           |                                                                        |
|           v (Inspection / Jadx / REA Tool)                                         |
|  [ Endpoints & Auth Extraction ]                                                   |
|      - App ID: 250528                                                              |
|      - Session Cookie: ndus=...                                                    |
|      - Anti-CSRF Token: bdstoken=...                                               |
|      - User-Agent Rotation                                                         |
|           |                                                                        |
|           v (Network Traffic Replay & Analysis)                                    |
|  [ Endpoint Contract ]                                                             |
|      - File Listing: GET /api/list                                                 |
|      - Download Link: GET /api/download?fs_id=...                                  |
|      - Chunk Upload: POST /api/create & /api/precreate                             |
|           |                                                                        |
|           v (Implementation)                                                       |
|  [ AList / Rclone-Extra Go Driver ] ----> Direct WebDAV & FUSE Integration         |
+------------------------------------------------------------------------------------+
```

---

## 2. Deconstructing the TeraBox API

TeraBox (formerly DuBox, developed by Baidu/Flextech Inc.) Baidu Netdisk ke international platform architecture par chalta hai.

### Key Authentication Tokens:
1. **`ndus` Cookie:**
   - Ye TeraBox ka primary session identifier hai.
   - Browser login session ya app login ke baad cookie store me `ndus` parameter set hota hai.
   - Example format: `ndus=Yd83b1a29f8c...`
   - Is cookie ke bina koi bhi authenticated API call execute nahi ho sakti.

2. **`bdstoken`:**
   - Ek dynamic hex string jo user session ke state aur CSRF prevention ko check karta hai.
   - API endpoints par query parameter ki tarah pass hota hai: `&bdstoken=xxxxxxxxxxxxxxxx`.

3. **`app_id`:**
   - TeraBox ke internal client identifiers hote hain (jaise Web client ke liye `250528`).

---

## 3. Core API Endpoints

### A. Quota & Account Info
```http
GET https://www.terabox.com/api/quota?checkexpire=1&checkfree=1 HTTP/1.1
Host: www.terabox.com
Cookie: ndus=<YOUR_COOKIE>
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)
```
* **Response Payload:** Total storage (`total: 1099511627776` = 1TB) aur used storage bytes return karta hai.

---

### B. Directory File Listing
```http
GET https://www.terabox.com/api/list?dir=%2F&order=time&desc=1&clienttype=0&app_id=250528&web=1&page=1&num=100 HTTP/1.1
Host: www.terabox.com
Cookie: ndus=<YOUR_COOKIE>
```
* **Response:** Har file ka `fs_id` (file system ID), `server_filename`, `size`, `md5`, aur `category` JSON list me milta hai.

---

### C. Download URL Extraction (Crack Method)
Jab TeraBox web interface me download click hota hai:
```http
GET https://www.terabox.com/api/download?app_id=250528&web=1&channel=dubox&clienttype=0&jsToken=<TOKEN>&dlink=1&fs_id=<FS_ID> HTTP/1.1
Host: www.terabox.com
Cookie: ndus=<YOUR_COOKIE>
```
* **Response:**
  TeraBox ka backend direct CDN storage node URL (e.g. `https://d3.terabox.com/file/...`) provide karta hai jo limited time ke liye valid hota hai.
* **Why Free Tier is Throttled:**
  TeraBox CDN server un authenticated download URLs par server-side token bucket rate limiting lagata hai (IP-based + token-based), jisse free users ka download thread 200 KB/s - 400 KB/s par cap ho jata hai.
* **Workarounds used by Community Drivers (AList / Rclone-Extra):**
  - High concurrency multi-chunk downloads (range headers: `Range: bytes=0-1048576`).
  - Mobile API user-agent emulation (Android app user-agent ko kabhi-kabhi web client se better priority milti hai).

---

## 4. Why AList is Better than Building a Raw Python Scraper on Phone

TeraBox frequently apne bot detection aur Captcha challenges update karta rehta hai:
- Raw scraper phone par maintain karna har 2 hafte me toot jata hai.
- **AList (`alist-org/alist`)** ek active global open-source project hai jisme TeraBox driver regularly update hota hai.
- AList is reverse-engineered layer ko ek standard **WebDAV** protocol me abstract kar deta hai, jisse standard Linux **Rclone** bina kisi issue ke mount kar sakta hai.
