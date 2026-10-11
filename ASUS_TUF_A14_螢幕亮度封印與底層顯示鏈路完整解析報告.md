# ASUS TUF Gaming A14 (FA401KM) 螢幕亮度封印根因分析與底層顯示鏈路參數全解

> **機型基準**：ASUS TUF Gaming A14 (`FA401KM_FA401KM`)
> **處理器與內顯**：AMD Krackan Point / Strix Point APU — `AMD Radeon(TM) 860M Graphics` (`PCI\VEN_1002&DEV_1114&SUBSYS_10D41043&REV_C2`)
> **獨立顯卡**：`NVIDIA GeForce RTX 5060 Laptop GPU` (`PCI\VEN_10DE&DEV_2D59&SUBSYS_10D41043&REV_A1`)
> **內建顯示面板**：天馬微電子 `Tianma TL140ADMP01`（硬體識別碼：`MONITOR\TMA2071` / EDID 廠商碼 `A151` 產品碼 `2071`，14.0 吋 2560×1600 165Hz eDP 霧面 IPS）
> **撰寫時間**：2026 年 10 月 11 日

---

## 一、問題現象與根因總結（Root Cause Analysis）

### 1.1 為什麼標稱 400～460 nits 的螢幕，拉到 100% 卻一直看不清、超級暗？

在混合顯示模式（NVIDIA Advanced Optimus / `Mux flag = 1`）下，筆電內建螢幕的訊號與背光完全由 **AMD Radeon 860M 內顯的 DCN（Display Core Next）顯示引擎**負責驅動。整體顯示鏈路如下：

```
[Windows DWM 桌面視窗管理員]
       │
       ▼
[Windows ICM / WCS 色彩管理]  ◄── (被掛載 FA401KM_1002_A1512071.icm，白點標記僅 284.14 nits)
       │
       ▼
[AMD KMD 驅動 (amdkmdag.sys) & DCN 硬體 3D LUT / Regamma 區塊]
       ▲
       ├── 1. ASUSOptimization 服務與 G-Helper 同時在背景呼叫 AsusSplendid.exe 搶奪控制權
       ├── 2. AsusSplendid.exe 狀態檔卡死在 EyeCareLevel=4 (最高級護眼濾鏡) + BWContrast=2
       └── 3. AsusCCT.dll 讀取異常白點 (wtpt invalid) 與平滑化失敗 (LutSmooth8Bit failed) 的曲線強灌入硬體 LUT
       │
       ▼
[eDP 1.4+ 實體通道 (8-bit RGB + AUX/PWM 背光控制)]
       ▲
       └── 4. G-Helper 預設開啟 optimal_brightness=1 + AMD 登錄檔與 Windows 電源計畫殘留省電死碼
       │
       ▼
[Tianma TL140ADMP01 面板 TCON 與 LED 背光模組]
```

造成螢幕「一直看不清、超級暗、像隔了一層灰霧」的並非單一設定，而是**四重軟體與韌體死碼疊加**的結果：

---

### 1.2 四大封印根因拆解

#### 根因一：`AsusSplendid.exe` 的單向狀態殘留缺陷（卡死在 `EyeCareLevel=4`）
* **發生經過**：華碩在驅動市集套件（`asussci2.inf` ➔ `ASUSOptimization`）中內建了 `AsusSplendid.exe`。當使用者曾透過軟體或熱鍵切換過「護眼模式（EyeCare，代碼 `17`）」或「電子書黑白模式（代碼 `212`）」後，`AsusSplendid.exe` 會在系統底層狀態檔 `YUser_my_sp_data.sys` 與 `HardwareSettings_Splendid_C` 寫入 **`EyeCareLevel=4`**（最高強度濾藍光與對比壓縮）及 **`BWContrast=2`**。
* **致命缺陷**：之後當你在 G-Helper 介面將視覺模式切回「預設（Default，代碼 `11`）」時，G-Helper 執行的是 `AsusSplendid.exe 11 0 50`。然而 `AsusSplendid.exe` 在處理代碼 `11` 時，**只更新了 `Mode=11`，卻沒有將狀態檔內的 `EyeCareLevel=4` 歸零**！除非從命令列明確執行 `AsusSplendid.exe 17 0 0`，否則護眼等級永遠卡在 `4`。

#### 根因二：出廠校色檔（`FA401KM_1002_A1512071.icm`）白點異常與 284 nits 峰值壓縮
* **二進位解剖證據**：在 `C:\ProgramData\ASUS\GameVisual\FA401KM_1002_A1512071.icm` 中：
  1. **`lumi`（Luminance 白點亮度標籤，Offset `684`）**：數值為 `0x011C23D4`（Big-Endian `s15Fixed16Number` 定點數），整數部分 `0x011C` = **`284.14 nits`**。華碩出廠校色程式（ACMP V2.3.0）將這塊面板的校準白點定在僅 284 nits（遠低於面板硬體能力）。
  2. **`wtpt`（Media White Point 媒體白點座標，Offset `704`）**：數值為 $X = 0.975128, Y = 1.000000, Z = 1.246185$。因為原生面板冷白點的 $Z$ 值（藍光分量）遠高於標準 D65 白點（$Z = 1.089058$），當 `AsusCCT.dll` 讀取該檔案計算色域映射時，在日誌 `CCTAPI_Log.txt` 中直接報錯：
     * `ICM wtpt is not valid, XYZ[3][0] = 0.975128`
     * `ICM wtpt is not valid, XYZ[3][2] = 1.246185`
     * `HIT: LutSmooth8Bit() failed!!!`
* **硬體級污染**：儘管計算報錯，`AsusSplendid.exe` 依然透過 **AMD ADLX / ADL 硬體通道**（`ADL_Display_RegammaR1_Set`）將壓縮後的查找表寫入 AMD 內顯的 DCN 硬體 3D LUT 中。這種硬體級 LUT 修改**不會反映在傳統 Windows GDI 的 `GetDeviceGammaRamp` 上**（GDI 看起來仍是滿值 `65535`），但實際輸出的畫面亮度與對比度卻被硬生生砍掉一大截。

#### 根因三：雙控制軟體常駐衝突（`ASUSOptimization` 服務 + 排程任務 vs `G-Helper`）
* 電腦同時運行著華碩官方的 **7 個背景服務**（特別是 `ASUSOptimization`）、**4 個 Windows 工作排程器任務**（如 `ASUS Optimization 36D18D69AFC3` 會在開關機時呼叫 `AsusHotkey.exe`），以及你安裝的 **`G-Helper`**。
* 每當插拔電源（觸發 `WMI event 123`）、休眠喚醒或開機時，兩邊各自監聽 WMI 事件並輪流呼叫 `AsusSplendid.exe` 覆寫螢幕狀態；同時 G-Helper 預設開啟了 `"optimal_brightness": 1`，每次開機自動向華碩 ACPI 寫入最佳化背光省電限制。

#### 根因四：驅動 INF 與系統電源管理中的「幽靈死碼」
* 雖然這塊 `TL140ADMP01` 面板在 VBIOS 與 EDID 中**不支援** AMD Vari-Bright（`ADL_Adapter_VariBright_Caps` 回傳 `Supported = 0`）、**不支援** Windows 內容自適應亮度 CABC、且為**固定原生 8-bit 面板**，但 AMD 驅動安裝檔（`u0203304.inf`）與登錄檔中卻殘留了 `Dal_UserVariBrightLevel = 3`、`PP_UserVariBrightLevel = 3`、`AutoColorDepthReduction_NA = 1`、`SPRSACDCUserEnable = 01` 等預設省電死碼，且 Windows 電源計畫的 `ADVANCEDCOLORQUALITYBIAS` 在電池模式下被設為 `0`（省電優先）。

---

## 二、全系統底層參數鉅細靡遺全解（Parameter Reference Manual）

以下按顯示鏈路從硬體底層到應用層，逐一解析每個參數的**位置、資料型態、所有可能值、原始異常值與修正後數值**。

---

### 2.1 第一層：面板硬體 EDID 與 ICC 校色檔二進位參數

#### (A) 面板 EDID 基礎與擴充區塊
* **登錄檔路徑**：`HKLM\SYSTEM\CurrentControlSet\Enum\DISPLAY\TMA2071\5&37b69103&0&UID512\Device Parameters\EDID`

| 參數位置 / 名稱 | 原始 Hex 值 | 解碼後數值 | 所有可能值與規範定義 | 硬體意義解析 |
| :--- | :--- | :--- | :--- | :--- |
| **Offset `0x08..0x0B`**<br>廠商與產品識別碼 | `51 A1 71 20` | 廠商：`TMA` (`0xA151`)<br>產品：`2071` (`0x2071`) | EISA 3 字元壓縮碼 + 16-bit Little-Endian 產品碼 | 對應華碩校色檔名中的 `A1512071`（天馬 `TL140ADMP01`）。 |
| **Offset `0x14` (Byte 20)**<br>`Video Input Definition` | `0xA5`<br>(`1010 0101`b) | 數位輸入、`8-bit` 色深、eDP 介面 | **Bit 7**：`1`=Digital, `0`=Analog<br>**Bits 6..4 (色深)**：<br>• `000` = 未定義<br>• `001` = 6 bpc<br>• **`010` = 8 bpc (本面板)**<br>• `011` = 10 bpc<br>• `100` = 12 bpc<br>• `101` = 14 bpc<br>• `110` = 16 bpc<br>**Bits 3..0 (介面)**：<br>• `0001` =single DVI<br>• `0010` = HDMI-a<br>• `0100` = MDDI<br>• **`0101` = DisplayPort / eDP (本面板)** | **這就是為何 AMD Adrenalin 介面沒有「色彩深度」選單**：面板韌體直接宣告為固定原生 8-bit eDP，不支援切換 10-bit。 |
| **CEA-861 Ext Offset `0x70`**<br>`HDR Static Metadata Data Block` | `E6 06 01 01 60 60 FF` | 僅支援 SDR Gamma<br>峰值亮度：**`400.0 nits`** | **Byte 2 (EOTF Bitmask)**：<br>• **`0x01` (Bit 0) = 傳統 SDR Gamma (本面板)**<br>• `0x02` (Bit 1) = HDR Traditional Gamma<br>• `0x04` (Bit 2) = SMPTE ST 2084 (HDR10)<br>• `0x08` (Bit 3) = Hybrid Log-Gamma (HLG)<br>**Byte 4 (`0x60` = 96)**：依 CTA-861 公式：<br>$\text{Max Nits} = 50 \times 2^{(CV / 32)}$<br>$= 50 \times 2^{(96/32)} = 400\text{ nits}$ | 面板韌體向驅動回報的峰值亮度上限為 **400 nits**，且未開啟 HDR10 EOTF 位元（純 SDR 廣色域面板）。 |

#### (B) 華碩出廠 ICC 校色檔（`FA401KM_1002_A1512071.icm`）內部標籤
* **原始路徑**：`C:\ProgramData\ASUS\GameVisual\FA401KM_1002_A1512071.icm`（現已移至 `_disabled_backup` 封存隔離）

| ICC Tag 簽名 | Offset / 大小 | 原始 Hex 數據 | 解碼值與物理意義 | 問題分析 |
| :--- | :--- | :--- | :--- | :--- |
| **`lumi`**<br>(LuminanceTag) | Offset `684`<br>(20 Bytes) | `00 00 00 00`<br>`01 1C 23 D4`<br>`00 00 00 00` | $Y = \text{0x011C} + \frac{\text{0x23D4}}{65536} = \mathbf{284.14\text{ cd/m}^2}$ | 定義校色目標白點絕對亮度僅 **284.14 nits**，遠低於面板實際極限。 |
| **`wtpt`**<br>(MediaWhitePointTag) | Offset `704`<br>(20 Bytes) | `00 00 F9 A2`<br>`00 01 00 00`<br>`00 01 3F 06` | $X = 0.975128$<br>$Y = 1.000000$<br>$Z = 1.246185$ | $Z$ 值過高（偏冷藍），超出 `AsusCCT.dll` 的 D65 容許範圍，觸發 `ICM wtpt is not valid` 錯誤。 |
| **`bkpt`**<br>(MediaBlackPointTag) | Offset `724`<br>(20 Bytes) | `00 00 00 1D`<br>`00 00 00 19`<br>`00 00 00 3B` | $X = 0.00044, Y = 0.00038, Z = 0.00090$ | 定義面板最低黑位基準點。 |
| **`rTRC` / `gTRC` / `bTRC`**<br>(Tone Reproduction Curves) | Offset `932` / `1456` / `1980`<br>(各 524 Bytes) | `curv` 型態，含 256 個 `UInt16` 節點 | 起點 `(R:27, G:22, B:50)` ➔ 終點 `65535` | 當 `AsusSplendid.exe` 將此曲線與色溫矩陣疊加並做 8-bit 平滑化時，觸發 `LutSmooth8Bit() failed!!!`。 |

---

### 2.2 第二層：ASUS Splendid / GameVisual 與 CCTAPI 參數集

#### (A) `AsusSplendid.exe` 命令列參數完整對照表
* **執行檔路徑**：`C:\WINDOWS\System32\DriverStore\FileRepository\asussci2.inf_amd64_197d319fab43e0fe\ASUSOptimization\AsusSplendid.exe`
* **呼叫語法**：`AsusSplendid.exe <Mode> [SubParam] [Value1] [Value2]`

| 第一參數 `<Mode>` | 模式名稱 | 完整呼叫範例 | 內部轉發至 `AsusCCT.dll` 的 `Param` | 詳細行為與副作用 |
| :--- | :--- | :--- | :--- | :--- |
| **`0`** 或 **`10`** | 初始化 / 重置暫存 | `AsusSplendid.exe 10` | `0x2` (依狀態檔) | 刪除舊 gamma 暫存檔，並讀取 `YUser_my_sp_data.sys` 重新套用上次紀錄的模式。 |
| **`11`** | **Default (標準預設)** | `AsusSplendid.exe 11 0 50` | `0x2` | 套用出廠 `.icm` 與色溫（第三參數 `0`~`100`，`50` 為預設中立色溫）。**注意：不會歸零 `EyeCareLevel`！** |
| **`13`** | **Vivid (鮮豔模式)** | `AsusSplendid.exe 13 0 50` | `0x3` | 透過硬體 LUT 拉高色彩飽和度與對比度。 |
| **`17`** | **EyeCare (護眼模式)** | `AsusSplendid.exe 17 0 <0..4>` | `0x7` | 第三參數為護眼等級 **`0`～`4`**。<br>• **`0`**：關閉護眼模式（**唯一能將狀態檔 `EyeCareLevel` 歸零的指令**）<br>• **`1`～`4`**：依序壓低藍光與整體亮度對比（先前你卡在 `4`）。 |
| **`18`** | **Disable (停用直出)** | `AsusSplendid.exe 18 2` | **`0x8` (Bypass)** | **最乾淨模式**：停用所有 GameVisual 濾鏡，將 AMD 內顯硬體 LUT 切回原生直出狀態。 |
| **`21`** | **Racing (賽車模式)** | `AsusSplendid.exe 21 0 50` | `0x15` (`21`) | 載入 GameVisual 賽車 LUT 曲線。 |
| **`22`** | **Scenery (風景模式)** | `AsusSplendid.exe 22 0 50` | `0x16` (`22`) | 載入風景 LUT 曲線（調整綠/藍飽和與亮部階調）。 |
| **`23`** | **RTS / RPG 模式** | `AsusSplendid.exe 23 0 50` | `0x17` (`23`) | 載入 RTS/RPG 暗部增亮與銳化曲線。 |
| **`24`** | **FPS 模式** | `AsusSplendid.exe 24 0 50` | `0x18` (`24`) | 大幅拉高暗部灰階（犧牲黑位與對比度以看清暗處敵人，日常看字會極度泛白）。 |
| **`25`** | **Cinema (劇院模式)** | `AsusSplendid.exe 25 0 50` | `0x19` (`25`) | 壓暗亮部並改變色溫以模擬劇院感。 |
| **`212`** | **E-Reading (黑白電子書)** | `AsusSplendid.exe 212 0 2 50` | 黑白 LUT + `Asus_Monochrome.icm` | 第三參數為黑白對比 `BWContrast`（`0`~`4`），第四參數為色溫 `BWColor`。會生成 `Asus_Monochrome.icm`。 |

#### (B) Splendid 狀態檔（`YUser_my_sp_data.sys` & `HardwareSettings_Splendid_C`）欄位全解
* **檔案路徑**：
  * `C:\ProgramData\ASUS\ASUS System Control Interface\ASUSOptimization\Splendid\YUser_my_sp_data.sys`
  * `C:\ProgramData\ASUS\ASUS System Control Interface\log\HardwareSettings_Splendid_C`

| 欄位名稱 | 可能值範圍 | 清理前異常值 | 清理後鎖定值 | 欄位意義說明 |
| :--- | :--- | :--- | :--- | :--- |
| **`Mode`** | `11`, `13`, `17`, `18`, `21`~`25`, `212` | `11` | **`18`** | 紀錄當前 GameVisual / Splendid 模式編號（`18` 為完全停用）。 |
| **`EyeCareLevel`** | `0` ～ `4` | **`4` (或 `2`)** | **`0`** | 護眼模式濾藍光/降亮度等級。`0` 為完全關閉。 |
| **`ColorTemperature`** | `0` ～ `100` | `50` | **`50`** | 色溫滑桿值（`0` 最暖黃、`50` 原生中立、`100` 最冷藍）。 |
| **`BWEnable`** | `0` (關閉) / `1` (開啟) | `0` | **`0`** | 電子書黑白模式總開關。 |
| **`BWContrast`** | `0` ～ `4` | **`2`** | **`0`** | 電子書模式的對比度壓縮等級。 |
| **`LutDcScale`** | `0` ～ `100` | `100` | **`100`** | 硬體 LUT 動態對比縮放百分比（`100` = 1.0 倍不縮放）。 |
| **`ColorSpaceMode`** | `0` (Native), `1` (sRGB), `2` (DCI-P3), `3` (Display P3) | `0` | **`0`** | 色域空間切換模式（此面板僅支援 `0` 原生色域）。 |
| **`ICMExist` / `ICMEXIST2`** | `YES` / `NO` | `YES` | **`NO`** | 標記是否存在並啟用華碩自訂 `.icm` 校色檔。改為 `NO` 防止再次載入 284 nits 設定檔。 |
| **`AMDADLXSup`** | `0` / `1` | `1` | `1` | 標記此機型透過 AMD ADLX 介面直接寫入內顯硬體 3D LUT。 |

---

### 2.3 第三層：G-Helper 設定檔（`config.json`）與運行日誌參數

* **設定檔路徑**：`C:\Users\YUser\AppData\Roaming\GHelper\config.json`
* **日誌檔路徑**：`C:\Users\YUser\AppData\Roaming\GHelper\log.txt`

| JSON 屬性名稱 | 所有可能值 | 清理前數值 | 清理後數值 | 底層行為與硬體作用 |
| :--- | :--- | :--- | :--- | :--- |
| **`visual`** | `11`, `13`, `17`, `18`, `21`~`25` | `11` | **`18`** | 控制 G-Helper 傳遞給 `AsusSplendid.exe` 的模式。設為 **`18`** 代表停用 Splendid 濾鏡。 |
| **`color_temp`** | `0` ～ `100` | `50` | **`50`** | 色溫百分比（`50` 為不偏移）。 |
| **`optimal_brightness`** | `0` (關閉) / `1` (開啟) | **`1`** | **`0`** | 開啟時，G-Helper 啟動會向華碩 ACPI WMI 發送 `Optimal Brightness = 1`，啟用面板背光省電映射。設為 **`0`** 徹底解除限制。 |
| **`services_disabled`** | `0` (不干預) / `1` (自動停用) | 未設定 (`0`) | **`1`** | 設為 **`1`** 時，G-Helper 每次開機都會自動檢查並強制停止、停用所有衝突的華碩官方背景服務。 |
| **`overdrive`** | `0` (關閉) / `1` (開啟) | `1` | `1` | 控制華碩 ACPI `ScreenOverdrive`（插電 165Hz 時開啟液晶像素加速，減少殘影；電池 60Hz 時自動關閉）。 |
| **`screen_auto`** | `0` (手動) / `1` (自動) | `1` | `1` | 拔電時自動切 60Hz 省電，插電時自動切回 165Hz。 |
| **`gpu_mode`** | `0` (Eco), `1` (Standard), `2` (Ultimate) | `1` | `1` | GPU 運作模式：`0` 強制關閉 RTX 5060 獨顯、`1` 混合輸出 (Advanced Optimus)、`2` 獨顯直連 (需重開機切換 MUX)。 |

#### 附錄：G-Helper 日誌中 `TL140ADMP01 HDR: False ACM: False | False 8 5 True` 六個欄位解密
在 `GHelper\log.txt` 中，每次顯示狀態變更會印出一行由 Windows `DisplayConfigGetDeviceInfo` 取得的硬體狀態：
1. **`HDR: False`**：`advancedColorEnabled`（是否啟用 HDR 高動態範圍）。
2. **`ACM: False`**：`autoColorManagementEnabled`（是否啟用 Windows 11 自動色彩管理 ACM，若開啟會強制將廣色域限縮至 sRGB）。
3. **`| False`**：`wideColorEnforced`（是否強制廣色域模式）。
4. **`8`**：`bitsPerColorChannel`（目前面板運行於原生 **8-bit** 色深）。
5. **`5` (插電時) / `13` (電池時)**：`DISPLAYCONFIG_GET_ADVANCED_COLOR_INFO` 的原始 `value` 位元遮罩（Bitmask）：
   * Bit 0 (`1`) = `advancedColorSupported`
   * Bit 2 (`4`) = `wideColorEnforced`（$1 + 4 = 5$）
   * Bit 3 (`8`) = `advancedColorForceDisabled`（拔電進入省電狀態時，系統強制標記停用進階色彩，故變為 $1 + 4 + 8 = 13$）。
6. **`True`**：代表該顯示器為筆電內建面板（`DISPLAYCONFIG_OUTPUT_TECHNOLOGY_INTERNAL`）。

---

### 2.4 第四層：AMD Radeon 860M 內顯驅動核心登錄檔參數

* **登錄檔路徑**：`HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001`
* **驅動對應 INF**：`C:\WINDOWS\System32\DriverStore\FileRepository\u0203304.inf_amd64_a6e5a337568ce3f0\u0203304.inf`（區段：`[ati2mtag_Krackan]`）

| 機碼名稱 | 型態 | 所有可能值與定義 | 清理前數值 | 清理後數值 | 底層硬體機制與死碼解析 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`Dal_UserVariBrightLevel`**<br>**`PP_UserVariBrightLevel`** | `REG_DWORD` | • **`0`**：最高畫質 / 關閉補償<br>• **`1`**：偏重畫質 (微幅省電)<br>• **`2`**：平衡 (Balanced)<br>• **`3`**：偏重省電 (預設值)<br>• **`4`**：最大化電池續航 | **`3`** | **`0`** | 控制 AMD DCN 引擎的 ABM（Adaptive Backlight Management，即 Vari-Bright）強度。雖本機 VBIOS 回報 `VariBrightSupported = 0`，但將殘留的 `3` 歸零可防止任何核心分支誤判觸發背光壓降。 |
| **`PP_VariBrightFeatureEnable`** | `REG_DWORD` | • **`0`**：停用 Vari-Bright 功能<br>• **`1`**：啟用 Vari-Bright 功能 | 未明確鎖定 | **`0`** | 在 PowerPlay 電源管理模組中明確鎖死關閉 Vari-Bright。 |
| **`mobile_runtime_component_NA`** | `REG_SZ` | • **`"true"`**：不提供 (隱藏 UI)<br>• **`"false"`**：提供 (顯示 UI) | `"true"` | `"true"` | 華碩在 `u0203304.inf` 第 13831 行寫死為 `"true"`，這就是為何 **AMD Software: Adrenalin Edition 介面裡沒有出現 Vari-Bright 選項**。 |
| **`AutoColorDepthReduction_NA`** | `REG_DWORD` | • **`0`**：停用自動降色深<br>• **`1`**：啟用自動降色深 | **`1`** | **`0`** | 控制 eDP 頻寬或省電狀態下是否自動壓低色彩位深與抖動精度。已改為 `0` 確保最佳色階表現。 |
| **`DAL3_DATA\power_v1\`**<br>**`SPRSACDCUserEnable`** | `REG_BINARY` | • **`00`**：停用 AC/DC 面板省電連動<br>• **`01`**：啟用連動 | **`01`** | **`00`** | Strix Point / Krackan Point 架構下的電源轉換省電開關，改為 `00` 防止切換電源時干預面板狀態。 |
| **`KMD_EnableBrightnessInterface2`** | `REG_DWORD` | • **`0`**：舊版 101 階 ACPI 亮度<br>• **`1`**：WDDM v2/v3 高精度 Millinits 亮度 | `1` | `1` (保持) | 讓 Windows 使用千分之一尼特（Millinits）與人眼對數感知曲線平滑調整背光，保持 `1` 最佳。 |
| **`DalMinBrightnessMillinits`** | `REG_DWORD` | 單位：毫尼特 ($10^{-3}\text{ nits}$)<br>常見範圍：`1000` (1 nit) ～ `10000` (10 nits) | `5000` | `5000` (保持) | 定義 Windows 亮度滑桿拉到 **0%** 時的最低保底物理亮度（`5000` = **5.0 nits**），防止 0% 時背光全滅黑屏。 |
| **`DalFeatureEnablePsrSU`** | `REG_DWORD` | • **`0`**：停用 PSR-SU<br>• **`1`**：啟用 PSR-SU | `0` | `0` (保持) | 面板選擇性自刷新（Panel Self Refresh - Selective Update）。保持 `0` 可避免 165Hz 下游標移動時的微閃爍或延遲。 |
| **`DalDisableReplayInAC`** | `REG_DWORD` | • **`0`**：插電時允許 Panel Replay<br>• **`1`**：插電時強制停用<br>• **`2`**：插電時依條件停用 | `2` | `2` (保持) | 控制 eDP Panel Replay 自刷新行為，保持 `2` 確保插電高刷時的絕對穩定。 |

---

### 2.5 第五層：Windows 11 顯示子系統、電源管理與背景服務

#### (A) Windows 顯示電源計畫隱藏參數（`SUB_VIDEO`：`7516b95f-f776-4464-8c53-06167f40cc99`）
可透過 `powercfg /qh SCHEME_CURRENT SUB_VIDEO` 檢視：

| 設定 GUID 與別名 | 名稱 | 所有可能值 | 清理前數值 | 清理後數值 | 作用說明 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`684c3e69-a4f7-4014-8754-d45179a56167`**<br>(`ADVANCEDCOLORQUALITYBIAS`) | 進階色彩品質偏向 | • **`0`**：偏向省電<br>• **`1`**：偏向視覺畫質 | AC: `1`<br>**DC: `0`** | **AC: `1`**<br>**DC: `1`** | 控制使用電池時是否允許 Windows DWM 為省電而降低色彩與亮度精度。已將電池模式也改為 **`1`（永遠畫質優先）**。 |
| **`fbd9aa66-9553-4097-ba44-ed6e9d65eab8`**<br>(`ADAPTBRIGHT`) | 啟用自動調整亮度 | • **`0`**：關閉<br>• **`1`**：開啟 | AC: `0`<br>DC: `0` | AC: `0`<br>DC: `0` | 環境光感測器自動亮度開關（本機無環境光感測器，固定為 `0`）。 |
| **`aded5e82-b909-4619-9949-f5d71dac0bcb`**<br>(`VIDEONORMALLEVEL`) | 顯示器亮度 | `0` ～ `100` (%) | `100%` (0x64) | 依使用者滑桿 | 電源計畫記錄的基準亮度百分比。 |

#### (B) Windows 顯示器資料儲存區（`MonitorDataStore`）与 DPI 縮放
* **MonitorDataStore 路徑**：`HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\MonitorDataStore\TMA20710_22_07E8_EB`
  * 內部僅有 `AutoColorManagementSupported = 1`，**無 `CabcSupported` 與 `CabcOption`**（這就是為何 Windows 11「系統 ➔ 顯示器 ➔ 亮度」中沒有「根據內容變更亮度」選單，因為面板硬體本身沒有 CABC）。
* **DPI 縮放路徑**：`HKCU\Control Panel\Desktop\PerMonitorSettings\TMA20710_22_07E8_EB...`
  * **`DpiValue`**：型態為 `REG_DWORD`（有號 32 位元整數，代表相對於 Windows 推薦縮放比例 `200%` 的階數偏移）：
    * `0` (`0x00000000`) = **200%**（Windows 預設推薦，192 DPI）
    * `-1` (`0xFFFFFFFF` / `4294967295`) = **175%**（你目前的設定，168 DPI）
    * `-2` (`0xFFFFFFFE` / `4294967294`) = **150%**（144 DPI）

#### (C) 已徹底停用的 7 個華碩背景服務與 4 個隱藏工作排程

| 類別 | 名稱 | 清理前狀態 | 清理後狀態 | 為何必須停用 |
| :--- | :--- | :--- | :--- | :--- |
| **Windows 服務** | `ASUSOptimization` | `Running` (`Auto`) | **`Stopped` (`Disabled`)** | **頭號衝突源**：在背景常駐 `AsusOptimization.exe` 並隨時呼叫 `AsusSplendid.exe` 覆寫螢幕 LUT 與色溫。 |
| **Windows 服務** | `ArmouryCrateControlInterface` | `Running` (`Auto`) | **`Stopped` (`Disabled`)** | 搶奪熱鍵與性能模式控制權。 |
| **Windows 服務** | `AsusAppService` | `Running` (`Auto`) | **`Stopped` (`Disabled`)** | MyASUS 背景通訊服務，與 G-Helper 重複。 |
| **Windows 服務** | `ASUSSoftwareManager` | `Running` (`Auto`) | **`Stopped` (`Disabled`)** | 在背景輪詢驅動更新與寫入狀態。 |
| **Windows 服務** | `ASUSSwitch` | `Running` (`Auto`) | **`Stopped` (`Disabled`)** | 華碩轉移助理常駐服務。 |
| **Windows 服務** | `ASUSSystemAnalysis` | `Running` (`Auto`) | **`Stopped` (`Disabled`)** | 背景系統硬體分析與遙測收集。 |
| **Windows 服務** | `ASUSSystemDiagnosis` | `Running` (`Auto`) | **`Stopped` (`Disabled`)** | 背景診斷服務。 |
| **工作排程器** | `ASUS Optimization 36D18D69AFC3` | `Ready` (`State 3`) | **`Disabled` (`State 1`)** | 會在關機/登入時偷跑 `AsusHotkey.exe`，繞過服務停用限制。 |
| **工作排程器** | `ASUS Update Checker 2.0` | `Ready` (`State 3`) | **`Disabled` (`State 1`)** | 背景更新檢查器。 |
| **工作排程器** | `AsusSystemAnalysis_754F3273...` | `Ready` (`State 3`) | **`Disabled` (`State 1`)** | 定時喚醒 `AsusSystemAnalysis.exe`。 |
| **工作排程器** | `AsusSystemDiagnosis_DriverQuality` | `Ready` (`State 3`) | **`Disabled` (`State 1`)** | 定時收集驅動遙測。 |

*(註：觸控板服務 `AsusPTPService` 與輸入法服務 `AsusIMESystemService` 屬於正常輸入硬體所需，予以保留。)*

---

## 三、未來重灌電腦避免再次發生的標準防呆 SOP

為什麼你明明沒有主動去開那些死碼，重灌或日常使用後卻會自己跑出來？
因為當新灌好 Windows 11 連上網時，**Windows Update 會自動下載並安裝 `ASUS System Control Interface v3` (`asussci2.inf`) 與 `FA401KM_ICMConfig`**，這兩個驅動套件在安裝瞬間就會自動建立上述 7 個服務、4 個排程任務，並把那顆只有 `284.14 nits` 的 `.icm` 校色檔塞進 `C:\ProgramData\ASUS\GameVisual`！

### 3.1 重灌後的黃金四步防呆準則

1. **絕對不要安裝 Armoury Crate 與 MyASUS**
   * 重灌前可先進 BIOS（開機按 `F2` ➔ `Advanced` ➔ `Armoury Crate Control Interface Support`）將其設為 **`Disabled`**，從主機板源頭阻止 Windows 自動塞入 Armoury Crate 服務。
   * 系統裝好後，直接安裝單一執行檔的 **G-Helper** 即可。
2. **一裝好 G-Helper，第一件事就是點「更多 (Extra) ➔ 停止華碩服務 (Stop)」**
   * 務必在 Windows Update 裝完 `ASUS System Control Interface v3` **之後**，進 G-Helper 的「更多 (Extra)」按下最下方的 **「停止 (Stop)」**，確保 `ASUSOptimization` 服務被停用。
3. **永遠不要在 G-Helper 去點「Eyecare (護眼)」或「E-Reading (電子書)」視覺模式**
   * 因為 `AsusSplendid.exe` 有「寫入 `EyeCareLevel` 後切回 Default 不會自動歸零」的底層 Bug，請將 G-Helper 的視覺模式維持不動，或直接執行下方的一鍵清理腳本將其鎖定在 `Disabled (18)`。
4. **執行下方的一鍵底層淨空腳本（花 3 秒鐘徹底拔除 `.icm` 與驅動死碼）**

---

### 3.2 重灌後「一鍵解除亮度封印與死碼淨空」PowerShell 腳本

未來如果重灌電腦，只要以**系統管理員身分開啟 PowerShell**，複製貼上以下這段腳本執行，3 秒鐘就能把所有封印亮度的服務、排程、284 nits 校色檔與 AMD 驅動死碼一次清得乾乾淨淨：

```powershell
# ==============================================================================
# ASUS TUF Gaming A14 (FA401KM) 螢幕亮度解封印與底層死碼一鍵清理腳本
# 請以「系統管理員身分 (Run as Administrator)」於 PowerShell 執行
# ==============================================================================

Write-Host "[1/6] 正在重置 AsusSplendid 護眼模式殘留並切回硬體直出 (Bypass Mode 18)..." -ForegroundColor Cyan
$spExe = Get-ChildItem "C:\WINDOWS\System32\DriverStore\FileRepository\asussci2.inf*\ASUSOptimization\AsusSplendid.exe" -ErrorAction SilentlyContinue | Select-Object -Last 1
if ($spExe) {
    & $spExe.FullName 17 0 0 | Out-Null
    Start-Sleep -Milliseconds 500
    & $spExe.FullName 18 2 | Out-Null
    Start-Sleep -Milliseconds 500
}

Write-Host "[2/6] 正在停止並停用衝突的華碩背景服務與工作排程..." -ForegroundColor Cyan
$asusServices = @(
    "ASUSOptimization", "ArmouryCrateControlInterface", "AsusAppService",
    "ASUSSoftwareManager", "ASUSSwitch", "ASUSSystemAnalysis", "ASUSSystemDiagnosis"
)
foreach ($svc in $asusServices) {
    Get-Service -Name $svc -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue
    Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
}
Get-ScheduledTask | Where-Object { $_.TaskName -match 'ASUS Optimization|ASUS Update Checker|AsusSystemAnalysis|AsusSystemDiagnosis' } | Disable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null

Write-Host "[3/6] 正在隔離壓制亮度的 284 nits GameVisual ICM 校色檔並清理狀態檔..." -ForegroundColor Cyan
$gvDir = "C:\ProgramData\ASUS\GameVisual"
if (Test-Path $gvDir) {
    $bakDir = Join-Path $gvDir "_disabled_backup"
    New-Item -ItemType Directory -Path $bakDir -Force | Out-Null
    Remove-Item "$gvDir\Asus_Monochrome.icm" -Force -ErrorAction SilentlyContinue
    Get-ChildItem "$gvDir\FA401KM_*.icm" -ErrorAction SilentlyContinue | ForEach-Object {
        Move-Item $_.FullName -Destination (Join-Path $bakDir $_.Name) -Force
    }
}
foreach ($spFile in @(
    "C:\ProgramData\ASUS\ASUS System Control Interface\ASUSOptimization\Splendid\YUser_my_sp_data.sys",
    "C:\ProgramData\ASUS\ASUS System Control Interface\log\HardwareSettings_Splendid_C"
)) {
    if (Test-Path $spFile) {
        $c = Get-Content $spFile -Raw
        $c = $c -replace 'EyeCareLevel=\d+', 'EyeCareLevel=0'
        $c = $c -replace 'BWEnable=\d+', 'BWEnable=0'
        $c = $c -replace 'BWContrast=\d+', 'BWContrast=0'
        $c = $c -replace 'ICMExist=YES', 'ICMExist=NO'
        $c = $c -replace 'ICMEXIST2=YES', 'ICMEXIST2=NO'
        $c = $c -replace 'Mode=\d+', 'Mode=18'
        Set-Content $spFile -Value $c -NoNewline -Encoding ASCII
    }
}

Write-Host "[4/6] 正在清除 AMD 內顯驅動登錄檔中的 Vari-Bright 與降色深死碼..." -ForegroundColor Cyan
$displayClass = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
Get-ChildItem $displayClass -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object {
    $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
    if ($p.DriverDesc -match 'AMD|Radeon') {
        Set-ItemProperty -Path $_.PSPath -Name "Dal_UserVariBrightLevel" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $_.PSPath -Name "PP_UserVariBrightLevel" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $_.PSPath -Name "PP_VariBrightFeatureEnable" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $_.PSPath -Name "AutoColorDepthReduction_NA" -Value 0 -Type DWord -Force
        $pwrKey = Join-Path $_.PSPath "DAL3_DATA\power_v1"
        if (Test-Path $pwrKey) {
            Set-ItemProperty -Path $pwrKey -Name "SPRSACDCUserEnable" -Value ([byte[]](0)) -Type Binary -Force
        }
    }
}

Write-Host "[5/6] 正在設定 Windows 電源計畫進階色彩品質為永遠畫質優先..." -ForegroundColor Cyan
powercfg /setacvalueindex SCHEME_CURRENT 7516b95f-f776-4464-8c53-06167f40cc99 684c3e69-a4f7-4014-8754-d45179a56167 1
powercfg /setdcvalueindex SCHEME_CURRENT 7516b95f-f776-4464-8c53-06167f40cc99 684c3e69-a4f7-4014-8754-d45179a56167 1
powercfg /setactive SCHEME_CURRENT

Write-Host "[6/6] 正在更新 G-Helper config.json (關閉 optimal_brightness 並鎖定直出模式)..." -ForegroundColor Cyan
$ghCfgPath = "$env:APPDATA\GHelper\config.json"
if (Test-Path $ghCfgPath) {
    $ghTask = Get-ScheduledTask -TaskName "GHelper*" -ErrorAction SilentlyContinue
    if ($ghTask) { Stop-ScheduledTask -TaskName $ghTask.TaskName -ErrorAction SilentlyContinue; Start-Sleep -Seconds 1 }
    $cfg = Get-Content $ghCfgPath -Raw | ConvertFrom-Json
    $cfg | Add-Member -NotePropertyName "optimal_brightness" -NotePropertyValue 0 -Force
    $cfg | Add-Member -NotePropertyName "visual" -NotePropertyValue 18 -Force
    $cfg | Add-Member -NotePropertyName "services_disabled" -NotePropertyValue 1 -Force
    $cfg | ConvertTo-Json -Depth 4 | Set-Content $ghCfgPath -Encoding UTF8
    if ($ghTask) { Start-ScheduledTask -TaskName $ghTask.TaskName -ErrorAction SilentlyContinue }
}

Write-Host "完成！所有限制螢幕亮度的底層死碼與衝突服務已全數清除。" -ForegroundColor Green
```
