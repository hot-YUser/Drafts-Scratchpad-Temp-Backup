# LINE Pay VGuard 事件探究記錄報告

> 性質：操作與觀測事實記錄。僅收錄量測值、檔案內容、log 行號與原文。
> 日期：2026-09-25。報告產出時設備已恢復原狀。

---

## 1. 設備基本資料（`getprop` / `uname` 實測值）

| 項目 | 值 |
|---|---|
| `ro.product.model` | `CPH2653` |
| `ro.product.brand` | `OnePlus` |
| `ro.product.device` | `OP5D55L1` |
| `ro.build.fingerprint` | `OnePlus/CPH2653/OP5D55L1:16/BP2A.250605.015/V.R4T3.26d97ac-1c1394-1d9854:user/release-keys` |
| `ro.build.version.release` | `16` |
| `ro.build.version.sdk` | `36` |
| `ro.build.id` | `BP2A.250605.015` |
| `ro.build.type` | `user` |
| `ro.build.version.security_patch` | `2026-08-01` |
| `ro.vendor.build.security_patch` | `2026-08-01` |
| `ro.boot.vbmeta.digest` | `cb625b2211e576853602d9386820c12e0c0bba584fc7ca19aa4fdef6dd69f43f` |
| `ro.boot.verifiedbootstate` | `green` |
| `ro.boot.vbmeta.device_state` | `locked` |
| kernel（`uname -r`） | `6.6.118-android15-OP-RESUKISU-huangdihd` |
| `sys.boot_completed`（查詢當下） | `1` |

### 1.1 Root 管理器實測

| 項目 | 值 |
|---|---|
| `/data/adb/ksu/bin/ksud` | 存在 |
| `/data/adb/ksu/bin/` 內容 | `bootctl、busybox、ksu_susfs、ksud、magiskboot、mkbootfs、resetprop、sus_su、znctl` |
| `su -V` | `35172` |
| `ksud -V` | `ksud 4.2.0-rc3-1-g6803643e (uapi: 4)` |
| `adb devices -l` | `3B159H0042T00000 device product:CPH2653 model:CPH2653 device:OP5D55L1` |

### 1.2 已安裝模組目錄（`/data/adb/modules/`）

共 10 個目錄：`TA_utl、enable-wifi-7、fix-signal-oneplus13、hybrid_mount、playintegrityfix、susfs4ksu、tricky_store、unlimitedphotos、zygisk_vector、zygisksu`。

各 `module.prop` 記錄值：

| 目錄 | `name` | `version` | `versionCode` | `author` |
|---|---|---|---|---|
| `enable-wifi-7` | `Enable Wi-Fi 6GHz & Wi-Fi 7` | `v02` | `2` | `AndroPlus` |
| `fix-signal-oneplus13` | `Fixes for OnePlus 13` | `v4.1` | `401` | `Fly` |
| `hybrid_mount` | `Hybrid Mount` | `6.2.1` | `602001999` | `Hybrid Mount Developers` |
| `playintegrityfix` | `Play Integrity Fork` | `v18` | `180000` | `osm0sis & chiteroman @ xda-developers` |
| `susfs4ksu` | `SUSFS-FOR-KERNELSU` | `v2.3.0-R28` | `105002028` | `sidex15 & simonpunk` |
| `tricky_store` | `Tricky Store OSS` | `v3.1.0 (172-41383f5-release)` | `172` | `beakthoven` |
| `unlimitedphotos` | `Google Photos Unlimited Backup` | `v5` | `50000` | `Rev4N - Credits to osm0sis & chiteroman` |
| `zygisk_vector` | `Vector` | `v2.0 (3021)` | `3021` | `JingMatrix` |
| `zygisksu` | `Zygisk Next` | `1.5.0 (843-5217106-release)` | `843` | `5ec1cff, Nullptr, aviraxp` |
| `TA_utl` | 無 `module.prop`；`webui/config.json` 內 `title` 為 `Tricky Addon` | — | — | — |

`tricky_store` 模組目錄內容：`classes.dex、daemon、inject、libTrickyStoreOSS.so、module.prop、post-fs-data.sh、sepolicy.rule、service.sh、webroot`。

### 1.3 應用程式版本與 UID（`dumpsys package` 實測）

| 應用 | 版本 | `versionCode` | UID | 安裝路徑（upay） |
|---|---|---|---|---|
| `com.linepaytw.upay` | `5.7.1`（`minSdk=32 targetSdk=35`） | `105070100` | `10435` | `/data/app/~~JVf414dl5_adIkBq5L3E6w==/com.linepaytw.upay-FaY1SVCidUCFN1TManXvXg==/`（`base.apk` + `split_config.arm64_v8a.apk` + `split_config.xxxhdpi.apk`） |
| `jp.naver.line.android` | `26.14.0`（`minSdk=32 targetSdk=36`） | `261400121` | `10371` | — |
| `io.github.vvb2060.keyattestation` | `1.8.4` | `198` | `10482` | — |
| `com.google.android.rkpdapp` | — | — | `10318` | — |
| `com.f0x1d.logfox` | `2.1.10` | `79` | — | — |

### 1.4 Play Integrity Fork 指紋設定（`custom.pif.prop` 前 25 行原文）

```text
MANUFACTURER=Google
MODEL=Pixel Fold
FINGERPRINT=google/felix_beta/felix:CANARY/ZP11.260821.010/16290768:user/release-keys
BRAND=google
PRODUCT=felix_beta
DEVICE=felix
RELEASE=CANARY
ID=ZP11.260821.010
INCREMENTAL=16290768
TYPE=user
TAGS=release-keys
SECURITY_PATCH=2026-09-05
DEVICE_INITIAL_SDK_INT=32
*.build.id=ZP11.260821.010
*.security_patch=2026-09-05
*api_level=32
spoofBuild=1
spoofProps=1
spoofProvider=0
spoofSignature=0
```

---

## 2. TrickyStore 設定檔實測內容

### 2.1 `target.txt`

* 路徑：`/data/adb/tricky_store/target.txt`；大小 `16755` bytes；`SHA-256` 前 16 碼 `391a1e3d4b4a1989`（兩次 pull 一致）。
* 行數：`616`。空行或 `#` 開頭行：`0`。以 `!` 結尾：`0`。以 `?` 結尾：`0`。
* `Modify: 2026-09-25 16:05:23.981768347 +0800`；`Access: 2026-08-08 19:02:02.684031042 +0800`。
* 字串命中：`upay` x0、`naver` x0、`linepay` x0、`line\.android` x0。
* 行號記錄：`com.google.android.gms` L241、`com.google.android.gsf` L245、`com.google.android.rkpdapp` L280、`io.github.vvb2060.keyattestation` L531。
* 與 `/sdcard/pm_list.txt`（658 個已安裝包）對照：
  * `com.linepaytw.upay`：已安裝，在 target 內：否。
  * `jp.naver.line.android`：已安裝，在 target 內：否。
  * `io.github.vvb2060.keyattestation`、`com.google.android.gms`、`com.google.android.gsf`、`com.google.android.rkpdapp`：已安裝，在 target 內：是。
  * 在 target 但未安裝（8）：`cm.aptoide.pt、com.inyuan.amis、com.inyuan.imsb、com.inyuan.n5、com.inyuan2018.ui、hello.litiaotiao.app、li.songe.gkd、watertracker.waterreminder.watertrackerapp.drinkwater`。

### 2.2 `keybox.xml`

* 路徑：`/data/adb/tricky_store/keybox.xml`；大小 `11609` bytes；`SHA-256`：`293d943bde5a1449aac3592bfacc652e95dff5be605dae1358760b8e9aeb0767`；`Modify: 2026-09-17 03:12:51.101999965 +0800`；權限 `0600`。
* 結構標籤計數：`NumberOfKeyboxes` 值為 `2`；兩個 `Keybox` 的 `DeviceID` 皆為 `dc371c2be02f867dc52efb2ba99247f9af2f21`；每個含 1 個 `algorithm="ecdsa"` 的 `Key`，各含 `NumberOfCertificates` 為 `4` 的憑證鏈。
* 備份檔：`keybox.xml.bak`（`13077` bytes，`Modify: 2026-09-17 03:12:51.017999965 +0800`）、`keybox.xml.bak.1`（`13309` bytes，`Modify: 2026-06-12 23:53:44.518999992 +0800`）。

### 2.3 `security_patch.txt`

* 大小 `48` bytes；`Modify: 2026-09-25 16:05:24.009768347 +0800`。內容原文：

```text
system=202608
boot=2026-08-05
vendor=2026-08-05
```

### 2.4 `tee_status` / `tee_status.txt` / `boot_key` / `hbk`

* `tee_status`（14 bytes）：內容 `teeBroken=true`。
* `tee_status.txt`（15 bytes，`Modify: 2026-08-12 18:14:37.345999997 +0800`）：內容 `tee_broken=true`。
* `boot_key`（64 bytes）：`4829c5caaf6f7e2b365a10c8516d2264691a27b845a885b023ed0fb1f2134faa`。
* `hbk`（32 bytes，hex）：`ae 9f 67 e5 39 e7 ee 04 ac fd c1 d2 69 95 0f 60 2e 8b 8c 03 45 b7 3c 79 6e 13 5e 94 21 9e 1b 79`。

### 2.5 `keys/` 目錄

* 探究中期記錄到 7 個子目錄：`10136、10139、10142、10370、10448、10474、99910142`。
* 重啟後（2026-09-25 17:56–18:00）記錄到 5 個子目錄，內容如下：

| 目錄 | 檔案 | 大小 | 修改時間 |
|---|---|---|---|
| `10136` | `39ef97e0dab911739718f9a55642ad18222a0ee8cc491f2a1a6b9ae47c51e2e7.bin` | `9242` | `2026-09-25 18:00` |
| `10139` | `b6909877950f9c60835bc0b37b15825a6df9cb865998457045ed6f039a4383aa.bin` | `7431` | `2026-09-25 17:56` |
| `10142` | （空） | — | — |
| `10448` | `a1284b0310d6402eb928987df1393cad404621a5062e4c72aa6d09660a7267d0.bin` | `2318` | `2026-09-25 17:56` |
| `10448` | `c2440e434e206aea20342c610a1c4b6b5cb64b44b08738706187b9c8e58e8035.bin` | `7354` | `2026-09-25 17:56` |
| `99910142` | （空） | — | — |

* UID 對照（`cmd package list packages -U`）：`10136=com.google.android.as.oss、10139=com.android.vending、10142/99910142=com.google.android.gms、10370=com.dcard.freedom、10448=com.shopee.tw、10474=com.garena.game.kgtw`。

### 2.6 `Config.kt` 觀測到的程式內容（`beakthoven/TrickyStoreOSS`，`config/Config.kt`）

* `needHack(callingUid)` 定義為 `checkNeed(callingUid, Mode.LEAF_HACK, teeBroken == false)`。
* `needGenerate(callingUid)` 定義為 `checkNeed(callingUid, Mode.GENERATE, teeBroken == true)`。
* `checkNeed` 內逐一比對該 UID 的包名：命中 `targetMode` 回傳 true；命中 `Mode.AUTO` 且 `autoPredicate` 為 true 回傳 true。
* `FileObserver` 監看 `/data/adb/tricky_store`：`target.txt` 變更觸發 `updateTargetPackages`；`keybox.xml` 變更觸發 `updateKeyBox`（內含 `SecurityLevelInterceptor.cleanupAll()`）；`security_patch.txt` 變更觸發 `updatePatchLevel`。

---

## 3. LINE Pay APK 靜態記錄

* `base.apk`：`57962044` bytes，`SHA-256` 前 16 碼 `14566fd651777e3f`；`split_config.arm64_v8a.apk`：`20420666` bytes，`SHA-256` 前 16 碼 `d8f9c8abbf2a454e`。
* `base.apk` 共 `3852` 個項目；dex 清單：`assets/audience_network/classes.dex`、`classes.dex`（`10198948` bytes）、`classes2.dex`（`7996432`）、`classes3.dex`（`9090448`）、`classes4.dex`（`9951708`）、`classes5.dex`（`5177644`）。
* `split` 內 `lib/arm64-v8a/libvosWrapperEx.so` 大小 `1941288` bytes。
* dex 字串計數：

| dex | `VGuardDetectionActivity` | `BOOT-STATE` | `CERT_NOT_SIGNED` | `VosWrapper` | `AesCipher` | `epiTransferSendMoney` | `v-key` |
|---|---|---|---|---|---|---|---|
| `classes.dex` | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| `classes2.dex` | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| `classes3.dex` | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| `classes4.dex` | 3 | 1 | 1 | 5 | 2 | 1 | 3 |
| `classes5.dex` | 0 | 0 | 0 | 8 | 0 | 0 | 0 |

* `libvosWrapperEx.so` 位元組計數：`v-key` x2、`syscall` x1、`BOOT-STATE` x0、`CERT_NOT_SIGNED` x0、`myHmac` x0、`AesCipher` x0、`attest` x0、`ContextCompat` x0、`VGuard` x0、`BOOT_STATE` x0。
* `ContextCompat` 計數：`classes.dex` 短字串 x1（上下文含 `ContextCompat.java`）；`classes4.dex` 短字串 x8（上下文為 `com/vkey/android/support/content/ContextCompat`、`ContextCompatApi21/23/Froyo/Honeycomb/Jellybean/KitKat` 等）；完整路徑 `androidx/core/content/ContextCompat` 在全部 dex 計數為 0；`assets/audience_network/classes.dex` 內 `ContextCompat` x1。
* `VGuard` 相關類別名稱（`classes4.dex` 擷取，共 20 個，節錄）：`Lcom/linepaytw/upay/biz/common/VGuardDetectionActivity`、`Lcom/linepaytw/upay/common/helper/vguard/DetectionCode`（含 `$a/$b`）、`VGuardLogger`、`VGuardManager`（含 `State/Idle/ThreatDetected/Timeout` 子類）、`vguard/a、vguard/b（含$b$a）、vguard/c（含$c$a/$c$a$a）`。
* V-Key 網址字串（`classes4.dex`）：`https://1177-ti.cloud.v-key.com/`、`https://1177-tla.cloud.v-key.com/`。
* `VGUARD_` 前綴字串共 42 個，包括：`VGUARD_ACCESSIBILITY_ENABLED、VGUARD_ACTION_ADB_DEBUGGING_STATUS、VGUARD_AIRDROID_PORT_IS_OPEN、VGUARD_ALERT_MESSAGE、VGUARD_ALERT_TITLE、VGUARD_DEVELOPER_OPTIONS_ENABLED、VGUARD_DIALOG_BUTTON_TEXT、VGUARD_DISABLED_APP_EXPIRED、VGUARD_ERROR_LICENSE_PACKAGE_NAME_MISMATCH、VGUARD_ERROR_LICENSE_SIGNER_CERT_MISMATCH、VGUARD_EXTRA_STATUS_IS_ENABLED、VGUARD_HANDLE_THREAT_POLICY、VGUARD_HIGHEST_THREAT_POLICY、VGUARD_INIT_STATUS、VGUARD_LICENSE_PACKAGE_NAME_MISMATCH、VGUARD_LICENSE_SIGNER_CERT_MISMATCH、VGUARD_MESSAGE、VGUARD_NETWORK_DETECTED、VGUARD_NETWORK_TYPES、VGUARD_OVERLAY_DETECTED、VGUARD_OVERLAY_DETECTED_DISABLE、VGUARD_REMOTE_APP_PACKAGE_CANDIDATES、VGUARD_SAFETY_CHECK、VGUARD_SAFETY_DENY、VGUARD_SAFETY_LIST、VGUARD_SCREEN_SHARING_DETECTED、VGUARD_SCREEN_SHARING_DISPLAY_NAMES、VGUARD_SEND_TROUBLESHOOTING_LOGS、VGUARD_SIDELOADED_APP_WITH_ACCESSIBILITY_PERMISSION_DETECTED、VGUARD_SIDELOADED_PACKAGE_ID、VGUARD_SIDELOADED_RESULT、VGUARD_SIDELOADED_SOURCE、VGUARD_SSL_ERROR_DETECTED、VGUARD_STATUS、VGUARD_STOP_OVERLAY_SERVICE、VGUARD_THREAT_RESPONSE_ITEM、VGUARD_THREAT_RESPONSE_LIST、VGUARD_VIRTUAL_SPACE_DETECTED、VGUARD_VIRTUAL_SPACE_TYPE、VGUARD_VIRTUAL_TAP_DETECTED、VGUARD_VIRTUAL_TAP_DETECTED_TYPE、VGUARD_VIRTUAL_TAP_TYPE`。
* `THREAT` 相關字串包括：`ABNORMAL_ENVIRONMENT_THREAT_ID、BOOT_STATE_THREAT_ID、CUSTOM_ROM_THREAT_ID、ROOT_THREAT_ID、SILENT_MODE_THREAT_ID、THREAT_ABNORMAL_ENVIRONMENT、THREAT_EMULATOR、THREAT_UNLOCKED_BOOTLOADER、THREAT_VIRTUAL_SPACE_APP_BASED、THREAT_VIRTUAL_SPACE_SYSTEM_BASED、THREAT_VIRTUAL_TAP`，另有 `FRIDA、FRIDA_DETECTED、FRIDA_JAVA_HOOKING、MAGISK_DETECTED、XPOSED、ROOTED、CUSTOM_ROM_DETECTED`。

---

## 4. Log 檔案清單

存放於 `C:\Users\YUser\Downloads\Mobile Devices\`：

| 檔名 | 大小（bytes） | 行數 | 首行時間戳前綴 | 末行時間戳前綴 | upay 主行程 PID | VosService PID |
|---|---|---|---|---|---|---|
| `25_09-15-51-25_229.log`（T0a） | `2132440` | `13194` | `1790322685.229` | `1790322695.525` | `23859` | `26049` |
| `25_09-16-09-28_074.log`（T0b） | `2278686` | `13792` | `1790323768.028` | `1790323777.893` | `27568` | `32330` |
| `25_09-17-32-29_903.log`（T1） | `2291183` | `14365` | `1790328749.898` | `1790328760.466` | `27309` | `29412` |
| `25_09-17-42-41_200.log`（T2） | `1968481` | `12032` | `1790329361.200` | `1790329369.381` | `4621` | `15557` |
| `25_09-17-52-08_427.log`（T3） | `2353582` | `15277` | `1790329928.403` | `1790329940.246` | `24176` | `29058` |

* 各檔 `Killing <VosService PID>:com.linepaytw.upay:vkey.android.vos.VosService/u0a435i-8900 (adj 0): isolated not needed` 皆記錄 1 次，PID 與上表 VosService PID 一致。
* 各檔 `START u0 ... VGuardDetectionActivity` 皆記錄 2 次；第二次的 `result code=3`（T0a L10599、T1 L10855；T0b/T2/T3 同構）。
* 各檔 `Screen trace: _st_EpiActivity _fr_tot:3` 皆記錄 1 次；`Screen trace: _st_VGuardDetectionActivity` 皆記錄 1 次（T0a `_fr_tot:23`、T0b `_fr_tot:23`、T1 `_fr_tot:27`、T2 `_fr_tot:26`、T3 `_fr_tot:27`）。
* 各檔 `upay-gw.line-apps.com ... responseCode: 400` 皆 1 次；`responseCode: 200` 次數：T0a x11、T0b x11、T1 x11、T2 x16、T3 x11。

---

## 5. 關鍵事件行號與原文（各檔）

### 5.1 T0a（`25_09-15-51-25_229.log`）

* L2805：`Start proc 23859:com.linepaytw.upay/u0a435 for next-top-activity {com.linepaytw.upay/com.linepaytw.upay.biz.main.LaunchActivity}`
* L3245：`V-OS.debug: ********** V-Key Release SDK: V-OS Processor 4.10.8.0 (Jul  2 2026 11:34:00) **********`（uid=10435 pid=23859）
* L3806：`TrickyStoreOSS: generateKey: forwarding symmetric key uid=10435 alias=com.linepaytw.upay.security.AesCipher`
* L9723：`V-OS.debug: ********** V-Key Release: V-OS Firmware (PQR) Version 50.8.0.0 **********`
* L9771：`TrickyStoreOSS: Requested KeyPair with alias: v-key`
* L9772：`TrickyStoreOSS: Generating EC keypair of size 256`
* L9773：`TrickyStoreOSS: System property ro.boot.vbmeta.digest: cb625b2211e576853602d9386820c12e0c0bba584fc7ca19aa4fdef6dd69f43f`
* L9780：`TrickyStoreOSS: getKeyEntry: serving cache uid=10435 alias=v-key`
* L9783：`BOOT-STATE: CERT_NOT_SIGNED_WITH_GOOGLE_ATTESTATION_ROOT_KEY`（uid=10435 pid=23859 tid=26002）
* L9806、L9931：`System.err: java.lang.ClassNotFoundException: androidx.core.content.ContextCompat`（堆疊含 `at vkey.android.vos.VosWrapper.startVOS(Native Method)`）
* L9831：`TrickyStoreOSS: generateKey: forwarding symmetric key uid=10435 alias=myHmac256`
* L10150：`START u0 {xflg=0x4 cmp=com.linepaytw.upay/.epi.presentation.EpiActivity ...} ... result code=0`
* L10251：`V-OS.debug: ********** V-Key Release SDK: V-OS Processor 4.10.8.0 ...`（pid=26017 再印一次）
* L10273：`Start proc 26049:com.linepaytw.upay:vkey.android.vos.VosService/u0ai100 for {com.linepaytw.upay/vkey.android.vos.VosService}`
* L10508：`Killing 26049:com.linepaytw.upay:vkey.android.vos.VosService/u0a435i-8900 (adj 0): isolated not needed`
* L10561：`START u0 {flg=0x20020000 ... cmp=com.linepaytw.upay/.biz.common.VGuardDetectionActivity ...} ... result code=0`
* L10568：`Death received, pid = 26049, processName = com.linepaytw.upay:vkey.android.vos.VosService`
* L10599：`START u0 {... VGuardDetectionActivity ...} ... result code=3`
* L11128：`Screen trace: _st_EpiActivity _fr_tot:3 _fr_slo:1 _fr_fzn:0`
* L12415：`Screen trace: _st_VGuardDetectionActivity _fr_tot:23 _fr_slo:2 _fr_fzn:0`

### 5.2 T0b（`25_09-16-09-28_074.log`）

* L2434：`Start proc 27568:com.linepaytw.upay/u0a435 ...`
* L2913、L9903：`V-Key Release SDK: V-OS Processor 4.10.8.0 ...`
* L9307：`V-Key Release: V-OS Firmware (PQR) Version 50.8.0.0`
* L9467、L9599：`ClassNotFoundException: androidx.core.content.ContextCompat`（堆疊含 `VosWrapper.startVOS`）
* L9759：`START u0 {... EpiActivity ...} result code=0`
* L9947：`Start proc 32330:com.linepaytw.upay:vkey.android.vos.VosService/u0ai100 ...`
* L10198：`Killing 32330:...VosService/u0a435i-8900 (adj 0): isolated not needed`
* L10223：`Death received, pid = 32330 ... VosService`
* L10419：`START u0 {... VGuardDetectionActivity ...} result code=0`
* L10443：`START u0 {... VGuardDetectionActivity ...} result code=3`
* L11089：`KeyMasterHalDevice: keymint_generate_csr_v2`（前一行 `KeymasterUtils: IKMHal_sendCmd failed with rsp_header->status: -18`）
* L11093、L11116：`RkpdSystemInterface` / `RkpdRegistrationBinder: android.os.ServiceSpecificException: Failure in CSR v2 generation. (code 1)`（含 `IRemotelyProvisionedComponent$Stub$Proxy.generateCertificateRequestV2` 堆疊）
* L11184–L11185：`TrickyStoreOSS: deleteKey pre-hook: uid=10435 alias=v-key domain=0`、`cleaned up uid=10435 alias=v-key`
* L11186：`keystore2: system/security/keystore2/src/database.rs:1696 - transaction failed Trying to get access tuple.`
* L11315：`Screen trace: _st_EpiActivity _fr_tot:3 _fr_slo:1 _fr_fzn:0`
* L12464：`Screen trace: _st_VGuardDetectionActivity _fr_tot:23 _fr_slo:3 _fr_fzn:0`

### 5.3 T1（`25_09-17-32-29_903.log`，`keybox.xml` 移走狀態）

* L2891：`Start proc 27309:com.linepaytw.upay/u0a435 ...`
* L3375、L9961：`V-Key Release SDK: V-OS Processor 4.10.8.0 ...`
* L9413：`V-Key Release: V-OS Firmware (PQR) Version 50.8.0.0`
* L9488、L9736：`ClassNotFoundException: androidx.core.content.ContextCompat`（堆疊含 `VosWrapper.startVOS`、`com.vkey.android.ge.a(SourceFile:433)`）
* L9596：`START u0 {... EpiActivity ...}`
* L10173：`Start proc 29412:com.linepaytw.upay:vkey.android.vos.VosService/u0ai100 ...`
* L10317：`Killing 29412:...VosService/u0a435i-8900 (adj 0): isolated not needed`
* L10341：`Death received, pid = 29412 ... VosService`
* L10658：`KeyMasterHalDevice: keymint_generate_csr_v2`（前一行 status `-18`）
* L10662、L10685：`Failure in CSR v2 generation. (code 1)`（`RkpdSystemInterface`、`RkpdRegistrationBinder`）
* L10767–L10768：`deleteKey pre-hook: uid=10435 alias=v-key`、`cleaned up`
* L10769：`keystore2 ... database.rs:1696 - transaction failed ...`（後續行含 `TX_unbind_key`、`KEY_NOT_FOUND`）
* L10834：`START u0 {... VGuardDetectionActivity ...} result code=0`
* L10855：`START u0 {... VGuardDetectionActivity ...} result code=3`
* L11862：`Screen trace: _st_EpiActivity _fr_tot:3 _fr_slo:1 _fr_fzn:0`
* L12937：`Screen trace: _st_VGuardDetectionActivity _fr_tot:27 _fr_slo:1 _fr_fzn:0`
* 該檔 `BOOT-STATE` x0、`Requested KeyPair` x0、`Generating EC` x0、`forwarding symmetric` x0、`serving cache` x0、`v-key` 僅 L10767–L10768（deleteKey 兩行）、`myHmac` x0、`AesCipher` x0、`vbmeta` x0。

### 5.4 T2（`25_09-17-42-41_200.log`，`security_patch.txt` 停用狀態）

* L2051：`Start proc 4621:com.linepaytw.upay/u0a435 ...`
* L2483、L8977：`V-Key Release SDK: V-OS Processor 4.10.8.0 ...`
* L8482：`V-Key Release: V-OS Firmware (PQR) Version 50.8.0.0`
* L8553、L8695：`ClassNotFoundException: androidx.core.content.ContextCompat`
* L8784：`START u0 {... EpiActivity ...}`
* L9048：`Start proc 15557:com.linepaytw.upay:vkey.android.vos.VosService/u0ai100 ...`
* L9372：`Killing 15557:...VosService/u0a435i-8900 (adj 0): isolated not needed`
* L9419：`Death received, pid = 15557 ... VosService`
* L9715：`keymint_generate_csr_v2`；L9719、L9742：`Failure in CSR v2 generation. (code 1)`
* L9824–L9825：`deleteKey pre-hook: uid=10435 alias=v-key`、`cleaned up`
* L9826：`database.rs:1696 - transaction failed ...`
* L9900：`START u0 {... VGuardDetectionActivity ...} result code=0`
* L9920：`START u0 {... VGuardDetectionActivity ...} result code=3`
* L10510：`Screen trace: _st_EpiActivity _fr_tot:3 _fr_slo:1 _fr_fzn:0`
* L11501：`Screen trace: _st_VGuardDetectionActivity _fr_tot:26 _fr_slo:2 _fr_fzn:0`
* 該檔 Tricky `uid=10435`：`intercept pre dataSz=204` x24、`dataSz=148` x9、`dataSz=168` x3、`intercept key gen` x3、deleteKey x2。

### 5.5 T3（`25_09-17-52-08_427.log`，Tricky 模組停用並重啟後）

* 該檔 `TrickyStoreOSS`（排除 adb 自身查詢行）共 0 行。
* L2138：`Start proc 24176:com.linepaytw.upay/u0a435 ...`
* L2570、L11501：`V-Key Release SDK: V-OS Processor 4.10.8.0 ...`
* L10779：`V-Key Release: V-OS Firmware (PQR) Version 50.8.0.0`
* L10900、L11243、L11715：`ClassNotFoundException: androidx.core.content.ContextCompat`（共 3 次）
* L11156：`START u0 {... EpiActivity ...}`
* L11565：`Start proc 29058:com.linepaytw.upay:vkey.android.vos.VosService/u0ai100 ...`
* L11570–L11571：`.vos.VosService: Unknown bits set in runtime_flags: 0x40000000`、`Using generational CollectorTypeCMC GC.`
* L12050：`Killing 29058:...VosService/u0a435i-8900 (adj 0): isolated not needed`
* L12113–L12114：`Death received, pid = 29058 ...`、`Process 29058 exited due to signal 9 (Killed)`
* L12353：`START u0 {... VGuardDetectionActivity ...} result code=0`
* L12381：`START u0 {... VGuardDetectionActivity ...} result code=3`
* L12836：`Screen trace: _st_EpiActivity _fr_tot:3 _fr_slo:2 _fr_fzn:0`
* L13965：`Screen trace: _st_VGuardDetectionActivity _fr_tot:27 _fr_slo:3 _fr_fzn:0`
* keystore2 新增記錄（T3 檔內）：`SECURE_HW_COMMUNICATION_FAILED`（L5698、L12281）、`CANNOT_ATTEST_IDS`（`checkin_attestation`，L6623）、`INVALID_KEY_BLOB`（L7348、L7462）、`database.rs:1696` 共 3 處（L5699、L6626、L12282，後續行含 `TX_unbind_key`、`KEY_NOT_FOUND`）、`Failure in CSR v2 generation. (code 1)` 共 4 處（L5608、L5631、L12188、L12211）。

---

## 6. 計數彙整（五檔，以全文正則計數）

| 訊號 | T0a | T0b | T1 | T2 | T3 |
|---|---|---|---|---|---|
| `Unknown syscall ID 0x0` | 77 | 75 | 57 | 67 | 86 |
| `Unknown syscall ID 0x1` | 84 | 83 | 65 | 85 | 90 |
| `Unknown syscall ID 0x2` | 24 | 24 | 20 | 21 | 25 |
| `Unknown syscall ID 0x131` | 1 | 1 | 1 | 1 | 1 |
| Keymaster `ret: -28` | 28 | 19 | 34 | 19 | 145 |
| Keymaster `ret: -18` | 0 | 1 | 1 | 1 | 2 |
| Keymaster `ret: -49` | 0 | 1 | 1 | 1 | 2 |
| Tricky `uid=10435 intercept key gen` | 3 | 3 | 3 | 3 | 0 |
| Tricky `uid=10435 intercept pre`（204/148/168） | 24/9/3 | 24/9/3 | T1 檔未記錄 `intercept pre` 行 | 24/9/3 | 0 |
| `deleteKey pre-hook uid=10435 alias=v-key` | 0 | 2 | 2 | 2 | 0 |
| `BOOT-STATE` | 1 | 0 | 0 | 0 | 0 |
| `Requested KeyPair / Generating EC / serving cache` | 1/1/1 | 0/0/0 | 0/0/0 | 0/0/0 | 0/0/0 |
| `forwarding symmetric` | 2 | 0 | 0 | 0 | 0 |
| `CNFE ContextCompat` | 2 | 2 | 2 | 2 | 3 |
| `START EpiActivity` / `START VGuard x2` | 1 / 2 | 1 / 2 | 1 / 2 | 1 / 2 | 1 / 2 |

---

## 7. 操作時間序（設備端實際執行的指令與回顯）

所有 `cp/mv/touch/rm` 均在測後還原；還原後均以 `sha256sum` 或 `cat` 驗證。

1. 備份並移走 keybox：`cp /data/adb/tricky_store/keybox.xml /data/adb/tricky_store/keybox.xml.t1bak && mv /data/adb/tricky_store/keybox.xml /data/adb/tricky_store/keybox.xml.disabled`。備份檔 `SHA-256` 與原值一致（`293d943b...`）。約 1 分鐘後 logcat 記錄 `TrickyStoreOSS: Clearing all keyboxes`。接著 `logcat -c`，進行 T1 測試，產出 `25_09-17-32-29_903.log`。
2. 還原 keybox：`mv /data/adb/tricky_store/keybox.xml.disabled /data/adb/tricky_store/keybox.xml`。`sha256sum` 回傳 `293d943b...`。logcat 記錄 `TrickyStoreOSS: Keybox algorithm attribute 'ecdsa' disagrees with parsed key 'ECDSA'; using parsed key`（2 行）與 `Successfully updated 2 keyboxes`。
3. 備份並停用 patch 設定：`cp /data/adb/tricky_store/security_patch.txt /data/adb/tricky_store/security_patch.txt.t2bak` 後 `mv ... security_patch.txt.disabled`。接著 `logcat -c`，進行 T2 測試，產出 `25_09-17-42-41_200.log`。
4. 還原 patch 設定：`mv /data/adb/tricky_store/security_patch.txt.disabled /data/adb/tricky_store/security_patch.txt`，`cat` 顯示三行原值。刪除臨時備份 `keybox.xml.t1bak`、`security_patch.txt.t2bak`。
5. 停用整個 Tricky 模組：`touch /data/adb/modules/tricky_store/disable`（`ls` 顯示該檔存在，大小 0）。使用者手動重啟。重啟後 `ps -A` 無 Tricky 行程，logcat 內 `TrickyStoreOSS` 計數為 0（不含 adb 自身查詢行），`keystore2` 行程存在（PID 1263）。接著 `logcat -c`，進行 T3 測試，產出 `25_09-17-52-08_427.log`。
6. 恢復模組：`rm /data/adb/modules/tricky_store/disable`（`ls` 不再列出該檔）。使用者再次手動重啟。重啟後記錄：`uptime` 顯示開機約 1 分鐘；`ps -A` 記錄 `TrickyStoreOSS` 行程（PID 3385）；`disable` 檔不存在；`keybox.xml`、`security_patch.txt`、`tee_status` 內容與大小同原值。

其他量測記錄：`keystore_cli_v2 generate --name=t0probe_tee --seclevel=tee` 回傳 `GenerateKey: success`、`DoesKeyExists: yes`，刪除後回傳 `Successfully deleted key.`；同次 logcat 記錄 `TrickyStoreOSS: intercept key gen uid=0 pid=573` 與 `deleteKey pre-hook: uid=0 alias=t0probe_tee`。

---

## 8. 網路上找到的相關資料（標題與網址）

### 8.1 V-Key / V-OS / V-Guard 官方與技術文件

* `V-OS Virtual Secure Element` — https://www.v-key.com/products/v-os-virtual-secure-element/
* `How V-OS Virtual Secure Element Bridges the Trust Gap and Protects Sensitive Data?` — https://www.v-key.com/resource/how-v-os-virtual-secure-element-bridges-the-trust-gap-and-protects-sensitive-data/
* `Is Jailbreak and Root Detection Enough for Security` — https://www.v-key.com/resource/is-detection-of-jailbroken-rooted-phone-sufficient-against-threats/
* `Ensuring Secure Cashless Transactions with V-OS Mobile App Protection` — https://www.v-key.com/resource/ensuring-secure-cashless-transactions-with-v-os-mobile-app-protection/
* `Cryptography in V-OS` — https://www.v-key.com/resource/cryptography-in-v-os
* `V-Key Technology Overview Whitepaper`（PDF） — https://www.v-key.com/wp-content/uploads/2022/12/V-Key-Technology-Whitepaper.pdf
* `V-Tap Developer Guide - Android`（PDF，33 頁，Version 3.6.1.6 - 4.0.0.0） — https://slidrio-decks.global.ssl.fastly.net/1114/original.pdf
* `V-OS Mobile App Protection with Runtime Defense` — https://www.v-key.com/products/v-os-mobile-app-protection
* `V-Key - Wikipedia` — https://en.wikipedia.org/wiki/V-Key

### 8.2 同類 V-Key 應用 bypass 討論

* `Using Software with V-key Components | XDA Forums`（SingPass / OCBC / POSB，含 `pm disable vkey.android.vos.MgService` 等指令記錄） — https://xdaforums.com/t/using-software-with-v-key-components.4237637/
* `Part 1: How I Secured a Banking App with V-Key SDK | Medium` — https://medium.com/@innerarchitecture/part-1-how-i-secured-a-banking-app-with-v-key-sdk-a1d667b3e43e
* `[DETECTION] Add protector Vkey · Issue #210 · rednaga/APKiD`（`libvosWrapperEx.so` 列為 Vkey 特徵） — https://github.com/rednaga/APKiD/issues/210

### 8.3 LINE Pay Root 議題

* `LINE Pay Taiwan支援中心：基本介紹`（列出 Root、Magisk、非 Play 商店 APK、開發人員模式、模擬器環境） — https://help2.line.me/linepay_tw/ios/categoryId/50003426/3/pc?country=TW&lang=zh-Hant
* `LINE Pay更新！中國品牌手機無法使用｜方格子` — https://vocus.cc/article/617e93b6fd897800012ad7a4
* `華為等中國手機不支援LINE Pay？其實是指沒有「Google服務」的機型｜udn` — https://tech.udn.com/tech/story/123151/5859957
* `[請益] Linepay過不了檢測 - PTT Android`（Kitsune、TS、`target.txt`、HMA 白名單記錄） — https://www.ptt.cc/bbs/Android/M.1728064923.A.707.html
* `[請益] line pay 開始擋root了 - PTT Android` — https://www.ptt.cc/bbs/Android/M.1627987325.A.93D.html
* `分享 Magisk 通過 Safetynet 方法 - Mobile01`（第 3、10、11 頁，含 Alpha、Shamiko、HMA、ApplistDetector 記錄） — https://www.mobile01.com/topicdetail.php?f=634&t=6446241
* `LINE Pay root 後無法使用 解決方法 - 木易行旅`（Magisk v28.1、DenyList、HMA；留言記錄獨立 LINE Pay App 通過規律不明） — https://yangstory.com/line-pay-root/
* `Root 銀行app 無法使用之解決步驟 - 木易行旅` — https://yangstory.com/root-%E9%8A%80%E8%A1%8Capp/
* `【心得】Kernelsu-next / Apatch 刷機紀錄 - 巴哈姆特`（PIF-Inject、TEESimulator-RS、HMA-OSS；記錄關閉 LIME 重開 LINE 才可用 LINE Pay） — https://forum.gamer.com.tw/C.php?bsn=60559&snA=67657
* `MeowGod8777/LINE-Root-Patches`（記錄 `VGuardDetectionActivity` 字串的公開倉庫） — https://github.com/MeowGod8777/LINE-Root-Patches

### 8.4 TrickyStore / TEE / 替代方案

* `beakthoven/TrickyStoreOSS`（本次設備安裝的 v3.1.0 所屬專案；含 `target.txt`、`security_patch.txt`、`config/Config.kt` 語義） — https://github.com/beakthoven/TrickyStoreOSS
* `keystore2 crashes on every boot on Android 13 ... · Issue #92`（開機期 keystore2 segfault 與 `teeBroken=true` 誤判記錄） — https://github.com/beakthoven/TrickyStoreOSS/issues/92
* `xStoikk/TrickyStoreOSS` — https://github.com/xStoikk/TrickyStoreOSS
* `5ec1cff/TrickyStore` — https://github.com/5ec1cff/TrickyStore
* `Tricky Store - Bootloader & Keybox Spoofing | XDA`（OnePlus `teeBroken=true` 多起記錄，p154/p240/p243/p288/p325） — https://xdaforums.com/t/tricky-store-bootloader-keybox-spoofing.4683446/
* `JingMatrix/TEESimulator`（內嵌 `kmr-ta` 的軟體 TEE 模擬方案） — https://github.com/JingMatrix/TEESimulator
* `Enginex0/TEESimulator-RS` — https://github.com/Enginex0/TEESimulator-RS
