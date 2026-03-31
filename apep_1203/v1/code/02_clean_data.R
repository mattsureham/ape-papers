## 02_clean_data.R — Clean and construct analysis dataset
## apep_1203: Argentina SAS Firm Registration Ban

source("00_packages.R")

data_dir <- "../data"

# ── Load raw data ─────────────────────────────────────────────────────────────

cat("Loading raw data...\n")
raw <- fread(file.path(data_dir, "firms_raw.csv"), encoding = "UTF-8")
cat("Raw rows:", nrow(raw), "\n")

# ── Fix date parsing ─────────────────────────────────────────────────────────

# The date column has mixed formats. Parse carefully.
cat("\nSample date values:\n")
print(head(unique(raw$date), 20))

# Try multiple date formats
raw[, date_clean := as.Date(NA)]

# Format 1: YYYY-MM-DD or YYYY-MM-DD HH:MM:SS
idx1 <- grepl("^\\d{4}-\\d{2}-\\d{2}", raw$date)
raw[idx1, date_clean := as.Date(substr(date, 1, 10), format = "%Y-%m-%d")]

# Format 2: DD/MM/YYYY
idx2 <- grepl("^\\d{2}/\\d{2}/\\d{4}", raw$date) & is.na(raw$date_clean)
raw[idx2, date_clean := as.Date(date, format = "%d/%m/%Y")]

# Format 3: DD-MM-YYYY
idx3 <- grepl("^\\d{2}-\\d{2}-\\d{4}", raw$date) & is.na(raw$date_clean)
raw[idx3, date_clean := as.Date(date, format = "%d-%m-%Y")]

cat("Date parsing results:\n")
cat("  Parsed:", sum(!is.na(raw$date_clean)), "\n")
cat("  Missing:", sum(is.na(raw$date_clean)), "\n")

# Filter to valid years: SAS law was 2017, we want pre-period from ~2015
raw <- raw[!is.na(date_clean) & year(date_clean) >= 2015 & year(date_clean) <= 2026]
cat("After date filter (2015-2026):", nrow(raw), "\n")

# ── Deduplicate: keep unique firms by CUIT ────────────────────────────────────

# The data is cumulative snapshots — same firm appears in multiple years' files.
# Deduplicate by CUIT, keeping the row with the earliest date (= registration).

cat("\nDeduplicating by CUIT...\n")
cat("  Unique CUITs before:", uniqueN(raw$cuit), "\n")

# Some rows have empty or NA CUIT — use firm_name + date as backup key
raw[is.na(cuit) | cuit == "", cuit := paste0("NOCUIT_", firm_name, "_", date_clean)]

# Keep first observation per CUIT (earliest date)
setorder(raw, cuit, date_clean)
firms <- raw[, .SD[1], by = cuit]
cat("  Unique firms after dedup:", nrow(firms), "\n")

# ── Standardize firm types ────────────────────────────────────────────────────

cat("\nFirm type distribution:\n")
print(firms[, .N, by = firm_type][order(-N)])

# Create clean firm type categories
firms[, type_clean := fcase(
  grepl("SIMPLIFICADA|S\\.A\\.S", firm_type, ignore.case = TRUE), "SAS",
  grepl("SOCIEDAD ANONIMA$|^SA$", firm_type, ignore.case = TRUE), "SA",
  grepl("RESPONSABILIDAD LIMITADA|S\\.R\\.L", firm_type, ignore.case = TRUE), "SRL",
  grepl("COOPERATIVA", firm_type, ignore.case = TRUE), "COOP",
  grepl("COMANDITA.*ACCIONES", firm_type, ignore.case = TRUE), "SCA",
  grepl("EXTRANJERA|SUCURSAL", firm_type, ignore.case = TRUE), "FOREIGN",
  grepl("ESTADO", firm_type, ignore.case = TRUE), "STATE",
  grepl("LEY 19550|SECCION IV", firm_type, ignore.case = TRUE), "INFORMAL",
  default = "OTHER"
)]

cat("\nClean type distribution:\n")
print(firms[, .N, by = type_clean][order(-N)])

# ── Standardize provinces ─────────────────────────────────────────────────────

# Clean province names
firms[, province_clean := trimws(toupper(province))]
firms[province_clean == "" | is.na(province_clean), province_clean := "UNKNOWN"]

# Harmonize common variants
firms[grepl("BUENOS AIRES$", province_clean) &
      !grepl("CIUDAD", province_clean), province_clean := "BUENOS AIRES"]
firms[grepl("CIUDAD.*BUENOS|CABA|C\\.A\\.B\\.A", province_clean),
      province_clean := "CABA"]

cat("\nProvince distribution (top 15):\n")
print(head(firms[, .N, by = province_clean][order(-N)], 15))

# ── Add time variables ────────────────────────────────────────────────────────

firms[, `:=`(
  year = year(date_clean),
  month = month(date_clean),
  ym = floor_date(date_clean, "month"),
  yq = floor_date(date_clean, "quarter")
)]

# ── SAS registrations over time: verify the ban ──────────────────────────────

cat("\n=== SAS registrations by year ===\n")
sas_by_year <- firms[type_clean == "SAS", .N, by = year][order(year)]
print(sas_by_year)

cat("\n=== SAS registrations by year-month (2019-2025) ===\n")
sas_monthly <- firms[type_clean == "SAS" & year >= 2019 & year <= 2025,
                     .N, by = .(ym)][order(ym)]
print(sas_monthly)

# ── Validate the natural experiment ──────────────────────────────────────────

# Key facts to verify:
# 1. SAS created by Law 27,349 in 2017
# 2. IGJ Resolution 9/2020: effective ban (SAS should collapse)
# 3. April 2024: IGJ Resolutions 11/2024 and 12/2024 reactivate SAS

sas_pre <- firms[type_clean == "SAS" & year %in% 2018:2019, .N]
sas_ban <- firms[type_clean == "SAS" & year %in% 2021:2023, .N]
sas_post <- firms[type_clean == "SAS" & year >= 2024 & month(date_clean) >= 5, .N]

cat("\nNatural experiment validation:\n")
cat("  SAS pre-ban (2018-2019):", sas_pre, "\n")
cat("  SAS during ban (2021-2023):", sas_ban, "\n")
cat("  SAS post-reactivation (May 2024+):", sas_post, "\n")

# ── Build province-month-type panel ──────────────────────────────────────────

# Focus on main firm types for DiD: SAS vs SA, SRL
main_types <- c("SAS", "SA", "SRL")
panel_firms <- firms[type_clean %in% main_types & province_clean != "UNKNOWN"]

# Aggregate to province-month-type counts
panel <- panel_firms[, .(n_firms = .N),
                     by = .(province = province_clean, ym, type = type_clean)]

# Create balanced panel: all province-month-type combinations
all_provs <- unique(panel$province)
all_months <- seq(as.Date("2017-01-01"), as.Date("2025-12-01"), by = "month")
all_types <- main_types
grid <- CJ(province = all_provs, ym = all_months, type = all_types)
panel <- merge(grid, panel, by = c("province", "ym", "type"), all.x = TRUE)
panel[is.na(n_firms), n_firms := 0]

# Add treatment indicators
panel[, `:=`(
  year = year(ym),
  month = month(ym),
  is_sas = as.integer(type == "SAS"),
  # Ban period: March 2020 (IGJ Resolution 9/2020) to April 2024
  ban_period = as.integer(ym >= as.Date("2020-03-01") & ym < as.Date("2024-04-01")),
  # Post-reactivation
  post_reactivation = as.integer(ym >= as.Date("2024-04-01")),
  # Treatment: SAS during ban
  treated_ban = as.integer(type == "SAS" & ym >= as.Date("2020-03-01") & ym < as.Date("2024-04-01")),
  # Treatment: SAS post-reactivation
  treated_post = as.integer(type == "SAS" & ym >= as.Date("2024-04-01"))
)]

# Province-type fixed effects
panel[, prov_type := paste0(province, "_", type)]
panel[, prov_month := paste0(province, "_", as.character(ym))]

cat("\nPanel dimensions:\n")
cat("  Provinces:", uniqueN(panel$province), "\n")
cat("  Months:", uniqueN(panel$ym), "\n")
cat("  Types:", uniqueN(panel$type), "\n")
cat("  Total rows:", nrow(panel), "\n")

# ── Summary statistics ────────────────────────────────────────────────────────

cat("\n=== Mean monthly registrations by type and period ===\n")
summary_stats <- panel[, .(
  mean_monthly = mean(n_firms),
  sd_monthly = sd(n_firms),
  total = sum(n_firms)
), by = .(type, period = fcase(
  ym < as.Date("2020-03-01"), "Pre-ban (2017-2020)",
  ym < as.Date("2024-04-01"), "Ban (2020-2024)",
  default = "Post-reactivation (2024+)"
))]
print(summary_stats[order(type, period)])

# ── Save analysis dataset ────────────────────────────────────────────────────

fwrite(panel, file.path(data_dir, "panel.csv"))
fwrite(firms, file.path(data_dir, "firms_clean.csv"))

cat("\n=== Cleaning complete ===\n")
cat("Saved panel.csv:", nrow(panel), "rows\n")
cat("Saved firms_clean.csv:", nrow(firms), "rows\n")
