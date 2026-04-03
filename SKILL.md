---
name: visa-itinerary-gen
description: 30秒生成领馆级签证行程计划书 — Generate consulate-grade visa itinerary from natural language. Real flyai data, zero hallucination. PDF + booking links with Fliggy.
homepage: https://github.com/zephryve/visa-itinerary-gen
metadata:
  version: 1.1.0
  agent:
    type: tool
    runtime: node
    context_isolation: execution
    parent_context_access: read-only
  openclaw:
    emoji: "\U0001F4CB"
    priority: 80
    requires:
      bins:
        - node
        - python3
      skills:
        - flyai
    intents:
      - visa_itinerary
      - travel_document
      - schengen_visa
    patterns:
      - "((visa|schengen|签证).*(itinerary|行程|plan|计划|行程单|行程表))"
      - "((generate|create|make|做|生成).*(visa|签证).*(itinerary|行程|plan|计划))"
      - "((travel plan|行程计划).*(visa|签证|consulate|领馆|embassy|大使馆))"
---

# visa-itinerary-gen — Visa Itinerary Generator

> **一句话说明：** 输入"4个人4月27号从杭州去意大利和法国，5月4号回"，30秒生成领馆级签证行程计划书（PDF）+ 飞猪预订链接。省 ¥30-110 代做费，省 3-5 小时手工排版。

Generate a consulate-grade visa itinerary document in 30 seconds. Real data from flyai, zero hallucination.

## Step 0: Dependency Check (MUST run before anything else)

When this skill is activated, **first run these checks silently**. If any dependency is missing, tell the user what to install and stop — do NOT proceed with incomplete dependencies.

```bash
# 1. Check flyai-cli
which flyai > /dev/null 2>&1 || echo "MISSING: flyai-cli"

# 2. Check python3
which python3 > /dev/null 2>&1 || echo "MISSING: python3"

# 3. Check playwright (for PDF generation)
python3 -c "import playwright" 2>/dev/null || echo "MISSING: playwright"
```

If anything is missing, show the user the appropriate install commands:

**flyai-cli missing:**
```bash
# OpenClaw users
clawhub install flyai

# Claude Code users
npm i -g @fly-ai/flyai-cli
cp -r /path/to/flyai-skill/skills/flyai ~/.claude/skills/flyai
```

**playwright missing:**
```bash
pip install playwright
python -m playwright install chromium
```

**Or run the one-click setup script** (from the skill's root directory):
```bash
bash scripts/setup.sh
```

Only proceed to Step 1 when all dependencies are confirmed.

## When to Use This Skill

Activate when the user wants to:
- Generate a travel itinerary for any visa application (Schengen, Japan, South Korea, Southeast Asia, etc.)
- Create a travel plan document for consulate/embassy submission
- Prepare visa application documents (specifically the itinerary)

## Input

The user provides a natural language description of their trip. Extract these parameters:

| Parameter | Required | Example |
|-----------|----------|---------|
| `destination` | Yes | "Italy and France" |
| `dates` | Yes | "Apr 27 - May 4" |
| `travelers` | Yes (default: 1) | 4 |
| `departure_city` | Yes | "Hangzhou" |
| `budget` | No | "60,000 CNY" |

Example: `"4个人4月27号从杭州去意大利和法国，5月4号回，预算6万"`

## Execution Steps

### Step 1: Parse Input

Extract destination cities, travel dates, number of travelers, departure city, and budget from the user's input. Plan a realistic day-by-day city routing.

For multi-country trips, determine the city sequence. Example for Italy + France:
- Milan → Venice → Florence → Rome → Nice → Paris

### Step 2: Get Current Date

```bash
date +%Y-%m-%d
```

Use this to calculate relative dates if the user says "next month" etc.

### Step 3: Call flyai — Flights

Search for all flight segments. Flight search works with both Chinese and English city names, but prefer Chinese for consistency.

**International departure:**
```bash
flyai search-flight --origin "{出发城市}" --destination "{第一个目的城市}" --dep-date "{start_date}" --sort-type 3
```

**Inter-city flights (if applicable):**
```bash
flyai search-flight --origin "{城市A}" --destination "{城市B}" --dep-date "{date}" --sort-type 3
```

**Return flight:**
```bash
flyai search-flight --origin "{最后一个城市}" --destination "{出发城市}" --dep-date "{end_date}" --sort-type 3
```

From each result, extract: `marketingTransportName`, `marketingTransportNo`, `depDateTime`, `arrDateTime`, `depStationName`, `arrStationName`, `adultPrice`, `jumpUrl`.

**If no flight found for a segment:** note it as "Train" or "To be confirmed" — do NOT hallucinate a flight number.

### Step 4: Call flyai — Hotels

For each city in the itinerary, search hotels. **You MUST include dates for overseas cities** — without dates, overseas cities return wrong results from unrelated cities (not empty, but wrong data — more dangerous).

**CRITICAL: Always use Chinese city names for hotel search.** English names cause flyai to fuzzy-match wrong cities (e.g., "Tokyo" → Cape Town, "Nice" → Dubai, "Osaka" → null). This is not a fallback — Chinese is the only reliable option for overseas cities.

```bash
flyai search-hotels --dest-name "{城市中文名}" --check-in-date "{checkin}" --check-out-date "{checkout}" --sort rate_desc
```

From each result, extract: `name`, `address`, `price`, `score`, `detailUrl`.

**Verify the hotel is actually in the target city.** Check the `address` field — if it contains a different country or city, discard that result.

Pick the top-rated hotel for each city. If no valid results, mark "Hotel to be confirmed" in the itinerary.

### Step 5: Call flyai — Attractions

For each city, search top attractions. **You MUST use Chinese city names** — English names return empty results.

**Universal rule: Regardless of user input language, translate ALL city names to Chinese before calling any flyai command (hotels, attractions, flights with non-Chinese city names).** Do not rely on a fixed mapping table — the agent is responsible for accurate translation.

```bash
flyai search-poi --city-name "{城市中文名}"
```

From results, extract: `name`, `address`, `freePoiStatus`, `ticketInfo.price`, `jumpUrl`.

Select 2-4 attractions per city to fill the daily itinerary. Distribute realistically — no more than 3 major attractions per day.

### Step 6: Internal Logic

**Only execute this step for multi-country Schengen trips.** For single-country trips or non-Schengen destinations (e.g., Japan, South Korea, Southeast Asia), skip this step entirely.

**Schengen 90/180 Day Check:**
- Count total days inside Schengen zone
- If > 90 days, add a warning at the top of the document

**Main Application Country:**
- Count days spent in each country
- The country with the most days = main application country
- If tied, the first country visited is the main application country

### Step 7: Generate Output

You MUST produce TWO outputs:

#### Output 1: Travel Plan Table (Markdown)

Generate a **full English** single-page travel plan table. This is the visa itinerary — keep it clean and simple, no extra sections.

```markdown
# Travel Plan

| Country | Day | Date | City | Touring Spots | Accommodation | Transportation |
|---------|-----|------|------|---------------|---------------|----------------|
| CHINA | 1 | {YYYY/MM/DD} ({Day}) | {origin}→{first_city} | — | {hotel_name} ({full_address}) | Flight {airline} {flight_no}: {origin}→{dest} {dep_time} |
| {COUNTRY} | 2 | {YYYY/MM/DD} ({Day}) | {city} | {Spot 1}, {Spot 2}, {Spot 3} | {hotel_name} | Public transport and walking |
| ... | ... | ... | ... | ... | ... | ... |
| CHINA | {n} | {YYYY/MM/DD} ({Day}) | {last_city}→{origin} | — | — | Flight {airline} {flight_no}: {dep_city}→{origin} {dep_time} |
```

**Critical rules:**
- ALL text in English
- Every day must have specific touring spots — never write "Free day" or "Rest"
- Touring Spots: just list attraction names, no descriptions (e.g. "Duomo di Milano, Galleria V.E. II, The Last Supper")
- Accommodation: first time a hotel appears → full name + address; subsequent nights at same hotel → name only
- Transportation: flight rows → "Flight {airline} {flight_no}: {route} {time}"; train rows → "Train {city_a}→{city_b}"; sightseeing days → "Public transport and walking"
- Keep it concise — the whole table should fit on a single A4 page
- No Declaration, no Financial Summary, no Notes for Visa Officer — just the itinerary table. Real visa itineraries that get approved are plain tables. Adding extra sections makes it look AI-generated, not human-prepared.

#### Generate PDF from the table

After generating the Markdown table, convert it to a single-page A4 PDF using playwright:

```python
from playwright.sync_api import sync_playwright

# 1. Write the table to a temporary HTML file (Times New Roman, A4, black & white)
# 2. Render to PDF:
with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page()
    page.goto(f'file://{html_path}')
    page.pdf(path='My_Travel_Plan.pdf', format='A4',
             margin={'top':'16mm','right':'14mm','bottom':'16mm','left':'14mm'},
             print_background=True)
    browser.close()
# 3. Delete the temporary HTML file — only deliver the PDF to the user
```

#### Output 2: Booking Links HTML (Chinese + English)

Generate TWO HTML files. **Reference the visual style, CSS, and HTML structure of `templates/` as design examples, but dynamically generate all content from flyai data.** The templates contain hardcoded demo data (Italy & France), not fillable placeholders — do NOT attempt find-and-replace. Instead, replicate the same layout and styling with real data.

- `booking_links_cn.html` — Chinese version with Chinese hotel/attraction names and recommendations
- `booking_links_en.html` — English version with English recommendations

Each HTML file contains three tables (Flights / Hotels / Attractions) with:
- Every row has a **copy button** (click to copy Fliggy link to clipboard) + clickable link
- **Recommendations** from flyai data: hotels show `star` + `interestsPoi` (e.g. "高档型 · 近圣马可广场"), attractions show `category` (e.g. "博物馆 · 达芬奇名作")
- Fonts: Georgia (cross-platform) + Playfair Display (EN title only, via Google Fonts)
- Style: memo briefing aesthetic (warm paper background, accent red dividers, black table headers)

Data to fill into templates:

**Flights table:** route (CN/EN city names), airline + specific flight number (e.g., "卡塔尔航空 QR871" / "Qatar Airways QR871"), price per person, Fliggy `jumpUrl`. **Flight numbers are mandatory** — extract `marketingTransportName` + `marketingTransportNo` from flyai results. Never omit the flight number or write only the airline name.

**Hotels table:** city, hotel `name` (EN) / flyai Chinese name, `price`, `star` + `interestsPoi` as recommendation, Fliggy `detailUrl`

**Attractions table:** city, attraction `name` (EN) / flyai Chinese name, `category` as recommendation, Fliggy `jumpUrl`

### Step 8: Delivery Review

Before delivering to the user, review each output as if you were the person who will submit it. The goal is to deliver something that can be used directly — not a draft that needs manual checking.

**Review Output 1 (Travel Plan PDF) — the visa officer will read this:**
- Every hotel address is in the correct city (not a different country or region)
- Every flight row has a specific flight number + departure time (not just the airline name)
- Each day's touring spots are only in that day's city (no mixing cities on transfer days)
- Transfer day timing is realistic (early morning flight = no sightseeing that day)
- Every piece of data (flight numbers, hotel names, touring spot names) must trace back to a flyai call. If a touring spot was not returned by flyai, it must be removed — use "Local exploration / neighborhood walk" instead. This skill's promise is zero hallucination from real data.

**Review Output 2 (Booking Links HTML) — the user will use this to book:**
- CN version: every flight has airline + flight number (e.g., "春秋航空 9C8515", not just "春秋航空")
- EN version: every flight has airline + flight number (e.g., "Spring Airlines 9C8515")
- Attraction categories/descriptions make sense (discard or replace obviously wrong labels like "山湖田园" for a city observation deck)
- Every hotel and flight has a Fliggy link; if data exists but link is missing, note "请在飞猪搜索该航线"

**When something fails review:**
- Fix it if you can (re-search, substitute data, remove bad labels)
- If unfixable (flyai has no data), mark it clearly in the output and tell the user what needs their attention
- Default is: user receives a ready-to-use document, not a TODO list

## Error Handling

| Situation | Action |
|-----------|--------|
| Flight not found | Write "To be confirmed — please check alternative routes" in Destination column |
| Hotel not found | Write "To be confirmed — please book a hotel with free cancellation" in Hotel column |
| Attraction data sparse | Use `fliggy-fast-search --query "{city} tourist attractions"` as fallback |
| Schengen stay > 90 days | Add prominent warning: "⚠ WARNING: Total Schengen stay exceeds 90 days" |
| flyai not installed | Print installation instructions and stop |
| Budget exceeded | Mention in booking links output that estimated total exceeds stated budget |

## Important Notes

- **Never hallucinate data.** Every flight number, hotel name, and address must come from flyai results. If flyai returns no data, mark it as "To be confirmed" — do NOT make up information. Visa officers can and will verify.
- **Always include booking links.** In Output 2, every hotel and flight must have a Fliggy booking link from the flyai response.
- **Keep the travel plan clean.** Output 1 is just a table — no extra sections, no branding. It should look like a normal person's travel plan, not an AI-generated document.
- **Brand mention.** Only in Output 2 (booking links), include "Based on fly.ai real-time results".
