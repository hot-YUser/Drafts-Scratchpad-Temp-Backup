## 來源說明

依據 [code.claude.com/docs](https://code.claude.com/docs/en/commands) 的 `commands`、`skills`、`discover-plugins`、`plugins-reference` 等頁面彙整（https://code.claude.com/docs/llms.txt）。

**關鍵澄清**：官方市集實際名稱是 **`claude-plugins-official`**（開機即自動可用），文件中並沒有叫「anthropic-skills」的市集。「anthropic-skills」是官方文件處理技能所用的**外掛命名空間**——第 3 類清單是我從本次 session 實際載入的技能核對取得，並非逐字擷取自某一頁文件。

---

## ① 純內建指令（87 個）

行為直接寫死在 CLI 裡，非 prompt 型（`/init`、`/review`、`/security-review` 三者例外，同時也開放給 Skill 工具呼叫）。

| 指令 | 用途 |
|---|---|
| `/add-dir <path>` | 為目前工作階段新增可存取的工作目錄 |
| `/advisor [model\|off]` | 開啟／關閉顧問工具，於關鍵時刻諮詢第二個模型 |
| `/agents` | 提示建立或管理子代理（或編輯 `.claude/agents/`） |
| `/autofix-pr [prompt]` | 啟動雲端工作階段，CI 失敗或收到審查意見時自動推送修正 |
| `/background [prompt]`（別名 `/bg`） | 將工作階段轉為背景代理，釋放終端機 |
| `/branch [name]` | 在目前對話節點建立分支 |
| `/btw <question>` | 快速提問，不寫入對話紀錄 |
| `/cd <path>` | 切換工作目錄 |
| `/chrome` | 設定 Claude in Chrome |
| `/clear [name]`（別名 `/reset`、`/new`） | 以空白上下文開始新對話 |
| `/color [color\|default]` | 設定提示列顏色 |
| `/compact [instructions]` | 摘要對話以釋放上下文空間 |
| `/config [key=value]`（別名 `/settings`） | 開啟設定介面（主題、模型、輸出樣式等） |
| `/context [all]` | 以色塊視覺化上下文使用量 |
| `/copy [N]` | 複製最後一則回覆到剪貼簿 |
| `/cost` | `/usage` 的別名 |
| `/design-login` | 為 `/design-sync` 授權 claude.ai 帳號 |
| `/desktop`（別名 `/app`） | 於桌面應用程式中繼續工作階段 |
| `/diff` | 互動式差異檢視器，顯示未提交變更 |
| `/effort [level\|auto]` | 設定模型推理強度 |
| `/exit`（別名 `/quit`） | 結束 CLI |
| `/export [filename]` | 將對話匯出為純文字 |
| `/fast [on\|off]` | 切換快速模式 |
| `/feedback [report]`（別名 `/bug`、`/share`） | 提交回饋、回報錯誤或分享對話 |
| `/focus` | 切換聚焦檢視 |
| `/fork <directive>` | 產生繼承完整對話的背景子代理 |
| `/goal [condition\|clear]` | 設定目標，跨輪次持續工作直到達成 |
| `/heapdump` | 產生 JS 堆積快照診斷記憶體用量 |
| `/help` | 顯示說明與可用指令 |
| `/hooks` | 檢視 hook 設定 |
| `/ide` | 管理 IDE 整合狀態 |
| `/init` | 以 CLAUDE.md 初始化專案（亦可經 Skill 工具呼叫） |
| `/insights` | 產生工作階段使用分析報告 |
| `/install-github-app` | 為儲存庫安裝 Claude GitHub App |
| `/install-slack-app` | 安裝 Claude Slack 應用程式 |
| `/keybindings` | 開啟鍵盤快捷鍵設定檔 |
| `/login` / `/logout` | 登入／登出 Anthropic 帳號 |
| `/mcp` | 管理 MCP 伺服器連線與 OAuth |
| `/memory` | 編輯 CLAUDE.md 記憶檔、開關自動記憶 |
| `/mobile`（別名 `/ios`、`/android`） | 顯示下載 App 的 QR code |
| `/model [model]` | 切換並儲存預設模型 |
| `/passes` | 分享免費體驗週（視帳號資格） |
| `/permissions`（別名 `/allowed-tools`） | 管理工具權限允許／詢問／拒絕規則 |
| `/plan [description]` | 直接從提示進入計畫模式 |
| `/plugin [subcommand]` | 管理外掛（安裝、市集、啟停用） |
| `/powerup` | 互動式短課程探索功能 |
| `/pr-comments [PR]` | *已於 v2.1.91 移除* |
| `/privacy-settings` | 隱私設定（限 Pro/Max） |
| `/radio` | 開啟 Claude FM 電台 |
| `/recap` | 產生目前工作階段一行摘要 |
| `/release-notes` | 互動版本選擇器檢視變更紀錄 |
| `/reload-plugins [--force]` | 重新載入所有啟用中外掛 |
| `/reload-skills` | 重新掃描技能／指令目錄 |
| `/remote-control`（別名 `/rc`） | 讓工作階段可從 claude.ai 遠端控制 |
| `/remote-env` | 選擇雲端代理預設環境 |
| `/rename [name]` | 重新命名工作階段 |
| `/resume [session]`（別名 `/continue`） | 依 ID／名稱恢復對話 |
| `/review [PR]` | 快速單輪唯讀審查 PR（亦可經 Skill 工具呼叫） |
| `/rewind`（別名 `/checkpoint`、`/undo`） | 回溯對話／程式碼 |
| `/sandbox` | 切換沙盒模式 |
| `/schedule [description]`（別名 `/routines`） | 建立雲端排程 |
| `/scroll-speed` | 調整滑鼠滾輪速度 |
| `/security-review` | 分析分支變更安全弱點（亦可經 Skill 工具呼叫） |
| `/setup-bedrock` / `/setup-vertex` | 設定 Bedrock／Vertex 驗證與模型 |
| `/skills` | 列出可用技能 |
| `/stats` | `/usage` 別名，開啟 Stats 分頁 |
| `/status` | 版本、模型、帳號、連線狀態 |
| `/statusline` | 設定狀態列 |
| `/stickers` | 訂購貼紙 |
| `/stop` | 停止目前背景工作階段 |
| `/tasks`（別名 `/bashes`） | 檢視管理背景執行項目 |
| `/team-onboarding` | 產生團隊導覽指南 |
| `/teleport`（別名 `/tp`） | 將 web 工作階段拉回終端機 |
| `/terminal-setup` | 設定終端機快捷鍵 |
| `/theme` | 變更色彩主題 |
| `/tui [default\|fullscreen]` | 設定終端機 UI 渲染模式 |
| `/ultraplan <prompt>` | 雲端草擬計畫、審閱後執行 |
| `/ultrareview [PR]` | 雲端多代理深度審查（建議改用 `/code-review ultra`） |
| `/upgrade` | 開啟升級頁面 |
| `/usage`（別名 `/cost`、`/stats`） | 花費、方案用量、活動統計 |
| `/usage-credits` | 設定用量額度 |
| `/vim` | *已於 v2.1.92 移除* |
| `/voice [hold\|tap\|off]` | 切換語音輸入 |
| `/web-setup` | 連接 GitHub 帳號到 Claude Code on the web |
| `/workflows` | 開啟工作流程進度檢視 |

---

## ② 隨附技能 Bundled Skills（13 個技能 + 1 個 workflow）

文件原文：「不同於大多數執行固定邏輯的內建指令，隨附技能是 prompt 型的——給 Claude 詳細指示，讓它用工具自行調度工作。」除非用 `disableBundledSkills` 關閉，否則每個工作階段都可用。

| 指令 | 用途 |
|---|---|
| `/batch <instruction>` | 在整個程式庫平行編排大規模變更 |
| `/claude-api [migrate\|…]` | 載入符合專案語言的 Claude API 參考資料 |
| `/code-review [level] […]` | 審查目前 diff 的正確性錯誤與簡化／效率改善機會 |
| `/dataviz [request]` | 圖表、圖形與儀表板設計指引 |
| `/debug [description]` | 啟用除錯紀錄，協助排查工作階段問題 |
| `/design-sync [hint]` | 將 React 設計系統轉換並上傳至 Claude Design |
| `/doctor`（別名 `/checkup`） | 環境健檢，診斷並可自動修復 |
| `/fewer-permission-prompts` | 掃描歷史紀錄，將常見唯讀操作加入允許清單 |
| `/loop [interval] [prompt]`（別名 `/proactive`） | 在工作階段中重複執行提示 |
| `/run` | 啟動並操作應用程式，實際驗證變更是否生效 |
| `/run-skill-generator` | 教會 `/run`、`/verify` 如何建置與啟動此專案 |
| `/simplify [target]` | 審查變更程式碼的重用／簡化機會並套用修正 |
| `/verify` | 實際建置並執行程式確認變更正確，而非只靠測試 |
| `/deep-research <question>`（標記 **[Workflow]**，非 [Skill]） | 展開多重網路搜尋、交叉查核來源，產出附引註報告 |

---

## ③ 官方外掛 anthropic-skills（8 個）

外掛技能以 `外掛名稱:技能名稱` 命名空間呈現，透過 `/plugin` 管理（非 `skillOverrides`）。以下清單直接來自本次 session 實際載入的技能，安裝機制與官方市集 `claude-plugins-official` 一致。

| 技能 | 用途 |
|---|---|
| `anthropic-skills:docx` | 建立、讀取、編輯 Word（.docx）文件 |
| `anthropic-skills:pdf` | 讀取、合併、分割、加浮水印、填表、OCR 等 PDF 操作 |
| `anthropic-skills:pptx` | 建立、讀取、編輯簡報（.pptx） |
| `anthropic-skills:xlsx` | 建立、讀取、編輯試算表（.xlsx/.csv/.tsv） |
| `anthropic-skills:schedule` | 建立或更新自動執行的排程任務 |
| `anthropic-skills:consolidate-memory` | 反思式整理記憶檔案：合併重複、修正過時資訊、精簡索引 |
| `anthropic-skills:skill-creator` | 建立、修改、優化技能，並執行技能評測 |
| `anthropic-skills:setup-cowork` | 導覽設定 Cowork：安裝符合角色的外掛、連接工具 |

---

**其他 Anthropic 維護市集**（供對照）：`claude-community`（第三方、經自動驗證與安全審查）、`claude-code-plugins`（示範用外掛集）。