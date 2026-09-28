# 臺灣河川／水利官方資料使用指南
## 以「輸入經緯度 → 回傳河川資訊」為核心的完整資料說明書

> 版本：2026-09-28（初版）  
> 修訂：2026-09-29 —— 全量 live 實測補充（見文末「修訂誌 2026-09-29」）。18 個 dataset 資源 UUID、
> 筆數／大小、GIC 335 組下載目標實測日期、站況↔即時 join key、x/y 對調 16/11 筆、三格式坑，皆為當日實測。
> 凡標【實測 2026-09-29】者為本次新增／修正；未標者為初版原文。
> 研究範圍：經濟部水利署、水利空間資訊服務平台、政府資料開放平台，以及水利規劃分署「流域環境情報地圖基礎地圖包」所引用之官方資料。  
> 目的：說清楚 **資料從哪裡拿、格式長什麼樣、有哪些欄位、能做什麼、不能做什麼、哪些結果是官方直接值、哪些必須自行推導**。

---

# 1. 先講結論

如果目標是：

```text
輸入：
latitude, longitude

輸出：
這個位置在哪個流域？
最近哪條河？
是主流還是支流？
是否位於河道／中央管河川區域？
距離河流多少？
距河口多少公里？
位於河川的相對位置？
附近有沒有水位站／流量站／雨量站？
目前水位多少？
警戒值是多少？
最近斷面在哪？
能否判斷上游／中游／下游？
```

官方資料已足以完成其中很大一部分。

但必須區分三種結果：

| 類型 | 意義 | 例子 |
|---|---|---|
| **官方直接資料** | 官方資料欄位直接提供 | 河川名稱、河川代碼、流域、幹流長度、治理起終點、水位站觀測值 |
| **由官方圖資推導** | 官方沒有直接給答案，但可用 GIS 計算 | 最近河川、距河川距離、是否落在 polygon、距河口里程、相對河段百分比 |
| **官方不足以統一判定** | 沒有全臺一致、可直接使用的官方答案 | 任意座標的「上游／中游／下游」、任意點即時流速、任意點水深 |

最實用的設計不是只回傳「某某溪」，而是：

```json
{
  "location": {
    "lat": 24.123456,
    "lon": 120.654321
  },
  "river": {
    "name": "大里溪",
    "code": "...",
    "basin": "烏溪流域",
    "hierarchy": "支流"
  },
  "spatial": {
    "distance_to_river_m": 81.3,
    "inside_channel": false,
    "inside_central_river_area": false,
    "distance_from_mouth_km": 17.8,
    "relative_position": 0.43
  },
  "section": {
    "nearest_cross_section": "...",
    "distance_m": 326
  },
  "hydrology": {
    "nearest_water_level_station": "...",
    "latest_water_level_m": 2.31,
    "observed_at": "..."
  },
  "classification": {
    "upstream_midstream_downstream": "中游",
    "classification_method": "derived",
    "confidence": 0.78
  }
}
```

其中每一欄最好再附：

```json
{
  "source": "WRA",
  "source_dataset": "...",
  "source_date": "...",
  "value_type": "official | derived",
  "confidence": 0.0
}
```

這樣系統才能清楚區分「官方事實」與「你的演算法推導」。

---

# 2. 官方資料生態系統

目前與此功能最相關的官方入口有三個。

## 2.1 水利規劃分署：流域環境情報地圖基礎地圖包

官方頁面：

<https://www.wra.gov.tw/wrap/cp.aspx?n=33935>

此資料包不是一支「經緯度查河川 API」。

它是一個 GIS 整合包，官方說明目前整合：

- 63 個實體檔案
- 4 個 WMS
- 16 個 WMTS
- 共 83 個圖層

其中水利署來源佔 37 個實體檔案。

用途是讓使用者以 QGIS / ArcGIS 疊圖分析。

### 適合做什麼

- 快速了解水利署有哪些 GIS 圖資
- 建立 QGIS 專案
- 疊合河川、流域、地形、生態、土地利用等資料
- 當成資料來源索引

### 不適合直接做什麼

- 它本身不是「lat/lon → JSON」服務
- 不應把這個地圖包當唯一資料來源
- 部分內含資料已較舊，真正產品應回頭取得來源平台的最新版本

---

## 2.2 水利空間資訊服務平台

主要入口：

<https://gic.wra.gov.tw/Gis/Gic/DataIndex/Data/Main.aspx>

舊式／公開下載清單：

<https://gic.wra.gov.tw/Gis/gic/API/Google/Index.aspx>

這是最重要的 **GIS 空間圖資來源**。

常見資料型態：

- 點 Point
- 線 LineString / Polyline
- 面 Polygon

可能提供：

- SHP
- KML
- 圖資展示
- 申請取得

### 重要限制

官方平台明確提醒：

1. 地理圖資受製圖數化方法、精度、完成時間、坐標轉換等影響。
2. 與現地狀況可能存在誤差。
3. 平台資料原則上僅供參考，不應直接當作法律證明或權利主張。

因此：

> **「點落在圖形內」不代表在法律上必然成立。**

尤其涉及河川區域、土地管制、開發限制時，必須再確認最新公告、圖籍及主管機關資料。

---

## 2.3 政府資料開放平台 / 水利署 Open Data API

政府資料開放平台：

<https://data.gov.tw/>

水利署 OpenAPI：

<https://opendata.wra.gov.tw/api/v2/openapi.get>

Swagger：

<https://opendata.wra.gov.tw/openapi/swagger/index.html>

大量水利署資料提供：

- CSV
- JSON
- XML
- API
- 資源清冊
- KML / SHP 下載網址

這類資料特別適合：

- 河川基本資料
- 流域基本資料
- 河川代碼
- 測站基本資料
- 即時觀測
- 警戒水位
- 排水基本資料

---

# 3. 你會遇到哪些資料格式

---

## 3.1 CSV

典型形式：

```csv
rivercode,rivername,englishrivername,lengthofmainriver,responsibleauthority
...,大甲溪,Dajia River,...,...
```

優點：

- 最容易解析
- 零 GIS 依賴
- 適合靜態表格、代碼表、測站資料

缺點：

- 一般 CSV 無法完整表示複雜 polygon / line geometry
- 部分「CSV 資料集」實際上只是資源清冊，欄位可能是下載網址，而不是空間圖形本身

---

## 3.2 JSON

典型概念：

```json
[
  {
    "rivercode": "...",
    "rivername": "大甲溪",
    "lengthofmainriver": "...",
    "responsibleauthority": "..."
  }
]
```

適合：

- REST API
- Web backend
- 定期同步
- 快取

注意：

水利署 Open Data API 的實際外層結構與查詢參數應以當下 Swagger / OpenAPI 為準，不要把範例外層結構寫死。

---

## 3.3 XML

與 JSON / CSV 通常是同一批資料的另一種輸出格式。

除非你的既有系統使用 XML，否則一般產品不需要優先選它。

---

## 3.4 ESRI Shapefile（SHP）

一份 Shapefile 通常不是只有 `.shp`：

```text
river.shp   # geometry
river.shx   # geometry index
river.dbf   # attributes
river.prj   # CRS
river.cpg   # encoding（不一定有）
```

一定要把同一組檔案放在一起。

適合：

- 河流線
- 河道 polygon
- 流域 polygon
- 河川區域
- 堤防
- 斷面線
- 測站位置

### 優點

- 成熟
- 廣泛支援
- 很適合本地離線查詢

### 缺點

- 格式老
- DBF 欄名及字串編碼有限制
- 多檔案
- Web 程式通常會先轉成 GeoPackage / FlatGeobuf / GeoJSON / 自訂 binary

---

## 3.5 KML

KML 本質是 XML 地理格式。

概念：

```xml
<Placemark>
  <name>某河川</name>
  <Polygon>
    ...
  </Polygon>
</Placemark>
```

優點：

- 容易在 Google Earth 開啟
- 可表示點、線、面

缺點：

- 對高效本地空間查詢並不是最佳格式
- 大資料量解析效率通常不如專門 GIS 格式

---

## 3.6 WMS

Web Map Service。

本質上是：

> 「伺服器把地圖渲染成圖片給你。」

適合：

- 顯示底圖
- 疊圖
- GIS Viewer

不適合作為：

- 河川拓撲計算
- 最近線段搜尋
- 沿河里程計算

因為你取得的主要是 rendered image，而不是完整 geometry。

---

## 3.7 WMTS

Web Map Tile Service。

本質上是切好的地圖 tile。

用途：

- 快速顯示地圖

不適合：

- 幾何計算
- Point-in-Polygon
- 河網分析

---

## 3.8 WFS / Feature Service 類型

若平台提供 feature 級服務，理論上可直接取得幾何與屬性。

適合：

```text
bbox query
feature query
attribute query
```

但產品設計上若要求：

- 高速
- 高可用
- 不受官方服務中斷影響

仍建議：

```text
官方來源
   ↓ 定期同步
本地資料庫 / 索引
   ↓
自己的 API
```

---

# 4. 座標系統：這是最重要的技術細節之一

使用者通常給：

```text
latitude = 24.12345
longitude = 120.67890
```

這通常視為：

```text
EPSG:4326
WGS84
```

但水利署不少結構化資料欄位會出現：

```text
x_3826
y_3826
```

這代表：

```text
EPSG:3826
TWD97 / TM2 zone 121
```

其單位是：

```text
公尺
```

例如：

```text
x_3826 = 212345.67
y_3826 = 2678912.34
```

而不是：

```text
lon = 120.xxx
lat = 24.xxx
```

---

## 4.1 建議策略

系統 API 對外統一：

```text
EPSG:4326
```

內部進行距離計算時：

```text
EPSG:4326
   ↓ transform
EPSG:3826
   ↓
distance / nearest / buffer
```

原因：

經緯度是角度，不應直接拿來當平面公尺距離計算。

---

# 5. 核心資料集總覽

下面是「經緯度 → 河川資訊」真正有價值的資料。

---

# 6. 河川基本資料

官方：

<https://data.gov.tw/dataset/167895>

【實測 2026-09-29】資源 UUID：`750be3f2-eac0-440d-b1d1-d642f74bb2f3`
（`https://opendata.wra.gov.tw/api/v2/750be3f2-eac0-440d-b1d1-d642f74bb2f3?format=JSON`），
79 筆／約 43.5KB。`data.gov.tw` 的 CKAN API（`api/action`、`openapi/v1`）實測 404，
只能解析 dataset 頁內嵌的資源連結；以下各節 UUID 同理，不再重複說明。

資料名稱：

**河川基本資料**

提供者：

經濟部水利署

內容：

中央管河川基本資料。

常見格式：

- CSV
- JSON
- XML

## 主要欄位

已確認官方欄位包括：

```text
rivercode
rivername
englishrivername
estuary
lengthofmainriver
manageend
manageendx_3826
manageendy_3826
managelength
managestart
managestartx_3826
managestarty_3826
passingcountycode
passingcountyname
responsibleauthority
```

其中重要欄位：

| 欄位 | 意義 |
|---|---|
| `rivercode` | 河川代碼 |
| `rivername` | 河川名稱 |
| `englishrivername` | 河川英文名稱 |
| `estuary` | 入海口 |
| `lengthofmainriver` | 幹流長度 |
| `managestart` | 治理起點 |
| `manageend` | 治理終點 |
| `managelength` | 治理長度，km |
| `*_3826` | TWD97 / TM2 121 座標（⚠見下方 x/y 對調警告） |
| `passingcountyname` | 流經縣市 |
| `responsibleauthority` | 權責單位 |

## 可以得到

- 河川名稱
- 河川代碼
- 英文名稱
- 幹流長度
- 入海口
- 治理起點
- 治理終點
- 治理長度
- 治理點座標
- 流經縣市
- 權責單位

## 【實測 2026-09-29】x/y 對調警告（ingest 必處理）

`managestartx_3826` 全表 0 空值，但 **16 筆的 x 是 y 量級**（x 正常約 16–35 萬；
淡水河 `managestartx_3826="2746208.485"`、y 欄 `"275562.405"`，明顯反了；
蘭陽溪、鳳山溪、頭前溪亦有）；`manageendx_3826` 同樣 **11 筆**（蘭陽溪、鳳山溪、
頭前溪、中港溪、和平溪）。ingest 規則：x 若 >1,000,000 即與 y 互換＋log；
正常範圍 x 約 159,616–350,000、y 約 2,400,000–2,800,000。

## 不能直接得到

- 任意座標在河川的哪一公里
- 上中下游
- 河道 geometry
- 即時水位
- 任意位置水深

---

# 7. 河川代碼

官方：

<https://data.gov.tw/dataset/22228>

【實測 2026-09-29】資源 UUID：`a644fa3e-6406-47e5-a797-dd746d5bb83f`，836 筆／約 509KB。
實測欄位：`basinname/basinrivercode/englishbasinname/englishsubsidiarybasinname/
englishsubsubsidiarybasinname/englishsubsubsubsidiarybasinname/
subsidiarybasinname/subsidiarybasinrivercode/subsubsidiarybasinname/
subsubsidiarybasinrivercode/subsubsubsidiarybasinname/subsubsubsidiarybasinrivercode/
governmentunitidentifier/remarks/wikicode`。
注意主鍵欄叫 `basinrivercode`（不是 `rivercode`），6 碼；`remarks` 常見 `96年版本`／`110年V3調整`；
`wikicode`（如 `Q10878902`）可拿來串維基補英文名／別名。

資料名稱：

**河川代碼**

用途非常重要：

> 建立河川身分與主／支流階層。

官方說明的代碼概念：

```text
共 6 碼
```

前 4 碼：

```text
河川 / 流域
```

後 2 碼：

```text
主流 / 支流 / 次支流階層
```

官方例示規則包含：

```text
00 = 主流
10 = 第 1 條支流
11 = 支流的支流（次支流）
...
```

實際完整編碼規則以最新官方代碼表為準。

## 可以得到

- 統一河川識別碼
- 河川名稱
- 主流／支流之從屬架構
- 建立父子河網 relationship 的依據之一

## 非常重要

不要只用中文河名當 primary key。

同名、別名、歷史命名、支流關係都可能讓純字串比對不穩定。

建議：

```text
river_code = canonical ID
river_name = display name
```

---

# 8. 流域基本資料

官方：

<https://data.gov.tw/dataset/167897>

【實測 2026-09-29】資源 UUID：`25d934ae-ecc4-4952-a05b-7ecc208bfd3a`，27 筆／約 8.9KB。

資料名稱：

**流域基本資料**

主要欄位：

```text
annualrunoff
basinlength
basinname
descriptionoforigin
drainageareaha
englishbasinname
riverbedslope
rivercode
rivername
```

## 可以得到

| 資訊 | 可取得 |
|---|---:|
| 流域名稱 | ✅ |
| 英文流域名 | ✅ |
| 流域面積 | ✅ |
| 主流長度 | ✅ |
| 發源地說明 | ✅ |
| 年逕流量 | ✅ |
| 河床平均坡度 | ✅ |
| 河川代碼 | ✅ |

## 注意

`riverbedslope` 是流域／河川尺度的平均性資訊。

不能直接解讀成：

> 「使用者所在這一點的坡度」。

若要局部坡度，需要：

- DEM
- 河道中心線
- 沿線高程採樣

自行計算。

---

# 9. 河川流域範圍圖

官方：

<https://data.gov.tw/dataset/9823>

空間平台也有：

**河川流域範圍圖**（GIC fname `BASIN`，SHP 直下實測 200 回 2.3MB zip，鏈路通）

geometry：

```text
Polygon
```

【實測 2026-09-29】dataset 9823 是 1 筆**索引**（`1d4d24f4-4745-40e3-b51c-8c422aae4fd7`），
內指 `DownLoad.aspx?fname=BASIN&filetype=SHP`，索引建置 `20201007`。
初版寫「建置 2000」是舊資訊，GIC 清單當日 BASIN 列無日期欄（其他圖層同日多為 2022–2026），
以實際下載的 SHP 內 `建置日期` 欄為準，不要再寫死 2000。

## 核心用途

最直接的功能：

```text
Point(lat, lon)
   ↓
Point-in-Polygon
   ↓
屬於哪個流域
```

例如：

```text
24.123, 120.678
→ 烏溪流域
```

## 可以推導

- 所屬流域
- 是否在某流域
- 距流域邊界
- 多流域附近的位置關係

## 注意

這份空間圖資年代偏舊。

若涉及：

- 最新法定邊界
- 工程設計
- 法律判定

不能只依賴這份舊 polygon。

---

# 10. 河川（支流）線圖

水利空間資訊服務平台：

<https://gic.wra.gov.tw/Gis/gic/API/Google/Index.aspx>

資料：

**河川(支流)**（GIC fname `RIVERLIN`，SHP；注意另有 `RIVERL`＝中央管河川區域線，名字相近不要搞混）

geometry：

```text
Line
```

【實測 2026-09-29】GIC 清單當日：建置 `2022/11/28`、上架 `2023/02/01`。
初版的「建置 2000／上架 2008」已過時，以下 §10–11、§15–16 凡寫 2000 者同此修正；
§47 年代對照表同步更新。用途判斷不變：仍只做一般辨識＋初步 nearest，不當最新河道／法定範圍。

## 核心用途

```text
輸入一個 Point
↓
搜尋附近河川線
↓
計算 nearest geometry
↓
得到最近河川
```

能做：

- 最近河流
- 距河流距離
- 找附近多條河流
- 建立近似河網
- Snap GPS 座標到河流線

例如：

```json
{
  "river": "大里溪",
  "distance_m": 82.5
}
```

## 限制

最重要的問題：

> 這份資料的原始建置年代是 2000 年。

因此它適合：

- 一般空間辨識
- 河川名稱查詢
- 初步 nearest river

但不應被視為最新河道形態或最新法定範圍。

---

# 11. 河川（河道）面圖

官方：

<https://data.gov.tw/dataset/25781>

【實測 2026-09-29】dataset 是 1 筆索引（`718138bb-7997-4235-ae94-6eae18756dd7`），
內指 `DownLoad.aspx?fname=RIVERPOLY&filetype=SHP`，官方描述 13,262 筆。

空間平台：

**河川(河道)**（GIC fname `RIVERPOLY`，SHP；KML 無此 fname，只有 SHP）

geometry：

```text
Polygon
```

官方資料說明：

- 約 13,262 筆圖徵
- 欄位包含河川中文名稱
- 中央管河川相關判定仍應以正式公告界點等法定資料為主

【實測 2026-09-29】GIC 清單當日：建置 `2022/11/28`、上架 `2023/02/01`（初版 2000 已過時）。

## 可以做

```text
Point-in-Polygon
```

得到：

```json
{
  "inside_river_channel": true
}
```

也可以：

- 找河道寬度近似值
- 河道面積
- 河道邊界距離
- 與設施／道路／土地做空間交集

## 不可過度解讀

它不是：

- 即時水面
- 現況水深
- 最新法定河川區域

「河道 polygon」與「法定河川區域」是不同概念。

---

# 12. 中央管河川界點

官方：

<https://data.gov.tw/dataset/173820>

空間平台亦提供：

**中央管河川界點**（GIC fname `boundarypoint`，KML＋SHP 皆有；dataset 173820 資源
`65f1f323-ba14-4c7b-a156-5012c64a948f`，2 筆，建置 `20241218`）

geometry：

```text
Point
```

空間平台目前顯示建置：

```text
2024-12-18（上架 2024/12/24；【實測 2026-09-29】GIC 清單當日確認）
```

## 用途

中央管河川有管理上的界點。

它可以幫助回答：

- 某位置相對中央管河川界點的上下游關係
- 管理範圍的起始概念
- 河川與界點以上河段的區別

## 不能直接等同

```text
界點以上 = 所有情況都叫「上游」
```

「中央管界點」是管理／法定概念，不是 geomorphology 的上中下游分類。

---

# 13. 中央管河川區域

水利空間資訊服務平台：

<https://gic.wra.gov.tw/Gis/Gic/DataIndex/Data/Main.aspx>

目前可見：

**中央管河川區域**（GIC fname `RIVREGLN`，SHP＋KML 皆有）

geometry：

```text
Polygon
```

平台顯示：

```text
建置日期：2026-03-25（【實測 2026-09-29】GIC 清單當日：建置 2026/05/26、上架 2026/06/12，
比初版再新一版；`rvframe` 中央管河川圖框、`drframe` 中央管排水圖框同日）
座標系統：WGS84
```

【實測 2026-09-29】初版寫「下載方式為申請」。GIC 公開清單當日 `RIVREGLN` SHP/KML、
`RIVERL`、`REGDAREA`、`REGDAREA_L`、`rvframe`、`drframe` 皆有 `downloadFile()` 直下目標，
已非申請制。真正要走申請的是更早的版本還是特定子集，未再細究；實作前直接打一次
`DownLoad.aspx?fname=RIVREGLN&filetype=SHP` 確認當下權限。

## 用途

最重要的判斷之一：

```text
Point-in-Polygon
→ 是否位於中央管河川區域
```

這比舊的「河川河道 polygon」更接近管理／法定範圍需求。

## 注意

若真正用途是：

- 土地開發
- 建築
- 法規
- 權利判定
- 行政處分

應以：

- 最新公告
- 正式河川圖籍
- 主管機關確認

為準。

API 回傳的 `inside_central_river_area = true` 最好標示：

```text
reference only
```

而不是：

```text
legal determination
```

---

# 14. 中央管河川區域線

同一平台：

**中央管河川區域線**（⚠ GIC 上真正的名字就叫 `RIVERL`，中文名「中央管河川區域線」；
不要跟 `RIVERLIN`＝河川(支流)搞混，兩者只差一個字母。SHP＋KML 皆有）

geometry：

```text
Line
```

【實測 2026-09-29】GIC 清單當日：建置 `2026/05/26`、上架 `2026/06/12`。

用途：

- 計算距法定／管理區域邊界多遠
- 判斷某位置接近哪一側邊界
- 畫出河川區域線

例如：

```json
{
  "distance_to_central_river_boundary_m": 32.6
}
```

---

# 15. 河川斷面線

空間平台：

**河川斷面線位置圖**（GIC fname `rcrossec`，SHP＋KML 皆有）

geometry：

```text
Line
```

目前平台顯示：

```text
建置日期：2022-11-28
上架日期：2023-02-01（【實測 2026-09-29】GIC 清單當日確認無變）
```

## 用途

這是建立「河段定位」很有價值的資料。

可計算：

```text
Point
↓
最近的河川斷面
↓
距離
```

回傳：

```json
{
  "nearest_cross_section": "...",
  "distance_m": 311
}
```

### 為什麼它比單純「上中下游」更有價值

「中游」可能涵蓋幾十公里。

但：

```text
最近斷面 XXX
距斷面 311 m
```

可以提供更明確的河段定位。

---

# 16. 河川斷面樁

空間平台：

**河川斷面樁位置圖**（GIC fname `RCROSPIL`，SHP＋KML 皆有；注意是 PIL 不是 SECTION）

geometry：

```text
Point
```

目前平台顯示：

```text
2022-11-28（【實測 2026-09-29】GIC 清單當日：建置 2022/11/28、上架 2023/02/01，確認無變）
```

可以：

- 找最近斷面樁
- 建立河段參考
- 將 GPS 點與官方測量斷面建立關係

---

# 17. 中央管河川河堤

官方：

<https://data.gov.tw/dataset/32730>

空間平台：

**中央管河川河堤**（GIC fname `rivdike`，SHP＋KML 皆有；dataset 32730 資源
`8f097e23-bd06-45d5-be5c-c3a08de27312`）

geometry：

```text
Line
```

【實測 2026-09-29】資料來源是 102–104 年度防洪工程調查（分三年涵蓋 25 條中央管河川：
102 年淡水河等 8 條、103 年大甲溪等 8 條、104 年鹽水溪等 9 條）。
GIC 清單當日：建置 `2024/01/08`、上架 `2024/05/21`（初版只有建置日，補上架日）。

## 可以做

- 最近堤防
- 距堤防距離
- 左／右岸分析（需要額外河流方向判定）
- 河段是否有堤防保護
- 與河道、道路、聚落做空間關係

---

# 18. 堤防或護岸位置

官方：

<https://data.gov.tw/dataset/129462>

資料：

**堤防或護岸位置圖**（【實測 2026-09-29】dataset 129462 資源
`e3901695-299e-4a8b-ae2c-8de241eb6a6d` 只有 1 筆，內指的正是 `rivdike` SHP，
更新 `20200828` —— **§17、§18 是同一份圖的兩個入口**，不要重複下載兩次。）

可以取得：

- 圖資資源
- 更新日期
- 空間 geometry

適合補足：

```text
附近是否有護岸／堤防
距離多少
```

---

# 19. 河川分署管轄範圍

空間平台：

**河川分署管轄範圍圖**（GIC fname `RVB`，只有 SHP 無 KML）

geometry：

```text
Polygon
```

【實測 2026-09-29】GIC 清單當日：建置 `2025/03/13`、上架 `2025/03/14`（初版只有建置日）。
注意 `wratb`＝台北水源特定區圖（2026/09/22，超新但跟河川分署無關）、`wrarb`＝水資源分署
轄區（2010），名字像但用途不同，不要拿錯。

可用：

```text
Point-in-Polygon
→ 屬於哪個河川分署管轄
```

這對 API 很實用：

```json
{
  "responsible_branch": "第三河川分署"
}
```

---

# 20. 排水基本資料

官方：

<https://data.gov.tw/dataset/167896>

名稱：

**排水基本資料**

對台灣非常重要。

因為使用者看到的「水路」不一定是天然河川，也可能是：

- 區域排水
- 排水幹線
- 人工渠道

【實測 2026-09-29】dataset 167896 資源 UUID：`33c1567b-598b-4e5d-9fa9-57059e17ee23`，
64 筆／約 35KB。

⚠ **欄名有 typo，parser 必須相容兩種拼法**（實測原樣）：名稱欄叫 `dainagename`（少一個 r）、
起點叫 `dainagestart`、終點叫 `dainageend`；但 `drainagecode`、`drainageoutlet` 又是正常拼法；
長度欄甚至叫 `ddrainageroadtotallengthofmainriver`（d 開頭雙寫）。深澳坑溪排水範例：
`drainagecode=11403O`（注意尾碼是字母 O 不是數字 0）、`drainageoutlet=基隆河`、
`drainageroadwatershedarea=700`。不要照初版欄名表寫死，ingest 先印 key 再對。

主要欄位（以實測為準，typo 原樣保留）：

```text
dainagename          # ⚠少一個 r
drainagecode         # 如 11403O（尾是字母 O）
drainageoutlet
dainagestart / dainagestartx_3826 / dainagestarty_3826
dainageend / dainageendx_3826 / dainageendy_3826
ddrainageroadtotallengthofmainriver   # ⚠d 雙寫
drainageroadwatershedarea
passingcountyname / responsibleauthority
```

## 能得到

- 排水名稱
- 排水編碼
- 排水出口
- 權責起終點
- 起終點座標
- 幹流長度
- 集水區面積

因此 API 不應只搜尋：

```text
river
```

也應搜尋：

```text
drainage
```

最終可以區分：

```json
{
  "watercourse_type": "river | drainage"
}
```

---

# 21. 中央管區域排水設施範圍

水利空間資訊服務平台目前提供（【實測 2026-09-29】GIC fname `REGDAREA`（面）、
`REGDAREA_L`（線），SHP＋KML 皆有；清單當日建置 `2026/05/26`、上架 `2026/06/12`，
跟 `RIVREGLN` 同批，比初版的 2026-03-25 再新一版）：

- 中央管區域排水設施範圍
- 中央管區域排水設施範圍線

目前平台顯示建置日期：

```text
2026-05-26（上架 2026/06/12）
```

用途：

```text
Point-in-Polygon
```

判斷位置是否位於中央管區排設施範圍。

---

# 22. 河川水位測站站況

官方：

<https://data.gov.tw/dataset/22227>

名稱：

**河川水位測站站況**

這是「測站 metadata」。

不是當下水位本身。

【實測 2026-09-29】dataset 22227 資源 `c4acc691-7416-40ca-9464-292c0c00da92`，
857 筆／約 2MB，共 64 欄（初版只列 10 個，全表如下，ingest 對照用）：

```text
affiliatedbasin / affiliatedsubsidiarybasinrivercode / affiliatedsubsubsidiarybasinrivercode
alertlevel1 / alertlevel2 / alertlevel3   # ⚠站況自帶的警戒多為空（有 alertlevel3 僅 46/857 站）
areacode / basinidentifier / brittlenessstatus / cardrivedistanceinhours
cityelectricitysupplystatus / constructionmanagement / crossriverstructuresnameofequipment
datacollectionfrequecy   # ⚠官方 typo（frequecy 少一個 n）
datasubmitted / drainagestatus / ecologicalenvironmentmonitoring
elevationofwaterlevelzeropoint   # 水尺零點高程（如 1500.00）
englishaddress / englishname / englishrivername   # ⚠englishrivername 空 82 站
equipmentstatus / equipmentstatusoncrossriverstructures / establishdate
floodpreventionpurpose / highsedimentstatus / hydrofacilitymanagement
hydrologicalmonitoringpurpose / lightningstatus
locationaddress   # 中文站址（如 新北市金山區金山里）
locationbytwd67_xy    # 舊座標（TWD67，"310097.50 2790371.80" 字串，中間空格分隔）
locationbytwd97_xy    # 用這個（TWD97，同格式字串，需 split 解析，不是數字）
maintaincycle / noperiodicaldatasubmissionreason / normalobservationtype
obervationitems   # ⚠官方 typo（obervation 少一個 s）
observationreason / observationstatus   # ⚠已廢 475／現存 382：先過濾 observationstatus=現存
observatoryidentifier   # 長碼（如 3132020RV1010H001）＝join 主鍵，下見 §23
observatoryname / onsitedatacollection / otherrequirement
realtimedatadeliveryfrequency / realtimedatadeliveryfrequencyinflooddefencetime
remarks / replacestatus
rivername   # ⚠空 11 站；中文河川名（如 大里溪）
riversectiondepositionanderosionchange / shortobservationtype
solarpotentialdemage / solarstatus / solarwatt / stealstatus / straightriverstatus
subsidencestatus / sunlightcoveragestatus / sunshinestatus / tidestatus
transmissionequipment / verticaldatumsourcestatus / walkdistanceinhours
waterdrawstatus / waterresourcedistrictidentifier / wirelesstransmissiontype
```

注意：**沒有 `stationidentifier` 欄**（初版欄名表誤植）。站的主鍵是 `observatoryidentifier`
（長碼 `3132020RV1010H001`）；即時水位的 `stationid` 是短碼（`1010H006`）。
join 規則：`站況.observatoryidentifier endswith 即時.stationid`（實測 373 live 站命中 369 站況，
現存 382 站命中 369）。

還包含：

- 所屬流域
- 主流／支流／次支流
- 警戒水位
- 站址
- 水尺零點
- 設備型態
- 是否位於跨河構造物
- 防汛用途
- 是否高含砂量河段
- 觀測狀況
- 維護資訊

## 可以做

輸入座標後：

```text
找最近水位站
```

再用 station id 串即時水位。

---

# 23. 即時水位資料

官方：

<https://data.gov.tw/dataset/25768>

名稱：

**即時水位資料**

【實測 2026-09-29】dataset 25768 資源 `73c4c3de-4045-4765-abeb-89f9f9cd5ff0`，
當日 373 筆。實測行為（跟官方說明的差異都在這裡）：

- 更新節奏：名義 10 分鐘一筆，但**各站時間戳不對齊**（當日 7 個 distinct datetime：
  `01:40×1、01:50×84、02:00×12、02:10×25、02:20×249`）。「最新」≠全站同一時刻，
  顯示時每站附自己的 `datetime`，並標「X 分鐘前」；有 2 站停在 9/17、9/26（斷線站），
  超過 1 小時沒更新的灰顯＋註「測站久未更新」。
- `checkresult` 當日 373 筆全 `true`，**不能拿它當品管通過證**；`checkdesc` 非空僅 3 筆
 （內容都是「近期水位變化合理」——有這句≠品管完成，仍是原始值）。
- `waterlevel` 有負值實例（`-0.06`、`-0.0340004`，2 筆）：水尺零點以上的相對讀值，
  **負值是合法的**，不要當錯誤濾掉，也不要解讀成「水深負數」。
- `observatoryidentifier` 後綴是傳輸方式（`4G:147／API:121／NB:99／NB2:4／NBIOW:2`），
  可順手做通訊品質統計，不管也行。
- join 主鍵見 §22：`即時.stationid（短碼）↔ 站況.observatoryidentifier 尾段`。

官方說明（保留）：

- 水利署所屬中央管河川／區域排水水位站
- 原始觀測最快每 10 分鐘一筆
- 即時原始資料尚未完成完整品管
- 儀器或傳輸異常時可能有錯誤或停止更新

實際欄位（英文鍵，不是初版寫的中文）：

```text
stationid                # 短碼（如 1010H006）
observatoryidentifier    # 短碼＋傳輸後綴（如 1010H006_API）
datetime                 # 如 2026-09-29T02:20:00（各站不對齊）
waterlevel               # 字串數字（如 "1.85"；可負，不要濾）
checkresult              # "true"/…（全 true 不代表品管通過）
checkdesc                # 多為 null；"近期水位變化合理" 仍是原始值
volt                     # 電壓（多為 null）
```

## 能做

```json
{
  "station_id": "...",
  "water_level_m": 2.31,
  "observed_at": "...",
  "raw": true
}
```

## 千萬不要做

把最近測站的水位說成：

```text
「你這個 GPS 點目前水深 2.31 m」
```

測站「水位」：

≠ 使用者位置水深

≠ 河床到水面的深度

≠ 任意河段的水位

---

# 24. 警戒水位值

官方：

<https://data.gov.tw/dataset/36692>

【實測 2026-09-29】dataset 36692 資源 `39ad439a-f7aa-4fd4-b1a7-e4622852cc69`，
200 筆／約 30KB。

⚠ **初版欄名表是錯的**：實際是**中文鍵**，不是英文：

```text
流域名稱 / 河川名稱 / 水位站名
一級警戒水位 / 二級警戒水位 / 三級警戒水位
```

空值率（200 筆）：一級 0 空、二級 3 空、**三級 158 空**。三級不是每站都有，
比較時先判空：有三級跟三級比，沒有退回二級，都沒有就只顯示水位不評級。
join 鍵是**中文站名**（`水位站名 ↔ 站況.observatoryname`，如 `蘭陽大橋`），
同名不同站的風險存在，ingest 時印出未命中／多命中清單。

警戒分：

- 一級
- 二級
- 三級

可以把最新水位與警戒值比較：

```json
{
  "water_level_m": 4.31,
  "alert_level_3_m": 4.50,
  "margin_to_level_3_m": 0.19
}
```

但警戒判斷仍應尊重官方即時發布機制，尤其資料可能：

- 延遲
- 未檢核
- 站別不同

---

# 25. 河川流量測站站況

官方：

<https://data.gov.tw/dataset/22223>

名稱：

**河川流量測站站況**

包含：

- 流域
- 主流
- 支流
- 次支流
- 河川代碼
- 測站名稱
- 觀測項目
- 設備資訊
- 測站環境
- 是否高含砂量河段
- 上游是否有放水點
- 站址
- 控制資訊
- 集水區相關資訊

【實測 2026-09-29】dataset 22223 資源 `9332bd66-0213-4380-a5d5-a43e7be49255`，
188 筆／約 474KB，結構同水位站況（含 `observatoryidentifier` 長碼＋`observationstatus`
現存／已廢＋`rivername`），join 規則同 §22。

用途：

```text
座標 → 最近流量站
```

## 注意

「流量站站況」主要是 station metadata。

是否能取得你所需期間的即時／歷史 discharge，應另外查對應的流量觀測資料集。

而即使有流量測站值：

```text
station discharge ≠ 任意點 discharge
```

---

# 26. 雨量站基本資料

官方：

<https://data.gov.tw/dataset/32729>

資料包含：

```text
stationidentifier
observatoryidentifier
observatoryname
locationaddress
basinidentifier
countyidentifier
areacode
x_3826
y_3826
elevation
village
affiliatedsubsidiarybasinrivercode
affiliatedsubsubsidiarybasinrivercode
equipementstatus
transmissionequipment
...
```

## 能做（⚠雨量站的 `stationidentifier` 是真欄位，如 `wr1206`，跟水位站況沒有該欄是兩回事）

- 最近雨量站
- 測站高度
- 所屬流域
- 支流關係
- 站址

【實測 2026-09-29】dataset 32729 資源 `15c166e9-800f-4a81-ba60-0ba61b6c9975`，
243 筆／約 176KB。兩點跟水位站不一樣：① `x_3826/y_3826` 是**數字**（如 `230647.47`，
不是字串，直接用）；② 現存／已廢看 `disusestatus`（`現存`／`廢站`），不是
`observationstatus`，先過濾 `現存`。梅子站範例：`observatoryname=梅子`、
`stationidentifier=wr1206`、`observatoryidentifier=3132002WTwr1206`。

官方說明亦指出：

水利署即時雨量觀測資料目前有部分由氣象署統一發布，因此實作即時雨量時不要假設所有資料仍從同一個 WRA dataset 取得。

---

# 27. 含沙量測站

官方：

<https://data.gov.tw/dataset/16929>

空間平台亦有：

**含沙量測站位置圖**（GIC fname `RIVSESTA`，KML＋SHP 皆有；dataset 16929 資源
`e30a0136-cab0-450d-a955-138e8e652ca0`，2 筆）

geometry：

```text
Point
```

【實測 2026-09-29】dataset 建置 `20260331`（初版的 2024-12-05 已過時）；
GIC 清單當日：建置 `2026/03/31`、上架 `2026/04/16`（跟水位／流量／雨量站同批更新，
這四個站位置圖是同一天版本）。

用途：

- 找最近含沙量觀測站
- 河川研究
- 沖淤／含砂特性分析

不能：

```text
由最近站直接斷定任意 GPS 點目前含沙量
```

---

# 28. 水利防災用影像

官方：

<https://data.gov.tw/dataset/36687>

非常實用。

【實測 2026-09-29】dataset 36687 資源 `f71b74eb-cbe5-42c6-8be5-7500450e7db0`，
131 筆／約 89KB。**座標已經是 `latitude_4326/longitude_4326`（字串數字），免轉換**，
直接最近點查詢。羅莫溪匯流口範例：`cameraid=17457`、`rivercode=242000`、
`tributary=馬鞍溪`、`imageurl=https://fmg.wra.gov.tw/109wraweb/getImage.aspx?…`、
`status=1`。

官方目前說明包含全台水情影像監視站資料，欄位例如：

```text
videosurveillancestationname
cameraid
cameraname
basinname
rivercode
tributary
latitude_4326
longitude_4326
imageformat
imageurl
status
```

## 可以做

```text
輸入座標
↓
找附近 camera
↓
回傳 image URL
```

例如：

```json
{
  "camera": {
    "name": "...",
    "distance_m": 1400,
    "image_url": "..."
  }
}
```

這對人工確認現況非常有價值。

---

# 29. 淹水潛勢圖

官方：

<https://data.gov.tw/dataset/25766>

空間平台亦提供多個定量降雨情境 polygon，例如：

```text
6 小時 150 mm
6 小時 250 mm
6 小時 350 mm

12 小時 200 mm
12 小時 300 mm
12 小時 400 mm

24 小時 200 mm
24 小時 350 mm
24 小時 500 mm
24 小時 650 mm
```

【實測 2026-09-29】dataset 25766 資源 `de9578fe-b014-4f00-b8ca-e6280324f08d` 共 30 筆，
結構跟初版想的不一樣，分兩批：

- 20 縣市 `7z` 包（`opendata.wra.gov.tw/cloud/25766InundationProbabilityMaps/207-01.7z`…），
  建置 `20181031`（初版寫 2019-12-30 是錯的），基隆到澎湖 01–20，金門馬祖澎湖走 `223-` 開頭；
- 10 定量降雨 SHP（GIC 直下，`flood_150mm_6hr`…`flood_650mm_24hr`，6/12/24 小時 × 各 3–4 級），
  建置 `20220812`（GIC 清單同日另有 `SHP119` 版＝TWD97/119 分帶）。

要做 Point-in-Polygon 拿 SHP 那 10 個；7z 是整包文件，ETL 才碰。

## 能做

```text
Point-in-Polygon
→ 某降雨情境下是否位於模擬淹水範圍
```

也可以得到：

- 模擬淹水深度級距
- 不同降雨情境比較

## 重要限制

官方明確說明：

- 是設計降雨＋水理模式的模擬結果
- 不是「下一場颱風一定會淹」
- 有不確定性
- 僅供防災相關業務參考
- 不宜作為土地使用管制／開發限制判定依據

所以 API 欄位最好叫：

```text
flood_potential
```

而不是：

```text
will_flood
```

---

# 30. 防災資訊淹水警戒

官方：

<https://data.gov.tw/dataset/5982>

屬於動態防災資訊。

它與「淹水潛勢圖」不同。

```text
淹水潛勢圖 = 靜態情境模擬
淹水警戒   = 動態防災事件資訊
```

【實測 2026-09-29】dataset 5982 資源 `301c0b62-8736-4e03-95ef-55309c1a5e74` 只有 1 筆，
內指 KML 直連（`opendata.wra.gov.tw/cloud/5982FloodWarningOfDisasterPreventionInformation/286-…警戒.kml`）。
跟 §29 的關係：§29＝靜態情境模擬、§30＝動態事件資訊，不要混用同一個欄名。

如果你的產品有即時功能，可以另外串接。

---

# 31. 深槽與裸露地

水利空間資訊服務平台還有歷年度（【實測 2026-09-29】GIC fname：`104fp_deep`／`104nfp_deep`／
`104fp_bareland`／`104nfp_bareland` 起，`104`–`114` 各年度、`fp`=汛期／`nfp`=非汛期、
`deep`=深槽／`bareland`=裸露地；104–110 只有 SHP，105／111／112／114 有 KML＋SHP）：

```text
汛期深槽
非汛期深槽
汛期裸露地
非汛期裸露地
```

這類資料可以描述：

- 河道主要深槽位置
- 河床裸露地
- 季節性變化
- 河道形態

但屬於年度／時期性成果。

不適合當成：

```text
永久不變的河道中心線
```

---

# 32. 到底能從一個座標直接查出什麼？

以下分成三層。

---

## 32.1 A 級：官方可以直接提供

### 河川身份

- 河川名稱
- 河川代碼
- 英文名稱
- 主／支流階層
- 所屬流域
- 幹流長度
- 流域面積
- 發源地
- 入海口
- 年逕流量
- 河床平均坡度
- 流經縣市
- 權責單位

### 管理

- 治理起點
- 治理終點
- 治理長度
- 中央管河川界點
- 河川分署管轄
- 中央管河川區域
- 中央管區域排水設施範圍

### 空間

- 河川線
- 河道面
- 流域面
- 河川區域線
- 河川區域面
- 堤防
- 斷面線
- 斷面樁
- 測站位置

### 水文

- 水位站
- 即時水位
- 警戒水位
- 流量站
- 雨量站
- 含沙量站
- 水情 camera

---

# 33. B 級：官方沒有直接給，但可以可靠推導

只要建立空間索引，就能自行算：

## 最近河流

```text
nearest(Point, RiverLine)
```

輸出：

```text
河川名稱
河川代碼
距離 m
```

---

## 是否在河道

```text
RiverChannelPolygon.contains(Point)
```

---

## 所屬流域

```text
BasinPolygon.contains(Point)
```

---

## 是否在中央管河川區域

```text
CentralRiverArea.contains(Point)
```

---

## 最近斷面

```text
nearest(Point, CrossSection)
```

---

## 最近水位站／流量站／雨量站

```text
nearest(Point, Station)
```

---

## 距離河口

若有可靠的：

- 河道中心線
- 主支流拓撲
- 河口節點
- 流向

即可：

```text
Snap Point to river network
↓
follow downstream edges
↓
sum edge length
↓
distance_to_mouth
```

輸出：

```json
{
  "distance_from_mouth_km": 42.73
}
```

這不是水利署直接欄位。

必須標記：

```text
derived
```

---

## 河流相對位置百分比

例如：

```text
distance from mouth = 40 km
main channel length = 100 km
```

可得到概念值：

```text
relative_position = 0.40
```

但最嚴謹的做法應是沿同一條有效河網路徑計算，而不是把官方「幹流長度」單純拿來相除。

---

## 河寬

如果有河道 polygon：

1. 找河流中心線上的最近點
2. 求局部切線
3. 建立法線
4. 與河道 polygon 相交
5. 求兩岸交點距離

即可估算：

```text
local_channel_width_m
```

這是推導值，不是官方欄位。

---

## 上下游方向

如果成功建立有向河網：

```text
source → mouth
```

即可知道：

- upstream
- downstream

並尋找：

- 上游最近匯流點
- 下游最近匯流點
- 距河口
- 距源頭

---

# 34. C 級：不能直接從官方資料可靠得到

以下不要偽裝成官方答案。

---

## 34.1 任意點「上游／中游／下游」

官方確實會在個別治理計畫、河川說明中使用：

- 上游
- 中游
- 下游
- 河口
- 源頭

但沒有找到：

> 「全臺所有河川統一的上／中／下游 GIS 分區圖層」。

也沒有統一：

```text
0–33% = 下游
33–66% = 中游
66–100% = 上游
```

這種標準。

部分河川的治理文件會依：

- 橋梁
- 匯流點
- 河床坡降
- 地形
- 治理特性

個別分段。

因此如果系統要輸出：

```json
{
  "segment": "中游"
}
```

最好附：

```json
{
  "method": "official_specific_rule | derived_rule"
}
```

---

# 35. 建議的上中下游分類方法

優先順序：

## Level 1：河川個別官方分界

若官方治理規劃已明確定義：

```text
A 橋以下 = 下游
A 橋至 B 橋 = 中游
B 橋以上 = 上游
```

使用它。

並標：

```text
classification_source = official
```

---

## Level 2：地貌／水文規則

若無正式分界，可自行使用：

- 距河口
- 高程
- 河床坡度
- 河寬
- 河流級序
- 主要匯流點
- 山區／平原轉折

建立規則。

這比固定三等分更合理。

---

## Level 3：純里程比例

最簡單：

```text
0–1/3   → 下游
1/3–2/3 → 中游
2/3–1   → 上游
```

可以用，但一定要標：

```text
heuristic
```

它不能稱為官方分類。

---

# 36. 任意位置的即時水深：拿不到

即使你有：

```text
water_level = 5.2 m
```

也不能直接推出：

```text
water_depth = 5.2 m
```

因為：

```text
水位 = 相對某個高程基準的水面高程 / 尺讀
水深 = 水面 - 該位置河床高程
```

要算任意點水深至少需要：

- 同時間水面高程
- 局部河床高程
- 水面坡降
- 河道斷面
- 必要時水理模式

所以官方開放資料並不能讓你對全臺任意點可靠回傳：

```text
current_depth
```

---

# 37. 任意位置即時流量：不能直接得到

流量測站有：

```text
Q = m³/s
```

但：

```text
nearest_station_Q
```

不能直接等同：

```text
user_location_Q
```

中間可能有：

- 支流匯入
- 取水
- 放水
- 堰壩
- 河道蓄水
- 降雨空間差異

若要任意河段即時流量，需要水文／水理模型。

---

# 38. 任意位置即時流速：不能直接得到

要知道流速通常需要：

- 流量
- 斷面
- 水深
- 糙率
- 坡度
- 水理模式

因此不是單靠官方公開 GIS 就能直接取得。

---

# 39. 小溪／野溪完整覆蓋：不能假設

水利署核心資料偏向：

- 中央管河川
- 區域排水
- 管理及水文業務

不能假設：

```text
台灣每一條山溝、小溪、野溪
```

都有：

- 官方名稱
- 完整中心線
- 河川代碼
- 流向
- 拓撲

若產品要做到極細小溪流，可能需再整合：

- DEM-derived stream network
- 國土測繪圖資
- 地方政府河川／排水資料
- 農村水保相關資料

但那些就不是單純的 WRA 河川資料範圍。

---

# 40. 建議的完整查詢流程

```text
User lat/lon (EPSG:4326)
         │
         ▼
座標合法性檢查
         │
         ▼
轉 EPSG:3826
         │
         ├─────────────► Basin polygon
         │                  │
         │                  └─ 所屬流域
         │
         ├─────────────► River line spatial index
         │                  │
         │                  ├─ 最近河川
         │                  └─ 距河川
         │
         ├─────────────► River channel polygon
         │                  └─ 是否位於河道
         │
         ├─────────────► Central river area
         │                  └─ 是否位於中央管河川區域
         │
         ├─────────────► River network topology
         │                  ├─ upstream/downstream
         │                  ├─ distance from mouth
         │                  ├─ relative position
         │                  └─ confluences
         │
         ├─────────────► Cross section
         │                  └─ 最近斷面
         │
         ├─────────────► Water level station
         │                  ├─ 最近站
         │                  └─ latest water level
         │
         ├─────────────► Alert levels
         │                  └─ 警戒比較
         │
         ├─────────────► Rain / flow / sediment stations
         │
         └─────────────► Camera
                            └─ 附近即時影像
```

---

# 41. 資料庫建議

如果追求：

- 小
- 快
- 離線
- 不依賴第三方服務

不要每次 query 都打 WRA API。

推薦：

```text
官方資料
  ↓
定期 ETL
  ↓
本地資料
  ↓
Spatial index
  ↓
lat/lon query
```

---

## 41.1 最簡單實作

靜態資料：

```text
GeoPackage / SQLite
```

動態資料：

```text
memory cache / SQLite
```

---

## 41.2 若要零重型 GIS dependency

可以預處理：

```text
SHP
 ↓ build step
自訂 binary
 ↓
R-tree
 ↓
Line / Polygon geometry
```

Runtime 只保留：

```text
R-tree
point-in-polygon
point-to-segment distance
polyline cumulative distance
```

即可做到非常小且快。

---

# 42. 空間索引

資料一多，不應：

```text
每次查詢掃描全部河流
```

而應使用：

```text
R-tree
```

流程：

```text
point
 ↓
bbox candidates
 ↓
exact geometry distance
 ↓
nearest result
```

查詢複雜度與效能會好很多。

---

# 43. 河網拓撲：最難但最有價值的部分

若你想做到：

```text
距河口
距源頭
上下游
匯流點
主支流
河段百分比
```

單純一堆 polyline 還不夠。

需要建立：

```text
graph
```

概念：

```text
Node
  - 河口
  - 匯流點
  - 源頭
  - 線段端點

Edge
  - river segment
  - length
  - river code
  - direction
```

例如：

```text
Source A ──┐
           ├── Confluence ───── Mouth
Source B ──┘
```

查詢點先：

```text
snap to edge
```

再：

```text
沿 downstream edge traversal
```

即可算：

```text
distance_to_mouth
```

---

# 44. 河流方向怎麼判定

官方舊 river line 不一定天然就是：

```text
vertex order = upstream → downstream
```

不要直接假設。

可以用：

1. 官方河口資訊
2. DEM 高程
3. 河川代碼階層
4. 匯流關係
5. 已知斷面／治理資訊

建立 directed graph。

---

# 45. 建議輸出 Schema

推薦實際產品回傳：

```json
{
  "query": {
    "lat": 24.123456,
    "lon": 120.654321,
    "crs": "EPSG:4326"
  },

  "watercourse": {
    "type": "river",
    "name": "大里溪",
    "river_code": "...",
    "hierarchy": "tributary",
    "basin": "烏溪流域"
  },

  "authority": {
    "responsible_authority": "...",
    "river_branch": "..."
  },

  "spatial": {
    "distance_to_centerline_m": 82.4,
    "inside_channel": false,
    "inside_central_river_area": false,
    "distance_to_boundary_m": 134.7
  },

  "river_position": {
    "distance_from_mouth_km": 17.83,
    "distance_to_source_km": null,
    "normalized_position": 0.43,
    "segment": "中游",
    "segment_method": "derived"
  },

  "cross_section": {
    "name": "...",
    "distance_m": 318
  },

  "water_level": {
    "station": "...",
    "station_distance_m": 2100,
    "observed_at": "...",
    "water_level_m": 2.31,
    "alert_level_1_m": null,
    "alert_level_2_m": 4.8,
    "alert_level_3_m": 4.1
  },

  "camera": {
    "name": "...",
    "distance_m": 3500,
    "image_url": "..."
  },

  "provenance": {
    "river_name": "official",
    "basin": "official_spatial_lookup",
    "distance_from_mouth_km": "derived",
    "segment": "derived"
  }
}
```

---

# 46. 建議再加入 confidence

每項結果應可帶：

```json
{
  "value": "大里溪",
  "confidence": 0.96,
  "method": "nearest_river_line",
  "distance_m": 12.3,
  "dataset_date": "2000"
}
```

原因：

如果 point：

```text
距河線 5 m
```

與：

```text
距河線 1800 m
```

兩者「最近河流」的可信度顯然不同。

---

# 47. 資料年代必須納入模型

這是非常重要的一點。

例如空間平台目前顯示：

【實測 2026-09-29】GIC 公開清單當日（建置／上架；初版多處已過時，variance 最大的是河川線系 2000→2022）：

| 圖資 | GIC fname | 建置 | 上架 |
|---|---|---|---|
| 河川(支流) | `RIVERLIN`（SHP only） | 2022/11/28 | 2023/02/01 |
| 河川(河道) | `RIVERPOLY`（SHP only） | 2022/11/28 | 2023/02/01 |
| 河川流域範圍圖 | `BASIN`（SHP；實測直下 2.3MB zip 通） | （清單無日期；dataset 索引建置 20201007） | — |
| 河川斷面線 | `rcrossec` | 2022/11/28 | 2023/02/01 |
| 河川斷面樁 | `RCROSPIL` | 2022/11/28 | 2023/02/01 |
| 中央管河川界點 | `boundarypoint` | 2024/12/18 | 2024/12/24 |
| 中央管河川河堤 | `rivdike`（102–104 年度調查底本） | 2024/01/08 | 2024/05/21 |
| 河川分署管轄範圍 | `RVB`（SHP only） | 2025/03/13 | 2025/03/14 |
| 水位／流量／雨量／含沙站位置圖 | `RIVWLSTA/RIVQASTA/ppobsta_wra/RIVSESTA`（現存 `_e`＋已廢 `_a` 分開） | 2026/03/31 | 2026/04/16 |
| 中央管河川區域 | `RIVREGLN` | 2026/05/26 | 2026/06/12 |
| 中央管河川區域線 | `RIVERL`（⚠不是 RIVERLIN） | 2026/05/26 | 2026/06/12 |
| 中央管區域排水設施範圍／線 | `REGDAREA`／`REGDAREA_L` | 2026/05/26 | 2026/06/12 |
| 中央管河川／排水圖框 | `rvframe`／`drframe` | 2026/05/26 | 2026/06/12 |
| 淹水潛勢 SHP（10 定量降雨） | `flood_*`（另有 SHP119 分帶版） | 20220812 | — |
| 水質監測站（水特局） | `rivqusta_wratb`（SHP only） | 2024/12/18 | 2024/12/24 |

因此不能只寫：

```text
source = WRA
```

應寫：

```json
{
  "source": "WRA",
  "dataset": "河川(支流)",
  "dataset_date": "2000"
}
```

使用者才知道：

- 名稱辨識可能仍有用
- 但 geometry 不一定代表 2026 現況

---

# 48. 「最新」和「最準」不是同一件事

例：

```text
中央管河川區域 2026
```

很新。

但用途是：

```text
管理／區域範圍
```

不是河水目前實際流動的水面。

另一方面：

```text
舊河道 polygon
```

雖然較舊，但 geometry 可能仍適合粗略河道定位。

不同資料回答不同問題。

不能只以日期選資料。

---

# 49. 法定範圍 vs 地理河流

請明確分成：

```text
river_centerline
river_channel
central_river_area
central_river_boundary
management_boundary
drainage_facility_area
```

它們不是同一件事。

典型情況：

```text
Point
  ├─ 距河川中心線 50m
  ├─ 不在河道 polygon
  └─ 但可能仍在中央管河川區域
```

這完全可能。

---

# 50. 官方資料有，但不一定能匿名直接下載

初版寫「一些最新圖資標申請」。【實測 2026-09-29】GIC 公開清單當日 `RIVREGLN`、
`RIVERL`、`REGDAREA(_L)`、`rvframe`、`drframe` 皆有 `downloadFile()` 直下目標
（SHP＋KML），已非申請制。仍保留「申請」可能的：更早版本、特定子集、或清單頁
之外的管制圖。實作前打一次 `DownLoad.aspx` 確認當下權限，不要憑印象寫死。

例如某些歷史版本或管制圖可能標：

```text
申請
```

所以資料狀態應區分：

```text
public_direct_download
public_api
application_required
view_only
```

產品開發前最好建立自己的 manifest：

```yaml
central_river_area:
  authority: WRA
  geometry: polygon
  latest_known_date: 2026-03-25
  access: application_required
```

---

# 51. 資料更新策略

不要 hardcode：

```text
這個檔案永遠是最新
```

建議：

```text
daily:
  即時水位
  動態警戒資料

monthly:
  metadata check

quarterly:
  spatial dataset metadata check

manual:
  申請型最新河川區域圖資
```

對每份資料記錄：

```text
downloaded_at
source_updated_at
source_dataset_date
checksum
schema_version
```

---

# 52. 靜態資料與動態資料要分開

## 靜態／慢速更新

```text
river code
river basic
basin basic
river line
river channel
basin polygon
central river area
levee
cross section
```

本地保存。

---

## 動態

```text
water level
warnings
camera image
rainfall
```

短 TTL cache。

例如：

```text
water level TTL = 5–10 min
```

---

# 53. 最低可用資料包（MVP）

如果第一版只想完成：

> 給 lat/lon → 告訴我附近河川

最低需要：

```text
1. 河川(支流) line（GIC `RIVERLIN` SHP，2022/11/28）
2. 河川流域範圍 polygon（GIC `BASIN` SHP，實測 2.3MB zip）
3. 河川代碼（UUID `a644fa3e-…`，836 筆／509KB）
4. 河川基本資料（UUID `750be3f2-…`，79 筆／43.5KB，⚠16+11 筆 x/y 對調見 §6）
5. 流域基本資料（UUID `25d934ae-…`，27 筆／8.9KB）
```

五表靜態 JSON 合計 < 600KB（不含 SHP），可整包進 SQLite 做啟動快取；
SHP 另做 build-time 精簡（§41.2）。

輸出即可做到：

```text
最近河流
距離
河川名稱
河川代碼
主支流
流域
幹流長度
流域面積
權責單位
```

---

# 54. 第二階段資料包

加入：

```text
6. 河川(河道)
7. 中央管河川區域
8. 中央管河川區域線
9. 中央管河川界點
10. 河川斷面線
11. 河川斷面樁
12. 中央管河川河堤
```

即可增加：

```text
是否在河道
是否在中央管河川區域
距區域線
最近界點
最近斷面
最近河堤
```

---

# 55. 第三階段：河網定位

自行建立：

```text
river graph
```

增加：

```text
distance_to_mouth
distance_to_source
relative_position
upstream/downstream
nearest_confluence
river segment
```

這一階段才真正能做好：

```text
上游 / 中游 / 下游
```

---

# 56. 第四階段：即時水情

串：

```text
water level station
latest water level
alert level
rain station
flow station
camera
```

輸出：

```text
附近目前水情
```

---

# 57. 建議不要輸出的誤導性欄位

除非有額外模型，不建議直接回：

```text
current_water_depth
current_velocity
current_flow_at_point
safe_to_enter_water
flood_will_occur
official_upstream_midstream_downstream
```

這些很容易讓使用者誤解。

---

# 58. 比「上中下游」更好的定位方式

建議 API 同時提供：

```text
river name
tributary
distance from mouth
normalized river position
nearest cross section
nearest confluence
elevation
```

例如：

```text
大甲溪
主流
距河口 61.8 km
全河路徑位置 48.2%
最近斷面：XX
距最近主要匯流點 2.3 km
```

這比只寫：

```text
大甲溪中游
```

資訊量高很多。

「中游」可以留作 UI 標籤。

---

# 59. 建議內部資料模型

```text
River
 ├─ code
 ├─ name
 ├─ parent_code
 ├─ basin_code
 ├─ hierarchy
 └─ metadata

RiverEdge
 ├─ id
 ├─ river_code
 ├─ from_node
 ├─ to_node
 ├─ geometry
 ├─ length_m
 └─ dataset_date

RiverNode
 ├─ id
 ├─ type
 │    source
 │    confluence
 │    mouth
 │    endpoint
 └─ coordinate

Basin
 ├─ code
 ├─ name
 └─ polygon

CrossSection
 ├─ id
 ├─ river_code
 └─ geometry

Station
 ├─ id
 ├─ type
 ├─ river_code
 ├─ coordinate
 └─ metadata
```

---

# 60. 建議查詢 API

```http
GET /river-info?lat=24.123&lon=120.678
```

回：

```json
{
  "river": {},
  "basin": {},
  "position": {},
  "management": {},
  "stations": {},
  "risk": {},
  "provenance": {}
}
```

---

# 61. 最重要的 provenance 設計

每個欄位應知道：

```text
它從哪來？
何時建置？
是直接值還是算出來？
```

例如：

```json
{
  "distance_from_mouth_km": {
    "value": 42.7,
    "type": "derived",
    "sources": [
      "WRA river line",
      "WRA river code"
    ],
    "method": "directed_network_shortest_downstream_path",
    "geometry_dataset_date": "2000"
  }
}
```

這會讓系統未來換新圖資時非常容易維護。

---

# 62. 官方來源索引

## 水利署／水規分署

### 流域環境情報地圖基礎地圖包
<https://www.wra.gov.tw/wrap/cp.aspx?n=33935>

### 水利空間資訊服務平台
<https://gic.wra.gov.tw/Gis/Gic/DataIndex/Data/Main.aspx>

### 空間圖資公開清單
<https://gic.wra.gov.tw/Gis/gic/API/Google/Index.aspx>

### 水資源空間資料標準
<https://gic.wra.gov.tw/gis/gic/dataformat/space/space.aspx>

### 水利署 OpenAPI
<https://opendata.wra.gov.tw/api/v2/openapi.get>

### Swagger
<https://opendata.wra.gov.tw/openapi/swagger/index.html>

---

# 63. 核心政府資料集索引

### 河川基本資料
<https://data.gov.tw/dataset/167895>

### 流域基本資料
<https://data.gov.tw/dataset/167897>

### 河川代碼
<https://data.gov.tw/dataset/22228>

### 河川流域範圍圖
<https://data.gov.tw/dataset/9823>

### 河川河道
<https://data.gov.tw/dataset/25781>

### 中央管河川界點
<https://data.gov.tw/dataset/173820>

### 中央管河川河堤
<https://data.gov.tw/dataset/32730>

### 堤防或護岸位置圖
<https://data.gov.tw/dataset/129462>

### 排水基本資料
<https://data.gov.tw/dataset/167896>

### 河川水位測站站況
<https://data.gov.tw/dataset/22227>

### 即時水位資料
<https://data.gov.tw/dataset/25768>

### 警戒水位值
<https://data.gov.tw/dataset/36692>

### 河川流量測站站況
<https://data.gov.tw/dataset/22223>

### 水利署所屬雨量站基本資料
<https://data.gov.tw/dataset/32729>

### 含沙量測站位置圖
<https://data.gov.tw/dataset/16929>

### 水利署水利防災用影像
<https://data.gov.tw/dataset/36687>

### 淹水潛勢圖
<https://data.gov.tw/dataset/25766>

### 防災資訊淹水警戒
<https://data.gov.tw/dataset/5982>

---

### 附錄：已驗證資源 UUID 對照【實測 2026-09-29】

`data.gov.tw` 的 CKAN API（`api/action`、`openapi/v1`）實測 404，只能解析 dataset 頁內嵌的
`opendata.wra.gov.tw/api/v2/<uuid>` 連結。以下 UUID 皆從頁面抓出且回傳 200（`?format=JSON`）：

| 資料集 | dataset id | 資源 UUID | 筆數／大小 |
|---|---|---|---|
| 河川基本資料 | 167895 | `750be3f2-eac0-440d-b1d1-d642f74bb2f3` | 79 筆／43.5KB |
| 河川代碼 | 22228 | `a644fa3e-6406-47e5-a797-dd746d5bb83f` | 836 筆／509KB |
| 流域基本資料 | 167897 | `25d934ae-ecc4-4952-a05b-7ecc208bfd3a` | 27 筆／8.9KB |
| 排水基本資料 | 167896 | `33c1567b-598b-4e5d-9fa9-57059e17ee23` | 64 筆／35KB |
| 警戒水位值 | 36692 | `39ad439a-f7aa-4fd4-b1a7-e4622852cc69` | 200 筆／30KB |
| 防災影像 | 36687 | `f71b74eb-cbe5-42c6-8be5-7500450e7db0` | 131 筆／89KB |
| 水位站站況 | 22227 | `c4acc691-7416-40ca-9464-292c0c00da92` | 857 筆／2MB，64 欄 |
| 即時水位 | 25768 | `73c4c3de-4045-4765-abeb-89f9f9cd5ff0` | 373 筆 |
| 雨量站基本資料 | 32729 | `15c166e9-800f-4a81-ba60-0ba61b6c9975` | 243 筆／176KB |
| 流量站站況 | 22223 | `9332bd66-0213-4380-a5d5-a43e7be49255` | 188 筆／474KB |
| 流域範圍圖（索引，內指 GIC `BASIN`） | 9823 | `1d4d24f4-4745-40e3-b51c-8c422aae4fd7` | 1 筆索引 |
| 河川河道（索引，內指 GIC `RIVERPOLY`，官方描述 13,262 筆） | 25781 | `718138bb-7997-4235-ae94-6eae18756dd7` | 1 筆索引 |
| 中央管河川界點（KML＋SHP，`boundarypoint`，建置 20241218） | 173820 | `65f1f323-ba14-4c7b-a156-5012c64a948f` | 2 筆 |
| 中央管河川河堤（`rivdike`，102–104 年度調查） | 32730 | `8f097e23-bd06-45d5-be5c-c3a08de27312` | 2 筆 |
| 堤防或護岸位置圖（同指 `rivdike`，更新 20200828） | 129462 | `e3901695-299e-4a8b-ae2c-8de241eb6a6d` | 1 筆 |
| 含沙量測站位置圖（`RIVSESTA`，建置 20260331） | 16929 | `e30a0136-cab0-450d-a955-138e8e652ca0` | 2 筆 |
| 淹水潛勢圖（20 縣市 7z＋10 定量降雨 SHP） | 25766 | `de9578fe-b014-4f00-b8ca-e6280324f08d` | 30 筆 |
| 防災資訊淹水警戒（KML，cloud 直連） | 5982 | `301c0b62-8736-4e03-95ef-55309c1a5e74` | 1 筆 |

基底：`https://opendata.wra.gov.tw/api/v2/<uuid>`；
GIC 直下：`https://gic.wra.gov.tw/gis/gic/API/Google/DownLoad.aspx?fname=<FNAME>&filetype=SHP|KML`。

### 附錄：GIC 關鍵 fname 對照【實測 2026-09-29】

公開清單頁是 ASP.NET postback，沒有靜態 `<a>`；解析 `downloadFile("<fname>","<type>")`
共 335 組。河川相關關鍵摘錄（SHP＝Shapefile，KML 無列者只有 SHP；`SHP119`＝TWD97/119 分帶版）：

```text
RIVERLIN   河川(支流)（SHP only）          rcrossec    河川斷面線位置圖
RIVERPOLY  河川(河道)（SHP only）          RCROSPIL    河川斷面樁位置圖（PIL 不是 SECTION）
BASIN      河川流域範圍圖（SHP；實測 2.3MB 通）  rivdike     中央管河川河堤
RIVREGLN   中央管河川區域（面）            boundarypoint 中央管河川界點
RIVERL     中央管河川區域線（⚠不是 RIVERLIN）  RVB         河川分署管轄範圍圖（SHP only）
REGDAREA   中央管區域排水設施範圍（面）    REGDAREA_L  同上範圍線
rvframe/drframe  中央管河川／排水圖框      emframe     一般性海堤圖框
RIVWLSTA_e/a 水位站位置圖_現存／已廢      RIVQASTA_e/a 流量站位置圖_現存／已廢
RIVSESTA   含沙量測站位置圖                ppobsta_wra_e/a 雨量站位置圖_水利署_現存／已廢
rivqusta_wratb 河川水質監測站位置圖_水特局 DIKEGATE    水門位置圖
PUMP_DRAIN 抽水站位置圖（SHP only）        wratb/wrarb 台北水源特定區／水資源分署轄區（⚠跟河川分署無關）
TWQPROT    自來水水質水量保護區圖（＋內外 0.5km 敏感區）
reservoir/ressub  水庫集水區／蓄水範圍     flood_*     淹水潛勢 10 定量降雨 SHP
104fp_deep…114nfp_bareland 深槽／裸露地（104–114 年度，fp=汛期/nfp=非汛期）
```

水位／流量／雨量／含沙四個站位置圖是同一天版本（建置 2026/03/31、上架 2026/04/16），
一次全抓，不要分四次。

---

# 64. 最終能力矩陣

| 功能 | 官方直接 | 可推導 | 建議可信度 |
|---|---:|---:|---|
| 河川名稱 | ✅ |  | 高 |
| 河川代碼 | ✅ |  | 高 |
| 主／支流 | ✅ | ✅ | 高 |
| 流域名稱 | ✅ | ✅空間定位 | 高 |
| 流域面積 | ✅ |  | 高 |
| 幹流長度 | ✅ |  | 高 |
| 發源地 | ✅ |  | 高 |
| 入海口 | ✅ |  | 高 |
| 權責單位 | ✅ |  | 高 |
| 流經縣市 | ✅ |  | 高 |
| 最近河流 |  | ✅ | 中～高，受圖資年代影響 |
| 距河流距離 |  | ✅ | 中～高 |
| 是否在河道 |  | ✅ | 中，舊河道圖需注意 |
| 是否在中央管河川區域 |  | ✅ | 高，但法定用途需正式確認 |
| 最近河堤 |  | ✅ | 高 |
| 最近斷面 |  | ✅ | 高 |
| 最近水位站 |  | ✅ | 高 |
| 即時水位 | ✅測站 |  | 高，但原始值可能未品管 |
| 警戒水位 | ✅測站 |  | 高 |
| 雨量站 | ✅ | ✅nearest | 高 |
| 流量站 | ✅ | ✅nearest | 高 |
| 水情影像 | ✅ | ✅nearest | 高 |
| 距河口 |  | ✅ | 中～高，依河網品質 |
| 距源頭 |  | ✅ | 中，源頭與拓撲較難 |
| 河川位置 % |  | ✅ | 中～高 |
| 上／中／下游 | 部分個別河川 | ✅ | 規則依賴 |
| 任意點水深 | ❌ | 需水理模型 | 低／不可直接 |
| 任意點流速 | ❌ | 需水理模型 | 低／不可直接 |
| 任意點即時流量 | ❌ | 需水文模型 | 低／不可直接 |
| 所有野溪完整名稱 | ❌ | 需其他來源 | 不完整 |

---

# 65. 實作上的推薦結論

若目標是打造一個：

```text
極快
本地
低依賴
lat/lon → river information
```

推薦架構：

```text
                ┌─ river code / metadata
                │
Official data ──┼─ river / basin geometry
                │
                ├─ central river area
                │
                ├─ cross section
                │
                └─ stations
                       │
                       ▼
                  build-time ETL
                       │
                       ▼
                compact local DB
                       │
                  ┌────┴────┐
                  │ R-tree  │
                  │ graph   │
                  └────┬────┘
                       │
                Point query
                       │
                       ▼
                  JSON response
```

Runtime 不一定需要 QGIS、GDAL 或 PostGIS。

如果 build pipeline 已把官方資料整理成：

- 統一 EPSG
- 精簡 geometry
- R-tree
- directed river graph
- compact metadata table

Runtime 可以非常小。

---

# 66. 最後一句最重要

你可以把整個能力理解成：

```text
官方負責提供：
「河川是誰、範圍在哪、基本資料、管理資料、測站資料」

你的系統負責計算：
「這個 GPS 點跟那些官方資料的空間／拓撲關係」
```

因此：

> **「給一個經緯度 → 回傳非常詳細的河川資訊」是可行的。**

真正的技術核心不是 API 本身，而是：

1. 找到正確版本的官方資料。
2. 統一 CRS。
3. 建立空間索引。
4. 建立可靠河網拓撲。
5. 對所有推導值保存 provenance。
6. 不把模型推導結果誤稱成官方判定。

完成這六件事，就能把零散的政府 GIS 資料變成一個快速、穩定且可解釋的河川定位引擎。

---

# 67. 實測 ETL 坑總表【實測 2026-09-29】

把前面各節的警告收斂成一張 ingest checklist，新表進來先對這張：

| # | 坑 | 位置 | 對策 |
|---|---|---|---|
| 1 | `managestart/end x_3826` 16+11 筆 x/y 對調（x>1M） | 河川基本資料 §6 | x>1,000,000 即 swap＋log；正常 x 16–35 萬、y 240–280 萬 |
| 2 | 排水欄名 typo：`dainagename/dainageend`、`ddrainage…` 雙寫 d；`drainagecode` 尾是字母 O | 排水 §20 | 相容兩種拼法；先印 key 再對，不要寫死 |
| 3 | 警戒水位是**中文鍵**（初版英文鍵錯誤）；三級 158/200 空 | 警戒 §24 | 有三級跟三級比，無退二級；join 用中文站名，注意同名站 |
| 4 | 站況**沒有 `stationidentifier`**（初版誤植）；主鍵是 `observatoryidentifier` 長碼 | 站況 §22 | join 用 `站況長碼 endswith 即時短碼`（369/373 命中） |
| 5 | 站況 64 欄含官方 typo（`datacollectionfrequecy`、`obervationitems`）；`englishrivername` 空 82 站、`rivername` 空 11 站 | 站況 §22 | key 原樣保留；英文名空不回退中文（標未知） |
| 6 | 站況 `observationstatus` 已廢 475／現存 382；雨量看 `disusestatus`（現存／廢站）不是 observationstatus | §22／§26 | 先過濾現存再算最近站 |
| 7 | 即時水位各站時間戳不對齊（7 個 distinct）；2 站停在 9/17、9/26 | 即時 §23 | 每站附自己 datetime＋「X 分鐘前」；逾 1h 灰顯 |
| 8 | `checkresult` 全 true 不代表品管通過；`checkdesc` 僅 3 筆「近期水位變化合理」仍是原始值 | 即時 §23 | 一律標原始值未品管 |
| 9 | `waterlevel` 可負（-0.06 實例），是水尺相對讀值 | 即時 §23 | 不濾負值，不解讀成水深 |
| 10 | §17、§18 是同一份 `rivdike` 的兩個入口 | §17／§18 | 只抓一次 |
| 11 | `RIVERL`（區域線）vs `RIVERLIN`（支流線）只差一字母 | §10／§14 | fname 常量集中管理，加註解 |
| 12 | GIC 清單是 ASP.NET postback，無靜態連結 | 附錄 fname | 解析 `downloadFile()` 參數；335 組當日 |
| 13 | `curl -o /dev/null -w` 在此環境顯示 0b，實際存檔 2.3MB | — | 測大小一律存檔驗 |
| 14 | Python urllib 在部分環境 SSL 失敗（Missing Subject Key Identifier），curl 通 | — | Go `net/http` 實作時再驗 TLS |
| 15 | 中央管最新圖（`RIVREGLN` 等）已有直下目標，「申請制」說法已過時 | §13／§50 | 實作前打一次 DownLoad.aspx 確認權限 |

---

# 修訂誌 2026-09-29

- 全量 live 實測：18 個 dataset 資源 UUID、筆數／大小（§63 附錄表）。
- GIC 公開清單解析：335 組 `downloadFile()`，關鍵 fname＋建置／上架日期（§47 對照表重寫；
  河川線系 2000→2022/11/28、區域系 2026-03-25→2026/05/26，初版日期已更正）。
- 修正 5 處事實錯誤：①警戒水位英文鍵→中文鍵（§24）；②站況 `stationidentifier`→`observatoryidentifier`
  ＋ 64 欄全表（§22）；③排水欄名 typo（§20）；④淹水潛勢 2019→2018（7z）／SHP 20220812
  且 30 筆分兩批（§29）；⑤「申請制」→已有直下目標（§13、§50）。
- 新增 join 規則：站況↔即時（長碼 endswith 短碼，369/373）、警戒↔站況（中文站名）。
- 新增行为實測：即時水位時間不對齊＋斷線站、checkresult 全 true、負水位合法、傳輸後綴分布、
  站況現存／已廢比、三級警戒空值率、x/y 對調 16/11 筆量化。
- 新增圖資：`rivqusta_wratb` 水質監測站、`RVB` 分署管轄 `wratb/wrarb` 易混提醒、
  深槽裸露地年度 fname 規則、水庫／水門／抽水站／保護區等周邊圖層（附錄 fname 表）。
- 備份：原初版留 `taiwan_wra_river_data_guide.md.bak-20260929`（同目錄），可 diff 回查。
