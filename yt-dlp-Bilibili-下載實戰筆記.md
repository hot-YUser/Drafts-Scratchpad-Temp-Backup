# yt-dlp 下載 Bilibili 影片實戰筆記

> 環境：Windows 11、yt-dlp 2026.10.26（win_exe）、ffmpeg 9.0.2、Firefox 已登入 Bilibili 帳號、100 Mbps 線路。
>
> 實測樣本：`BV1mss56SEKb`（4 小時 3 分、9.33 GiB）與 `av117619877223078`（4 集合集、單部 10 至 11 GiB）。

## 一、先講結論

| 情境 | 做法 |
|---|---|
| 抓一部小片、幾百 MiB | `yt-dlp --cookies-from-browser firefox -f "30112+30280" --http-chunk-size 2M URL` |
| 抓多部長片、要吃滿線路 | **自寫多執行緒 Range 下載器**（第五節），實測 10.3 MiB/s |

`yt-dlp` 的 `--concurrent-fragments`（`-N`）對 Bilibili 這種單一 URL 的 DASH 軌效果不穩定，同一組參數曾在不同時段量到 0.7、3.6、6.6、9.3、13.7 MiB/s。要可預測地吃滿 100 Mbps，直接用第五節的腳本。

## 二、Cookie 是解析度的門檻

`--cookies-from-browser firefox` 直接讀 Firefox profile 的 `cookies.sqlite`，本次抽出 168 個 cookie，才看得到含 1080P 高碼率的完整格式清單。

未登入時 Bilibili 通常只給 360P 等級的低階格式（社群長期回報，本篇未逐項重測）。

批次抓多部改用 `--cookies cookies.txt`（Netscape 格式）可省下每次解 profile 的時間，也避開 Firefox 執行中鎖住資料庫。

## 三、看懂 `-F` 的清單

`300xx` 是視訊軌（video only），`302xx` 是音軌（audio only）。尾數由 Bilibili 決定，實際對照一律以 `-F` 印出的解析度與編碼欄為準。

同一部片的 1080P 選項（實測）：

| 格式 ID | 解析度 | 編碼 | 碼率 | 預估體積 |
|---|---|---|---|---|
| `30080` | 1920×1080 | AVC | 3618k | 6.16 GiB |
| `30077` | 1920×1080 | HEVC | 1431k | 2.44 GiB |
| `30112` | 1920×1080 | AVC 高碼率 | 5294k | 9.01 GiB |
| `30102` | 1920×1080 | HEVC 高碼率 | 2750k | 4.68 GiB |

重點：**不是每部片都有 HEVC**。同一個合集的 p01、p03 有 `30102`，p04 只列 AVC，`-F` 不先確認就假設有 HEVC 備援，會在切換格式時直接失敗。

音軌：`30280` 約 176 至 178k、`30232` 約 92 至 95k、`30216` 約 66k。只抓 `30280`。

## 四、坑一：HTTP Error 567

下載一開始就連續噴 `Got error: HTTP Error 567: Unknown Status`，重試 30 次、每輪退避 5 秒依然全滅，1 byte 都拿不到，但資訊解析與 `-F` 都正常。

根因在請求形式。CDN 對「不帶 Range 的整檔 GET」回 567，body 為空。yt-dlp 預設單連線整檔下載，正好踩中。

同一天、同一條簽名 URL 的對照：

| 請求形式 | 回應 |
|---|---|
| 無 `Range` | `567`，0 byte |
| `Range: bytes=0-` | `206` |
| `Range: bytes=0-1023` | `206` |

`--http-chunk-size` 會把下載切成帶 Range 的請求，問題消失。自寫下載器本來就全程帶 Range，不受影響。

保留一段誠實記錄：curl 帶 `Range` 曾拿到 `206` 但 body 為 0 byte，同 URL 交給 urllib 或 ffmpeg 卻正常。curl 在這個環境不可靠，測速不要用它。

## 五、坑二：`-N` 對單一 URL 沒有可靠的並行效果

`--concurrent-fragments` 作用在碎片化的 HLS/DASH 流上。Bilibili 的視訊軌是單一 URL 的 https 資源，`--http-chunk-size` 切出的 range 在單一進程內循序抓取，多開執行緒的期待會落空。

實測證據（同一部片、同一時段）：

| 配置 | 40 秒實得 | 換算 |
|---|---|---|
| 無 chunk 無併發 | 0 | 567 |
| `chunk 10M -N 1` | 29.2 MB | 0.73 MiB/s |
| `chunk 2M -N 4` | 223.7 MB | 5.6 MiB/s |
| `chunk 1M -N 32` | 約 2.0 MiB/s | 加到 32 條也沒用 |
| 自寫 6 執行緒 range | 464 MiB / 45 秒 | **10.31 MiB/s** |

`-N 14` 與 `-N 28` 都試過，28 條反而掉到 6.9 MiB/s。單一進程內加併發不是穩定解。

## 六、滿速做法：多執行緒 Range 下載器

原理很簡單：把檔案切成 8 MiB 區塊，`Range: bytes=a-b` 平行抓，標頭帶 `User-Agent` 與 `Referer: https://www.bilibili.com/`，每塊寫回預先配置好的檔案對應偏移。實測 6 至 7 執行緒就能吃滿 100 Mbps。

```python
#!/usr/bin/env python3
"""Bilibili DASH 多執行緒 Range 下載器（只用標準庫）。"""
import subprocess, sys, os, json, threading, time, urllib.request, queue

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")
REF = "https://www.bilibili.com/"
CHUNK = 8 << 20
WORKERS = int(os.environ.get("DL_WORKERS", "7"))


def info(part, url):
    out = subprocess.run(["yt-dlp", "--cookies-from-browser", "firefox",
                          "-J", f"{url}?p={part}"], capture_output=True, check=True).stdout
    d = json.loads(out)
    return d["entries"][0] if "entries" in d else d


def pick(d, fid):
    for f in d["formats"]:
        if f["format_id"] == fid:
            return f
    raise SystemExit(f"format {fid} missing")


def size_of(fmt):
    """一律向 CDN 問真實總長。JSON 的 filesize_approx 常比實際小幾 KB，
    照它 truncate 會把尾端切掉（實測 p3 差 4,752 bytes）。"""
    req = urllib.request.Request(fmt["url"], headers={
        "User-Agent": UA, "Referer": REF, "Range": "bytes=0-0"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return int(r.headers["Content-Range"].split("/")[1])


def fetch(url, start, end, tries=6):
    last = None
    for _ in range(tries):
        try:
            req = urllib.request.Request(url, headers={
                "User-Agent": UA, "Referer": REF,
                "Range": f"bytes={start}-{end}", "Accept-Encoding": "identity"})
            with urllib.request.urlopen(req, timeout=60) as r:
                data = r.read()
            if len(data) == end - start + 1:
                return data
            last = f"short read {len(data)}/{end-start+1}"
        except Exception as e:
            last = repr(e)
        time.sleep(1.5)
    raise RuntimeError(f"range {start}-{end} failed: {last}")


def download(url, path, total):
    done_path = path + ".done"
    done = set(json.load(open(done_path))) if os.path.exists(done_path) else set()
    if not os.path.exists(path):
        with open(path, "wb") as f:
            f.truncate(total)
    bounds = [(s, min(s + CHUNK - 1, total - 1)) for s in range(0, total, CHUNK)]
    pending = queue.Queue()
    for i, (s, e) in enumerate(bounds):
        if i not in done:
            pending.put((i, s, e))
    lock, got, errs = threading.Lock(), [0], []

    def worker():
        while True:
            try:
                i, s, e = pending.get_nowait()
            except queue.Empty:
                return
            try:
                data = fetch(url, s, e)
                with open(path, "r+b") as f:
                    f.seek(s)
                    f.write(data)
                with lock:
                    done.add(i); got[0] += len(data)
                    json.dump(sorted(done), open(done_path, "w"))
            except Exception as ex:
                with lock:
                    errs.append(str(ex))

    threads = [threading.Thread(target=worker) for _ in range(WORKERS)]
    for t in threads:
        t.start()
    t0, last = time.time(), 0
    while any(t.is_alive() for t in threads):
        time.sleep(5)
        with lock:
            cur = got[0]
        if cur != last:
            print(f"{cur/1073741824:6.2f}/{total/1073741824:6.2f} GiB  "
                  f"{cur/1048576/max(time.time()-t0,1e-9):5.2f} MiB/s", flush=True)
            last = cur
    # 尾部保險：長度不足就延伸並重抓最後幾塊，避免檔案尾端被切
    if os.path.getsize(path) < total:
        with open(path, "r+b") as f:
            f.truncate(total)
        for i in range(len(bounds) - 1, max(len(bounds) - 4, -1), -1):
            s0, e0 = bounds[i]
            data = fetch(url, s0, e0)
            with open(path, "r+b") as f:
                f.seek(s0); f.write(data)
            done.add(i)
        json.dump(sorted(done), open(done_path, "w"))
    if errs:
        raise RuntimeError(f"{len(errs)} chunk failures: {errs[:3]}")


def track(part, url, fid, dest):
    d = info(part, url)
    fmt = pick(d, fid)
    total = size_of(fmt)
    base = f"{d['title']} [{d['id']}]"
    path = os.path.join(dest, base + f".f{fid}." + ("m4a" if fmt["ext"] == "m4a" else "mp4"))
    download(fmt["url"], path, total)
    return path, base


if __name__ == "__main__":
    part, dest = int(sys.argv[1]), sys.argv[2]
    fid = sys.argv[3] if len(sys.argv) > 3 else "30112"
    url = "https://www.bilibili.com/video/av117619877223078"
    vid, base = track(part, url, fid, dest)
    aud, _ = track(part, url, "30280", dest)
    final = os.path.join(dest, base + ".mp4")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", vid, "-i", aud,
                    "-c", "copy", "-movflags", "+faststart", final], check=True)
    os.remove(vid); os.remove(aud)
    for p in (vid + ".done", aud + ".done"):
        if os.path.exists(p):
            os.remove(p)
    print("merged:", final)
```

使用：

```powershell
$env:DL_WORKERS=7
python dl.py 3 "D:\LoveLive_15th_Fes" 30112
```

腳本設計的幾個必要細節，少一個就會出事：

| 細節 | 理由 |
|---|---|
| `.done` 記錄已完成區塊 | 斷線重跑只補缺塊，10 GiB 不必從頭 |
| 每塊檢查回傳長度 | CDN 會回短讀（幾百 bytes），不檢查會寫進殘缺資料 |
| `.done` 與資料檔必須成對存在 | 只留 `.done` 而資料檔被刪，重跑會跳過全部區塊，產出全零檔案（音軌靜音就是這樣來的） |
| 預先 `truncate(total)` | Windows 的 NTFS 不支援稀疏檔，這一步會立刻佔滿磁碟 |
| 總長一律問 CDN | `yt-dlp -J` 的 `filesize_approx` 常比實際小，照它切會少抓尾端（實測差 4,752 bytes） |
| 完成後才 `ffmpeg -c copy` 合併 | 音視訊分軌下載，合併需要額外約一個成品大小的空間 |

## 七、鏡像選擇

同一條簽名 URL 換掉主機名通常可用（簽名綁路徑與參數，不綁網域）。實測：

| 主機 | 8 MiB 區塊耗時 | 換算 |
|---|---|---|
| `upos-hz-mirrorakam.akamaized.net` | 4.10s | 1.95 MiB/s |
| `upos-sz-mirrorhw.bilivideo.com` | 4.95s | 1.62 MiB/s |
| `upos-sz-mirrorcosov.bilivideo.com` | 6.97s | 1.15 MiB/s |
| `upos-sz-mirrorali.bilivideo.com` | 168.53s 逾時 | 不可用 |

反面教材：把區塊輪流丟給 Akamai 與 cosov，整體從 6.6 MiB/s 掉到 **3.6 MiB/s**，慢鏡像的慢連線會拖住整批。要嘛全走最快的單一主機，要嘛只混用速度接近的主機。

## 八、先探測再開抓

```powershell
yt-dlp --cookies-from-browser firefox -f "30112+30280" `
  --download-sections "*00:00-00:00:30" `
  -P . -o "probe.%(ext)s" "URL"
```

`--download-sections` 走 ffmpeg 的 Range 請求，順帶繞過 567。30 秒片段通常 5 秒內跑完，能同時驗證格式可用性與實際碼率。

同時先確認目標格式存在：`-F` 只列 AVC 的片就別期待 HEVC 備援。

## 九、抓完之後驗證

```powershell
ffprobe -v error -show_entries format=duration,size,bit_rate `
  -show_entries stream=index,codec_name,width,height,duration -of default=nw=1 "檔案.mp4"

ffmpeg -v error -i "檔案.mp4" -map 0 -c copy -f null -

ffmpeg -v error -ss 0 -t 20 -i "檔案.mp4" -f null -
ffmpeg -v error -ss 14590 -t 25 -i "檔案.mp4" -f null -
```

`-c copy` 那條走完整檔，抓不到解碼錯誤，但能抓出截斷、索引損毀、合併失敗。10 GiB 約 6 秒，無輸出即通過。

## 十、常見需求速查

| 需求 | 指令 |
|---|---|
| 只要音訊 | `-f 30280 -x --audio-format m4a` |
| 只要封面 | `--skip-download --write-thumbnail` |
| 只要前 10 分鐘 | `--download-sections "*00:00-00:10:00"` |
| 多 P 選段 | `--playlist-items 1-5` |
| 多 P 命名 | `-o "%(playlist_index)02d_%(title)s.%(ext)s"` |
| 斷點續傳 | yt-dlp 直接重跑；自寫下載器靠 `.done` |
| 保留中間軌 | 加 `-k`（預設合併後刪除） |
| 字幕 | `--write-subs --sub-langs all`（需登入，且不是每部都有） |

## 十一、檔名與終端編碼

yt-dlp 的 `fs` 編碼是 utf-8，但 Windows 主控台 locale 是 cp936。標題含數學粗體（`𝓛𝓸𝓿𝓮...`）時，磁碟上的檔名完全正確，stdout 印出的 `Destination` 會變成 `!  15  【.1】` 這類殘缺字串。

看到日誌有怪檔名，先 `ls` 確認實際檔名，不要急著重下。

## 十二、錯誤對照表

| 症狀 | 原因 | 處理 |
|---|---|---|
| `HTTP Error 567` 連噴 | 無 Range 的整檔請求被 CDN 拒絕 | 改用帶 Range 的下載方式 |
| 速度卡在 1 至 2 MiB/s | 單連線，`-N` 沒有真的並行 | 換多執行緒 range 下載器 |
| 加到 28 條執行緒反而更慢 | 伺服器端對 IP 有總量限制 | 6 至 7 條就夠，別再加 |
| 混合鏡像後掉速 | 慢鏡像的慢連線拖住整批 | 全走最快主機 |
| 格式清單只有 360P | 沒帶 Cookie，或帳號權限不足 | `--cookies-from-browser firefox` |
| 切到 HEVC 直接失敗 | `-F` 沒先確認該 P 有沒有 HEVC | 先 `-F` 再看 |
| 音軌全靜音、影片正常 | `.done` 存在但資料檔已刪，全部區塊被跳過 | `.done` 與資料檔必須成對刪 |
| 合併階段空間不足 | 成品另佔一份空間 | 先清出至少一個成品的空間 |
| 日誌檔名亂碼 | cp936 顯示不了星體字元 | 不影響，`ls` 確認即可 |
| 合併時噴 `Invalid NAL unit size` / `Input buffer exhausted` | Bilibili 的 m4s 尾端封包本身殘缺（實測多 24 / 202 bytes），屬來源特性 | 先確認檔案長度等於 CDN 總長，長度正確就別重抓 |

## 十三、實測數據

第一部（`BV1mss56SEKb`，1080P AVC 高碼率 + 178k 音軌）：

| 項目 | 值 |
|---|---|
| 大小 | 10,014,543,179 bytes（9.33 GiB） |
| 長度 | 14624.62 秒（4:03:44.6） |
| 視訊 / 音訊 | H.264 High 1920×1080 29.97fps / AAC LC 48kHz 立體聲 |
| 平均碼率 | 5.48 Mbps |

第二部（`av117619877223078` 的 p01，U-NEXT 源）：

| 項目 | 值 |
|---|---|
| 大小 | 11,085,265,974 bytes（10.32 GiB） |
| 長度 | 14594.58 秒（4:03:14.6） |
| 平均碼率 | 6.08 Mbps |
| 下載方式 | 多執行緒 range，10.31 MiB/s |

畫質對照（官方 Day.1 對 U-NEXT p01，音訊包絡對齊偏移 +10.15 秒，6 個對齊畫格）：

| 指標 | 官方 | U-NEXT | 差異 |
|---|---|---|---|
| Tenengrad（越高越銳） | 1316.4 | 1408.3 | +7.0% |
| 高頻能量 | 1.703 | 1.846 | +8.4% |
| 8×8 區塊化（越低越好） | 1.245 | 1.218 | 較佳 |
