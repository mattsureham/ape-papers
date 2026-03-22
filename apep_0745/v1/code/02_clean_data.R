## 02_clean_data.R — Build LA x month panel from Companies House + NSPL lookup
## APEP-0745: The Freeport Gamble

source("00_packages.R")

cat("=== Building LA x Month Panel ===\n")

# --- Load postcode-to-LA lookup ---
lookup <- readRDS("../data/postcode_la_lookup.rds")
cat("Lookup records:", format(nrow(lookup), big.mark = ","), "\n")

# --- Load Companies House data ---
cat("Reading Companies House data...\n")
ch <- fread(
  "../data/companies_house.csv",
  select = c("CompanyNumber", "RegAddress.PostCode", "IncorporationDate",
             "SICCode.SicText_1"),
  showProgress = FALSE
)
cat("Total records:", format(nrow(ch), big.mark = ","), "\n")

ch[, inc_date := as.Date(IncorporationDate, format = "%d/%m/%Y")]
ch <- ch[inc_date >= as.Date("2016-01-01") & inc_date <= as.Date("2025-12-31")]
cat("Records 2016-2025:", format(nrow(ch), big.mark = ","), "\n")

ch[, postcode := toupper(trimws(RegAddress.PostCode))]
ch <- ch[nchar(postcode) >= 5 & nchar(postcode) <= 8]
ch[, year := year(inc_date)]
ch[, month := month(inc_date)]
ch[, ym := paste0(year, "-", sprintf("%02d", month))]

# SIC code for logistics flag
ch[, sic_raw := SICCode.SicText_1]
ch[, sic_code := as.integer(substr(gsub("[^0-9]", "", sic_raw), 1, 5))]
ch[, is_logistics := sic_code >= 49000 & sic_code < 54000]

# --- Merge with LA lookup ---
cat("Merging with LA lookup...\n")
ch_la <- merge(ch, lookup[, .(postcode, la_code)],
               by = "postcode", all.x = FALSE)
cat("Matched to LAs:", format(nrow(ch_la), big.mark = ","), "\n")

# Keep only England (LA codes starting with E)
ch_eng <- ch_la[grepl("^E", la_code)]
cat("English companies:", format(nrow(ch_eng), big.mark = ","), "\n")

# --- Define freeport treatment BY LA CODE ---
freeport_las <- data.table(
  freeport = c(
    rep("Teesside", 4), rep("Humber", 3), rep("Thames", 3),
    rep("Freeport East", 2), rep("Solent", 2), rep("East Midlands", 3),
    rep("Plymouth", 1), rep("Liverpool", 3)
  ),
  la_code = c(
    # Teesside (Nov 2021)
    "E06000001", "E06000002", "E06000004", "E06000003",
    # Humber (Nov 2021)
    "E06000011", "E06000013", "E06000012",
    # Thames (Nov 2021)
    "E06000034", "E09000002", "E09000016",
    # Freeport East (Dec 2021)
    "E07000076", "E07000202",
    # Solent (Mar 2022)
    "E06000045", "E07000086",
    # East Midlands (Apr 2022)
    "E07000134", "E07000039", "E07000176",
    # Plymouth (Jul 2022)
    "E06000026",
    # Liverpool (Jul 2022)
    "E08000012", "E06000006", "E08000015"
  ),
  la_name = c(
    "Hartlepool", "Middlesbrough", "Stockton-on-Tees", "Redcar and Cleveland",
    "East Riding of Yorkshire", "North Lincolnshire", "North East Lincolnshire",
    "Thurrock", "Barking and Dagenham", "Havering",
    "Tendring", "Ipswich",
    "Southampton", "Eastleigh",
    "North West Leicestershire", "South Derbyshire", "Rushcliffe",
    "Plymouth",
    "Liverpool", "Halton", "Wirral"
  ),
  activation_date = as.Date(c(
    rep("2021-11-19", 4), rep("2021-11-19", 3), rep("2021-11-19", 3),
    rep("2021-12-30", 2), rep("2022-03-22", 2), rep("2022-04-01", 3),
    rep("2022-07-04", 1), rep("2022-07-01", 3)
  ))
)

# Verify freeport LAs exist in data
freeport_in_data <- freeport_las$la_code[freeport_las$la_code %in% unique(ch_eng$la_code)]
cat("\nFreeport LAs found in data:", length(freeport_in_data), "/", nrow(freeport_las), "\n")

# Tag companies in freeport LAs
ch_eng[, treated_la := la_code %in% freeport_las$la_code]
cat("Companies in freeport LAs:", format(sum(ch_eng$treated_la), big.mark = ","), "\n")

# --- Build LA x month panel ---
cat("\nBuilding LA x month panel...\n")
la_month <- ch_eng[, .(
  n_inc = .N,
  n_logistics = sum(is_logistics, na.rm = TRUE)
), by = .(la_code, ym, year, month)]

# Get all unique LAs
all_las <- unique(ch_eng[, .(la_code)])
all_las[, treated_la := la_code %in% freeport_las$la_code]

# Merge freeport info
all_las <- merge(all_las, freeport_las[, .(la_code, freeport, la_name, activation_date)],
                 by = "la_code", all.x = TRUE)

# All year-months
all_yms <- data.table(ym = sort(unique(ch_eng$ym)))
all_yms[, year := as.integer(substr(ym, 1, 4))]
all_yms[, month := as.integer(substr(ym, 6, 7))]

# Cross join for balanced panel
panel <- CJ(la_code = all_las$la_code, ym = all_yms$ym)
panel <- merge(panel, all_las, by = "la_code")
panel <- merge(panel, all_yms, by = "ym")
panel <- merge(panel,
  la_month[, .(la_code, ym, n_inc, n_logistics)],
  by = c("la_code", "ym"), all.x = TRUE)
panel[is.na(n_inc), n_inc := 0L]
panel[is.na(n_logistics), n_logistics := 0L]

# Treatment variables
panel[, period_date := as.Date(paste0(ym, "-01"))]
panel[, post := treated_la & !is.na(activation_date) & period_date >= activation_date]
panel[, treat_post := as.integer(post)]
panel[, first_treat := ifelse(treated_la & !is.na(activation_date),
  as.integer(format(activation_date, "%Y")) * 12L + as.integer(format(activation_date, "%m")),
  0L)]
panel[, time_int := year * 12L + month]
panel[, log_inc := log(1 + n_inc)]

# Region code from lookup (for robustness checks)
region_map <- unique(lookup[, .(la_code, region)])[!is.na(region)]
panel <- merge(panel, region_map, by = "la_code", all.x = TRUE)

# --- Summary ---
cat("\n=== Panel Summary ===\n")
cat("Dimensions:", nrow(panel), "rows\n")
cat("LAs:", n_distinct(panel$la_code), "\n")
cat("Months:", n_distinct(panel$ym), "\n")
cat("Treated LAs:", n_distinct(panel$la_code[panel$treated_la]), "\n")
cat("Control LAs:", n_distinct(panel$la_code[!panel$treated_la]), "\n")

pre_treated <- panel[treated_la == TRUE & post == FALSE]
post_treated <- panel[treated_la == TRUE & post == TRUE]
control <- panel[treated_la == FALSE]

cat("Mean monthly inc (treated pre):", round(mean(pre_treated$n_inc), 1), "\n")
cat("Mean monthly inc (treated post):", round(mean(post_treated$n_inc), 1), "\n")
cat("Mean monthly inc (control):", round(mean(control$n_inc), 1), "\n")
cat("SD(log_inc) pre-treatment:", round(sd(pre_treated$log_inc), 3), "\n")

saveRDS(panel, "../data/panel.rds")
saveRDS(freeport_las, "../data/freeport_las.rds")
cat("\nPanel saved.\n")
