## ==============================================================
## 01_fetch_data.R — Fetch Eurostat data for five policy reversals
## APEP-0579: Policy Reversals Meta-Natural Experiment
## ==============================================================

source("00_packages.R")
data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## Helper: eurostat package may return 'time' or 'TIME_PERIOD'
fix_time_col <- function(dt) {
  dt <- as.data.table(dt)
  if ("TIME_PERIOD" %in% names(dt) && !"time" %in% names(dt)) {
    setnames(dt, "TIME_PERIOD", "time")
  }
  dt
}

## ---------------------------------------------------------------
## REFORM 1: Denmark fat tax (Oct 2011 – Jan 2013)
## Outcome: HICP food price indices vs non-food
## Dataset: prc_hicp_midx (monthly index, 2015=100)
## ---------------------------------------------------------------
cat("=== REFORM 1: Denmark fat tax — HICP monthly indices ===\n")

dk_hicp <- tryCatch({
  get_eurostat("prc_hicp_midx",
               filters = list(geo = "DK", unit = "I15"),
               time_format = "date")
}, error = function(e) stop("Failed to fetch Denmark HICP: ", e$message,
                            "\nPivot research question or fix the source."))

stopifnot("Denmark HICP data empty" = nrow(dk_hicp) > 0)

# COICOP codes for food vs non-food
food_codes <- c("CP0111", "CP0112", "CP0113", "CP0114", "CP0115",
                "CP0116", "CP0117", "CP0118", "CP0119",
                "CP011", "CP012", "CP01")  # Food & non-alcoholic beverages
nonfood_codes <- c("CP03", "CP04", "CP05", "CP06", "CP07", "CP08", "CP09")

dk_hicp_dt <- fix_time_col(dk_hicp)
dk_hicp_dt[, coicop := as.character(coicop)]
dk_hicp_dt[, values := as.numeric(values)]
dk_hicp_dt[, date := as.Date(time)]

# Filter to 2008-2016 window
dk_panel <- dk_hicp_dt[date >= "2008-01-01" & date <= "2016-12-31"]

# Mark treated (food) vs control (non-food)
dk_panel[, treated := fifelse(coicop %in% food_codes, 1L, 0L)]
dk_panel <- dk_panel[treated == 1L | coicop %in% nonfood_codes]

# Policy periods
dk_panel[, policy_on := fifelse(date >= "2011-10-01" & date < "2013-01-01", 1L, 0L)]
dk_panel[, post_repeal := fifelse(date >= "2013-01-01", 1L, 0L)]

cat("Denmark HICP:", nrow(dk_panel), "obs,",
    uniqueN(dk_panel$coicop), "COICOP categories,",
    uniqueN(dk_panel[treated == 1]$coicop), "food,",
    uniqueN(dk_panel[treated == 0]$coicop), "non-food\n")

fwrite(dk_panel, file.path(data_dir, "dk_hicp_panel.csv"))

## ---------------------------------------------------------------
## REFORM 2: Czech Republic healthcare co-payments (Jan 2008 – Jan 2015)
## Outcome: Health expenditure by financing scheme
## Dataset: hlth_sha11_hf (System of Health Accounts)
## ---------------------------------------------------------------
cat("\n=== REFORM 2: Czech Republic healthcare co-payments ===\n")

cz_health <- tryCatch({
  get_eurostat("hlth_sha11_hf",
               filters = list(geo = "CZ", unit = "MIO_EUR"),
               time_format = "date")
}, error = function(e) stop("Failed to fetch Czech health data: ", e$message))

stopifnot("Czech health data empty" = nrow(cz_health) > 0)

cz_health_dt <- fix_time_col(cz_health)
cz_health_dt[, values := as.numeric(values)]
cz_health_dt[, date := as.Date(time)]
cz_health_dt[, year := year(date)]

# Healthcare financing agents: HF1 = government, HF3 = household OOP
cz_health_dt[, icha11_hf := as.character(icha11_hf)]

# Filter relevant financing schemes
cz_panel <- cz_health_dt[icha11_hf %in% c("HF1", "HF3", "TOT_HF") &
                           year >= 2003 & year <= 2020]

# Treated = household OOP (HF3), control = government (HF1)
cz_panel[, treated := fifelse(icha11_hf == "HF3", 1L, 0L)]
cz_panel[, policy_on := fifelse(year >= 2008 & year < 2015, 1L, 0L)]
cz_panel[, post_repeal := fifelse(year >= 2015, 1L, 0L)]

cat("Czech health:", nrow(cz_panel), "obs,",
    uniqueN(cz_panel$year), "years,",
    uniqueN(cz_panel$icha11_hf), "financing schemes\n")

fwrite(cz_panel, file.path(data_dir, "cz_health_panel.csv"))

## ---------------------------------------------------------------
## REFORM 3: Italy Reddito di Cittadinanza (Apr 2019 – Aug 2023)
## Outcome: At-risk-of-poverty rate by NUTS2
## Dataset: ilc_li41 (at risk of poverty rate by NUTS2)
## Also: lfst_r_lfe2emprt (employment rate by NUTS2)
## ---------------------------------------------------------------
cat("\n=== REFORM 3: Italy Reddito di Cittadinanza ===\n")

# At-risk-of-poverty rate
it_poverty <- tryCatch({
  get_eurostat("ilc_li41",
               filters = list(geo = c("IT", paste0("IT", c("C", "F", "G", "H", "I",
                                                            "11", "12", "13", "21", "22",
                                                            "25", "31", "32", "33", "34",
                                                            "41", "42", "43", "44", "45",
                                                            "51", "52", "53", "55",
                                                            "61", "62", "63", "64",
                                                            "71", "72")))),
               time_format = "date")
}, error = function(e) {
  cat("ilc_li41 fetch with filters failed, trying without geo filter...\n")
  tryCatch({
    raw <- get_eurostat("ilc_li41", time_format = "date")
    raw[grepl("^IT", raw$geo), ]
  }, error = function(e2) stop("Failed to fetch Italy poverty data: ", e2$message))
})

stopifnot("Italy poverty data empty" = nrow(it_poverty) > 0)

it_pov_dt <- fix_time_col(it_poverty)
it_pov_dt[, values := as.numeric(values)]
it_pov_dt[, date := as.Date(time)]
it_pov_dt[, year := year(date)]
it_pov_dt[, geo := as.character(geo)]

# Keep NUTS1/NUTS2 Italian regions (3-4 char codes: ITC, ITF, ITC1, etc.)
it_pov_dt <- it_pov_dt[grepl("^IT[A-Z]", geo) & nchar(geo) %in% c(3, 4)]
# Prefer NUTS2 (4 char) if available, else use NUTS1 (3 char)
if (nrow(it_pov_dt[nchar(geo) == 4]) >= 10) {
  it_pov_dt <- it_pov_dt[nchar(geo) == 4]
  cat("  Using NUTS2 regions\n")
} else {
  it_pov_dt <- it_pov_dt[nchar(geo) == 3]
  cat("  Using NUTS1 regions (NUTS2 insufficient)\n")
}

# Employment rate by NUTS2
it_emp <- tryCatch({
  raw <- fix_time_col(get_eurostat("lfst_r_lfe2emprt", time_format = "date"))
  raw[grepl("^IT", geo)]
}, error = function(e) {
  cat("Warning: Could not fetch Italy employment. Proceeding with poverty only.\n")
  NULL
})

# Italy poverty panel
it_panel <- it_pov_dt[year >= 2015 & year <= 2024]
it_panel[, policy_on := fifelse(year >= 2019 & year < 2024, 1L, 0L)]
it_panel[, post_repeal := fifelse(year >= 2024, 1L, 0L)]

# High vs low poverty regions (2015–2018 baseline)
baseline_poverty <- it_panel[year %in% 2015:2018,
                              .(mean_poverty = mean(values, na.rm = TRUE)),
                              by = geo]
median_pov <- median(baseline_poverty$mean_poverty, na.rm = TRUE)
baseline_poverty[, treated := fifelse(mean_poverty > median_pov, 1L, 0L)]

it_panel <- merge(it_panel, baseline_poverty[, .(geo, treated)], by = "geo")

cat("Italy poverty:", nrow(it_panel), "obs,",
    uniqueN(it_panel$geo), "NUTS2 regions,",
    sum(baseline_poverty$treated), "high-poverty (treated),",
    sum(1 - baseline_poverty$treated), "low-poverty (control)\n")

fwrite(it_panel, file.path(data_dir, "it_poverty_panel.csv"))

if (!is.null(it_emp)) {
  it_emp[, values := as.numeric(values)]
  it_emp[, date := as.Date(time)]
  it_emp[, year := year(date)]
  it_emp[, geo := as.character(geo)]
  nuts_len <- nchar(it_pov_dt$geo[1])  # match the same NUTS level
  it_emp <- it_emp[grepl("^IT[A-Z]", geo) & nchar(geo) == nuts_len &
                     year >= 2015 & year <= 2024]
  it_emp <- merge(it_emp, baseline_poverty[, .(geo, treated)], by = "geo")
  it_emp[, policy_on := fifelse(year >= 2019 & year < 2024, 1L, 0L)]
  it_emp[, post_repeal := fifelse(year >= 2024, 1L, 0L)]
  fwrite(it_emp, file.path(data_dir, "it_employment_panel.csv"))
  cat("Italy employment:", nrow(it_emp), "obs\n")
}

## ---------------------------------------------------------------
## REFORM 4: Poland retirement age reform (Jan 2013 – Oct 2017)
## Outcome: Employment rate by age group and sex
## Dataset: lfsq_ergan (quarterly employment rate by age/sex)
## ---------------------------------------------------------------
cat("\n=== REFORM 4: Poland retirement age reform ===\n")

pl_emp <- tryCatch({
  raw <- fix_time_col(get_eurostat("lfsq_ergan", time_format = "date"))
  raw[grepl("^PL$", geo)]
}, error = function(e) stop("Failed to fetch Poland employment data: ", e$message))

stopifnot("Poland employment data empty" = nrow(pl_emp) > 0)

pl_emp[, values := as.numeric(values)]
pl_emp[, date := as.Date(time)]
pl_emp[, geo := as.character(geo)]
pl_emp[, sex := as.character(sex)]
pl_emp[, age := as.character(age)]

# Focus on ages 55-64 and 60-64 by sex
# Treated: Women 60-64 (retirement age was 60, raised to 67, then reversed to 60)
# Control: Men 60-64 (retirement age was 65, raised to 67, less binding)
# Also: 55-59 as additional control (not directly affected by threshold)
pl_panel <- pl_emp[age %in% c("Y60-64", "Y55-59") &
                     sex %in% c("F", "M") &
                     date >= "2008-01-01" & date <= "2022-12-31"]

# Treated = women 60-64 (most affected group)
pl_panel[, treated := fifelse(sex == "F" & age == "Y60-64", 1L, 0L)]
pl_panel[, policy_on := fifelse(date >= "2013-01-01" & date < "2017-10-01", 1L, 0L)]
pl_panel[, post_repeal := fifelse(date >= "2017-10-01", 1L, 0L)]
pl_panel[, quarter := quarter(date)]
pl_panel[, yearq := year(date) + (quarter - 1) / 4]

cat("Poland employment:", nrow(pl_panel), "obs,",
    uniqueN(pl_panel$date), "quarters,",
    "sex-age groups:", uniqueN(paste(pl_panel$sex, pl_panel$age)), "\n")

fwrite(pl_panel, file.path(data_dir, "pl_employment_panel.csv"))

## ---------------------------------------------------------------
## REFORM 5: France 75% supertax (2013-2014 income)
## Outcome: Labor cost index
## Dataset: lc_lci_r2_q (quarterly labor cost index)
## Compare FR vs DE, NL, BE
## ---------------------------------------------------------------
cat("\n=== REFORM 5: France 75% supertax ===\n")

fr_lci <- tryCatch({
  raw <- fix_time_col(get_eurostat("lc_lci_r2_q", time_format = "date"))
  raw[geo %in% c("FR", "DE", "NL", "BE", "AT")]
}, error = function(e) stop("Failed to fetch France LCI data: ", e$message))

stopifnot("France LCI data empty" = nrow(fr_lci) > 0)

fr_lci[, values := as.numeric(values)]
fr_lci[, date := as.Date(time)]
fr_lci[, geo := as.character(geo)]
fr_lci[, nace_r2 := as.character(nace_r2)]
fr_lci[, lcstruct := as.character(lcstruct)]

# Total labor costs, total NACE
fr_panel <- fr_lci[date >= "2008-01-01" & date <= "2019-12-31"]

# Treated = France, control = DE, NL, BE, AT
fr_panel[, treated := fifelse(geo == "FR", 1L, 0L)]
fr_panel[, policy_on := fifelse(date >= "2013-01-01" & date < "2015-01-01", 1L, 0L)]
fr_panel[, post_repeal := fifelse(date >= "2015-01-01", 1L, 0L)]
fr_panel[, quarter := quarter(date)]
fr_panel[, yearq := year(date) + (quarter - 1) / 4]

cat("France LCI:", nrow(fr_panel), "obs,",
    uniqueN(fr_panel$geo), "countries,",
    uniqueN(fr_panel$date), "quarters\n")

fwrite(fr_panel, file.path(data_dir, "fr_lci_panel.csv"))

## ---------------------------------------------------------------
## DATA VALIDATION
## ---------------------------------------------------------------
cat("\n=== FINAL DATA VALIDATION ===\n")

dk_check <- fread(file.path(data_dir, "dk_hicp_panel.csv"))
cz_check <- fread(file.path(data_dir, "cz_health_panel.csv"))
it_check <- fread(file.path(data_dir, "it_poverty_panel.csv"))
pl_check <- fread(file.path(data_dir, "pl_employment_panel.csv"))
fr_check <- fread(file.path(data_dir, "fr_lci_panel.csv"))

stopifnot("Denmark: need 100+ obs" = nrow(dk_check) >= 100)
stopifnot("Czech: need 10+ obs" = nrow(cz_check) >= 10)
stopifnot("Italy: need 20+ obs" = nrow(it_check) >= 20)
stopifnot("Poland: need 20+ obs" = nrow(pl_check) >= 20)
stopifnot("France: need 50+ obs" = nrow(fr_check) >= 50)

cat("\nAll data validation passed!\n")
cat("  Denmark:", nrow(dk_check), "obs\n")
cat("  Czech Republic:", nrow(cz_check), "obs\n")
cat("  Italy:", nrow(it_check), "obs\n")
cat("  Poland:", nrow(pl_check), "obs\n")
cat("  France:", nrow(fr_check), "obs\n")
cat("  Total:", nrow(dk_check) + nrow(cz_check) + nrow(it_check) +
    nrow(pl_check) + nrow(fr_check), "obs\n")
