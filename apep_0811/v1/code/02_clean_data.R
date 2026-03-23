# 02_clean_data.R — Clean Companies House data for triple-DiD analysis
# Construct monthly incorporation/dissolution panel by country x sector

source("00_packages.R")

cat("Reading Companies House data...\n")
dt <- fread("../data/companies_house.csv", select = c(
  "CompanyNumber", "CompanyCategory", "CompanyStatus",
  "IncorporationDate", "DissolutionDate",
  "SICCode.SicText_1", "RegAddress.Country", "RegAddress.PostCode"
), na.strings = "")

cat(sprintf("Raw companies: %s\n", format(nrow(dt), big.mark = ",")))

# --- Extract SIC division (first 2 digits) ---
# SIC codes are stored as "56101 - Licensed restaurants" format
dt[, sic_raw := SICCode.SicText_1]
dt[, sic_code := str_extract(sic_raw, "^\\d+")]
dt[, sic_div := substr(sic_code, 1, 2)]

# --- Classify country ---
# Scottish companies have CompanyNumber starting with "SC"
# Northern Irish companies start with "NI"
# The rest are England & Wales
dt[, country := fcase(
  grepl("^SC", CompanyNumber), "Scotland",
  grepl("^NI", CompanyNumber), "NorthernIreland",
  default = "EnglandWales"
)]

# Cross-check with RegAddress.Country where available
# (RegAddress.Country is often blank or inconsistent, so CompanyNumber prefix is primary)
cat("\nCountry distribution (from CompanyNumber prefix):\n")
print(dt[, .N, by = country][order(-N)])

# --- Define sectors ---
# Treatment sector: SIC 56 (Food and beverage service activities)
#   56.10 - Restaurants and mobile food service
#   56.21 - Event catering
#   56.30 - Beverage serving (pubs, bars)
#
# Placebo sectors (similar SME-heavy service sectors, unaffected by calorie labeling):
#   47 - Retail trade
#   62 - Computer programming/IT
#   45 - Motor vehicle trade
#   68 - Real estate
#   96 - Other personal services

target_sectors <- c("56", "47", "62", "45", "68", "96")
dt_sectors <- dt[sic_div %in% target_sectors]

dt_sectors[, sector := fcase(
  sic_div == "56", "FoodService",
  sic_div == "47", "Retail",
  sic_div == "62", "IT",
  sic_div == "45", "MotorTrade",
  sic_div == "68", "RealEstate",
  sic_div == "96", "PersonalServices"
)]

cat(sprintf("\nCompanies in target sectors: %s\n", format(nrow(dt_sectors), big.mark = ",")))
cat("\nSector distribution:\n")
print(dt_sectors[, .N, by = sector][order(-N)])

# --- Parse dates ---
dt_sectors[, inc_date := as.Date(IncorporationDate, format = "%d/%m/%Y")]
dt_sectors[, dis_date := as.Date(DissolutionDate, format = "%d/%m/%Y")]

# Also try ISO format if the first parse fails
dt_sectors[is.na(inc_date) & !is.na(IncorporationDate),
           inc_date := as.Date(IncorporationDate)]

cat(sprintf("\nIncorporation dates parsed: %s of %s\n",
            format(sum(!is.na(dt_sectors$inc_date)), big.mark = ","),
            format(nrow(dt_sectors), big.mark = ",")))

# --- Filter to analysis window: Jan 2019 - Dec 2025 ---
dt_sectors[, inc_month := floor_date(inc_date, "month")]
dt_sectors[, dis_month := floor_date(dis_date, "month")]

start_date <- as.Date("2019-01-01")
end_date   <- as.Date("2025-12-01")

# --- Construct monthly incorporation counts ---
# Panel: country x sector x month
inc_panel <- dt_sectors[
  inc_month >= start_date & inc_month <= end_date &
    country %in% c("EnglandWales", "Scotland"),
  .(incorporations = .N),
  by = .(country, sector, inc_month)
]

# Create balanced panel (fill zeros for missing country-sector-months)
grid <- CJ(
  country = c("EnglandWales", "Scotland"),
  sector = unique(dt_sectors$sector),
  inc_month = seq(start_date, end_date, by = "month")
)

panel <- merge(grid, inc_panel, by = c("country", "sector", "inc_month"), all.x = TRUE)
panel[is.na(incorporations), incorporations := 0]

# --- Construct dissolution counts (same structure) ---
dis_panel <- dt_sectors[
  dis_month >= start_date & dis_month <= end_date &
    country %in% c("EnglandWales", "Scotland"),
  .(dissolutions = .N),
  by = .(country, sector, dis_month = dis_month)
]

panel <- merge(panel, dis_panel,
               by.x = c("country", "sector", "inc_month"),
               by.y = c("country", "sector", "dis_month"),
               all.x = TRUE)
panel[is.na(dissolutions), dissolutions := 0]

# --- Treatment variables ---
treatment_date <- as.Date("2022-04-01")
panel[, post := as.integer(inc_month >= treatment_date)]
panel[, england := as.integer(country == "EnglandWales")]
panel[, food := as.integer(sector == "FoodService")]
panel[, treat_ddd := england * food * post]

# Time variable for event study
panel[, month_rel := as.integer(difftime(inc_month, treatment_date, units = "days")) %/% 30]

# Log transformation (adding 1 for zeros)
panel[, log_inc := log(incorporations + 1)]

# --- Order and save ---
setorder(panel, country, sector, inc_month)
fwrite(panel, "../data/panel.csv")

cat(sprintf("\nPanel dimensions: %d rows (%d country x %d sector x %d months)\n",
            nrow(panel),
            uniqueN(panel$country),
            uniqueN(panel$sector),
            uniqueN(panel$inc_month)))

cat("\nSample statistics by country x treatment:\n")
print(panel[sector == "FoodService",
            .(mean_inc = round(mean(incorporations), 1),
              sd_inc = round(sd(incorporations), 1),
              total_inc = sum(incorporations)),
            by = .(country, post)])

cat("\nCleaning complete. Panel saved to data/panel.csv\n")
