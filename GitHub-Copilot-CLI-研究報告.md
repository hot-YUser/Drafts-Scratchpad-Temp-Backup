# GitHub Copilot CLI 方案、模型與學生授權研究

研究日期：2026-10-11  
對象帳號：`hot-YUser`  
本機環境：Windows，GitHub Copilot CLI **1.0.95**（`copilot`）

這份報告整理這次對本機 Copilot CLI、GitHub 官方文件、方案頁，以及帳號即時授權的查證。結論先寫在前面，後面是量測與來源。

## 結論

Copilot CLI 沒有自己的訂閱。它使用同一個 GitHub 帳號上的 **GitHub Copilot** 授權。不該為了 CLI 去訂 GitHub Pro，也不該去訂 Microsoft 365 Copilot。

這台機器在啟用學生方案之前，CLI 讀到的是 **Copilot Free**（`free_limited_copilot`）。啟用 GitHub Copilot Student 之後，即時授權已改成 **Copilot Student**（`free_educational_quota`）。

Student 把程式碼補全和 Chat 改成無上限，並給了每月 **200 次** `premium_interactions`。模型手選沒有打開：`/model` 過濾後仍是空的，進階模型的政策仍是停用。要自己挑模型，最低是 Copilot Pro（$10 美元/月）；Opus、Fable、GPT-6 Astra、GPT-6 Sol 這類在這個帳號的目錄裡標成 `pro_plus`。

## 1. 本機 CLI 是什麼

安裝位置：

`C:\Users\YUser\AppData\Local\Microsoft\WinGet\Packages\GitHub.Copilot_Microsoft.Winget.Source_8wekyb3d8bbwe\copilot.exe`

版本：`GitHub Copilot CLI 1.0.95`。

它是終端機裡的 TUI。模型選單是互動指令 `/model`（別名 `/models`），也可以用啟動參數 `--model`。沒有寫入 `~/.copilot/settings.json` 的預設模型時，會走 **Auto**。

帳號以 GitHub 登入，登入名稱 `hot-YUser`。憑證存在 Windows Credential Manager，目標是 `https://github.com:hot-YUser.copilot-cli`。這和 `gh` 的 token 是分開的。

官方安裝文件寫：Copilot CLI 包含在所有 Copilot 方案裡。組織或企業授權還要管理員在原則裡打開 CLI。個人方案沒有這一層。

## 2. 三個常被混在一起的產品

| 產品 | 實際是什麼 | 和 Copilot CLI 的關係 |
|---|---|---|
| GitHub Pro | GitHub 帳號方案：私有庫、進階程式碼審查等 | 無關。Student Developer Pack 送的通常是這個 |
| GitHub Copilot（Free / Student / Pro / Pro+ / Max / Business / Enterprise） | 寫程式的 AI。CLI、VS Code、Copilot app、github.com 都吃這份授權 | 就是 CLI 要的授權 |
| Microsoft 365 Copilot | Word、Excel、Outlook、Teams 裡、讀公司檔案的 Copilot | 另一份合約，不能拿來登 Copilot CLI |

GitHub Copilot 用 GitHub 帳號登入。Microsoft 365 Copilot 要有合格的 Microsoft 365 基礎授權，再加購 M365 Copilot。兩邊共用「Copilot」這個名字，計費與登入都不同。

X 上 2026 年 9 月到 10 月的學生福利貼文，常把「GitHub Pro」和「Copilot Pro」寫成同一件事，或寫成學生包送免費 Copilot Pro。官方在 2026-03-13 之後的分法是：已驗證學生得到 **Copilot Student**；已驗證教師與熱門開源專案維護者才是免費 **Copilot Pro**。

## 3. 官方方案（文件與方案頁，2026-10）

方案頁：<https://github.com/features/copilot/plans>  
文件：<https://docs.github.com/en/copilot/get-started/plans>

文件寫明所有方案都包含 Copilot CLI 與 Copilot app。

| 方案 | 月費 | 模型 | 用量單位（文件） |
|---|---|---|---|
| Copilot Free | $0 | 只能 Auto | 有 AI credits 配額；補全每月 2,000 次 |
| Copilot Student | $0，已驗證學生 | 只能 Auto | 有 AI credits 配額；補全無上限 |
| Copilot Pro | $10（部分使用者免費） | 可選一組模型 | 1,000 基本 + 500 flex = 1,500 AI credits |
| Copilot Pro+ | $39 | 進階模型 | 3,900 + 3,100 = 7,000 |
| Copilot Max | $100 | 進階模型，優先使用 | 10,000 + 10,000 = 20,000 |
| Copilot Business | $19 / 席次 | 進階模型 | 每使用者 1,900，組織可共用 |
| Copilot Enterprise | $39 / 席次 | 進階模型，優先使用 | 每使用者 3,900，組織可共用 |

1 AI credit = $0.01 美元。付費方案的程式碼補全與 next edit suggestion 不扣 credits。Chat、CLI、cloud agent、Spaces、Spark、第三方 coding agent 會扣。

Flex 是加在基本額度上的變動配額，GitHub 說之後可能調整。Pro 的 $15、Pro+ 的 $70、Max 的 $200，是「基本額度對應訂閱價格，再加上 flex」的每月合計。

方案頁 Free 卡片上的句子：

> No credit card required. Verified students have access to the GitHub Copilot Student plan.

前半是說開通 Free 不用綁信用卡。後半是說通過 GitHub Education 學生認證的人，可以另外拿到也免費的 **Copilot Student**。Learn more 連到 <https://github.com/education/students>。這句話不是「學生包會自動變成 Free」，也不是「去訂 GitHub Pro 或 Microsoft 365」。

訂閱入口（同一個 GitHub 帳號）：

- Copilot Pro：<https://github.com/github-copilot/signup?ref_product=copilot&ref_type=purchase&ref_style=text&ref_plan=pro>
- Copilot Pro+：<https://github.com/github-copilot/signup?ref_product=copilot&ref_type=purchase&ref_style=text&ref_plan=pro-plus>
- Copilot Max：<https://github.com/settings/billing/licensing?ref_product=copilot&ref_type=purchase&ref_style=text&ref_plan=max>
- 學生啟用：<https://github.com/settings/education/benefits>

## 4. 2026 年方案變動

- **2026-03-13**：已有 GitHub Education 福利的學生改到新的 Copilot Student。模型組合一併調整。  
  <https://github.blog/changelog/2026-03-13-updates-to-github-copilot-for-students/>
- **2026-04-20**：暫停 Student、Pro、Pro+ 的新註冊。Copilot Free 仍開放。既有使用者仍可在方案之間升級。Opus 從 Pro 移除，留在 Pro+。  
  <https://github.blog/changelog/2026-04-20-changes-to-github-copilot-plans-for-individuals/>
- **2026-04-27**：宣布 2026-06-01 起，premium request 改為 GitHub AI Credits。一次短問句和一場長時間 agent，不再收同樣的一單位。  
  <https://github.blog/news-insights/company-news/github-copilot-is-moving-to-usage-based-billing/>
- **2026-05-12**：Pro / Pro+ 加入 flex，並推出 Max。6 月 1 日起的個人方案合計用量：Pro $15、Pro+ $70、Max $200。  
  <https://github.blog/news-insights/company-news/github-copilot-individual-plans-introducing-flex-allotments-in-pro-and-pro-and-a-new-max-plan/>
- **2026-06-17**：changelog 標題為個別方案重新開放。GitHub 員工 Pierce Boggan 同日在 X 表示 Student、Pro、Pro+、Max 會在隨後幾週逐步重開。  
  <https://github.blog/changelog/2026-06-17-copilot-individual-plan-sign-ups-are-reopening/>

文件現在仍提供學生啟用步驟，並寫明：教育認證通過，和 Copilot Student 掛上帳號，是兩步。認證後若仍顯示 Free、試用或付費結帳，不要完成購買，等幾天再試；持續只有付費選項再聯絡 GitHub Support。

<https://docs.github.com/en/copilot/how-tos/copilot-on-github/set-up-copilot/enable-copilot/set-up-for-students>

GitHub 每月重評 Copilot 學生資格。Student Developer Pack 的學生驗證本身是兩年，到期要再驗證。兩套時限不要混成同一件事。

## 5. 啟用 Student 之前，本機看到的模型

查法有兩層。

1. CLI 1.0.95 內建目錄 `modelsCatalog()`，來自 `runtime.node`。這是這版 CLI 認識的模型 ID。
2. 用這個帳號的 Copilot 授權呼叫 `capiClientRetrieveModelsForAuth`，讀 GitHub 回給這個帳號的即時目錄。`modelsJson` 是過濾後、標成可在選單選的清單；`unfilteredModelsJson` 是完整目錄。

### 5.1 CLI 內建、說明頁會列出的模型

`helpVisibleModels` 與 `copilot help config` 的 `model` 列舉一致，共 30 個：

- Anthropic：`claude-sonnet-5.5`、`claude-sonnet-5`、`claude-fable-5.1`、`claude-fable-5`、`claude-opus-5.5`、`claude-opus-5`、`claude-opus-4.8`、`claude-opus-4.8-fast`、`claude-sonnet-4.6`、`claude-haiku-5.5`、`claude-haiku-4.5`
- OpenAI：`gpt-6.1-sol`、`gpt-6-sol`、`gpt-6-luna`、`gpt-6-astra`、`gpt-5.6-sol`、`gpt-5.6-terra`、`gpt-5.6-luna`、`gpt-5.5`、`gpt-5.4`、`gpt-5.4-mini`、`gpt-5.3-codex`、`gpt-5-mini`
- 其他：`mai-code-1.1-flash`、`gemini-3.8-flash`、`gemini-3.7-flash`、`grok-4.7`、`grok-4.6`、`grok-4.5`、`kimi-k3`

內建建議模型：`gpt-6.1-sol`、`gpt-6-astra`、`gpt-6-luna`、`claude-opus-5.5`、`claude-sonnet-5.5`。

不進主選單：

- 隱藏：`gpt-5.6-sol-fast`
- 只給子代理：`copilot-search-a/b/c`、`exec-agent-a/b/c`

Auto 的路由檔是 `efficiency`、`balance`、`intelligence`。有長上下文的模型還可以選 `default` 或 `long_context`。

### 5.2 這個帳號的即時目錄

未過濾目錄 46 筆。過濾後可選清單是 **0**。每一筆 `model_picker_enabled` 都是 false。所以 TUI 的 `/model` 沒有可手選的列，實際對話走 Auto。

啟用 Student 之前，政策為啟用、且方案包含 `free` 或沒有方案限制的是：

| 模型 ID | 顯示名稱 | 分類 |
|---|---|---|
| `gpt-6-luna` | GPT-6 Luna | lightweight |
| `gpt-5.6-luna` | GPT-5.6 Luna | lightweight |
| `gpt-5-mini` | GPT-5 mini | lightweight |
| `mai-code-1.1-flash` | MAI-Code-1.1-Flash | lightweight |
| `claude-haiku-4.5` | Claude Haiku 4.5 | lightweight |
| `kimi-k3` | Kimi K3 | powerful |

當時政策停用、且 `restricted_to` 不含 `free` 的包括 Claude Sonnet 5.5 / Sonnet 5、Fable、Opus、Haiku 5.5，以及 GPT-6.1 Sol、GPT-6 Sol、GPT-6 Astra、GPT-5.6 Sol、GPT-5.6 Terra、GPT-5.5、GPT-5.4、GPT-5.4 mini。

CLI 說明有列、這次帳號目錄沒有回傳的是：`claude-sonnet-4.6`、`gpt-5.3-codex`、`gemini-3.8-flash`、`gemini-3.7-flash`、`grok-4.7`、`grok-4.6`、`grok-4.5`。

本機既有 session 顯示 Auto 實際選過 `mai-code-1.1-flash`（MAI-Code-1.1-Flash）和 `gpt-6-luna`（GPT-6 Luna）。一輪使用者對話被記成 1 次 premium request、成本 1.0。

當時本機使用者快取（2026-10-09）的授權：

| 欄位 | 值 |
|---|---|
| `access_type_sku` | `free_limited_copilot` |
| `copilot_plan` | `individual` |
| Chat | 每月 200，剩下 200 |
| Completions | 每月 2,000，剩下 2,000 |
| `premium_interactions` | 0，`has_quota` 為 false |
| `cloud_session_storage_enabled` | false |
| `can_upgrade_plan` | true |
| 配額重設日 | 2026-11-01 |

`copilot_plan: individual` 只表示個人方案這一族，不能用來區分 Free 和 Student。要看的是 `access_type_sku`。

## 6. 啟用 Copilot Student 之後的實測

啟用後重新向 `https://api.github.com/copilot_internal/user` 查詢。快取檔 `~\AppData\Local\copilot\copilot-user-cache.json` 當時仍是 10 月 9 日的 Free 資料，所以已開著的 CLI 要重開才會讀到新方案。即時 API 已經變了。

| | 啟用前 | 啟用後 |
|---|---|---|
| `access_type_sku` | `free_limited_copilot` | `free_educational_quota` |
| 程式碼補全 | 每月 2,000 | 無上限（`unlimited=true`） |
| Chat | 每月 200 | 無上限 |
| `premium_interactions` | 0，沒有配額 | 200，查詢時剩下 200 |
| 雲端 session 儲存 | 關 | 開 |
| 重設日 | 2026-11-01 | 2026-11-01 |
| `can_upgrade_plan` | true | true |
| 手選模型 | 過濾後 0 筆 | 過濾後仍是 0 筆 |

模型政策的變化只有一筆：`gpt-5.4-mini`（GPT-5.4 mini）從停用改成啟用。

啟用後政策為啟用的 7 個：

- Claude Haiku 4.5
- GPT-6 Luna
- GPT-5.6 Luna
- GPT-5.4 mini
- GPT-5 mini
- MAI-Code-1.1-Flash
- Kimi K3

仍停用的抽樣：

| 模型 | 政策 | `restricted_to` |
|---|---|---|
| Claude Sonnet 5.5 | disabled | `pro`、`pro_plus`、`business`、`enterprise`、`max` |
| Claude Opus 5.5 | disabled | `pro_plus`、`business`、`enterprise`、`max` |
| GPT-6.1 Sol | disabled | `pro_plus`、`business`、`enterprise`、`max` |

因此 Student 沒有把 CLI 變成可以自選模型的 Pro。它提高的是補全、Chat 與進階互動的額度，並打開雲端 session 儲存。

## 7. Premium 額度是什麼

上次報告裡的「Premium 額度」指的是 API 欄位 `premium_interactions`，不是 Microsoft 365，也不是那 2,000 次補全。

在這個 Student 帳號上，三個配額是分開的：

| 配額 | 現在 | 用在哪 |
|---|---|---|
| `completions` | 無上限 | 打字時的 inline 補全 |
| `chat` | 無上限 | Chat 那一桶 |
| `premium_interactions` | 每月 200 | 你主動請 Copilot 做事的進階互動 |

Free 時期的 CLI session 把一輪使用者對話記成 1 次 premium request。Student 之後，這類 CLI / agent 回合會從這 200 次扣。補全不扣。

用完不會留到下個月。這個帳號的重設日是 **2026-11-01**。用完之後，進階互動會停，補全還在。Student 是免費方案，這 200 次不能加購。

名稱容易和現在的文件對不上。2026-06-01 起，付費方案改以 **GitHub AI Credits** 計費：依模型的 input、output、cached tokens 計價，1 credit = $0.01 美元。舊的 premium request 是「一次使用者發起的互動」，長短都可能只算一次（再乘模型倍率）。兩種單位不能直接換算。文件仍把 premium request 標成舊制，主要留給 6 月 1 日之後仍留在年約、請求制的 Pro / Pro+。這個帳號的即時配額仍是 200 次 `premium_interactions`，不是 200 credits。

用量頁：<https://github.com/settings/billing>，側欄 AI usage。Copilot 設定頁也能看。

較舊的「About individual plans」頁仍寫 Student 每月 300 premium requests、Free 每月 50。那頁和 6 月之後的 credits 文件不一致。這次以這個帳號 API 的 200 次為準，不以那頁的 300 為準。

## 8. 若還想自己選模型

Student 已經是文件所說的學生方案，而且模型手選仍關著。下一步不是再找學生包，也不是 GitHub Pro 或 Microsoft 365。

- 只想繼續用 Auto、把補全用滿：維持現在的 Copilot Student。
- 要在 CLI `/model` 裡自己選模型：訂 **GitHub Copilot Pro，$10 美元/月**。
- 要這個帳號目錄裡標成 `pro_plus` 的模型（Opus、Fable、GPT-6 Astra、GPT-6 Sol 這類）：看 **Copilot Pro+，$39 美元/月**。2026-04-20 的 changelog 也寫過 Opus 已從 Pro 拿掉。
- 用量持續很高：Copilot Max，$100 美元/月，合計 20,000 credits。

訂的時候用現在這個 GitHub 帳號。若結帳頁暫時沒有某個方案，對照 2026-06-17 的逐步重開，而不是改去訂另一家產品。

## 9. 來源

官方：

- Plans for GitHub Copilot：<https://docs.github.com/en/copilot/get-started/plans>
- 方案與定價頁：<https://github.com/features/copilot/plans>
- 學生免費啟用：<https://docs.github.com/en/copilot/how-tos/copilot-on-github/set-up-copilot/enable-copilot/set-up-for-students>
- 個人用量計費：<https://docs.github.com/copilot/concepts/billing/usage-based-billing-for-individuals>
- 安裝 Copilot CLI：<https://docs.github.com/en/copilot/how-tos/copilot-cli/install-copilot-cli>
- 舊制 premium requests：<https://docs.github.com/en/billing/concepts/product-billing/github-copilot-premium-requests>
- 2026-03-13 學生方案更新：<https://github.blog/changelog/2026-03-13-updates-to-github-copilot-for-students/>
- 2026-04-20 暫停新註冊：<https://github.blog/changelog/2026-04-20-changes-to-github-copilot-plans-for-individuals/>
- 2026-04-27 改為 AI credits：<https://github.blog/news-insights/company-news/github-copilot-is-moving-to-usage-based-billing/>
- 2026-05-12 flex 與 Max：<https://github.blog/news-insights/company-news/github-copilot-individual-plans-introducing-flex-allotments-in-pro-and-pro-and-a-new-max-plan/>
- 2026-06-17 重新開放：<https://github.blog/changelog/2026-06-17-copilot-individual-plan-sign-ups-are-reopening/>

本機量測：

- `copilot` 1.0.95 的 `copilot help config` 與 `runtime.node` 的 `modelsCatalog()`
- `GET https://api.github.com/copilot_internal/user`（啟用前後）
- `capiClientRetrieveModelsForAuth` 的過濾與未過濾模型目錄
- `~\AppData\Local\copilot\copilot-user-cache.json`（啟用前快取，2026-10-09）
- `~\.copilot\session-state\` 裡既有 session 的 Auto 路由紀錄

X 上的學生福利貼文用來對照常見誤解，不當作方案內容的依據。方案內容以 GitHub 文件、changelog，以及這個帳號的即時 API 為準。
