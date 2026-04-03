## 02_clean_data.R — Construct analysis panel with ROO Restrictiveness Index
## apep_1338: Brexit Rules of Origin and Trade Disintegration

source("code/00_packages.R")

raw <- readRDS("data/comtrade_uk_hs4_raw.rds")

## ── 1. Classify partners ────────────────────────────────────────────────────

eu27_codes <- c(40, 56, 100, 191, 196, 203, 208, 233, 246, 250, 276, 300,
                348, 372, 380, 428, 440, 442, 470, 528, 616, 620, 642, 703,
                705, 724, 752)

# Non-EU control partners: major economies with no ROO change vis-a-vis UK
# US (842), Canada (124), Japan (392), South Korea (410), Australia (36)
control_codes <- c(842, 124, 392, 410, 36)

## ── 2. Build panel: aggregate to HS4 × partner_type × year ─────────────────

panel <- raw |>
  filter(
    partnerCode != 0,          # drop "World" aggregate
    partnerCode != 826,        # drop UK self-trade
    cmdCode != "TOTAL",        # drop total
    nchar(cmdCode) == 4        # keep HS4 only
  ) |>
  mutate(
    eu = as.integer(partnerCode %in% eu27_codes),
    control = as.integer(partnerCode %in% control_codes),
    year = as.integer(period),
    hs4 = cmdCode,
    hs2 = substr(cmdCode, 1, 2),
    trade_value = as.numeric(primaryValue)
  ) |>
  # Keep only EU and control partners

  filter(eu == 1 | control == 1) |>
  # Aggregate to HS4 × partner_type × year
  group_by(hs4, hs2, eu, year, flowCode) |>
  summarize(
    trade_value = sum(trade_value, na.rm = TRUE),
    n_partners = n_distinct(partnerCode),
    .groups = "drop"
  )

cat("Panel dimensions:\n")
cat("  Rows:", nrow(panel), "\n")
cat("  HS4 codes:", n_distinct(panel$hs4), "\n")
cat("  Years:", paste(sort(unique(panel$year)), collapse = ", "), "\n")
cat("  EU rows:", sum(panel$eu == 1), "  Control rows:", sum(panel$eu == 0), "\n")

## ── 3. Construct ROO Restrictiveness Index (Estevadeordal 2000 method) ──────
##
## TCA ANNEX ORIG-2 specifies product-specific rules of origin at HS chapter
## (2-digit) and heading (4-digit) level. We code the ROO-RI following the
## Estevadeordal (2000) ordinal scale:
##
##   1 = Y (Change of item/minimal processing)
##   2 = CTSH (Change of Tariff Subheading)
##   3 = CTH (Change of Tariff Heading)
##   4 = CC (Change of Chapter)
##   5 = CC + Tech Requirement or RVC ≥ 50%
##   6 = WO (Wholly Obtained) or CC + RVC ≥ 55%
##   7 = Exception (no preferential rule possible)
##
## We code at HS-2 chapter level from the TCA product-specific rules.
## Sources: TCA ANNEX ORIG-2 (Official Journal L 149, 30.4.2021)

roo_ri <- tribble(
  ~hs2, ~roo_ri, ~rule_type,
  # Live animals, meat, dairy, fish (Chapters 01-05): largely WO
  "01",  6, "WO",
  "02",  6, "WO",
  "03",  6, "WO",
  "04",  5, "CC+RVC",
  "05",  4, "CC",
  # Vegetables, fruits, cereals, milling (06-11)
  "06",  6, "WO",
  "07",  6, "WO",
  "08",  6, "WO",
  "09",  4, "CC",
  "10",  6, "WO",
  "11",  4, "CC",
  # Oils, fats, processed food, beverages, tobacco (12-24)
  "12",  6, "WO",
  "13",  4, "CC",
  "14",  4, "CC",
  "15",  5, "CC+proc",
  "16",  4, "CC",
  "17",  4, "CC",
  "18",  4, "CC",
  "19",  4, "CC",
  "20",  4, "CC",
  "21",  4, "CC",
  "22",  4, "CC",
  "23",  4, "CC",
  "24",  4, "CC",
  # Minerals, ores (25-27)
  "25",  3, "CTH",
  "26",  3, "CTH",
  "27",  5, "CC+proc",
  # Chemicals, pharmaceuticals (28-38)
  "28",  3, "CTH",
  "29",  3, "CTH",
  "30",  3, "CTH",
  "31",  3, "CTH",
  "32",  3, "CTH",
  "33",  3, "CTH",
  "34",  3, "CTH",
  "35",  3, "CTH",
  "36",  3, "CTH",
  "37",  3, "CTH",
  "38",  3, "CTH",
  # Plastics, rubber (39-40)
  "39",  3, "CTH",
  "40",  3, "CTH",
  # Leather, furskins (41-43)
  "41",  4, "CC",
  "42",  4, "CC",
  "43",  4, "CC",
  # Wood, paper (44-49)
  "44",  3, "CTH",
  "45",  3, "CTH",
  "46",  3, "CTH",
  "47",  3, "CTH",
  "48",  3, "CTH",
  "49",  3, "CTH",
  # Textiles (50-63): strict double-transformation rules
  "50",  5, "CC+proc",
  "51",  5, "CC+proc",
  "52",  5, "CC+proc",
  "53",  5, "CC+proc",
  "54",  5, "CC+proc",
  "55",  5, "CC+proc",
  "56",  5, "CC+proc",
  "57",  5, "CC+proc",
  "58",  5, "CC+proc",
  "59",  5, "CC+proc",
  "60",  5, "CC+proc",
  "61",  5, "CC+proc",
  "62",  5, "CC+proc",
  "63",  5, "CC+proc",
  # Footwear, headgear (64-67)
  "64",  4, "CC",
  "65",  4, "CC",
  "66",  4, "CC",
  "67",  4, "CC",
  # Stone, ceramics, glass (68-70)
  "68",  3, "CTH",
  "69",  3, "CTH",
  "70",  3, "CTH",
  # Precious metals, jewellery (71)
  "71",  4, "CC",
  # Iron, steel, base metals (72-83)
  "72",  4, "CC",
  "73",  3, "CTH",
  "74",  3, "CTH",
  "75",  3, "CTH",
  "76",  3, "CTH",
  "78",  3, "CTH",
  "79",  3, "CTH",
  "80",  3, "CTH",
  "81",  3, "CTH",
  "82",  3, "CTH",
  "83",  3, "CTH",
  # Machinery (84)
  "84",  3, "CTH",
  # Electrical equipment (85)
  "85",  4, "CTH+RVC",
  # Vehicles (86-89): most restrictive — automotive ROO
  "86",  3, "CTH",
  "87",  6, "RVC55",
  "88",  4, "CTH+RVC",
  "89",  3, "CTH",
  # Instruments, clocks, musical (90-92)
  "90",  3, "CTH",
  "91",  3, "CTH",
  "92",  3, "CTH",
  # Arms (93)
  "93",  4, "CC",
  # Furniture, toys, misc (94-96)
  "94",  3, "CTH",
  "95",  3, "CTH",
  "96",  3, "CTH",
  # Art (97)
  "97",  4, "CC"
)

## ── 4. Merge ROO-RI onto panel ──────────────────────────────────────────────

panel <- panel |>
  left_join(roo_ri, by = "hs2")

# Check merge
n_missing_roo <- sum(is.na(panel$roo_ri))
cat("\nROO-RI merge:\n")
cat("  Matched:", nrow(panel) - n_missing_roo, "\n")
cat("  Missing:", n_missing_roo, "\n")
cat("  Unique HS2 in data:", n_distinct(panel$hs2), "\n")
cat("  Unique HS2 in ROO-RI:", nrow(roo_ri), "\n")

# Drop unmatched (residual/services chapters)
panel <- panel |> filter(!is.na(roo_ri))

## ── 5. Create analysis variables ────────────────────────────────────────────

panel <- panel |>
  mutate(
    post = as.integer(year >= 2021),
    # Exclude 2020 (transition year + COVID)
    transition = as.integer(year == 2020),
    # Log trade value (add 1 for zeros)
    log_trade = log(trade_value + 1),
    # Interaction terms
    post_eu = post * eu,
    post_eu_roo = post * eu * roo_ri,
    post_roo = post * roo_ri,
    eu_roo = eu * roo_ri,
    # Product-partner ID for FE
    hs4_eu = paste0(hs4, "_", eu),
    # High vs low ROO indicator (for heterogeneity)
    high_roo = as.integer(roo_ri >= 5),
    # Sector groups
    sector = case_when(
      hs2 %in% sprintf("%02d", 1:24)  ~ "Agriculture",
      hs2 %in% sprintf("%02d", 25:27) ~ "Minerals",
      hs2 %in% sprintf("%02d", 28:38) ~ "Chemicals",
      hs2 %in% sprintf("%02d", 39:40) ~ "Plastics",
      hs2 %in% sprintf("%02d", 41:43) ~ "Leather",
      hs2 %in% sprintf("%02d", 44:49) ~ "Wood/Paper",
      hs2 %in% sprintf("%02d", 50:63) ~ "Textiles",
      hs2 %in% sprintf("%02d", 64:67) ~ "Footwear",
      hs2 %in% sprintf("%02d", 68:71) ~ "Stone/Glass",
      hs2 %in% sprintf("%02d", 72:83) ~ "Metals",
      hs2 %in% c("84", "85")          ~ "Machinery",
      hs2 %in% sprintf("%02d", 86:89) ~ "Vehicles",
      hs2 %in% sprintf("%02d", 90:97) ~ "Instruments",
      TRUE ~ "Other"
    )
  )

## ── 6. Drop 2020 ────────────────────────────────────────────────────────────

analysis <- panel |> filter(transition == 0)

cat("\nAnalysis panel (excluding 2020):\n")
cat("  Rows:", nrow(analysis), "\n")
cat("  HS4 products:", n_distinct(analysis$hs4), "\n")
cat("  Years:", paste(sort(unique(analysis$year)), collapse = ", "), "\n")
cat("  Post-TCA obs:", sum(analysis$post == 1), "\n")
cat("  Pre-TCA obs:", sum(analysis$post == 0), "\n")

## ── 7. Summary of ROO-RI distribution ───────────────────────────────────────

cat("\nROO-RI distribution across HS4 products:\n")
analysis |>
  filter(year == min(year)) |>
  group_by(roo_ri, rule_type) |>
  summarize(n_hs4 = n_distinct(hs4), .groups = "drop") |>
  arrange(roo_ri) |>
  print(n = 20)

## ── 8. Save ─────────────────────────────────────────────────────────────────

saveRDS(analysis, "data/analysis_panel.rds")
saveRDS(panel, "data/full_panel.rds")
cat("\nSaved data/analysis_panel.rds and data/full_panel.rds\n")
