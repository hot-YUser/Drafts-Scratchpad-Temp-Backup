# Pi Coding Agent (`@earendil-works/pi-coding-agent`) 跨機可重現初始化配置與實戰攻略

> **給 AI Agent 的執行指令（Agent Execution Contract）**
> 當使用者在新電腦將本文件交給你並要求「幫我配置好 Pi」時，請直接依序執行本文件的 **Step 1 ～ Step 6**，並遵守以下四條鐵律：
> 1. **嚴禁預設鎖定任何模型**：`~/.pi/agent/settings.json` 內**不得**寫入 `defaultProvider`、`defaultModel`、`defaultThinkingLevel` 或 `enabledModels`，模型選擇權 100% 留給使用者自行透過 `/model` 與 `/scoped-models` 決定。
> 2. **供應商只留 OpenCode (`opencode-go`)**：若新電腦存在 `~/.omp/agent/agent.db`，僅同步 `opencode-go` 的憑證至 `~/.pi/agent/auth.json`；**不得**同步其他供應商，也**不得**建立自訂 `models.json`。若無 `.omp` 資料庫，保留空 `{}` 並提示使用者執行 `/login`。
> 3. **`auto-router.ts` 維持零初始值**：部署 `~/.pi/agent/extensions/auto-router.ts` 時，**不得**預先建立 `auto-router.json`。在還沒跑過 `/auto-config` 之前，不得在模型清單註冊出 `router/auto`。
> 4. **所有檔案強制使用 UTF-8（無 BOM）+ LF 換行寫入**：Windows 下嚴禁使用預設 ANSI / CP950 / GB18030 編碼，否則 `pi` 以 `fs.readFileSync(path, "utf-8")` 讀取 `AGENTS.md` 時會將繁體中文全部解碼為 `U+FFFD` 亂碼。

---

## Step 1：安裝或確認 Pi CLI 環境

1. 檢查本機是否已安裝 `pi`（需 Node.js 22.19+）：
   ```bash
   pi --version
   ```
2. 若尚未安裝，依作業系統執行官方安裝命令：
   ```powershell
   # Windows (PowerShell)
   powershell -c "irm https://pi.dev/install.ps1 | iex"
   ```
   ```bash
   # macOS / Linux
   curl -fsSL https://pi.dev/install.sh | sh
   ```
   ```bash
   # 或透過 npm 全域安裝
   npm install -g --ignore-scripts @earendil-works/pi-coding-agent
   ```

---

## Step 2：寫入全域工程守則 `~/.pi/agent/AGENTS.md`（UTF-8 無 BOM）

建立目錄 `~/.pi/agent/`，並將以下內容以 **UTF-8（無 BOM，LF 換行）** 寫入 `~/.pi/agent/AGENTS.md`：

````markdown
# System Prompt: Core Engineering Philosophy & Guardrails

## 零、全局語言與輸出規範 (Global Language Standard)
- **繁體中文至上**：專案中的各個角落能用繁中就用繁中，包括與我的對話交談、說明、提交、發布等（程式碼運行相關除外，函式、變數必須全英文）。
- **結構除臭**：直球講結論與事實。禁止客服寒暄、段落結尾昇華、假對比（不是 X 而是 Y）、自問自答與對稱的三連排比。
- **語法潔癖**：不用破折號（——）、不用「進行＋動詞」、不堆疊「被」字句與長「的」字鏈；用具體的人事物當主詞。
- **詞彙黑名單**：嚴禁中國用語與商業黑話（如：賦能、閉環、抓手、落地、底層邏輯、視頻、信息、優化）。

## 一、專案工程哲學 (Project Engineering Philosophy)
我們追求極致的代碼品質與長期可維護性。請以「這套系統需穩定運行且易於擴展三年以上」的視角進行每一次設計與修改。

1. **The "Ponytail" Standard (馬尾哲學：極致優雅的懶惰)**
   - 真實的「懶惰」是寫出**一次到位、完美雙贏的架構**，從而消除未來的維護成本。
   - 拒絕「為 DRY 而 DRY」的醜陋妥協（如：傳遞過多狀態參數、寫出深層嵌套的 if/else 義大利麵代碼）。
   - 當面對複雜度增加時，大膽引入合適的設計模式（如 Visitor, Strategy, Factory）來優雅解耦，而非在爛架構上打補丁。

2. **Long-term over Short-term (長遠勝於苟且)**
   - 優先考慮長期的擴展性與 Clean Code，絕不接受留下技術債的「Quick Fix」或「Workaround」。
   - 離開營地時，必須比發現時更乾淨（童子軍法則）。在實作新功能時，主動識別並重構周圍的技術債。

3. **Test-Driven Refactoring (有防護網的大膽重構)**
   - 不要害怕修改核心或大量程式碼。如果現有寫法違反 SOLID 原則，請大膽提出徹底重構的方案。
   - **重構的唯一鐵律**：在大刀闊斧修改前，必須先確保或補足防護網鎖定現有行為。
   - 測試的馬尾原則：拒絕冗餘的測試 Boilerplate。如果是獨立邏輯或小工具，以一個極簡、免框架的 Runnable Check (如 assert 腳本) 鎖定行為即可；只有在面對牽涉複雜外部依賴（如 DB、API）的核心業務時，才使用專案既有的測試框架補齊單元/特徵測試。

---

## 二、核心行為準則 (Core Behavioral Guardrails)
跳脫繁瑣的教條，在任何任務中嚴格遵守以下四條紅線：

1. **求真與審慎 (Truth & Prudence)**
   - 絕不瞎猜臆想業務邏輯，絕不假裝理解或編造不存在的 API/套件。
   - 當需求模糊、資訊不足，或發現改動範圍超出預期時，立即暫停並主動向人類確認。

2. **合理抽象 vs 盲目重用 (Smart Abstraction)**
   - 鼓勵複用現有模組，但**拒絕削足適履**。若現有架構已無法優雅支撐新需求，請提議重構，而非強行擴展（避免破壞單一職責原則）。
   - 避免盲目造輪子，但允許為了消除技術債而創造新的、更高維度的介面與抽象。

3. **嚴謹驗證 (Rigorous Verification)**
   - 程式碼必須經過驗證，絕不跳過校驗或敷衍輸出。
   - 確保你的每一個修改都能在邏輯上自洽，並經得起嚴格的 Code Review。

---

## 三、Git Commit Policy
- 完成每個 logical unit of work（例如一個功能、一個 bug fix、一段重構、一個測試通過）後就自動 commit。
- 嚴格使用 Conventional Commits 格式（如 `feat:`, `fix:`, `refactor:`, `test:`, `chore:` 等）。
- **Commit 語文規定**：前綴類型（Type）與範圍（Scope）保持英文，但**描述（Description）與本體（Body）請使用繁體中文**。
  - 範例：`feat(api): 新增使用者登入的 JWT 驗證端點`
  - 範例：`refactor(redaction): 透過 Visitor 模式重構並整併 walkers`
- 保持合理的提交粒度，避免過於瑣碎的 tiny edits 污染歷史紀錄，也避免包含多個不相關改動的巨型 commit。

---

# 四、 開發信條 (The Geek Creed)

> **極致的快速、小巧的精緻、刀鋒般的邏輯。**

以極客精神為傲，對「快速、小巧、原生」有絕對且偏執的渴望。無情剔除一切抽象稅（Abstraction Tax）與臃腫封裝。

## 準則

1. **極致底層與零依賴預設 (Raw Native by Default)**
   - **越底層越好**：預設以零第三方依賴、最貼近底層（OS API / 語言標準庫 / 平台原生基元）的方式直球解決問題。能用幾十行乾淨的原生代碼搞定，就絕不引入第三方庫。
   - **榨乾平台原生能力**：真正的「小巧」，是把平台內建與官方基元（Official Primitives）的能力壓榨到極限，而非在應用層自己手搓笨拙的替代邏輯。

2. **極客的依賴潔癖：只向「經典」低頭 (Bow Only to Masterpieces)**
   - 拒絕平庸的輪子：**嚴禁**引入新建、低星、未經時間殘酷考驗的「野生第三方專案」。
   - 尊重殿堂級工程：當面對高複雜度領域，或該生態系已有公認的**官方標準 / 社群殿堂級經典（De Facto Standards）**時，請直接使用它們。不寫無意義的重複代碼去對抗已經做到極致的權威標準，也是極簡主義的一環。

3. **小與快是第一級指標 (Size & Speed First)**
   - 產物體積、啟動速度、記憶體佔用不是事後優化，是設計的起點。願意為了極致的執行效率與精悍體積，捨棄笨重的開發者便利性框架。

4. **刀鋒般的邏輯與誠實取捨 (Razor-Sharp Logic)**
   - 短、直白、可讀。快速小巧 ≠ 潦草；不為壓行數而犧牲正確性與架構美感。
   - 誠實標注產物的體積、啟動表現、依賴純淨度，以及為了追求極致小快所做的權衡。
````

---

## Step 3：寫入核心設定 `~/.pi/agent/settings.json`

寫入 `~/.pi/agent/settings.json`（注意：若在 macOS / Linux 環境，請移除 `shellPath` 欄位；在 Windows 則指向 Git Bash `C:\\Program Files\\Git\\bin\\bash.exe`）：

```json
{
  "$schema": "https://pi.dev/schemas/settings.schema.json",
  "defaultTools": [
    "+grep",
    "+find",
    "+ls",
    "+codemode",
    "+tool_search"
  ],
  "cacheWarming": "idle",
  "showCacheMissNotices": true,
  "shellPath": "C:\\Program Files\\Git\\bin\\bash.exe",
  "autocompleteMaxVisible": 12,
  "collapseChangelog": true,
  "enableInstallTelemetry": false,
  "enableAnalytics": false,
  "terminal": {
    "showTerminalProgress": true,
    "clearOnShrink": true
  }
}
```

### 各設定項目的實質作用：
- **`defaultTools`**：在預設 `read`, `bash`, `edit`, `write` 之上，解鎖官方內建但預設封印的 `grep`、`find`、`ls`、**`codemode`（QuickJS WebAssembly 沙盒批次腳本執行）** 與 **`tool_search`（動態搜尋延遲載入的 MCP 工具）**。
- **`cacheWarming: "idle"` + `showCacheMissNotices: true`**：閒置 30 分鐘內若預估能省超過 $0.05 美金，自動在背景保溫 Prompt Cache；當發生重大 Cache Miss 或壓縮時主動提示。
- **`terminal.showTerminalProgress: true`**：啟用 OSC 9;4 終端機分頁與工作列進度環（Windows Terminal 原生支援）。
- **`terminal.clearOnShrink: true`**：消除 TUI 收合輸出時的殘影。
- **`enableInstallTelemetry: false` / `enableAnalytics: false`**：關閉背景遙測回報。

---

## Step 4：寫入零初始值雙軌路由器 `~/.pi/agent/extensions/auto-router.ts`

建立 `~/.pi/agent/extensions/auto-router.ts`（**不要建立 `auto-router.json`**，讓它在未設定前完全隱形，待使用者自行執行 `/auto-config` 時才註冊 `router/auto`）：

```typescript
/**
 * Configurable Auto Router Extension (Zero-Default)
 *
 * Does NOT register any virtual model until configured by the user via `/auto-config`.
 * Run `/auto-config` to pick Planning & Implementation models, or `/auto-config off` to remove it.
 */

import { existsSync, readFileSync, unlinkSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext, ModelRoute, ModelRouteRequest } from "@earendil-works/pi-coding-agent";
import { getAgentDir } from "@earendil-works/pi-coding-agent";

const VIRTUAL_PROVIDER = "router";
const VIRTUAL_ID = "auto";
const EDIT_TOOLS: Record<string, true> = { edit: true, write: true };

interface AutoRouterConfig {
	plan: string;
	impl: string;
}

interface RouteState {
	phase: "planning" | "implementation";
	target: string;
}

function loadConfig(): AutoRouterConfig | undefined {
	const configPath = join(getAgentDir(), "auto-router.json");
	if (!existsSync(configPath)) return undefined;
	try {
		const raw = JSON.parse(readFileSync(configPath, "utf-8")) as Partial<AutoRouterConfig>;
		if (typeof raw.plan === "string" && raw.plan.includes("/") && typeof raw.impl === "string" && raw.impl.includes("/")) {
			return { plan: raw.plan, impl: raw.impl };
		}
		return undefined;
	} catch {
		return undefined;
	}
}

function parseModelRef(ref: string): { provider: string; id: string } | undefined {
	const slash = ref.indexOf("/");
	if (slash <= 0 || slash === ref.length - 1) return undefined;
	return { provider: ref.slice(0, slash), id: ref.slice(slash + 1) };
}

function resolvePhysicalModel(
	request: ModelRouteRequest<RouteState>,
	ctx: ExtensionContext,
	targetRef: string,
	state?: RouteState,
): ModelRoute<RouteState> {
	const parsed = parseModelRef(targetRef);
	const model = parsed ? ctx.modelRegistry.find(parsed.provider, parsed.id) : undefined;
	if (!model) {
		throw new Error(`找不到目標模型 "${targetRef}"，請執行 /auto-config 重新選擇。`);
	}
	return { model, thinkingLevel: request.thinkingLevel, state };
}

function registerRouterModel(pi: ExtensionAPI, config: AutoRouterConfig): void {
	pi.registerVirtualModel<RouteState>({
		provider: VIRTUAL_PROVIDER,
		id: VIRTUAL_ID,
		name: `Auto (${config.plan} -> ${config.impl})`,
		thinkingLevels: ["off", "minimal", "low", "medium", "high", "xhigh", "max"],
		route(request, ctx) {
			const current = loadConfig();
			if (!current) {
				throw new Error("尚未設定 Auto 路由模型，請先執行 /auto-config。");
			}
			if (request.reason === "direct") {
				return resolvePhysicalModel(request, ctx, current.impl);
			}
			const state = request.state;
			if (!state) {
				return resolvePhysicalModel(request, ctx, current.plan, {
					phase: "planning",
					target: current.plan,
				});
			}
			const lastUser = request.messages.findLastIndex((m) => m.role === "user");
			const editedThisTurn = request.messages
				.slice(lastUser + 1)
				.some((m) => m.role === "toolResult" && EDIT_TOOLS[m.toolName] && !m.isError);
			if (state.phase === "planning" && editedThisTurn) {
				return resolvePhysicalModel(request, ctx, current.impl, {
					phase: "implementation",
					target: current.impl,
				});
			}
			return resolvePhysicalModel(request, ctx, state.target, state);
		},
	});
}

export default function (pi: ExtensionAPI): void {
	const initial = loadConfig();
	if (initial) {
		registerRouterModel(pi, initial);
	}

	pi.registerCommand("auto-config", {
		description: "設定或關閉 Auto 雙軌路由模型 (/auto-config | /auto-config status | /auto-config off)",
		handler: async (args, ctx) => {
			const configPath = join(getAgentDir(), "auto-router.json");
			const current = loadConfig();
			const parts = args.trim().split(/\s+/).filter(Boolean);

			if (parts[0] === "off" || parts[0] === "clear") {
				if (existsSync(configPath)) unlinkSync(configPath);
				pi.unregisterVirtualModel(VIRTUAL_PROVIDER, VIRTUAL_ID);
				ctx.ui.notify("已關閉並移除 router/auto 虛擬模型。", "info");
				return;
			}

			if (parts[0] === "status") {
				if (!current) {
					ctx.ui.notify("目前未設定 Auto 路由（未註冊任何虛擬模型）。執行 /auto-config 即可挑選模型。", "info");
				} else {
					ctx.ui.notify(
						`目前 router/auto 設定：\n• 規劃階段 (Plan): ${current.plan}\n• 實作階段 (Impl): ${current.impl}`,
						"info",
					);
				}
				return;
			}

			if (!ctx.hasUI) return;

			const available = ctx.modelRegistry
				.getAvailable()
				.filter((m) => !(m.provider === VIRTUAL_PROVIDER && m.id === VIRTUAL_ID))
				.map((m) => `${m.provider}/${m.id}`);

			if (available.length === 0) {
				ctx.ui.notify("目前沒有已認證的可用模型，請先執行 /login。", "warning");
				return;
			}

			const planChoice = await ctx.ui.select(
				`[1/2] 選擇「規劃階段 (Planning)」模型${current ? ` (目前: ${current.plan})` : ""}`,
				available,
			);
			if (!planChoice) return;

			const implChoice = await ctx.ui.select(
				`[2/2] 選擇「實作階段 (Implementation - 首次改檔後切換)」模型${current ? ` (目前: ${current.impl})` : ""}`,
				available,
			);
			if (!implChoice) return;

			const next: AutoRouterConfig = { plan: planChoice, impl: implChoice };
			writeFileSync(configPath, `${JSON.stringify(next, null, 2)}\n`, "utf-8");
			registerRouterModel(pi, next);
			ctx.ui.notify(
				`已啟用 router/auto 虛擬模型（可用 /model 選取）：\n• 規劃階段：${next.plan}\n• 實作階段：${next.impl}`,
				"info",
			);
		},
	});
}
```

---

## Step 5：一鍵部署官方內建擴充套件、Subagent 角色與 Prompt 指令

執行以下 Node.js 腳本，它會自動定位本機 `@earendil-works/pi-coding-agent` 安裝目錄下的 `examples/extensions/`，完成三件事：
1. 部署 **8 個官方零依賴擴充**：`plan-mode/`（目錄型）、`subagent/`（目錄型）、`questionnaire.ts`、`git-checkpoint.ts`、`handoff.ts`、`permission-gate.ts`、`protected-paths.ts`、`notify.ts`（刻意排除與 `plan-mode` 撞 `/todos` 指令的 `todo.ts`）。
2. 部署 **4 個 Subagent 角色定義**（`scout.md`, `planner.md`, `reviewer.md`, `worker.md`）至 `~/.pi/agent/agents/`，並**自動剔除官方範本寫死的 `model: claude-...`**，使子代理自動繼承主視窗當前選用的模型。
3. 部署 **4 個工作流指令**（`/implement`、`/scout-and-plan`、`/implement-and-review`、`/deslop`）至 `~/.pi/agent/prompts/`。

```javascript
// 儲存為 setup-pi-extensions.mjs 並執行：node setup-pi-extensions.mjs
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { execSync } from "node:child_process";

const home = os.homedir();
const piAgentDir = path.join(home, ".pi", "agent");

// 自動尋找 @earendil-works/pi-coding-agent 的安裝路徑
const npmRoot = execSync("npm root -g", { encoding: "utf8" }).trim();
const pkgDir = path.join(npmRoot, "@earendil-works", "pi-coding-agent");
const extSrcDir = path.join(pkgDir, "examples", "extensions");

if (!fs.existsSync(extSrcDir)) {
	throw new Error(`找不到官方範例擴充目錄：${extSrcDir}`);
}

const extDest = path.join(piAgentDir, "extensions");
const agentsDest = path.join(piAgentDir, "agents");
const promptsDest = path.join(piAgentDir, "prompts");

fs.mkdirSync(path.join(extDest, "plan-mode"), { recursive: true });
fs.mkdirSync(path.join(extDest, "subagent"), { recursive: true });
fs.mkdirSync(agentsDest, { recursive: true });
fs.mkdirSync(promptsDest, { recursive: true });

// 1. 複製單檔型官方擴充
for (const file of [
	"questionnaire.ts",
	"git-checkpoint.ts",
	"handoff.ts",
	"permission-gate.ts",
	"protected-paths.ts",
	"notify.ts",
]) {
	fs.copyFileSync(path.join(extSrcDir, file), path.join(extDest, file));
}

// 2. 複製目錄型官方擴充 (plan-mode & subagent)
for (const file of ["index.ts", "utils.ts"]) {
	fs.copyFileSync(path.join(extSrcDir, "plan-mode", file), path.join(extDest, "plan-mode", file));
}
for (const file of ["index.ts", "agents.ts"]) {
	fs.copyFileSync(path.join(extSrcDir, "subagent", file), path.join(extDest, "subagent", file));
}

// 3. 複製 Subagent 角色檔並移除寫死的 model 欄位（改為自動繼承當前 Session 模型）
for (const file of ["scout.md", "planner.md", "reviewer.md", "worker.md"]) {
	let content = fs.readFileSync(path.join(extSrcDir, "subagent", "agents", file), "utf8");
	content = content.replace(/^model:\s*.+\r?\n/m, "").replace(/\r\n/g, "\n");
	fs.writeFileSync(path.join(agentsDest, file), content, "utf8");
}

// 4. 複製 Subagent 工作流 Prompts 並建立 /deslop
for (const file of ["implement.md", "scout-and-plan.md", "implement-and-review.md"]) {
	fs.copyFileSync(path.join(extSrcDir, "subagent", "prompts", file), path.join(promptsDest, file));
}

const deslopMd = `---
description: 消除剛完成程式碼中的過度抽象、單次 Helper 與防禦性冗碼 (Deslop)
---
通讀本次變更涉及的所有檔案（完整讀取，勿僅看片段），在不改變預期外部行為的前提下精煉實作：

1. 移除沒有明確職責或未降低真實複雜度的多餘抽象、Wrapper 與只被呼叫一次的單行 Helper。
2. 移除信任邊界內多餘的防禦性檢查（對已有型別保證的內部參數不寫 typeof / instanceof / Array.isArray）；只在真正的輸入邊界驗證。
3. 收緊型別定義，消除 any、不必要轉型與過度寬鬆的 optional 欄位。
4. 刪除僅重複敘述程式碼表面的廢話註解，只保留解釋「為什麼（權衡、邊界條件、不變量）」的註解。
5. 修改後執行專案的檢查或測試驗證，並回報精簡了哪些部分。
`;
fs.writeFileSync(path.join(promptsDest, "deslop.md"), deslopMd, "utf8");

console.log("✅ 官方擴充、Subagent 角色與 Prompt 模板部署完成！");
```

---

## Step 6：（可選）從本機 `.omp` 單獨同步 `opencode-go` 認證與 MCP

若新電腦已安裝並登入過 `oh-my-pi` (`~/.omp/agent/`)，執行以下腳本可將 **`opencode-go` 單一供應商憑證**與 **`mcp.json`** 同步至 `~/.pi/agent/`（若無 `.omp`，請跳過此步並直接在 `pi` 內執行 `/login`）：

```javascript
// 儲存為 sync-omp-to-pi.mjs 並執行：node sync-omp-to-pi.mjs
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { DatabaseSync } from "node:sqlite";

const home = os.homedir();
const ompAgentDir = path.join(home, ".omp", "agent");
const piAgentDir = path.join(home, ".pi", "agent");

// 1. 僅同步 opencode-go 的 API Key
const dbPath = path.join(ompAgentDir, "agent.db");
if (fs.existsSync(dbPath)) {
	const db = new DatabaseSync(dbPath, { readOnly: true });
	const rows = db
		.prepare(
			"SELECT data FROM auth_credentials WHERE provider = 'opencode-go' AND credential_type = 'api_key' AND disabled_cause IS NULL ORDER BY updated_at ASC",
		)
		.all();
	if (rows.length > 0) {
		const latest = JSON.parse(rows[rows.length - 1].data);
		if (latest.key) {
			const authPath = path.join(piAgentDir, "auth.json");
			fs.writeFileSync(
				authPath,
				JSON.stringify({ "opencode-go": { type: "api_key", key: latest.key } }, null, 2) + "\n",
				{ encoding: "utf8", mode: 0o600 },
			);
			console.log("✅ 已將 opencode-go 憑證同步至 ~/.pi/agent/auth.json");
		}
	}
}

// 2. 同步 mcp.json（如存在）
const ompMcpPath = path.join(ompAgentDir, "mcp.json");
if (fs.existsSync(ompMcpPath)) {
	fs.copyFileSync(ompMcpPath, path.join(piAgentDir, "mcp.json"));
	console.log("✅ 已將 mcp.json 同步至 ~/.pi/agent/mcp.json");
}
```

---

## Step 7：驗收檢查清單（Verification）

配置完成後，AI Agent 必須依序執行以下指令確認零報錯：

1. **檢查 `AGENTS.md` 編碼是否為純淨 UTF-8（無 `U+FFFD` 亂碼）**：
   ```bash
   node -e 'const fs=require("fs"),os=require("os"),p=require("path");const t=fs.readFileSync(p.join(os.homedir(),".pi/agent/AGENTS.md"),"utf8");if(t.includes("\ufffd"))throw new Error("Invalid UTF-8!");console.log("UTF-8 OK");'
   ```
2. **檢查擴充套件是否成功載入（`--plan` 旗標應出現在 `--help` 中）**：
   ```bash
   pi --help | grep -- "--plan"
   ```
3. **檢查模型列表是否僅包含 `opencode-go` 且無未授權的預設 `auto` 模型**：
   ```bash
   pi --list-models
   ```

---

## 附錄：日常操作與進階功能速查表（Cheat Sheet）

### 1. 核心快捷鍵與執行中操控
| 動作 | macOS / Linux | Windows / WSL | 說明 |
|---|---|---|---|
| **選模型 / 設為預設** | `Ctrl+L` → `Ctrl+S` | `Ctrl+L` → `Ctrl+S` | 打開 `/model` 選單，對中意的模型按 `Ctrl+S` 存為預設 |
| **常用模型快切轉盤** | `/scoped-models` | `/scoped-models` | 勾選幾顆主力模型並按 `Ctrl+S` 後，用 **`Ctrl+P`** / **`Alt+P`** 秒切 |
| **切換思考深度** | `Shift+Tab` | `Shift+Tab` | 循環切換 `off` → `minimal` → `low` → `medium` → `high` → `xhigh` → `max` |
| **執行中插話轉向** | `Enter` | `Enter` | 等當前這一步 Tool 跑完，立刻插隊引導下一步 |
| **執行中排入待辦** | `Alt+Enter` | **`Ctrl+Q`** | 不打斷當前任務，排入佇列等整件事做完才接著跑 |
| **收回排隊訊息** | `Alt+Up` | **`Alt+Q`** | 把排隊中的訊息拉回輸入框重改 |
| **外部編輯器寫長文** | `Ctrl+G` | `Ctrl+G` | 呼叫 `$EDITOR`（如 VS Code）撰寫長 Prompt |
| **終端機跑指令** | `!cmd` / `!!cmd` | `!cmd` / `!!cmd` | `!` 輸出會餵給 AI 看；`!!` 純自己看（不進 Context、不耗 Token） |
| **展開工具 / 思考** | `Ctrl+O` / `Ctrl+T` | `Ctrl+O` / `Ctrl+T` | 展開或收合冗長的 Tool 輸出 / Thinking 區塊 |
| **打開對話樹時光機** | 連按兩下 `Esc` 或 `/tree` | 連按兩下 `Esc` 或 `/tree` | 跳回過去的節點改寫提問並長出新分支（自動濃縮舊分支經驗） |

### 2. 已部署的擴充功能與 `/` 快捷指令
| 指令 / 快捷鍵 | 功能說明 |
|---|---|
| **`Ctrl+Alt+P`** 或 **`/plan`** | **切換唯讀規劃模式**。自動鎖住 `edit`/`write` 並限制 `bash` 為唯讀白名單；AI 產出 `Plan:` 步驟並經你確認執行後，底部顯示即時進度條（可用 `/todos` 查看）。 |
| **`/scout-and-plan <需求>`** | 派 `scout` 子代理快速探勘程式碼，再交給 `planner` 子代理產出結構化施工藍圖（純規劃不動手）。 |
| **`/implement <需求>`** | `scout` 探勘 → `planner` 規劃 → `worker` 在獨立 Context 子行程完成實作。 |
| **`/implement-and-review <需求>`** | `worker` 實作 → `reviewer` 跑 `git diff` 審查抓蟲 → `worker` 修正。 |
| **`/handoff <下一階段目標>`** | 討論完架構後，將當前對話的決策與相關檔案提煉成自包含 Prompt，自動開一個乾淨的新 Session。 |
| **`/deslop`** | 完工後一鍵要求 AI 通讀變更檔案，砍掉單次 Helper、移除信任邊界內多餘的防禦性檢查並收緊型別。 |
| **`/auto-config`** | 互動挑選「規劃模型」與「實作模型」並啟用 `router/auto` 虛擬模型；輸入 **`/auto-config off`** 即可隨時移除。 |
| **`/fork`** | 從歷史節點分叉出新 Session，並由 `git-checkpoint` 擴充自動詢問是否**連同程式碼狀態一起還原到當時的快照**。 |
| **`/trust`** | 授權或撤銷當前專案目錄載入本地 `.pi/` 資源的權限（儲存於 `~/.pi/agent/trust.json`）。 |
| **`/reload`** | 修改設定檔、Prompts、Skills、Extensions 或 MCP 後免重開即刻生效。 |
