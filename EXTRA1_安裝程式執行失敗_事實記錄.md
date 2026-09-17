# 蒼の彼方のフォリズム EXTRA1 光碟安裝程式執行失敗 — 事實記錄

本文件僅記錄**可直接量測／觀測**之事實與原始輸出數值，以及各項數值的取得方式。
內容不含推論、不含因果結論、不含建議。

- 報告產出時間：2026-09-17 22:31:52（本地時間）
- 本次系統開機時間：2026-09-17 20:55:38（本地時間，由 `GetTickCount64()` 反推）
- 使用者帳戶：`DESKTOP-CAI6DP5\YUser`

---

## 1. 系統環境量測

| 項目 | 量測值 | 取得方式 |
|---|---|---|
| ProductName / DisplayVersion | `Windows 10 IoT Enterprise` / `26H2` | `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion` |
| CurrentBuild / UBR | `26300` / `9457` | 同上 |
| EditionID | `IoTEnterprise` | 同上 |
| `GetACP()`（系統 ANSI 代碼頁） | 起初 `950`；2026-09-17 使用者變更系統 locale 並重新開機後 `932` | `kernel32!GetACP` |
| `GetOEMCP()` | `932`（變更後） | `kernel32!GetOEMCP` |
| `GetSystemDefaultLangID()` | `0x0411`（ja-JP，變更後） | `kernel32!GetSystemDefaultLangID` |
| `GetUserDefaultLCID()` | `0x0404`（zh-TW） | `kernel32!GetUserDefaultLCID` |
| 邏輯磁碟 | `C:` NTFS(DriveType 3)、`D:` NTFS(3)、`F:` UDF(5, 標籤 `SPR003ADV2`) | `Win32_LogicalDisk` |
| 光碟機裝置類型 | `Microsoft 虛擬 DVD-ROM` | `Win32_CDROMDrive` |
| UAC | `EnableLUA=1`、`ConsentPromptBehaviorAdmin=0`、`PromptOnSecureDesktop=0`、`EnableInstallerDetection=1` | `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System` |
| Defender | `RealTimeProtectionEnabled=False`、`AntivirusEnabled=False`、`AMRunningMode=Not running`、`IsTamperProtected=False` | `Get-MpComputerStatus` / `Get-MpPreference` |
| Smart App Control | `VerifiedAndReputablePolicyState=2`、`SAC_PreviousState=4294967295`、`EmodePolicyRequired=0`、`SkuPolicyRequired=0` | `HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy` |
| WDAC 作用中政策檔 | 8 個 `.cip`（含 `{1283AC0F-FFF1-49AE-ADA1-8A933130CAD6}.cip` 79907 B、`{784C4414-79F4-4C32-A6A5-F0FB42A51D0D}.cip` 196506 B 等） | `C:\Windows\System32\CodeIntegrity\CiPolicies\Active` |
| CodeIntegrity/Operational 記錄 | 該次查詢（最近 3 日、`-MaxEvents 30`）僅見政策啟用事件（Id 3084/3099/3116），無阻擋事件 | `Get-WinEvent` |
| AppLocker | `HKLM\SOFTWARE\Policies\Microsoft\Windows\SrpV2` 不存在 | 登錄檔查詢 |
| IFEO（Setup.exe / LEProc / aokana） | 無項目 | `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options` |
| 相容性旗標（Layers）原有項目 | `C:\Program Files (x86)\AMD\Chipset_Software\QT_Dependencies\Setup.exe : ~ WIN8RTM WIN7RTM`、`...\K-Lite Codec Pack\MPC-HC64\mpc-hc64.exe : (空)`、HKLM：`OneDrive.exe : ~ PERPROCESSSYSTEMDPIFORCEOFF` | `HKCU/HKLM\...\AppCompatFlags\Layers` |
| SmartScreen 記錄 | 查詢 `Microsoft-Windows-SmartScreen/Debug` 無結果 | `Get-WinEvent` |
| `NoDriveTypeAutoRun` | `145` (0x91) | `HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer` |
| 掛載留存性 | 重新開機後 `F:\Setup.exe` 不存在；`Get-CimInstance Win32_LogicalDisk` 僅回 C:、D: | 重開機後量測 |

---

## 2. 標的檔案（雜湊與 PE 屬性）

### 2.1 4th Anniversary Box Disc-2 光碟（現掛載於 `F:`，標籤 `SPR003ADV2`）

| 路徑 | 大小 (bytes) | MD5 |
|---|---|---|
| `F:\Setup.exe` | 211,456 | `2cf01977cd596bd397bde447065dc5d0` |
| `F:\蒼の彼方のフォリズムEXTRA1_4BOX\Setup.exe` | 211,456 | `2cf01977cd596bd397bde447065dc5d0` |
| `F:\蒼の彼方のフォリズムEXTRA1_4BOX\BGIForInstalling.exe` | 1,346,048 | `63caf9f27647d5839e3289f7d613b9a9` |

- `F:\AutoRun.inf`（45 bytes，以 CP932 解讀）：
  ```
  [AutoRun]
  OPEN=Setup.exe
  ICON=Setup.exe,0
  ```

### 2.2 EXTRA1 STANDARD EDITION 光碟（`SPR002EX1.ISO`，量測當時掛載於 `E:`／`F:`）

| 路徑 | 大小 (bytes) | MD5 |
|---|---|---|
| `E:\Setup.exe` | 211,456 | `2cf01977cd596bd397bde447065dc5d0` |
| `E:\蒼の彼方のフォリズムEXTRA1\Setup.exe` | 211,456 | `2cf01977cd596bd397bde447065dc5d0` |
| `E:\蒼の彼方のフォリズムEXTRA1\BGIForInstalling.exe` | 1,346,048 | 當次量測值前 12 碼 `63caf9f27647` |

- `E:\Autorun.inf`（103 bytes，以 CP932 解讀）：
  ```
  [Autorun]
  open=蒼の彼方のフォリズムEXTRA1\Setup.exe
  ICON=蒼の彼方のフォリズムEXTRA1\Setup.exe,0
  ```

### 2.3 `Setup.exe` 的 PE 量測（對 `F:\Setup.exe` 與 `E:\Setup.exe` 量測，兩者位元組相同）

| 項目 | 值 |
|---|---|
| Machine | `0x14c`（i386 / PE32） |
| Subsystem | `2`（Windows GUI） |
| ImageBase | `0x400000` |
| 節區 | `.text` / `.rdata` / `.data` / `.rsrc` / `.reloc` |
| Data Directories 有值者 | Import(rva 0xd834, 60)、Resource(0x11000, 148144)、Reloc(0x36000, 2472)、LoadCfg(0xd1e8, 64)、IAT(0xb000, 320) |
| Security 目錄（Authenticode） | size = `0`（無簽章） |
| 匯入 DLL | 僅 `KERNEL32.dll` 與 `USER32.dll`（USER32 僅 `WaitForInputIdle`） |
| KERNEL32 匯入（節錄） | `GetModuleFileNameA`、`FindFirstFileA`、`FindNextFileA`、`FindClose`、`GetFileAttributesA`、`SetFileAttributesA`、`CopyFileA`、`GetTempPathA`、`MoveFileExA`、`RemoveDirectoryA`、`DeleteFileA`、`CreateProcessA`、`WaitForSingleObject`、`CreateFileW`、`GetVersionExA`、`GetCommandLineA`、`TerminateProcess`、`Sleep`、`GetTickCount`、`WriteFile`、`GetStdHandle` |
| Manifest（RT_MANIFEST） | `requestedExecutionLevel level="requireAdministrator" uiAccess="false"`；`dpiAware True/PM`；`supportedOS` 含 `{e2011457-...}`、`{35138b9a-...}`、`{4a2f28e3-...}`、`{1f676c76-...}`、`{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}` |
| 版本資源 | `CompanyName`=`BURIKO Co.,Ltd.`；`FileDescription`=`Installer for BURIKO General Interpreter`；`FileVersion`=`1.0`；`LegalCopyright`=`Copyright (C) 2007-2017 BURIKO Co.,Ltd.`；`OriginalFilename`=`Setup.exe`；`ProductVersion`=`1.0.0.1` |
| PE TimeDateStamp | `1494912422`（2017-05-16 UTC） |
| 資源內容 | `RT_ICON`(3): 4 個、`RT_GROUP_ICON`(14): 1 個、`RT_VERSION`(16)、`RT_MANIFEST`(24, lang 1033)。無 `RT_DIALOG`、無 `RT_STRING` |

### 2.4 安裝引擎 `BGIForInstalling.exe`（兩個版本）

| 來源 | 路徑 | 大小 (bytes) | MD5 |
|---|---|---|---|
| 本體光碟切片（解出之 `SPR002` 目錄） | `C:\Users\YUser\Downloads\[141128][sprite] 蒼の彼方のフォリズム 初回限定特装版 (mdf+mds+rr3)\[141128][sprite] 蒼の彼方のフォリズム 初回限定特装版 (mdf+mds+rr3).part1\SPR002\蒼の彼方のフォリズム\BGIForInstalling.exe` | 1,229,312 | `e79e2ca3bccefe42562773b3d209f093` |
| 4BOX Disc-2 光碟 | `F:\蒼の彼方のフォリズムEXTRA1_4BOX\BGIForInstalling.exe` | 1,346,048 | `63caf9f27647d5839e3289f7d613b9a9` |
| EXTRA1 STANDARD EDITION 光碟 | `E:\蒼の彼方のフォリズムEXTRA1\BGIForInstalling.exe`（量測當時） | 1,346,048 | 前 12 碼 `63caf9f27647`（同次量測） |

其他同目錄檔案（量測值）：

| 檔案 | SPR002 片 | EXTRA1(2017) 片子目錄 | 4BOX 片子目錄 |
|---|---|---|---|
| `Setup.exe` | 203,776（MD5 `4ac382dde888298da907b45aae88e536`） | 211,456 | 211,456 |
| `installer.arc` | 1,200,995（MD5 `cfa2ce286f32a9c6f17653735eeba708`） | 1,106,152 | 1,248,129 |
| `BGI.hvl` | 2,192 | 1,872 | 7,696 |
| `BGI.itl` | — | 696 | 703 |
| `BHVC.exe` | 45,056 | 45,056 | 61,440 |
| `UnInstaller.exe` | 1,848,320 | 1,858,560 | 1,880,064 |
| `system.arc` | 34,346,138 | 33,553,139 | 32,364,223 |
| 16-byte 標記檔 | `AoNoKanataNoFourRhythm` = `30313233343536373839414243444546`（ASCII `0123456789ABCDEF`） | `AoNoKanataNoFourRhythmEX1` = `0123456789ABCDEF`（同 bytes） | `AoNoKanataNoFourRhythmEX1` = 16 bytes |

---

## 3. 光碟映像檔（磁碟上）

| 映像 | 大小 (bytes) | 路徑 |
|---|---|---|
| `SPR002EX1.ISO` | 4,454,494,208 | `C:\Users\YUser\Downloads\[170630][sprite] 蒼の彼方のフォリズム EXTRA1 STANDARD EDITION (iso+mds+rr3)\SPR002EX1.ISO` |
| `SPR003ADV1.ISO` | 7,027,064,832 | `C:\Users\YUser\Downloads\[181130][sprite] 蒼の彼方のフォリズム 4th Anniversary Box (iso+mds+rr3)\[181130][sprite] 蒼の彼方のフォリズム 4th Anniversary Box Disc-1 「蒼の彼方のフォリズム Perfect Edition」 (iso+mds+rr3)\SPR003ADV1.ISO` |
| `SPR003ADV2.ISO` | 3,246,829,568 | `C:\Users\YUser\Downloads\[181130][sprite] 蒼の彼方のフォリズム 4th Anniversary Box (iso+mds+rr3)\[181130][sprite] 蒼の彼方のフォリズム 4th Anniversary Box Disc-2 「蒼の彼方のフォリズム EXTRA1」 (iso+mds+rr3)\SPR003ADV2.ISO` |

### 3.1 `F:\蒼の彼方のフォリズムEXTRA1_4BOX` 完整內容（36 檔，合計 3,245,942,664 bytes）

```
AoNoKanataNoFourRhythmEX1          16
BGI.hvl                         7,696
BGI.itl                           703
BGIForInstalling.exe        1,346,048
BHVC.exe                       61,440
Setup.exe                     211,456
UnInstaller.exe             1,880,064
data01000.arc                  29,242
data01100.arc                 394,933
data02000.arc              76,235,190
data02010.arc             162,136,770
data02020.arc             100,842,874
data02030.arc               2,585,423
data02040.arc              61,411,315
data02041.arc               1,632,148
data02042.arc              24,719,335
data02090.arc               2,890,915
data02100.arc              39,708,337
data02101.arc              49,085,072
data02110.arc              14,435,726
data02700.arc             532,525,336
data02800.arc           1,499,306,936
data02900.arc               2,616,816
data02901.arc              20,930,750
data02902.arc              40,029,980
data02903.arc                  91,088
data02904.arc               1,174,874
data03000.arc               7,806,936
data04000.arc             317,604,824
data04999.arc               1,483,075
data05000.arc             229,928,847
data05001.arc               6,284,675
installer.arc               1,248,129
sysgrp.arc                 11,267,760
sysprg.arc                    348,384
system.arc                 32,364,223
蒼の彼方のフォリズムEXTRA1_4BOX.exe  1,315,328
```

### 3.2 2017 片（`E:\` 當時量測）

- 根目錄：`AOKANAINIT.FL` 1,701,344,808 / `Autorun.inf` 103 / `Setup.exe` 211,456 / 目錄 `蒼の彼方のフォリズムEXTRA1`
- `蒼の彼方のフォリズムEXTRA1\` 內 36 檔 + 子目錄 `DirectX9`；`DirectX9\` 內 9 檔（`BDA.cab`、`BDANT.cab`、`BDAXP.cab`、`DirectX.cab`、`DSETUP.dll`、`dsetup32.dll`、`dxnt.cab`、`dxsetup.exe`、`ManagedDX.CAB`）。以上為該片掛載於 `E:` 期間以 `dir /s /b` 量測
- 該片檔案大小（節錄，用於第 7 節比對）：`data01000.arc` 29,242、`data01100.arc` 394,933、`data02000.arc` 76,235,190、`data02010.arc` 162,136,770、`data02020.arc` 100,842,874、`data02030.arc` 2,585,423、`data02040.arc` 61,411,315、`data02041.arc` 1,632,148、`data02042.arc` 24,719,335、`data02090.arc` 2,890,915、`data02100.arc` 39,708,337、`data02101.arc` 49,085,072、`data02110.arc` 14,435,726、`data02800.arc` 1,499,306,936、`data02900.arc` 2,616,816、`data02901.arc` 20,930,750、`data02902.arc` 40,029,980、`data02903.arc` 91,088、`data02904.arc` 1,174,874、`data03000.arc` 7,806,936、`data04000.arc` 317,604,824、`data04999.arc` 1,483,075、`data05000.arc` 229,928,847、`data05001.arc` 6,284,675、`sysgrp.arc` 11,267,760、`sysprg.arc` 348,384、`system.arc` 33,553,139、`BGI.hvl` 1,872、`BGI.itl` 696、`BHVC.exe` 45,056、`installer.arc` 1,106,152、`UnInstaller.exe` 1,858,560、`蒼の彼方のフォリズムEXTRA1.exe` 1,315,328
- 該片無 `data02700.arc`

---

## 4. 執行行為量測（時間、exit code、產物）

### 4.1 直接執行 stub（ACP=950 期間）

| 執行動作 | 量測結果 |
|---|---|
| `ShellExecuteExW`（default verb，等同雙擊）開啟 `F:\Setup.exe` | 行程建立；**0.057 秒**後結束；**exit code 0**；`%TEMP%` 未出現 `bgi*.exe`；未觀察到子行程；無可見視窗；Application 事件記錄中無 `Setup.exe` 相關錯誤事件 |
| 同一動作開啟 `F:\蒼の彼方のフォリズムEXTRA1\Setup.exe`（4BOX 片子目錄，位元組相同） | 0.0569 秒結束；exit code 0；`%TEMP%` 未出現 `bgi*.exe` |

### 4.2 A/B/C 重現（使用同一顆 211,456 bytes stub，置於自建目錄）

| 實驗 | 資料夾名 | 結果 |
|---|---|---|
| A | `蒼の彼方のフォリズムEXTRA1`（含 U+30FC 等假名，建立於 NTFS） | 0.572 秒結束；exit code 0；`%TEMP%` 未出現 `bgi*.exe` |
| B | `AOKANA_EXTRA1`（純 ASCII） | `%TEMP%\bgi00000.exe` 出現 |
| C | `蒼彼方EXTRA1`（漢字、無假名） | `%TEMP%\bgi00000.exe` 出現 |

A/C 之資料夾名在**建立後**以 `WideCharToMultiByte(950, 0, name, -1, buf, 0x400, "?", NULL)` 量測之轉換結果：

```
'蒼の彼方のフォリズムEXTRA1'  ->  '蒼?彼方??????EXTRA1'      (MANGLED)
'蒼彼方EXTRA1'              ->  '蒼彼方EXTRA1'             (OK)
'AOKANA_EXTRA1'             ->  'AOKANA_EXTRA1'           (OK)
```

以同一方法量測 stub 自身路徑（光碟上）：

```
輸入：F:\蒼の彼方のフォリズムEXTRA1\Setup.exe
輸出：F:\蒼?彼方???????EXTRA1\Setup.exe
GetFileAttributesA(上述輸出 + "\BGIForInstalling.exe")  =  -1
os.path.exists(原路徑檔案) = True，大小 1,346,048
```

`GetACP()` = 950 期間，對 registry 以 ANSI API 量測：

```
RegOpenKeyExA(HKLM, "SOFTWARE\WOW6432Node\sprite\蒼の彼方のフォリズム"(以 CP950 轉換), ...)
  -> rc = 2（ERROR_FILE_NOT_FOUND）
RegOpenKeyExW(同一字串，未轉換) -> rc = 0（存在）
```

### 4.3 系統 locale 變更為 ja-JP 後（`GetACP()`=932）

| 量測 | 結果 |
|---|---|
| `GetFileAttributesA("F:\蒼の彼方のフォリズムEXTRA1\BGIForInstalling.exe".encode('cp932'))` | `33` (0x21 = FILE_ATTRIBUTE_READONLY \| FILE_ATTRIBUTE_ARCHIVE) |
| `RegOpenKeyExA` 同上 registry 路徑 | `rc = 0` |
| `ShellExecuteExW` 開啟 `E:\Setup.exe`（2017 片，當時掛載） | +0.29 秒 `bgi00000.exe` 行程出現；`%TEMP%\bgi00000.exe` 出現；stub 於 +3.23 秒 exit code 0 |

### 4.4 1,346,048 bytes 引擎的條件矩陣（皆以「是否建立可見視窗／存活時間」量測）

| 變因 | 設定 | 結果 |
|---|---|---|
| 由 stub 啟動 | cwd=`%TEMP%`，argv[1]=光碟子目錄 | 1.09 秒結束；exit code 0 |
| 無參數 | cwd=來源目錄 | 1.10 秒；exit 0 |
| 僅 argv[1] | cwd=來源目錄 | 1.10 秒；exit 0 |
| argv[1] + `"Execute as a launcher."` | cwd=來源目錄 | 1.10 秒；exit 0 |
| 提權／非提權 | `ShellExecuteEx`（提權）與 `CreateProcess` + 環境變數 `__COMPAT_LAYER=RunAsInvoker`（非提權） | 兩種皆 1.10 秒；exit 0 |
| 相容性模式 | `HKCU\...\AppCompatFlags\Layers` 設為 `~ WIN7RTM`、`~ WIN8RTM` | 兩者皆 1.10 秒；exit 0 |
| 使用者 locale | `HKCU\Control Panel\International\Locale` = `00000411`（`GetUserDefaultLCID()` 隨即在同行程回報 `0x0411`） | 1.09 秒；exit 0 |
| 來源置於本機磁碟 | `%TEMP%\aokana_test` 迷你鏡像（112.4 MiB，含 `installer.arc`、`BGI.hvl`、`BGI.itl`、`BHVC.exe`、`BGIForInstalling.exe` 等；缺 `AOKANAINIT.FL` 與 13 個大檔） | stub 於 +0.20 秒產生 `%TEMP%\bgi00000.exe`；該行程結束後檔案消失 |

### 4.5 上述矩陣中，1,229,312 bytes 引擎（同一顆 stub、同一來源目錄、同一 cwd）之量測

| 執行 | 觀測序列 |
|---|---|
| 2017 片來源目錄 | +1.10 秒 建立視窗（class `BGI - Main window`、標題 `Buriko General Interpreter in Launcher mode`、尺寸 461×369、不可見）→ +1.34 秒 轉為可見 → +2.32 秒 出現 `GDI+ Window (bgi00055.exe)` → +2.69 秒 標題變為 `蒼の彼方のフォリズム EXTRA1` → 持續執行 >15 秒 |
| 4BOX 片來源目錄 | +1.10 秒 建立視窗（`Buriko General Interpreter in Launcher mode`）→ +1.22 秒 轉為可見 → +2.20 秒 出現 `GDI+ Window (bgi00066.exe)` → +2.69 秒 標題變為 `蒼の彼方のフォリズム EXTRA1` → 2026-09-17 22:31 量測時行程仍在執行（pid 30724），可見視窗標題 `蒼の彼方のフォリズム EXTRA1` |

### 4.6 對照組：已安裝本體遊戲（同引擎家族）

`C:\Users\YUser\Documents\sprite\蒼の彼方のフォリズム\蒼の彼方のフォリズム.exe`（1,200,128 bytes）執行量測：

| 時間 | 觀測 |
|---|---|
| +1.07 秒 | 可見視窗 class `BGI - Main window`、標題 `Ethornell - BURIKO General Interpreter ( Version : 1.602 - Compatibility : 1.72 )`（461×369） |
| +2.44 秒 | 出現 `GDI+ Window (蒼の彼方のフォリズム.exe)` |
| +2.89 秒 | 出現 `#32770`（標題空、不可見、357×139） |
| +3.04 秒 | `#32770` 標題變為 `蒼の彼方のフォリズム`、轉為可見 |
| +12 秒 | 行程仍存活（量測後由本次作業以 `TerminateProcess` 結束） |

---

## 5. `Setup.exe` 之靜態反組譯結果

工具：`capstone` 5.0.7（x86 32-bit）、`pefile`；範圍 `.text`（VA 0x401000 起，39,543 bytes）。

觀測到的字串常數（節錄）：

```
bgi%.5d.exe
BGIForInstalling.exe
%s\%s
%s\*
%s "%s" "%s"
Execute as a launcher.
```

觀測到的 API 呼叫與邏輯序列（VA 位址為量測值）：

1. `sub_4012c0`：`GetModuleFileNameA(NULL, buf, 0x30c)`（0x4013ad）取得自身路徑 → 呼叫 `sub_401790`（路徑分割：複製字串至 offset 0 與 0x30c 兩份緩衝，於最後一個 `\` 處截斷，並記錄檔名指標與索引）
2. 先以 `"%s\%s"`（0x40d1a4）組合 `自身目錄\BGIForInstalling.exe` 作為候選
3. 迴圈（0x4013f0）：對候選呼叫 `sub_401000`；若回傳 0 則 `FindFirstFileA("%s\*")`（0x40d1ac）列舉自身目錄，跳過 `.`（0x40d1b4）與 `..`（0x40d1b8），對每個具 `FILE_ATTRIBUTE_DIRECTORY`(0x10) 的項目以 `"%s\%s\%s"` 組成 `目錄\項目\BGIForInstalling.exe` 再試
4. `sub_401000`：`GetFileAttributesA`（0x40102b）檢查候選；`== -1` 時回傳 0；具 `0x10`（目錄）時回傳 0；否則 `GetTempPathA(0x30c, ...)`（0x40106c）+ `sprintf("bgi%.5d.exe")`（0x401073/0x401084）→ 呼叫 `sub_4015b0(路徑, 0x60003)` → `CopyFileA(src, dst, FALSE)`（0x4010e0）；失敗則遞增計數重試，上限 `0x186a0`（100,000）
5. `sub_401130`：組出命令列 `sprintf("%s \"%s\" \"%s\"", 複本路徑, 來源目錄, "Execute as a launcher.")`（0x4011d3/0x4011e4）→ `CreateProcessA(NULL, cmdline, ..., lpCurrentDirectory=複本所在目錄)`（0x401215）→ `Sleep(1)`、`WaitForInputIdle(h, -1)`（USER32，0x401232）、`WaitForSingleObject(h, -1)`（0x401241）→ `CloseHandle` → 以 `sub_4015b0` 刪除複本（最多 100 次 × `Sleep(10)`）
6. `sub_4015b0` 內部使用 `SetFileAttributesA`、`FindFirstFileA/FindNextFileA`、`RemoveDirectoryA`、`DeleteFileA`、`MoveFileExA`（`sub_401740`，旗標 4）；`sub_401740` 先呼叫 `sub_401840`（`GetVersionExA` + 比較 `dwPlatformId == 2`）

---

## 6. Procmon 追蹤記錄

- 工具：`Procmon64.exe`（可攜），下載自 `https://live.sysinternals.com/Procmon64.exe`，2,237,208 bytes，SHA256 `fc3af5317c707e0555ad6e7590ad65ceb5c5085b053b41221944ac3ca3492d9c`，`Get-AuthenticodeSignature` 結果 `Valid`，簽署者 `CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US`
- 啟動方式：`/AcceptEula /Quiet /Minimized /BackingFile`，經 `ShellExecuteEx`（`runas`）提權執行；追蹤後以 `/Terminate` 結束並以 `/OpenLog ... /SaveAs ...` 轉出 CSV
- 產生檔案：`t1.pml` 1,121,088,273 bytes、`t1.csv` 194,742,066 bytes（追蹤期間全程 12 秒）
- 追蹤期間執行的動作：`ShellExecuteExW`（default verb）開啟 `E:\Setup.exe`（2017 片）

| 統計 | 值 |
|---|---|
| 事件總數 | 1,045,515 |
| `bgi00000.exe` 事件 | 1,817 |
| `Setup.exe` 事件 | 1,805 |
| 結果分佈 | `SUCCESS` 2726、`NAME NOT FOUND` 338、`REPARSE` 315、`BUFFER OVERFLOW` 85、`FAST IO DISALLOWED` 66、`FILE LOCKED WITH ONLY READERS` 53、`INVALID DEVICE REQUEST` 13、`NO MORE ENTRIES` 13、`BUFFER TOO SMALL` 8、`INVALID PARAMETER` 3（以上為該兩行程事件之統計） |

`bgi00000.exe` 之 Operation 統計（全表）：

```
RegOpenKey 430, RegQueryValue 223, RegCloseKey 210, CreateFile 117,
QuerySecurityFile 110, IRP_MJ_CLOSE 109, CloseFile 104, RegQueryKey 94,
RegSetInfoKey 81, Load Image 54, CreateFileMapping 50,
FASTIO_RELEASE_FOR_SECTION_SYNCHRONIZATION 50, QueryOpen 37, RegEnumValue 28,
QueryBasicInformationFile 27, QueryEAFile 23, FileSystemControl 23,
RegEnumKey 14, QueryNameInformationFile 9, QueryStandardInformationFile 7,
Thread Create 6, Thread Exit 6, Process Profiling 2, Process Start 1,
ReadFile 1, Process Exit 1
```

**在該行程事件中未出現的 Operation 類型**（上表之外）：`DeviceIoControl`、`QueryVolumeInformationFile`、`Process Create`（另一行程）、`TCP/網路` 相關操作。

Process Start 事件之記錄內容：

```
Process Name : bgi00000.exe
Command line : C:\Users\YUser\AppData\Local\Temp\bgi00000.exe "E:\蒼の彼方のフォリズムEXTRA1" "Execute as a launcher."
Current dir. : C:\Users\YUser\AppData\Local\Temp\
```

對來源目錄的存取（完整）：

```
09:35:10.7957732  QueryOpen  FAST IO DISALLOWED  E:\蒼の彼方のフォリズムEXTRA1
09:35:10.7958614  CreateFile SUCCESS  E:\蒼の彼方のフォリズムEXTRA1  (Read Attributes, Open Reparse Point)
09:35:10.7960486  CreateFile SUCCESS  E:\蒼の彼方のフォリズムEXTRA1  (Execute/Traverse, Directory)
09:35:11.8297480  CloseFile  SUCCESS  E:\蒼の彼方のフォリズムEXTRA1
09:35:11.8297644  IRP_MJ_CLOSE SUCCESS E:\蒼の彼方のフォリズムEXTRA1
```

**未觀察到**對下列路徑任何形式的開啟或探查（`CreateFile`／`QueryOpen`／`NAME NOT FOUND`）：`AOKANAINIT.FL`、`installer.arc`、`data*.arc`、`BGI.hvl`、`BGI.itl`、`BHVC.exe`、`蒼の彼方のフォリズムEXTRA1.exe`、以及該目錄內的其他任何檔案。

載入的模組（`Load Image`，節錄）：`bgi00000.exe`、`WINMM.dll`、`DINPUT8.dll`、`d3d9.dll`、`dwmapi.dll`、`WININET.dll`、`DSOUND.dll`、`ResampleDmo.DLL`、`msdmo.dll`、`UMPDC.dll`、`InputHost.dll`、`CoreMessaging.dll`、`CRYPTBASE.DLL`、`bcryptprimitives.dll`、`kernel.appcore.dll`、`uxtheme.dll`、以及 `gdiplus`、`comctl32` 等（共 54 筆 `Load Image`）。

尾端事件序列（時間戳為 Procmon 記錄值）：

```
09:35:11.8013269  Load Image             SUCCESS   C:\Windows\SysWOW64\uxtheme.dll
09:35:11.8127696  Process Profiling      SUCCESS   User Time: 0.8750000 s, Kernel Time: 0.1093750 s,
                                                  Private Bytes: 2,883,584, Working Set: 12,521,472
09:35:11.8131871  RegOpenKey             SUCCESS   HKCU
09:35:11.8133116  RegOpenKey             SUCCESS   HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize
09:35:11.8133817  RegQueryValue          SUCCESS   HKCU\...\Themes\Personalize\AppsUseLightTheme  (REG_DWORD, Data: 0)
09:35:11.8149527  RegOpenKey             REPARSE   HKLM\System\CurrentControlSet\Control\Nls\CustomLocale
09:35:11.8165932  RegQueryValue          NAME NOT FOUND  HKLM\System\CurrentControlSet\Control\Nls\CustomLocale\zh-TW
09:35:11.8194960  RegQueryValue          SUCCESS   HKLM\...\Nls\ExtendedLocale\zh-TW  (REG_SZ, Data: zh-TW)
09:35:11.8208332  CreateFile             SUCCESS   C:\Windows\Globalization\zh-TW.nlx
09:35:11.8211553  Thread Exit            SUCCESS   (Thread ID 27016,15660,6868,21460,14772)
09:35:11.8281646  CreateFile             SUCCESS   C:   (Desired Access: Generic Read/Write,
                                                  Disposition: OpenIf, Options: Synchronous IO Non-Alert,
                                                  Non-Directory File, ShareMode: Read, Write, ...)
09:35:11.8283887  Process Exit           SUCCESS   Exit Status: 0,
                                                  User Time: 0.8906250 s, Kernel Time: 0.1093750 s,
                                                  Private Bytes: 2,850,816, Peak Private Bytes: 2,981,888
09:35:11.8331583  IRP_MJ_CLOSE           SUCCESS   C:\Users\YUser\AppData\Local\Temp\bgi00000.exe
```

追蹤期間該行程未建立任何子行程（其事件中無 `Process Create`；同時段對新行程的輪詢僅觀察到 `Setup.exe` 與 `bgi00000.exe` 兩者）。

---

## 7. 檔案清單比對（光碟 vs 已安裝本體）

比對對象：`E:\蒼の彼方のフォリズムEXTRA1`（當時掛載，36 檔）與 `C:\Users\YUser\Documents\sprite\蒼の彼方のフォリズム`（37 檔）。

- 僅光碟有：`AoNoKanataNoFourRhythmEX1`、`BGI.itl`、`BGIForInstalling.exe`、`Setup.exe`、`UnInstaller.exe`、`data02090.arc`、`data02902.arc`、`data02904.arc`、`installer.arc`、`蒼の彼方のフォリズムEXTRA1.exe`
- 僅本體有：`Uninstaller.exe`、`data02111.arc`、`data02999.arc`、`data04010.arc`、`data04021.arc`、`data04022.arc`、`data04023.arc`、`data04024.arc`、`data04099.arc`、`uninst.lst`、`蒼の彼方のフォリズム.exe`
- 同名但大小不同：

| 檔案 | 本體 (bytes) | 光碟 (bytes) |
|---|---|---|
| `BGI.hvl` | 2,192 | 1,872 |
| `data01000.arc` | 42,691 | 29,242 |
| `data01100.arc` | 2,535,870 | 394,933 |
| `data02000.arc` | 188,057,056 | 76,235,190 |
| `data02010.arc` | 359,013,132 | 162,136,770 |
| `data02020.arc` | 124,062,676 | 100,842,874 |
| `data02030.arc` | 908,889,957 | 2,585,423 |
| `data02040.arc` | 137,101,956 | 61,411,315 |
| `data02041.arc` | 120,661,863 | 1,632,148 |
| `data02042.arc` | 114,966,414 | 24,719,335 |
| `data02100.arc` | 74,706,547 | 39,708,337 |
| `data02101.arc` | 127,331,439 | 49,085,072 |
| `data02110.arc` | 177,407,475 | 14,435,726 |
| `data02800.arc` | 1,491,431,580 | 1,499,306,936 |
| `data02900.arc` | 2,616,364 | 2,616,816 |
| `data02901.arc` | 19,653,803 | 20,930,750 |
| `data02903.arc` | 90,376 | 91,088 |
| `data03000.arc` | 20,927,695 | 7,806,936 |
| `data04000.arc` | 211,233,367 | 317,604,824 |
| `data04999.arc` | 3,278,153 | 1,483,075 |
| `data05000.arc` | 208,115,087 | 229,928,847 |
| `data05001.arc` | 17,543,935 | 6,284,675 |
| `sysgrp.arc` | 15,897,740 | 11,267,760 |
| `sysprg.arc` | 348,660 | 348,384 |
| `system.arc` | 34,346,138 | 33,553,139 |

---

## 8. Locale Emulator 相關記錄（事實）

安裝位置：`C:\Users\YUser\Documents\Locale.Emulator.2.5.0.1\`

| 檔案 | 大小 (bytes) |
|---|---|
| `LEProc.exe` | 29,696 |
| `LEGUI.exe` | 219,648 |
| `LoaderDll.dll` | 6,144 |
| `LocaleEmulator.dll` | 63,488 |
| `LEConfig.xml`、`LECommonLibrary.dll`、`LEContextMenuHandler.dll`、`LEInstaller.exe`、`LEUpdater.exe`、`LEVersion.xml`、`Lang`、另有兩個 `*.installer.bak` | — |

`LoaderDll.dll` 量測：PE machine `0x14c`、TimeDateStamp `1629744840`、節區 `.Asuna`(4096)/`.idata`(1024)/`.reloc`(512)、匯出函式 `LeCreateProcess`、Security 目錄 size `0`（無簽章）。

`LEConfig.xml` 內之 Profile 欄位（兩個 Profile 各含）：

```
<Parameter></Parameter>
<Location>ja-JP</Location>
<Timezone>Tokyo Standard Time</Timezone>
<RunAsAdmin>false|true</RunAsAdmin>
<RedirectRegistry>true</RedirectRegistry>
<IsAdvancedRedirection>false</IsAdvancedRedirection>
<RunWithSuspend>false</RunWithSuspend>
```

Windows 事件記錄（`Application` 記錄檔，時間為記錄檔顯示值）— 2026-09-17 20:05 前後三筆：

1. `Application Error`（Id 1000）：
   ```
   失敗的應用程式名稱： LEProc.exe，版本： 0.0.0.0，時間戳記： 0x61268e6d
   錯誤模組名稱： LoaderDll.dll， 版本： 0.0.0.0，時間戳記： 0x6123eec8
   例外狀況代碼： 0xc0000005
   錯誤位移： 0x00001a85
   Faulting 應用程式路徑： C:\Users\YUser\Documents\Locale.Emulator.2.5.0.1\LEProc.exe
   Faulting 模組路徑： C:\Users\YUser\Documents\Locale.Emulator.2.5.0.1\LoaderDll.dll
   報告識別碼： 4b1761c2-2aa2-4a3a-bfb6-2de6e4d0e112
   ```
2. `.NET Runtime`（Id 1026）：
   ```
   應用程式: LEProc.exe
   Framework 版本: v4.0.30319
   描述: 處理序已終止，因為有未處理的例外狀況。
   例外狀況資訊: System.AccessViolationException
      於 LEProc.LoaderWrapper.LeCreateProcess(IntPtr, System.String, System.String, System.String, UInt32, STARTUPINFO ByRef, PROCESS_INFORMATION ByRef, IntPtr, IntPtr, IntPtr, IntPtr)
      於 LEProc.LoaderWrapper.Start()
      於 LEProc.Program.DoRunWithLEProfile(System.String, Int32, LECommonLibrary.LEProfile)
      於 LEProc.Program.RunWithGlobalProfile(System.String, System.String)
      於 LEProc.Program.Main(System.String[])
   ```
3. `Windows Error Reporting`（Id 1001）APPCRASH 兩筆，P1=`LEProc.exe`、P4=`LoaderDll.dll`、P7=`c0000005`、P8=`00001a85`

---

## 9. 使用者開啟紀錄（UserAssist 解碼值）

來源：`HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist\{CEBFF5CD-ACE2-4F4F-9178-9926F41749EA}\Count`（名稱欄位 ROT13 解碼；時間欄位為 FILETIME 換算，UTC）

| 名稱 | 執行次數欄位 | 時間欄位 (UTC) |
|---|---|---|
| `F:\setup.exe` | 2 | 2026-09-17 12:11:50 |
| `F:\startup.exe` | 0 | 2026-09-02 05:23:50 |
| `E:\Setup.exe` | 1 | 2026-09-17 12:03:56 |
| `C:\Users\YUser\Downloads\[141128][sprite] 蒼の彼方のフォリズム 初回限定特装版 (mdf+mds+rr3)\[141128][sprite] 蒼の彼方のフォリズム 初回限定特装版 (mdf+mds+rr3).part1\SPR002\Setup.exe` | 2 | 2026-09-17 11:54:47 |
| `C:\Users\YUser\Documents\Locale.Emulator.2.5.0.1\LEGUI.exe` | 0 | 2026-08-14 10:26:16 |

---

## 10. 安裝結果（本次調查期間產生）

### 10.1 由本次作業啟動的引擎（1,229,312 bytes）與使用者操作後，檔案系統與 registry 出現以下項目

`C:\Users\YUser\Documents\sprite\蒼の彼方のフォリズムEXTRA1`：33 項（32 檔 + 子目錄 `UserData`），檔案合計 2,711,761,155 bytes

```
BGI.hvl                                            1,872
BHVC.exe                                          45,056
Uninstaller.exe                                1,858,560   (mtime 2026-09-17 22:05:45.829)
data01000.arc                                     29,242
data01100.arc                                    394,933
data02000.arc                                 76,235,190
data02010.arc                                162,136,770
data02020.arc                                100,842,874
data02030.arc                                  2,585,423
data02040.arc                                 61,411,315
data02041.arc                                  1,632,148
data02042.arc                                 24,719,335
data02090.arc                                  2,890,915
data02100.arc                                 39,708,337
data02101.arc                                 49,085,072
data02110.arc                                 14,435,726
data02800.arc                              1,499,306,936
data02900.arc                                  2,616,816
data02901.arc                                 20,930,750
data02902.arc                                 40,029,980
data02903.arc                                     91,088
data02904.arc                                  1,174,874
data03000.arc                                  7,806,936
data04000.arc                                317,604,824
data04999.arc                                  1,483,075
data05000.arc                                229,928,847
data05001.arc                                  6,284,675
sysgrp.arc                                    11,267,760
sysprg.arc                                       348,384
system.arc                                    33,553,139
uninst.lst                                         4,975
蒼の彼方のフォリズムEXTRA1.exe                   1,315,328   (mtime 2017-05-24 23:00:00)
```

registry：

```
HKLM\SOFTWARE\WOW6432Node\sprite\蒼の彼方のフォリズムEXTRA1\InstalledFolder
  = C:\Users\YUser\Documents\sprite\蒼の彼方のフォリズムEXTRA1

HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\蒼の彼方のフォリズムEXTRA1
  UninstallString = C:\Users\YUser\Documents\sprite\蒼の彼方のフォリズムEXTRA1\Uninstaller.exe
  InstallLocation = (未設定 / None)
```

### 10.2 與 4BOX 光碟目錄（`F:\蒼の彼方のフォリズムEXTRA1_4BOX`）之比對

- 光碟有／安裝後沒有：`AoNoKanataNoFourRhythmEX1`、`BGI.itl`、`BGIForInstalling.exe`、`Setup.exe`、`UnInstaller.exe`、`data02700.arc`、`installer.arc`、`蒼の彼方のフォリズムEXTRA1_4BOX.exe`
- 安裝後有／光碟沒有：`Uninstaller.exe`、`uninst.lst`、`蒼の彼方のフォリズムEXTRA1.exe`
- 同名但大小不同：`BGI.hvl`（光碟 7,696 → 安裝 1,872）、`BHVC.exe`（光碟 61,440 → 安裝 45,056）、`system.arc`（光碟 32,364,223 → 安裝 33,553,139）

### 10.3 與 2017 片（第 3.2 節量測值）之比對

- 安裝後之 `BGI.hvl` 1,872、`BHVC.exe` 45,056、`system.arc` 33,553,139、`data*.arc` 各檔大小、以及 `蒼の彼方のフォリズムEXTRA1.exe`（1,315,328），與該片所列數值相同
- 該片亦無 `data02700.arc`

### 10.4 已安裝本體之狀態（安裝 EXTRA1 前後量測）

| 項目 | 值 |
|---|---|
| 路徑 | `C:\Users\YUser\Documents\sprite\蒼の彼方のフォリズム` |
| 項目數 | 38（安裝前後皆為 38） |
| 含 `EXTRA1`／`EX1`／`AoNoKanata`／`data02090`／`data02902`／`data02904` 之檔名 | 無 |
| 檔案合計 | 6,219,165,827 bytes |
| `uninst.lst` | 4,399 bytes，mtime 2026-09-17 20:08:10.727635 |
| `BGI.hvl` | 2,192 bytes，mtime 2014-11-14 16:00:00 |
| registry（`HKLM\SOFTWARE\WOW6432Node\sprite\蒼の彼方のフォリズム\InstalledFolder`） | `C:\Users\YUser\Documents\sprite\蒼の彼方のフォリズム` |

### 10.5 `Documents\sprite` 於「安裝完成前」與 2026-09-17 22:31 兩次量測之差異

- 安裝完成前之量測（`蒼の彼方のフォリズムEXTRA1\Uninstaller.exe` 的 mtime 為 2026-09-17 22:05:45）：`Documents\sprite` 僅有 1 個資料夾 `蒼の彼方のフォリズム`
- 2026-09-17 22:31 量測：4 個資料夾

| 資料夾 | 項目數 | 檔案合計 (bytes) |
|---|---|---|
| `[190929][sprite] 蒼の彼方のフォリズム steam版 (files)` | 1 | 0（頂層無檔案） |
| `蒼の彼方のフォリズム` | 38 | 6,219,165,827 |
| `蒼の彼方のフォリズムEXTRA1` | 33 | 2,711,761,155 |
| `蒼の彼方のフォリズムPerfect Edition` | 35 | 7,023,414,875 |

`D:\sprite`：`蒼の彼方のフォリズム`（41 項）、`蒼の彼方のフォリズム HR`（31 項）、`蒼の彼方のフォリズムPerfect Edition`（38 項）；三者皆無 `EXTRA1`／`EX1`／`AoNoKanata` 相關檔名。

`HKLM\SOFTWARE\WOW6432Node\sprite` 子機碼（22:31 量測）：

```
蒼の彼方のフォリズム              → InstalledFolder = C:\Users\YUser\Documents\sprite\蒼の彼方のフォリズム
蒼の彼方のフォリズムEXTRA1        → InstalledFolder = C:\Users\YUser\Documents\sprite\蒼の彼方のフォリズムEXTRA1
蒼の彼方のフォリズムPerfect Edition → InstalledFolder = C:\Users\YUser\Documents\sprite\蒼の彼方のフォリズムPerfect Edition
```

---

## 11. 本次作業執行過的變更與其還原狀態

### 11.1 建立後已刪除

| 項目 | 建立時大小 |
|---|---|
| `C:\AOKANA_LE\`（含 junction `EXTRA1` → 光碟子目錄） | — |
| `%TEMP%\probe_ansi\`（A/B/C 實驗用目錄與 stub 複本） | — |
| `%TEMP%\aokana_test\`（迷你鏡像，量測 112.41 MiB） | 117,874,176 |
| `%TEMP%\bgi00042.exe`、`bgi00099.exe`、`bgi00055.exe`（引擎複本） | 1,346,048 / 1,346,048 / 1,229,312 |
| `%TEMP%\extra1_ui.bmp`、`extra1_ui.png`、`extra1_ui2.png`、`extra1_ui_screen.bmp` | 680,490 / 8,619 / 8,619 / 680,490 |
| `%TEMP%\pm\Procmon64.exe` | 2,237,208 |
| `%TEMP%\pm\t1.pml` | 1,121,088,273 |
| `%TEMP%\pm\t1.csv` | 194,742,066 |

另刪除 `%TEMP%` 內由安裝程式／引擎自身產生之 `bgi*.exe` 複本（含被提權執行後 ACL 受限、需以提權 cmd 刪除者）。

### 11.2 建立後保留

| 項目 | 說明 |
|---|---|
| `C:\Users\YUser\Desktop\install_EXTRA1.cmd` | 1,504 bytes（ASCII 編碼）；內容見附錄 A |
| `%TEMP%\bgi00066.exe` | 1,229,312 bytes、MD5 `e79e2ca3bccefe42562773b3d209f093`；2026-09-17 22:31 時仍被 pid 30724 使用 |

### 11.3 暫時修改後已還原

| 登錄值 | 原值 | 暫改值 | 還原後量測 |
|---|---|---|---|
| `HKCU\Control Panel\International\Locale` | `00000404` | `00000411` | `00000404` |
| `HKCU\Control Panel\International\LocaleName` | `zh-TW` | `ja-JP` | `zh-TW` |
| `HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers` 之 `E:\蒼の彼方のフォリズムEXTRA1\BGIForInstalling.exe` | 不存在 | `~ WIN7RTM`、`~ WIN8RTM`（先後設定） | 值已刪除 |

Procmon 執行後量測：無 `procmon` 相關行程、`Get-Service` 查無 `procmon` 服務。

### 11.4 由使用者本人執行之變更（本次調查期間觀察到）

- 系統 locale（非 Unicode 程式的語言）由繁中改為日文並重新開機：`GetACP()` 由 950 變為 932；開機時間 2026-09-17 20:55:38
- 掛載／卸載光碟映像（`SPR002EX1.ISO`、`SPR003ADV2.ISO`）；目前僅 `F:`（SPR003ADV2, UDF）掛載中
- 於本次作業開啟的安裝程式視窗中完成 EXTRA1 安裝（第 10 節所列之檔案與 registry 項目）
- `Documents\sprite` 下新增 `[190929][sprite] 蒼の彼方のフォリズム steam版 (files)`、`蒼の彼方のフォリズムPerfect Edition` 兩個資料夾

### 11.5 未變更

- 光碟映像檔（`SPR002EX1.ISO`、`SPR003ADV1.ISO`、`SPR003ADV2.ISO`）與其內容
- 已安裝遊戲之既有檔案（第 10.4 節前後量測值相同）
- 系統設定與 registry（除第 11.3、11.4 節所列者）

---

## 12. 本次執行過的可行啟動方式（原始命令）

以 1,229,312 bytes 引擎啟動 4BOX 片來源目錄之方式（2026-09-17 22:0x 執行）：

```
複本建立：以位元組複製方式，將
  C:\Users\YUser\Downloads\[141128][sprite] 蒼の彼方のフォリズム 初回限定特装版 (mdf+mds+rr3)\[141128][sprite] 蒼の彼方のフォリズム 初回限定特装版 (mdf+mds+rr3).part1\SPR002\蒼の彼方のフォリズム\BGIForInstalling.exe
  複製為 C:\Users\YUser\AppData\Local\Temp\bgi00066.exe
  （複本大小 1,229,312、MD5 e79e2ca3bccefe42562773b3d209f093，與來源相同）

執行：ShellExecuteExW(lpVerb = NULL, lpFile = "%TEMP%\bgi00066.exe",
        lpParameters = "\"F:\蒼の彼方のフォリズムEXTRA1_4BOX\" \"Execute as a launcher.\"",
        lpDirectory = "%TEMP%", nShow = 1)
```

以同一引擎啟動 2017 片來源目錄之方式（先前行為量測）：

```
執行：lpFile = "%TEMP%\bgi00055.exe",
      lpParameters = "\"E:\蒼の彼方のフォリズムEXTRA1\" \"Execute as a launcher.\"",
      lpDirectory = "%TEMP%"
```

以 `Cmd` 等價命令列表示即：

```
start "" /d "%TEMP%" "%TEMP%\bgi00066.exe" "<光碟上之EXTRA1子目錄>" "Execute as a launcher."
```

---

## 附錄 A：`C:\Users\YUser\Desktop\install_EXTRA1.cmd`（1,504 bytes，ASCII）

```
@echo off
chcp 932 >nul
setlocal
rem ---- find the WORKING installer engine (the 1,229,312-byte build from the base-game disc) ----
set "ENG="
for /f "delims=" %%F in ('dir /b /s /a-d "C:\Users\YUser\Downloads\BGIForInstalling.exe" 2^>nul') do (
  for %%Z in ("%%~fF") do if %%~zZ EQU 1229312 set "ENG=%%~fF"
)
rem ---- find the mounted EXTRA1 disc folder (any drive E:..K: that has BGIForInstalling.exe) ----
set "SRC="
for %%L in (E F G H I J K) do if not defined SRC if exist "%%L:\" for /d %%D in ("%%L:\*") do if not defined SRC if exist "%%~fD\BGIForInstalling.exe" set "SRC=%%~fD"

if /i "%~1"=="--check" (
  if defined SRC (echo CHECK: source folder OK) else (echo CHECK: source folder NOT FOUND ^(mount the ISO first^))
  if defined ENG (echo CHECK: working engine OK) else (echo CHECK: working engine NOT FOUND)
  if exist "%SRC%\BGIForInstalling.exe" echo CHECK: source exe OK
  exit /b 0
)
if not defined SRC  ( echo [x] No mounted EXTRA1 disc found ^(looked at E:..K:^). Mount the ISO first. & pause & exit /b 1 )
if not defined ENG  ( echo [x] Working installer engine not found under Downloads. & pause & exit /b 1 )
tasklist | findstr /i "bgi0" >nul && ( echo [!] An installer is already running - close it first. & pause & exit /b 1 )
copy /y "%ENG%" "%TEMP%\bgi00001.exe" >nul || ( echo [x] Copy failed & pause & exit /b 1 )
echo Starting EXTRA1 installer ...
start "" /d "%TEMP%" "%TEMP%\bgi00001.exe" "%SRC%" "Execute as a launcher."
exit /b 0
```

`--check` 模式輸出（2026-09-17 22:2x 執行）：

```
CHECK: source folder OK
CHECK: working engine OK
CHECK: source exe OK
```

---

## 附錄 B：量測工具

| 工具 | 用途 | 備註 |
|---|---|---|
| `capstone` 5.0.7、`pefile`（Python） | PE 解析與 x86 反組譯 | |
| Python 3.14（`ctypes`） | 直接呼叫 Win32 API（`ShellExecuteExW`、`CreateProcessW`、`GetFileAttributesA`、`RegOpenKeyExA/W`、`WideCharToMultiByte`、`CreateToolhelp32Snapshot`、`EnumWindows` 等） | |
| `Procmon64.exe`（Sysinternals 可攜版） | 檔案／登錄／行程／執行緒事件追蹤 | SHA256 `fc3af5317c707e0555ad6e7590ad65ceb5c5085b053b41221944ac3ca3492d9c`；`Valid`、`CN=Microsoft Corporation` |
| `Get-WinEvent`、`Get-CimInstance`、`Get-MpComputerStatus`、`Get-Volume`、`tasklist`、`dir`、`cmd` | 系統與事件記錄查詢 | |
| `glob`／`os.scandir` 之受時限界定的目錄走訪 | 依檔名與大小定位檔案 | |
