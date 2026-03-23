# 02b_separate_england.R — Separate England from Wales using registered office address
# Addresses reviewer concern that Wales is untreated but grouped with England

source("00_packages.R")

cat("Reading Companies House data to separate England from Wales...\n")
dt <- fread("../data/companies_house.csv", select = c(
  "CompanyNumber", "SICCode.SicText_1", "IncorporationDate",
  "RegAddress.Country", "RegAddress.PostCode"
), na.strings = "")

# Extract SIC division
dt[, sic_code := str_extract(SICCode.SicText_1, "^\\d+")]
dt[, sic_div := substr(sic_code, 1, 2)]

# Filter to target sectors
target_sectors <- c("56", "47", "62", "45", "68", "96")
dt <- dt[sic_div %in% target_sectors]

# Classify jurisdiction using multiple signals:
# 1. Company number prefix: SC = Scotland, NI = Northern Ireland
# 2. RegAddress.Country field
# 3. Postcode prefix (if needed)

dt[, jurisdiction := "Unknown"]

# Scottish companies
dt[grepl("^SC", CompanyNumber), jurisdiction := "Scotland"]

# Northern Irish companies
dt[grepl("^NI", CompanyNumber), jurisdiction := "NorthernIreland"]

# For non-SC/NI companies, try to distinguish England from Wales
# using RegAddress.Country
dt[jurisdiction == "Unknown", reg_country_clean := toupper(trimws(RegAddress.Country))]

cat("\nRegAddress.Country values for non-SC/NI companies:\n")
reg_counts <- dt[jurisdiction == "Unknown", .N, by = reg_country_clean][order(-N)]
print(head(reg_counts, 20))

# Map common values
dt[jurisdiction == "Unknown", jurisdiction := fcase(
  reg_country_clean %in% c("ENGLAND", "UNITED KINGDOM", "UK", "GREAT BRITAIN",
                            "GB", ""), "EnglandOrUK",
  reg_country_clean == "WALES", "Wales",
  reg_country_clean == "SCOTLAND", "Scotland",
  reg_country_clean == "NORTHERN IRELAND", "NorthernIreland",
  default = "EnglandOrUK"  # Default: most non-SC/NI companies are English
)]

# For companies with postcode, use postcode to distinguish England from Wales
# Welsh postcodes start with: CF, SA, LL, NP, LD, SY (partly), HR (partly)
# But this is imprecise — many SY and HR postcodes are English
# Better: use the first letter(s) and known Welsh postcode areas
dt[jurisdiction == "EnglandOrUK", pc_area := str_extract(RegAddress.PostCode, "^[A-Z]+")]

# Full Welsh postcode areas: CF, SA, LL, NP, LD, SY (Powys part)
# Being conservative — only use clearly Welsh areas
welsh_areas <- c("CF", "SA", "LL", "NP", "LD")
dt[jurisdiction == "EnglandOrUK" & pc_area %in% welsh_areas, jurisdiction := "Wales"]

cat("\nJurisdiction distribution after classification:\n")
print(dt[, .N, by = jurisdiction][order(-N)])

# For the main analysis, we want England-only vs Scotland-only
# Companies marked "EnglandOrUK" without Welsh postcodes are overwhelmingly English
dt[jurisdiction == "EnglandOrUK", jurisdiction := "England"]

cat("\nFinal jurisdiction counts:\n")
print(dt[, .N, by = jurisdiction][order(-N)])

# --- Construct panel ---
dt[, sector := fcase(
  sic_div == "56", "FoodService",
  sic_div == "47", "Retail",
  sic_div == "62", "IT",
  sic_div == "45", "MotorTrade",
  sic_div == "68", "RealEstate",
  sic_div == "96", "PersonalServices"
)]

dt[, inc_date := as.Date(IncorporationDate, format = "%d/%m/%Y")]
dt[is.na(inc_date), inc_date := as.Date(IncorporationDate)]
dt[, inc_month := floor_date(inc_date, "month")]

start_date <- as.Date("2019-01-01")
end_date   <- as.Date("2025-12-01")

# Build panel for England vs Scotland (dropping Wales and NI)
inc_panel <- dt[
  inc_month >= start_date & inc_month <= end_date &
    jurisdiction %in% c("England", "Scotland"),
  .(incorporations = .N),
  by = .(country = jurisdiction, sector, inc_month)
]

grid <- CJ(
  country = c("England", "Scotland"),
  sector = unique(dt[, sector]),
  inc_month = seq(start_date, end_date, by = "month")
)

panel <- merge(grid, inc_panel, by = c("country", "sector", "inc_month"), all.x = TRUE)
panel[is.na(incorporations), incorporations := 0]

# Treatment variables
treatment_date <- as.Date("2022-04-01")
panel[, post := as.integer(inc_month >= treatment_date)]
panel[, england := as.integer(country == "England")]
panel[, food := as.integer(sector == "FoodService")]
panel[, treat_ddd := england * food * post]
panel[, log_inc := log(incorporations + 1)]
panel[, cs := paste0(country, "_", sector)]
panel[, ct := paste0(country, "_", inc_month)]
panel[, st := paste0(sector, "_", inc_month)]

# Time relative to treatment
panel[, quarter_rel := as.integer(
  (year(inc_month) - year(treatment_date)) * 4 +
  (quarter(inc_month) - quarter(treatment_date))
)]
panel[, qrel_bin := fcase(
  quarter_rel < -8, -8L,
  quarter_rel > 8, 8L,
  default = as.integer(quarter_rel)
)]
panel[, es_treat := england * food]

setorder(panel, country, sector, inc_month)
fwrite(panel, "../data/panel_eng_only.csv")

cat(sprintf("\nEngland-only panel: %d rows\n", nrow(panel)))
cat("\nPre-treatment food service means:\n")
print(panel[post == 0 & sector == "FoodService",
            .(mean_inc = mean(incorporations), sd = sd(incorporations)),
            by = country])

# --- Re-run main regression ---
cat("\n=== MAIN REGRESSION (England vs Scotland, no Wales) ===\n")

m_eng <- feols(log_inc ~ treat_ddd | cs + ct + st,
               data = panel, vcov = "hetero")
cat(sprintf("β = %.4f (SE = %.4f)\n", coef(m_eng)["treat_ddd"], se(m_eng)["treat_ddd"]))
cat(sprintf("95%% CI: [%.4f, %.4f]\n",
            coef(m_eng)["treat_ddd"] - 1.96 * se(m_eng)["treat_ddd"],
            coef(m_eng)["treat_ddd"] + 1.96 * se(m_eng)["treat_ddd"]))

# Event study
m_es_eng <- feols(log_inc ~ i(qrel_bin, es_treat, ref = -1) | cs + ct + st,
                  data = panel, vcov = "hetero")

# Pre-trend F-test
ct_es <- coeftable(m_es_eng)
pre_coefs <- grep(":-[2-9]|:-1[0-9]", rownames(ct_es), value = TRUE)
if (length(pre_coefs) > 0) {
  wald_pre <- wald(m_es_eng, keep = pre_coefs, print = FALSE)
  cat(sprintf("Pre-trend F-test: F = %.3f, p = %.4f\n", wald_pre$stat, wald_pre$p))
}

# Sector-specific trends robustness
panel[, time_index := as.integer(inc_month - min(inc_month))]
panel[, sector_trend := time_index * as.integer(as.factor(sector))]

m_trends <- feols(log_inc ~ treat_ddd + i(sector, time_index) | cs + ct,
                  data = panel, vcov = "hetero")
cat(sprintf("\nWith sector trends: β = %.4f (SE = %.4f)\n",
            coef(m_trends)["treat_ddd"], se(m_trends)["treat_ddd"]))

# Permutation inference: permute treatment sector label
set.seed(42)
n_perm <- 999
perm_betas <- numeric(n_perm)
sectors <- unique(panel$sector)

for (i in seq_len(n_perm)) {
  # Randomly assign one sector as "pseudo-treated"
  pseudo_food <- sample(sectors, 1)
  panel[, pseudo_treat := england * as.integer(sector == pseudo_food) * post]
  m_perm <- feols(log_inc ~ pseudo_treat | cs + ct + st,
                  data = panel, vcov = "hetero")
  perm_betas[i] <- coef(m_perm)["pseudo_treat"]
}

actual_beta <- coef(m_eng)["treat_ddd"]
perm_p <- mean(abs(perm_betas) >= abs(actual_beta))
cat(sprintf("\nPermutation p-value (999 draws): %.4f\n", perm_p))
cat(sprintf("Actual β: %.4f, Permutation 95th pctile: %.4f\n",
            actual_beta, quantile(abs(perm_betas), 0.95)))

# Save
save(m_eng, m_es_eng, m_trends, perm_betas, perm_p, actual_beta, panel,
     file = "../data/england_only_results.RData")

cat("\nEngland-only analysis complete.\n")
