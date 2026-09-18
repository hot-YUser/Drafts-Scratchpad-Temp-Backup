# Bonsai 2 27B 三元模型在 RTX 5060 筆電上的 llama.cpp 實測報告

> 測試日期：2026-09-18 ~ 2026-09-19
> 測試機：NVIDIA GeForce RTX 5060 Laptop（8GB VRAM）筆電
> 結論先講：這台機器能跑 27B 等級的模型，最快約 **38 字/秒**，Context 最大能拉到 **262,144 tokens**（但要付出速度代價）。

---

## 1. 測試環境（完整交代）

### 1.1 硬體

| 項目 | 規格 |
|---|---|
| 機型 | 筆電 |
| CPU | AMD Ryzen AI 7 350 w/ Radeon 860M（16 邏輯核心，llama.cpp 預設用 8 執行緒） |
| GPU | **NVIDIA GeForce RTX 5060 Laptop GPU** |
| VRAM | **8151 MiB（顯示卡報告）/ 8123 MiB（llama.cpp 可用）** |
| GPU 架構 | Blackwell，`compute capability 12.0` |
| 系統 RAM | **32 GB（31.1 GB 可用）** |
| 驅動 | NVIDIA `616.92`，CUDA UMD `13.4` |
| 系統 | Windows 11 x64 |

> 注意：另有兩張顯示卡存在（AMD Radeon 860M 內顯、GameViewer 虛擬顯示卡），但本次測試全部只用 NVIDIA 那張。

### 1.2 軟體（這是最關鍵的坑）

| 項目 | 值 | 說明 |
|---|---|---|
| **llama.cpp 來源** | **`https://github.com/PrismML-Eng/llama.cpp`** | **不是原版 `ggml-org/llama.cpp`** |
| Release tag | `prism-b10683-d8f26ee` | 官方 demo 腳本鎖定的版本 |
| 版本字串 | `0.2.0-dev (build 10683, commit d8f26eec7)` | 用 `llama-cli.exe --version` 驗過 |
| 編譯器 | MSVC 19.44.35228.0 for Windows AMD64 | |
| 安裝路徑 | `C:\Users\YUser\llama-bonsai\bin-cuda\` | |
| 二進位套件 | `llama-prism-b10683-d8f26ee-bin-win-cuda-13.3-x64.zip` | 主程式 |
| CUDA runtime | `cudart-llama-bin-win-cuda-13.3-x64.zip` | 附屬 DLL，必須一起解壓到同目錄 |
| 官方跑法文件 | `https://github.com/PrismML-Eng/Bonsai-demo` | 唯一的 source of truth |

### 1.3 為什麼不能用原版 llama.cpp（`winget install llama.cpp` 的那個）

`winget` 上那個是原版（`ggml.llamacpp` b11026），**跑不了這個模型**。原因是：

本模型的權重存在一個「旋轉過的基底」裡。模型檔的 metadata 明確寫著：

```
prism.hadamard.version    = 1
prism.hadamard.block_size = 1024
prism.hadamard.transform  = normalized-sylvester-walsh-hadamard
```

意思是：這些數字在存檔前被做過一次數學旋轉，執行時必須做對應的反向旋轉才算得出正確答案。原版 llama.cpp 沒有這套運算，所以：

- 遇到 `PQ2_0` / `PTQ1_0`：直接拒絕載入（認不得這格式）
- 遇到普通的 `Q2_0`：會載入、**不報錯、但吐出垃圾**

這是官方模型卡的原文警告。所以：**請用 PrismML 的 fork**。

### 1.4 為什麼沒跑官方 `setup.ps1`

官方 `Bonsai-demo` 有 `setup.ps1` 一鍵安裝，但本次沒用，理由：

1. 它會建 Python 虛擬環境、裝套件 —— 本次已有模型檔，不需要。
2. 它會**重新下載 7.2GB 模型** —— 本地已有。
3. **它有個 bug 會踩到**：它用正則表達式在 `nvidia-smi` 輸出裡找 `CUDA Version:` 來決定抓哪個版本。但本機的 `nvidia-smi` 只印出 `CUDA UMD Version: 13.4`，**沒有 `CUDA Version:` 這行**，所以正則會落空，誤判成「沒有 NVIDIA GPU」→ 改抓 CPU 或 Vulkan 版 → 慢到不能用。

所以採用手動安裝：直接抓 `CUDA 13.3` 的 Windows 版本 zip，解壓即可。

> 另一個坑：`Expand-Archive` 在本機的 PowerShell 模組損壞（`Microsoft.PowerShell.Archive` 載不進來），改用 `unzip -o` 解壓。

### 1.5 模型檔（兩份都驗過完整性）

| 檔案 | 大小 | SHA256（與 HuggingFace 公布值比對） |
|---|---|---|
| `Ternary-Bonsai-2-27B-PQ2_0.gguf` | 7,206,168,928 bytes = **7.206 GB** | `3907dc1658db1f78a9826bf8d5bcb8dc65db0d466388937af57f2294fae62ec1` ✅ 一致 |
| `Ternary-Bonsai-2-27B-PTQ1_0.gguf` | 5,946,648,928 bytes = **5.947 GB** | `53107f530aa52eb00912263ab1ee29bd199261c87cd7b4ad4ca1318c1fe33ee3` ✅ 一致 |

模型來源：`https://huggingface.co/prism-ml/Ternary-Bonsai-2-27B-gguf`

模型內在規格（從 GGUF metadata 讀出）：

```
general.architecture          = qwen35
qwen35.block_count            = 64        （64 個運算區塊）
qwen35.context_length         = 262144    （原生 Context 上限 262K）
qwen35.embedding_length       = 5120
qwen35.attention.head_count   = 24
qwen35.attention.head_count_kv= 4
qwen35.full_attention_interval= 4         （每 4 層一次完整注意力 = 混合注意力）
general.quantization_version  = 2
file_type（PQ2_0）            = 141 -> PQ2_0 - 2.13 bpw (group 128)
file_type（PTQ1_0）           = PTQ1_0 - 1.75 bpw ternary (group 128)
tensor 組成（PQ2_0）          = f32: 353, bf16: 96, pq2_0: 402  （共 851）
```

> **混合注意力很重要**：這個模型約 75% 是線性注意力、25% 是完整注意力。所以它的 KV cache 遠比同規模模型小，這也是它能在本機跑長 Context 的原因。

---

## 2. 參數白話說明（每個參數改了，機器裡實際發生什麼）

| 參數 | 實際影響 |
|---|---|
| `-m <路徑>` | 讀哪個模型檔。沒給就不能跑。 |
| `-ngl 99` | 要把幾層放進顯卡（模型共 65 層）。`99` = 全放。放進去的層用 GPU 算（快），放不下的掉回 CPU/RAM 算（**慢 30 倍**）。數字越大越快，顯存不夠就崩潰。 |
| `-fa on` | 注意力計算用效能較好的演算法。實測差 1~2%，保持 `on`。 |
| `-c 4096` | Context 格數。輸入 token + 輸出 token 的總和上限。超過就遺忘前文。格數翻倍 = 顯存裡 context 區翻倍。 |
| `-ctk q4_0 -ctv q4_0` | 把「記憶格」從 16-bit 壓成 4-bit，KV 記憶體省約 3.5 倍（`64 KiB/token → 18 KiB/token`）。 |
| `-nkvo` | 把 KV cache 從顯卡搬到系統 RAM。顯卡只留權重。省顯存，但每步要經 PCIe 往返，速度掉一個量級。 |
| `-np 1` | **只有 server 用**。同時服務幾個請求。每多一槽就多一份 Context 顯存。8GB 卡必須設 `1`。 |
| `--temp 1.0` | 輸出亂度。`0` = 每次都選最可能的字，答案固定死板。`1.0` = 按機率隨機抽，同一問題兩次答案不同。越高越發散，太高會胡言亂語。本模型官方定 `1.0`。 |
| `--top-p 0.95` | 候選字池大小（機率累積）。由高到低加，加到 95% 就砍掉後面的長尾。`1.0` = 全留。 |
| `--top-k 20` | 候選字池大小（個數硬上限）。先只留前 20 名，再用 top-p/temp 篩。 |
| `-p "..."` | 這次要問的文字。 |
| `-st` | single-turn，跑完就關。**不加會停在互動模式等待輸入**，腳本永遠等不到結束（本次一開始卡 600 秒就是這個坑）。 |
| `-n 256` | 最多吐幾個 token。設太小回答會被腰斬。 |
| `--log-disable` | 只印答案，不印除錯訊息。正式用。 |
| `--verbose` | 全印。看「卸載幾層、顯存怎麼分配、pp/tg 速度」靠它。 |
| `--host / --port` | server 綁哪個位址跟埠。`127.0.0.1` = 只給本機連，別人連不進來（安全）。 |

---

## 3. 階段一：能跑

### 3.1 可跑指令（CLI）

```powershell
C:\Users\YUser\llama-bonsai\bin-cuda\llama-cli.exe `
  -m C:\Users\YUser\Downloads\Ternary-Bonsai-2-27B-PQ2_0.gguf `
  -ngl 99 -fa on -c 4096 --log-disable `
  --temp 1.0 --top-p 0.95 --top-k 20 `
  -st -p "Explain quantum computing in simple terms." -n 256
```

### 3.2 實測結果

| 測試 | 結果 |
|---|---|
| `-c 4096 -n 64` 短測 | ✅ `exit 0`，`prompt 191.9 t/s`，`gen 37.1 t/s` |
| `-c 4096 -n 256` 官方範例長文 | ✅ `exit 0`，`prompt 175.9 t/s`，`gen 38.3 t/s`，輸出正常英文解釋 |
| 層數卸載 | `offloaded 65/65 layers to GPU`（全部塞進顯卡） |
| 顯存佔用 | `CUDA0 8123 MiB = 0 free + 7087 model + 1036 context` |
| `-c 8192 -ngl 99` | ❌ `ggml-cuda.cu:107 CUDA error`，`exit 2147483647`（測了兩次都一樣） |

**小結**：4096 Context 是「全速」的上限。8GB 顯存被權重吃掉 7087 MiB 後，只剩約 1GB 能給 Context。

---

## 4. 階段二：速度最佳化

### 4.1 基準測試（`llama-bench -p 512 -n 128 -r 3`，跑 3 次取平均）

| 條件 | pp512（讀輸入） | tg128（吐字） |
|---|---|---|
| PQ2_0，`-fa on` | `775.21 ± 14.17` | **`39.06 ± 0.28`** |
| PQ2_0，`-fa off` | `762.38 ± 18.29` | `38.75 ± 0.31` |
| PQ2_0，`-fa on` + KV q4_0 | `772.70 ± 12.67` | `38.48 ± 0.04` |
| **PTQ1_0**，`-fa on` | `354.20 ± 0.29` | `34.51 ± 0.04` |
| **PTQ1_0**，`-fa off` | `349.41 ± 3.64` | `34.16 ± 0.06` |
| **PTQ1_0**，`-fa on` + KV q4_0 | `351.48 ± 2.22` | `34.28 ± 0.05` |

### 4.2 讀這張表

1. **`-fa on` 一律留著**。開關差 1~2%，沒有理由關。
2. **KV 量化（q4_0）幾乎無損**。因為這模型是混合注意力，KV 本來就小，瓶頸在權重頻寬不在 KV。但它在拉長 Context 時價值巨大（見第 5 節）。
3. **PQ2_0 比 PTQ1_0 快**：吐字快 13%（`39.06 vs 34.51`），讀輸入快 **2.2 倍**（`775 vs 354`）。
4. **PTQ1_0 小 1.26 GB**。這 1.26GB 在拉 Context 時是決定性的（見第 5 節）。

### 4.3 兩種打包格式怎麼選

官方說法：PTQ1_0 在 Ada 架構（RTX 4090 那代）比較快，PQ2_0 在 Blackwell / H100 / A100 比較快。本次測試的 RTX 5060 屬 Blackwell，實測符合預期 —— **短 Context 用 PQ2_0 快，長 Context 用 PTQ1_0 才塞得下**。

---

## 5. 拉滿 Context：全方向實測（本報告核心）

### 5.1 先講結論：三條路線的天花板

| 方案 | Context 全速上限 | 吐字速度 | 適合誰 |
|---|---|---|---|
| PQ2_0，f16 KV，全放 GPU | 6,144 | ~37 t/s | 短對話 |
| PQ2_0 + KV q4_0，全放 GPU | **22,016** | ~33.7 t/s | 22K 內最快 |
| PQ2_0 + KV 搬 RAM | 131,072 | ~10.9 t/s | PQ 能到的最大 |
| PTQ1_0，f16 KV，全放 GPU | 25,088 | ~28 t/s | 過渡帶 |
| **PTQ1_0 + KV q4_0，全放 GPU** | **72,960** | ~30 t/s | **73K 內最佳解** |
| **PTQ1_0 + KV 搬 RAM** | **262,144（原生滿血）** | 11 t/s（空載）→ 1.4 t/s（13 萬字實填） | **要拉滿就用它** |

「全速」定義：`-ngl 99` 手動鎖定，65 層全部在 GPU，沒有任何一層掉回 CPU。

### 5.2 PQ2_0，f16 KV（KV 留在顯卡，不壓縮）

| `-c` | 結果 | 層數 | pp | tg | 顯存殘量 |
|---|---|---|---|---|---|
| 4,096 | ✅ | 65/65 | 175.9 | 38.3 | 0 free |
| 6,144 | ✅ | 65/65 | 118.0 | 31.6 | — |
| 8,192 | ❌ `cu:107 CUDA error` | — | — | — | — |
| 26,624 / 28,672 / 32,768 | ❌ 各種 buffer 分配失敗 | — | — | — | — |

> 8,192 手動鎖 `-ngl 99` 必炸。若不鎖 `-ngl`、讓 `--fit on` 自動降層，會自動降到 `50/65` 層而「跑得起來」，但速度掉到 `prompt 3.4 / gen 1.1`（慢 30 倍，因為 15 層要經 PCIe 往返）。

### 5.3 PQ2_0 + KV q4_0（KV 仍在顯卡，但壓成 4-bit）

| `-c` | 結果 | context 顯存 | pp | tg |
|---|---|---|---|---|
| 8,192 | ✅ 65/65 | 293 MiB | 182.0 | 33.7 |
| 12,288 | ✅ 65/65 | 365 MiB | 178.9 | 33.3 |
| 16,384 | ✅ 65/65 | 437 MiB | 179.1 | 33.8 |
| 20,480 | ✅ 65/65 | 509 MiB | 176.4 | 33.9 |
| 21,504 | ✅ 65/65 | 527 MiB | 173.8 | 33.6 |
| **22,016** | ✅ 65/65 | 536 MiB | 181.1 | 33.7 |
| 22,272 | ❌ `cu:107 OOM` | — | — | — |
| 22,528 / 24,576 | ❌ 同上 | — | — | — |

**天花板：22,016 ~ 22,272**。f16 版只能到 6,144，加 q4_0 直接翻到 22K，而且速度只掉一點（`38 → 33.7`）。這是本次最划算的一招。

### 5.4 PTQ1_0，f16 KV（KV 留在顯卡，不壓縮）

| `-c` | 結果 | 層數 | pp | tg | 顯存殘量 |
|---|---|---|---|---|---|
| 8,192 | ✅ | 65/65 | 110.5 | 30.0 | 717 free |
| 12,288 | ✅ | 65/65 | 113.6 | 29.0 | 457 free |
| 16,384 | ✅ | 65/65 | 114.4 | 30.2 | 197 free |
| 24,576 | ✅ | 65/65 | 112.5 | 29.4 | 0 free |
| **25,088** | ✅ | 65/65 | 89.0 | 28.0 | 0 free |
| 25,600 | ❌ `cu:107 OOM` | — | — | — | — |
| 26,624 / 28,672 / 32,768 | ❌ | — | — | — | — |

**天花板：25,088 ~ 25,600**。25,088 跑完時 `free = 0`，一滴不剩，8GB 卡配 PTQ 的物理極限。

### 5.5 PTQ1_0 + KV q4_0（最佳甜蜜點）

| `-c` | 結果 | context 顯存 | pp | tg |
|---|---|---|---|---|
| 32,768 | ✅ 65/65 | 725 MiB | 110.0 | 30.1 |
| 65,536 | ✅ 65/65 | 1,301 MiB | 110.5 | 30.2 |
| 69,632 | ✅ 65/65 | 1,373 MiB | 112.9 | 30.2 |
| 71,680 | ✅ 65/65 | 1,409 MiB | 112.5 | 30.0 |
| 72,704 | ✅ 65/65 | 1,427 MiB | 110.8 | 30.0 |
| **72,960** | ✅ 65/65 | 1,432 MiB | 108.9 | 30.1 |
| 73,216 | ❌ `cu:107 OOM` | — | — | — |
| 73,728 / 81,920 / 98,304 / 131,072 | ❌（後幾個是 compute buffer 或 KV 分配失敗） | — | — | — |

**天花板：72,960 ~ 73,216**。這是「全部在顯卡、全速」能到的最大 Context。

### 5.6 PTQ1_0 + KV 搬 RAM（`-nkvo`）—— 拉滿 262K

| `-c` | 結果 | VRAM context | Host KV | pp | tg |
|---|---|---|---|---|---|
| 131,072 | ✅ 65/65 | 0 | 8,341 MiB | 72.7 | 11.2 |
| **262,144** | ✅ 65/65 | 0 | 16,537 MiB | 61.0 | **11.4** |

**262,144 = 模型原生滿血 Context，成功達成**。系統 RAM 用掉約 17GB（總量 31GB，仍有餘裕）。

### 5.7 組合技（`-nkvo` + q4_0，262,144）

✅ 65/65，`Host 4,757 MiB`（比純 `-nkvo` 的 17GB 省 3.5 倍），`prompt 72.2 / gen 10.6`。

省 RAM 效果顯著，但吐字反而比純 `-nkvo` 慢一點（解壓縮要算力）。**262K 下不推薦疊加**，除非系統 RAM 很緊。

### 5.8 PQ2_0 + KV 搬 RAM（`-nkvo`）

| `-c` | 結果 | 死因 |
|---|---|---|
| 131,072 | ✅ 65/65，`Host 8,341 MiB`，`prompt 88.7 / gen 10.9` | — |
| 135,168 | ❌ | 載入成功、CUDA graph warmup 完，decode 期 `cu:107 OOM` |
| 139,264 / 147,456 | ❌ | compute buffer `758 / 798 MiB` 分配失敗 |
| 163,840 | ❌ | compute pp buffer `878 MiB` 分配失敗 |
| 196,608 | ❌ | compute pp buffer `1,038 MiB` 分配失敗 |
| 262,144 | ❌ | compute pp buffer `1,358 MiB` 分配失敗 |

**天花板：131,072 ~ 135,168**。

> **關鍵發現（翻案）**：這裡的死因**不是 KV**（KV 已經搬到 RAM 了），而是 **compute pp buffer 會隨 Context 線性膨脹**：
> `131,072 → 158 MiB`（能過）→ `163,840 → 868 MiB` → `196,608 → 1,028 MiB` → `262,144 → 1,358 MiB`
> PTQ1_0 同樣招式能上 262K，是因為它權重小 1.1GB，顯卡裡騰得出空間放這個 buffer。

### 5.9 實填長文驗證（「空載測不準」的解答）

空載（只問一句 1+1）跑大 Context，KV 跟中間 buffer 都是空的，速度會虛高。所以另外做了兩次真實長文測試：

| 測試 | 設定 | 結果 |
|---|---|---|
| **6 萬字實填** | PTQ1_0，`-c 65536 + q4_0`，餵 60,061 tokens，生成 512 | ✅ `prefill 295.5 t/s`，`gen 20.3 t/s`，總耗時 207 秒 |
| **13 萬字實填** | PTQ1_0，`-c 131072 + -nkvo`，餵 130,061 tokens，生成 256 | ✅ `prefill 202.0 t/s`，`gen 1.37 t/s`，總耗時 736 秒（12.5 分鐘） |

**重點解讀**：

- 空載測到的 `pp 110 t/s` 是假議題。真實長文 prefill 頻寬其實高達 **295 t/s**（讀 6 萬字只花 203 秒）。
- 但吐字速度會隨 Context 長度崩塌：`gen 30（空載）→ 20（6 萬字）→ 1.4（13 萬字 + KV 在 RAM）`。
- 原因：每生成一個 token，都要對全部 KV 做注意力運算。KV 越大越慢；KV 搬到 RAM 後還要經 PCIe 往返，慢上加慢。

---

## 6. 階段三：Server + 內建 Web UI

### 6.1 踩到的坑

`llama-server -ngl 99 -c 4096` 預設多槽，**直接起不來**：

```
ggml_backend_cuda_buffer_type_alloc_buffer: allocating 598.50 MiB on device 0: cudaMalloc failed: out of memory
alloc_tensor_range: failed to allocate CUDA0 buffer of size 627572736
llama_init_from_model: failed to initialize the context: failed to allocate buffer for rs cache
```

CLI 單次請求能過，不代表 server 多槽能過 —— server 每一個槽都要一份 KV 跟 recurrent state buffer。**解法：加 `-np 1`**（一次只服務一個請求）。

### 6.2 兩種大 Context server 實測

| server 設定 | health | Web UI | API 實測 |
|---|---|---|---|
| PTQ1_0 `-c 72960 -ctk q4_0 -ctv q4_0 -np 1` | `{"status":"ok"}` | 首頁 12,639 bytes（前端 bundle 正常） | `"1 + 1 equals 2."`，`prompt 99.7 / gen 32.6 t/s` |
| PTQ1_0 `-c 262144 -nkvo -np 1` | `{"status":"ok"}` | 同上 | `"The answer is 2."`，`prompt 61.1 / gen 11.8 t/s` |

兩個都成功 `listening on http://127.0.0.1:8080`。

> 實測小坑：`curl` 直接打 `http://127.0.0.1:8080/` 會回 `Error: gzip is not supported by this browser`（44 bytes）。要加 `--compressed` 才拿得到真正的 HTML（12,639 bytes）。瀏覽器沒這問題。

### 6.3 Web UI 跟 API 的三個入口

| 用途 | 網址 |
|---|---|
| 聊天介面（像 ChatGPT） | `http://127.0.0.1:8080` |
| OpenAI 相容 API | `http://127.0.0.1:8080/v1/chat/completions` |
| 健康檢查 | `http://127.0.0.1:8080/health` |

API 是 OpenAI 相容格式，所以任何支援 OpenAI API 的 Agent / IDE 外掛 / 腳本都能直接接，把 base URL 指到 `http://127.0.0.1:8080/v1` 即可。

### 6.4 可直接複製的啟動指令

**73K 全速版（推薦日常用）**

```powershell
C:\Users\YUser\llama-bonsai\bin-cuda\llama-server.exe `
  -m C:\Users\YUser\Downloads\Ternary-Bonsai-2-27B-PTQ1_0.gguf `
  -ngl 99 -fa on -c 72960 -ctk q4_0 -ctv q4_0 -np 1 `
  --temp 1.0 --top-p 0.95 --top-k 20 `
  --host 127.0.0.1 --port 8080
```

**262K 拉滿版**

```powershell
C:\Users\YUser\llama-bonsai\bin-cuda\llama-server.exe `
  -m C:\Users\YUser\Downloads\Ternary-Bonsai-2-27B-PTQ1_0.gguf `
  -ngl 99 -fa on -c 262144 -nkvo -np 1 `
  --temp 1.0 --top-p 0.95 --top-k 20 `
  --host 127.0.0.1 --port 8080
```

**22K 內最快版（用 PQ2_0）**

```powershell
C:\Users\YUser\llama-bonsai\bin-cuda\llama-server.exe `
  -m C:\Users\YUser\Downloads\Ternary-Bonsai-2-27B-PQ2_0.gguf `
  -ngl 99 -fa on -c 22016 -ctk q4_0 -ctv q4_0 -np 1 `
  --temp 1.0 --top-p 0.95 --top-k 20 `
  --host 127.0.0.1 --port 8080
```

**問一次就走（CLI）**

```powershell
C:\Users\YUser\llama-bonsai\bin-cuda\llama-cli.exe `
  -m C:\Users\YUser\Downloads\Ternary-Bonsai-2-27B-PTQ1_0.gguf `
  -ngl 99 -fa on -c 72960 -ctk q4_0 -ctv q4_0 --log-disable `
  --temp 1.0 --top-p 0.95 --top-k 20 -st `
  -p "Explain quantum computing in simple terms." -n 256
```

---

## 7. 完整決策記錄（為什麼這樣做）

| # | 決策 | 理由 |
|---|---|---|
| 1 | 用 `PrismML-Eng/llama.cpp` fork，不用原版 | 原版認不得 `PQ2_0/PTQ1_0`，或靜默吐垃圾（缺 Hadamard 運算） |
| 2 | 鎖 `prism-b10683-d8f26ee`，不用最新 `b10687` | 官方 demo 腳本 pin 的版本，經完整驗證；最新版只差一天但未經腳本驗證 |
| 3 | 手動抓 zip，不跑 `setup.ps1` | 避免重下 7.2GB 模型、避免建 venv、避開它的 CUDA 偵測 bug |
| 4 | 手動指定 CUDA 13.3 | `nvidia-smi` 只印 `CUDA UMD Version: 13.4`，沒有 `CUDA Version:`，官方正則會落空誤判 |
| 5 | 用 `unzip -o` 解壓 | 本機 PowerShell `Expand-Archive` 模組損壞 |
| 6 | CLI 測試一律加 `-st` | 不加會進互動模式永不返回（一開始卡 600 秒） |
| 7 | 長任務用背景行程 + log pattern 等待 | 避免阻塞，也能即時看卸載層數跟顯存分配 |
| 8 | 每次只跑一個測試 | 8GB VRAM 不能併發，兩個行程同時載模型會互搶顯存，測出來的層數跟速度全部失真 |
| 9 | 先測 `-ngl 99` 而非從 `-ngl 0` 慢慢加 | 6.7GB 權重 + 1GB context < 8.1GB，理論塞得下，直接測更快證實/證偽 |
| 10 | 大 Context 用二分法找邊界 | 精確到 512 token 粒度（例如 72,960 過 / 73,216 炸） |
| 11 | 補做「實填長文」測試 | 空載跑大 Context 測不出真實 KV/buffer 壓力，速度會虛高 |
| 12 | Server 一律加 `-np 1` | 多槽預留多份 KV/RS buffer，8GB 卡必 OOM |

---

## 8. 常見問題

**Q：4096 Context 是不是太小了？**
不小也大。4096 tokens 約等於 3,000 個中文字加回答，單問單答夠用。但要長文件分析、RAG、多輪 Agent 就不夠 —— 模型原生是 262K，4096 只用了 1.5%。要更大請看第 5 節，72,960 全速、262,144 拉滿都能做到。

**Q：為什麼照官方 `-ngl 99` 卻 OOM？**
官方 benchmark 是在 16GB 卡（RTX 4070 Ti SUPER / 4090）上測的。本次測試機只有 8GB，權重就吃掉 6.5~7GB。請參照本報告的天花板表。

**Q：不鎖 `-ngl`，讓它自動降層跑大 Context 可以嗎？**
可以跑，但速度慘不忍睹。實測 `-c 8192` 自動降到 `50/65` 層：`prompt 3.4 / gen 1.1`，比全速慢 30 倍。掉速的不是「讀輸入」，而是「吐字」整段——每生成一個 token 那幾層都要經 PCIe 往返一次。

**Q：PQ2_0 跟 PTQ1_0 品質有差嗎？**
官方 14 項 benchmark 兩者幾乎同分。本次實測同一題兩份都答對、都正常。選哪個是速度跟容量的取捨，不是品質。

**Q：可以用原版 llama.cpp 嗎？**
不行，見 1.3 節。

**Q：Server 綁 `127.0.0.1` 別的電腦連不到？**
對，這是刻意的安全設定。要對區網開放請改 `--host 0.0.0.0`，但要注意它沒有任何認證機制，等同把模型服務開放給區網所有人。

---

## 9. 證據索引（如何查證本報告每個數字）

本報告每個數字都來自實測 log，可用以下關鍵字在測試紀錄中查證：

| 查證項目 | log 關鍵字 |
|---|---|
| 層數卸載 | `load_tensors: offloaded 65/65 layers to GPU` |
| 顯存分配 | `common_memory_breakdown_print: \| - CUDA0 (RTX 5060 Laptop GPU) \|` |
| 速度 | `slot print_timing: id 0 \| task 0 \|` 或 `[ Prompt: xxx t/s \| Generation: xxx t/s ]` |
| 實填 token 數 | `slot operator (): id 0 \| task 0 \| new prompt, n_ctx_slot = N, task.n_tokens = N` |
| OOM 死因 | `ggml_backend_cuda_buffer_type_alloc_buffer: allocating N MiB ... cudaMalloc failed: out of memory` |
| CUDA 硬錯誤 | `ggml-cuda.cu:107: CUDA error` |

測試時的背景行程名稱（供追溯）：

- 階段一：`verify4096`、`final4096`、`fail8192`
- 階段二：`bench-base`、`bench-faoff`、`bench-kvq4`、`c8192-auto`
- PTQ 對比：`ptq-verify`、`bench-ptq`、`ptq-c8192`、`ptq8192full`
- 邊界二分：`ptq-c12288`、`ptq16384full`、`ptq24576full`、`ptq25088full`、`ptq25600full`、`ptq26624full`、`ptq28672full`、`ptq32768full`
- KV 量化：`kvq4-32768`、`kvq4-65536`、`kvq4-69632`、`kvq4-71680`、`kvq4-72704`、`kvq4-72960`、`kvq4-73216`、`kvq4-73728`、`kvq4-81920`、`kvq4-98304`、`kvq4-131072`
- KV 搬 RAM：`kvcpu-131072`、`kvcpu-262144`、`combo-262144`
- PQ2_0 + q4_0：`pqkv-8192`、`pqkv-12288`、`pqkv-16384`、`pqkv-20480`、`pqkv-21504`、`pqkv-22016`、`pqkv-22272`、`pqkv-22528`、`pqkv-24576`
- PQ2_0 + 搬 RAM：`pqkvcpu-131072`、`pqkvcpu-135168`、`pqkvcpu-139264`、`pqkvcpu-147456`、`pqkvcpu-163840`、`pqkvcpu-196608`、`pqkvcpu-262144`
- 實填長文：`fill-65536`（60,061 tokens）、`fill-131072`（130,061 tokens）
- Server：`srv4096`（多槽失敗）、`srv4096np1`、`srv-ptq73k`、`srv-ptq262k`
- 對照 bench：`bench-kvq4ptq`、`bench-ptq-faoff`

---

## 10. 附錄：名詞速查

給沒碰過 llama.cpp 的讀者。本報告出現的術語都可在這裡查到白話解釋。

| 名詞 | 白話解釋 |
|---|---|
| **llama.cpp** | 一個在本機跑大型語言模型（LLM）的開源程式。它是「引擎」，不是模型。就像影片播放器 vs 影片檔。 |
| **GGUF** | 模型檔案的格式（副檔名 `.gguf`）。就像 `.mp4` 是影片檔格式。 |
| **模型檔 / 權重** | 模型本身，一個幾 GB 的檔案。本次主角約 **6~7 GB**。 |
| **量化（Quantization）** | 把模型壓小的技術。原本 27B 模型要 54GB，量化後只要 6~7GB，代價是稍微掉一點聰明度。 |
| **三元權重（Ternary）** | 一種極端量化：每個參數只存 `-1 / 0 / +1` 三種值。本模型就是這種，所以能壓到 1/9 大小。 |
| **PQ2_0 / PTQ1_0** | 本模型出廠的**兩種打包格式**（都是三元）。差別在怎麼把「三種值」塞進位元裡，影響檔案大小跟速度。 |
| **token** | 模型處理文字的最小單位。中文大約 1 個字 ≈ 1 個 token，英文大約 4 個字母 ≈ 1 個 token。 |
| **Context（`-c`）** | 模型的「記憶容量」，單位是 token。**輸入的 + 模型吐出的，加總不能超過這個數字**，超過就忘記前面講什麼。 |
| **VRAM / 顯存** | 顯示卡自己的記憶體。本次測試機是 **8GB**（llama.cpp 可用 8123 MiB）。模型要跑得快就得放進這裡。 |
| **RAM / 系統記憶體** | 主機的記憶體。本次測試機是 **32GB**（可用 31.1 GB）。比 VRAM 大很多但慢很多。 |
| **offload / `-ngl`** | 要把幾層模型放進顯卡。`-ngl 99` = 全部塞進去（本模型共 65 層）。沒塞進去的層會掉到 RAM 用 CPU 算，速度暴跌。 |
| **KV cache** | 模型為了「記住前面講過什麼」而暫存的資料。Context 越大，這塊越大。 |
| **pp（prompt processing）** | 模型「讀懂輸入」的速度，單位 token/秒。 |
| **tg（text generation）** | 模型「吐字」的速度，單位 token/秒。**日常體感速度看這個**。 |
| **CUDA / Blackwell** | NVIDIA 顯卡的運算平台。RTX 5060 屬 Blackwell 架構（compute capability 12.0）。 |
| **fork（分支）** | 有人把原始專案複製一份改過的版本。本次**必須用官方原作者的 fork**，原版 llama.cpp 跑不了。 |
| **CLI / Server / API** | 三種用法：CLI 是打一行指令問一次就結束；Server 是常駐背景、開瀏覽器聊天；API 是常駐背景讓其他程式用 HTTP 呼叫（同一個 server 同時提供後兩者）。 |

> CLI 與 Server 吃的是同一個模型，但 Server 會預留多份記憶空間，所以**同樣的 Context，Server 比 CLI 更容易爆顯存**。本次解法是加 `-np 1`（一次只服務一個請求）。
