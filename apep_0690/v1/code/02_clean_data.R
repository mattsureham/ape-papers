## 02_clean_data.R — Parse raw data and build analysis panel
## Paper: apep_0690 — UK Office-to-Residential PD Rights

source("00_packages.R")
setwd(file.path(dirname(getwd()), "data"))

# ============================================================
# 1. Parse Table 123 — all year sheets into a single panel
# ============================================================
cat("\n=== Parsing Table 123 ===\n")

t123_file <- "Live_Table_123.ods"
sheets <- readODS::list_ods_sheets(t123_file)
year_sheets <- sheets[grepl("^\\d{4}-\\d{2}$", sheets)]
cat("Year sheets:", paste(year_sheets, collapse = ", "), "\n")

parse_t123_sheet <- function(sheet_name) {
  year_start <- as.integer(substr(sheet_name, 1, 4))

  # Try skip=2 first, then skip=3 (newer format)
  for (skip_val in c(2, 3)) {
    df <- data.table(suppressMessages(readODS::read_ods(t123_file, sheet = sheet_name, skip = skip_val)))
    col_names <- tolower(gsub("\\n", " ", names(df)))
    if (any(grepl("dclg code|new build", col_names))) break
  }

  # Clean column names (remove newlines)
  setnames(df, gsub("\\n", " ", names(df)))
  cn <- names(df)

  # Find key columns by pattern matching
  # Must match "Current ONS code" specifically — not "Former ONS code"
  ons_col <- grep("^current", cn, ignore.case = TRUE)[1]
  if (is.na(ons_col)) ons_col <- grep("ons code", cn, ignore.case = TRUE)
  if (length(ons_col) > 1) ons_col <- tail(ons_col, 1)  # Take last if multiple
  ons_col <- ons_col[1]
  auth_col <- grep("authority", cn, ignore.case = TRUE)[1]
  new_build_col <- grep("^new build$", cn, ignore.case = TRUE)[1]
  net_add_col <- grep("^net addition", cn, ignore.case = TRUE)[1]
  pdr_office_col <- grep("office to residential", cn, ignore.case = TRUE)[1]
  net_conv_col <- grep("^net conversion", cn, ignore.case = TRUE)[1]
  net_cou_col <- grep("^net change", cn, ignore.case = TRUE)[1]
  demolitions_col <- grep("^demolition", cn, ignore.case = TRUE)[1]
  pdr_total_res_col <- grep("total.*residential", cn, ignore.case = TRUE)
  pdr_total_res_col <- if (length(pdr_total_res_col)) tail(pdr_total_res_col, 1) else NA

  if (is.na(ons_col) || is.na(net_add_col)) {
    cat(sprintf("  %s: SKIP (cols not found)\n", sheet_name))
    return(data.table())
  }

  # Build result
  safe_col <- function(idx) {
    if (is.na(idx)) return(NA_real_)
    suppressWarnings(as.numeric(df[[idx]]))
  }

  result <- data.table(
    year = year_start,
    ons_code = as.character(df[[ons_col]]),
    la_name = as.character(df[[auth_col]]),
    new_build = safe_col(new_build_col),
    net_additions = safe_col(net_add_col),
    pdr_office = safe_col(pdr_office_col),
    net_conversions = safe_col(net_conv_col),
    net_change_of_use = safe_col(net_cou_col),
    demolitions = safe_col(demolitions_col),
    pdr_total_residential = safe_col(pdr_total_res_col)
  )

  # Filter to valid LA rows (English LA ONS codes)
  result <- result[grepl("^E0[6-9]|^E10", ons_code)]

  cat(sprintf("  %s: %d LAs, PDR office: %s\n",
              sheet_name, nrow(result),
              ifelse(!is.na(pdr_office_col), "YES", "no")))
  return(result)
}

t123_panel <- rbindlist(lapply(year_sheets, parse_t123_sheet), fill = TRUE)
cat("Table 123 panel:", nrow(t123_panel), "rows,",
    uniqueN(t123_panel$ons_code), "LAs,",
    uniqueN(t123_panel$year), "years\n")
cat("Year range:", paste(range(t123_panel$year), collapse = "-"), "\n")
cat("PDR office available years:", paste(sort(unique(t123_panel$year[!is.na(t123_panel$pdr_office)])), collapse = ", "), "\n")

# ============================================================
# 2. Parse VOA floorspace — extract office share by LA
# ============================================================
cat("\n=== Processing VOA floorspace ===\n")

voa <- fread("voa_floorspace/SCat_LA_floorspace.csv")

# Filter to Local Authority level, not abolished
voa_la <- voa[geography == "LAUA" & abolished_year == "[z]"]
cat("VOA LA rows:", nrow(voa_la), "\n")

clean_numeric <- function(x) {
  x <- gsub("\\[c\\]", NA, x)
  x <- gsub(",", "", x)
  suppressWarnings(as.numeric(x))
}

voa_la[, office_fs := clean_numeric(`Offices (Inc Computer Centres)`)]
voa_la[, office_hq_fs := clean_numeric(`Offices Headquarters/Institutional`)]
voa_la[, total_fs := clean_numeric(as.character(Total))]
voa_la[, total_office_fs := fifelse(is.na(office_fs), 0, office_fs) +
         fifelse(is.na(office_hq_fs), 0, office_hq_fs)]
voa_la[, office_share := total_office_fs / total_fs]

voa_office <- voa_la[, .(ons_code = area_code, la_name_voa = area_name,
                          total_office_fs, total_fs, office_share)]

cat("VOA office data:", nrow(voa_office), "LAs\n")
cat("Office share: mean =", round(mean(voa_office$office_share, na.rm = TRUE), 3),
    ", sd =", round(sd(voa_office$office_share, na.rm = TRUE), 3),
    ", range [", round(min(voa_office$office_share, na.rm = TRUE), 3), ",",
    round(max(voa_office$office_share, na.rm = TRUE), 3), "]\n")

# ============================================================
# 3. Parse population data
# ============================================================
cat("\n=== Processing population data ===\n")

pop <- fread("population_by_la.csv")
names(pop) <- tolower(names(pop))
pop <- pop[, .(ons_code = geography_code,
               year = as.integer(gsub("Mid-", "", date_name)),
               population = obs_value)]
pop <- pop[grepl("^E0[6-9]|^E10", ons_code)]
cat("Population panel:", nrow(pop), "rows,",
    uniqueN(pop$ons_code), "LAs\n")

# ============================================================
# 4. Parse house price data (UK HPI)
# ============================================================
cat("\n=== Processing house prices ===\n")

if (file.exists("uk_hpi_full.csv")) {
  hpi <- fread("uk_hpi_full.csv")
  cat("HPI raw rows:", nrow(hpi), "\n")

  hpi[, year := year(as.Date(Date, format = "%d/%m/%Y"))]
  hpi_la <- hpi[grepl("^E0[6-9]|^E10", AreaCode) & !is.na(year)]
  cat("HPI LA rows:", nrow(hpi_la), "\n")

  # Annual mean prices by LA
  price_cols <- c("AveragePrice", "DetachedPrice", "SemiDetachedPrice",
                  "TerracedPrice", "FlatPrice")
  price_cols <- intersect(price_cols, names(hpi_la))

  # Convert to numeric
  for (pc in price_cols) {
    hpi_la[, (pc) := suppressWarnings(as.numeric(get(pc)))]
  }

  hpi_annual <- hpi_la[, lapply(.SD, function(x) mean(x, na.rm = TRUE)),
                       by = .(ons_code = AreaCode, year),
                       .SDcols = price_cols]
  # Replace NaN with NA
  for (pc in price_cols) {
    hpi_annual[is.nan(get(pc)), (pc) := NA_real_]
  }
  cat("HPI annual panel:", nrow(hpi_annual), "rows,",
      uniqueN(hpi_annual$ons_code), "LAs\n")
  fwrite(hpi_annual, "hpi_annual_la.csv")
} else {
  cat("No HPI file found. Proceeding without prices.\n")
  hpi_annual <- data.table()
}

# ============================================================
# 5. Article 4 directions
# ============================================================
cat("\n=== Loading Article 4 data ===\n")
article4 <- fread("article4_boroughs.csv")
cat("Article 4 boroughs:", nrow(article4), "\n")

# ============================================================
# 6. Merge into analysis panel
# ============================================================
cat("\n=== Building analysis panel ===\n")

# Merge Table 123 + population
panel <- merge(t123_panel, pop, by = c("ons_code", "year"), all.x = TRUE)
cat("After pop merge:", nrow(panel), "rows\n")

# Merge VOA office share (cross-sectional)
panel <- merge(panel, voa_office[, .(ons_code, office_share, total_office_fs, total_fs)],
               by = "ons_code", all.x = TRUE)
cat("After VOA merge:", nrow(panel), "rows, office_share available:",
    sum(!is.na(panel$office_share)), "\n")

# Merge house prices
if (nrow(hpi_annual) > 0) {
  panel <- merge(panel, hpi_annual, by = c("ons_code", "year"), all.x = TRUE)
  cat("After HPI merge:", nrow(panel), "rows\n")
}

# Create treatment variables
panel[, post := as.integer(year >= 2013)]
panel[, office_x_post := office_share * post]

# Per-capita housing supply
panel[, additions_pc := net_additions / (population / 1000)]

# Log outcomes (handle zeros)
panel[, log_additions := log(pmax(net_additions, 1))]
panel[, log_additions_pc := log(pmax(additions_pc, 0.01))]

# PDR share of total additions
panel[, pdr_office_share := pdr_office / pmax(net_additions, 1)]

# Article 4 indicator — match by name (fuzzy for London boroughs)
panel[, article4 := as.integer(la_name %in% article4$la_name |
        gsub(" UA$| London Boro$| City of London", "", la_name) %in%
        gsub(" UA$| London Boro$| City of London", "", article4$la_name))]

# Event time relative to 2013
panel[, event_time := year - 2013]

# Log prices
price_vars <- intersect(c("AveragePrice", "FlatPrice", "DetachedPrice",
                           "SemiDetachedPrice", "TerracedPrice"), names(panel))
for (pv in price_vars) {
  panel[, (paste0("log_", pv)) := log(pmax(get(pv), 1))]
}

# Quartile treatment groups for heterogeneity
panel[, office_quartile := cut(office_share,
        breaks = quantile(office_share, probs = c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE),
        labels = c("Q1_low", "Q2", "Q3", "Q4_high"),
        include.lowest = TRUE)]

# Save panel
fwrite(panel, "analysis_panel.csv")

# ============================================================
# Summary
# ============================================================
cat("\n=== PANEL SUMMARY ===\n")
cat(sprintf("Rows: %d\n", nrow(panel)))
cat(sprintf("LAs: %d\n", uniqueN(panel$ons_code)))
cat(sprintf("Years: %s\n", paste(range(panel$year), collapse = "-")))
cat(sprintf("Post=1: %d rows\n", sum(panel$post, na.rm = TRUE)))
cat(sprintf("Article 4 LAs: %d\n", sum(panel[year == max(year)]$article4, na.rm = TRUE)))
cat(sprintf("Office share: mean=%.3f, sd=%.3f\n",
            mean(panel$office_share, na.rm = TRUE),
            sd(panel$office_share, na.rm = TRUE)))
cat(sprintf("Net additions: mean=%.1f, sd=%.1f\n",
            mean(panel$net_additions, na.rm = TRUE),
            sd(panel$net_additions, na.rm = TRUE)))
cat(sprintf("Additions per 1K pop: mean=%.2f, sd=%.2f\n",
            mean(panel$additions_pc, na.rm = TRUE),
            sd(panel$additions_pc, na.rm = TRUE)))
if ("AveragePrice" %in% names(panel)) {
  cat(sprintf("Average price: mean=%.0f, sd=%.0f\n",
              mean(panel$AveragePrice, na.rm = TRUE),
              sd(panel$AveragePrice, na.rm = TRUE)))
}
if ("FlatPrice" %in% names(panel)) {
  cat(sprintf("Flat price: mean=%.0f, sd=%.0f\n",
              mean(panel$FlatPrice, na.rm = TRUE),
              sd(panel$FlatPrice, na.rm = TRUE)))
}

cat("\nPDR office-to-residential by year:\n")
pdr_by_year <- panel[!is.na(pdr_office), .(
  n_las = .N,
  total_pdr = sum(pdr_office, na.rm = TRUE),
  mean_pdr = mean(pdr_office, na.rm = TRUE)
), by = year]
print(pdr_by_year[order(year)])
