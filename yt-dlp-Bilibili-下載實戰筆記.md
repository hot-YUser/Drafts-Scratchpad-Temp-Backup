# yt-dlp 下載 Bilibili 影片實戰筆記

> 環境：Windows 11、yt-dlp 2026.10.26（win_exe）、ffmpeg 9.0.2、Firefox 已登入 Bilibili 帳號。
>
> 實測樣本：[BV1mss56SEKb](https://www.bilibili.com/video/BV1mss56SEKb)，4 小時 3 分的 1080P 長片，成品 9.33 GiB。

## 一、最短路徑

```powershell
yt-dlp --cookies-from-browser firefox `
  -f "30112+30280" `
  --http-chunk-size 10M -N 8 `
  -P "$env:USERPROFILE\Downloads" `
  "https://www.bilibili.com/video/BV1mss56SEKb"
```

這串參數的三個關鍵各有不可替代的理由：Cookie 決定能不能拿到高解析度，`--http-chunk-size` 決定 CDN 會不會直接回 567，`-N` 決定單條連線被限速時能不能繞過。少任何一個都會退回很糟的預設行為。

`ffmpeg` 必須在 `PATH` 裡，Bilibili 的音視訊是分開的 DASH 軌，合併要靠它。

## 二、Cookie 是解析度的門檻

`--cookies-from-browser firefox` 直接讀 Firefox profile 的 `cookies.sqlite`，本次抽出 168 個 cookie，換到含 1080P 高碼率的完整格式清單。

未登入時 Bilibili 通常只給 360P 等級的低階格式（社群長期回報，本篇未逐項重測）。要驗證自己的帳號到底能拿到哪一檔，跑一次 `-F` 最快。

批次抓多部時建議改用 `--cookies cookies.txt`（Netscape 格式，瀏覽器擴充套件可匯出）。理由有兩個：不必每次呼叫都重新解 profile，也避開 Firefox 執行中鎖住資料庫造成的讀取失敗。

## 三、看懂 `-F` 的清單

Bilibili 的 DASH 編號規律：`300xx` 是視訊軌（video only），`302xx` 是音軌（audio only）。編號尾數由 Bilibili 決定，實際對照一律以 `-F` 印出的解析度與編碼欄為準。

本次樣本量到的 1080P 選項：

| 格式 ID | 解析度 | 編碼 | 碼率 | 預估體積 |
|---|---|---|---|---|
| `30080` | 1920×1080 | AVC | 3618k | 6.16 GiB |
| `30077` | 1920×1080 | HEVC | 1431k | 2.44 GiB |
| `30112` | 1920×1080 | AVC 高碼率 | 5294k | 9.01 GiB |
| `30102` | 1920×1080 | HEVC 高碼率 | 2750k | 4.68 GiB |

同一解析度下 HEVC 的碼率大約是 AVC 的一半，體積也接近砍半。要省空間選 HEVC，要通用相容性（舊播放器、剪輯軟體、車機）選 AVC。

音軌對照：`30280` 約 178k、`30232` 約 95k、`30216` 約 66k。只有 `30280` 值得抓。

## 四、坑一：HTTP Error 567

現象是下載一開始就連續噴 `Got error: HTTP Error 567: Unknown Status`，重試 30 次、每輪退避 5 秒依然全滅，連 1 byte 都拿不到。同一部片的資訊解析、`-F` 都正常。

根因不在限流，在請求形式。CDN 對「不帶 Range 的整檔 GET」直接回 567，body 是空的。yt-dlp 預設就是單連線整檔下載，正好踩中。

實測對照（同一天、同一條簽名 URL）：

| 請求形式 | 回應 |
|---|---|
| 無 `Range` | `567`，0 byte |
| `Range: bytes=0-` | `206` |
| `Range: bytes=0-1023` | `206` |

解法是 `--http-chunk-size 10M`，yt-dlp 會把下載拆成一段段 10 MiB 的 Range 請求，問題消失。

保留一段誠實記錄：用 curl 手動帶 `Range` 曾拿到 `206` 但 body 為 0 byte，同一條 URL 交給 ffmpeg 卻正常取到資料。推測是 header 指紋差異，沒有追到底。實務上不必深究，走 yt-dlp 或 ffmpeg 就沒這問題。

## 五、坑二：單連線被壓速

同樣帶 `--http-chunk-size 10M`，不加併發時單連線跑滿 60 分鐘只抓到 3.3 GiB，約 1 MiB/s。

改成 `-N 8` 後，90 秒抓 468 MiB（5.2 MiB/s），完整 9.01 GiB 那次平均 13.74 MiB/s。

重點：`-N` 必須跟 `--http-chunk-size` 一起用。沒有 chunk 切分時，一個下載任務只有一條連線，`-N` 完全沒有作用。

## 六、先探測再開抓

長片一抓就是幾小時，先花 5 秒確認格式真的抓得下來：

```powershell
yt-dlp --cookies-from-browser firefox -f "30112+30280" `
  --download-sections "*00:00-00:00:30" `
  -P . -o "probe.%(ext)s" "URL"
```

`--download-sections` 會走 ffmpeg 的 Range 請求，順帶繞過 567。30 秒片段在 5 秒內跑完，能同時驗證格式可用性與實際碼率。擊破「清單有列但抓不下來」這種假象。

## 七、抓完之後驗證

```powershell
# 容器與串流資訊
ffprobe -v error -show_entries format=duration,size,bit_rate `
  -show_entries stream=index,codec_name,width,height,duration -of default=nw=1 "檔案.mp4"

# 全檔結構檢查（不重新編碼，10 GiB 約 6 秒）
ffmpeg -v error -i "檔案.mp4" -map 0 -c copy -f null -

# 首尾抽樣解碼
ffmpeg -v error -ss 0 -t 20 -i "檔案.mp4" -f null -
ffmpeg -v error -ss 14590 -t 25 -i "檔案.mp4" -f null -
```

`-c copy` 那條會完整讀過每個 packet，抓不到解碼錯誤，但能抓出截斷、索引損毀、合併失敗。無輸出即通過。

## 八、常見需求速查

| 需求 | 指令 |
|---|---|
| 只要音訊 | `-f 30280 -x --audio-format m4a` |
| 只要封面 | `--skip-download --write-thumbnail` |
| 只要前 10 分鐘 | `--download-sections "*00:00-00:10:00"` |
| 多 P 選段 | `--playlist-items 1-5` |
| 多 P 命名 | `-o "%(playlist_index)02d_%(title)s.%(ext)s"` |
| 斷點續傳 | 直接重跑同一條指令，`.part` 會接續 |
| 保留中間軌 | 加 `-k`（預設合併後刪除） |
| 字幕 | `--write-subs --sub-langs all`（需登入，且不是每部都有） |

## 九、檔名與終端編碼

yt-dlp 的 `fs` 編碼是 utf-8，但 Windows 主控台 locale 是 cp936。標題含數學粗體（`𝓛𝓸𝓿𝓮...`）時，寫到磁碟的檔名完全正確，但 stdout 印出來的 `Destination` 會被壓成 `!  15  【.1】` 這類殘缺字串。

看到日誌裡有怪檔名，先 `ls` 看實際檔名，不要急著重下。這次就是虛驚一場。

## 十、錯誤對照表

| 症狀 | 原因 | 處理 |
|---|---|---|
| `HTTP Error 567` 連噴 | 無 Range 的整檔請求被 CDN 拒絕 | `--http-chunk-size 10M` |
| 速度長期 1 MiB/s | 單連線被限速 | `-N 8` 搭配 chunk size |
| 格式清單只有 360P | 沒帶 Cookie，或帳號權限不足 | `--cookies-from-browser firefox` |
| 合併階段報錯 | 缺 ffmpeg | 安裝並加入 `PATH` |
| 日誌檔名亂碼 | cp936 顯示不了星體字元 | 不影響，`ls` 確認即可 |

## 十一、本次成品數據

| 項目 | 值 |
|---|---|
| 大小 | 10,014,543,179 bytes（9.33 GiB） |
| 長度 | 14624.62 秒（4:03:44.6） |
| 視訊 | H.264 High、1920×1080、29.97 fps |
| 音訊 | AAC LC、48 kHz、立體聲 |
| 平均碼率 | 5.48 Mbps |

下載耗時約 11 分 11 秒（視訊）加 32 秒（音訊），驗證階段 `-c copy` 全檔讀完零錯誤。
