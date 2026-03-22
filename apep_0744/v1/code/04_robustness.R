# 04_robustness.R — Additional robustness checks
# Wales 20mph Speed Limit and Road Safety (apep_0744)

source("00_packages.R")

data_dir <- "../data"

panel <- fread(file.path(data_dir, "panel_la_quarter_speedcat.csv"))
low <- panel[speed_cat == "low_speed"]
low[, ln_collisions := log(n_collisions + 1)]

# ============================================================================
# 1. Poisson regression (count data model)
# ============================================================================

cat("\n=== Poisson QMLE ===\n")

m_pois <- fepois(n_collisions ~ treat | la_code + year_quarter,
                 data = low, cluster = ~la_code)
cat("Poisson QMLE:\n")
summary(m_pois)

# ============================================================================
# 2. Exclude 2023Q3 (transition quarter)
# ============================================================================

cat("\n=== Excluding transition quarter (2023Q3) ===\n")

low_notrans <- low[year_quarter != "2023Q3"]
m_notrans <- feols(n_collisions ~ treat | la_code + year_quarter,
                   data = low_notrans, cluster = ~la_code)
summary(m_notrans)

# ============================================================================
# 3. Urban-only subsample
# ============================================================================

cat("\n=== Urban-only LAs ===\n")

# Collisions have urban_or_rural flag — reload raw data for this
raw <- fread(file.path(data_dir, "collisions_2020_2024.csv"))
raw[, country := fifelse(grepl("^W", local_authority_ons_district), "Wales",
                         fifelse(grepl("^E", local_authority_ons_district), "England", "Other"))]
raw <- raw[country %in% c("England", "Wales")]
raw[, date_parsed := as.Date(date, format = "%d/%m/%Y")]
raw[is.na(date_parsed), date_parsed := as.Date(date, format = "%Y-%m-%d")]
raw <- raw[!is.na(date_parsed)]
raw[, year := year(date_parsed)]
raw[, quarter := quarter(date_parsed)]
raw[, year_quarter := sprintf("%dQ%d", year, quarter)]
raw[, speed_cat := fifelse(speed_limit <= 30, "low_speed", "high_speed")]

# urban_or_rural_area: 1 = Urban, 2 = Rural
urban_raw <- raw[urban_or_rural_area == 1 & speed_cat == "low_speed"]
urban_panel <- urban_raw[, .(
  n_collisions = .N,
  n_ksi = sum(accident_severity <= 2)
), by = .(la_code = local_authority_ons_district,
          country, year_quarter)]

# Add panel variables
qtr_grid <- data.table(expand.grid(year = 2020:2024, quarter = 1:4))
qtr_grid[, year_quarter := sprintf("%dQ%d", year, quarter)]
qtr_grid[, qtr_idx := .I]
qtr_grid[, post := as.integer(year > 2023 | (year == 2023 & quarter >= 4))]

urban_panel <- merge(urban_panel, qtr_grid[, .(year_quarter, post)],
                     by = "year_quarter", all.x = TRUE)
urban_panel[, welsh := as.integer(country == "Wales")]
urban_panel[, treat := welsh * post]

m_urban <- feols(n_collisions ~ treat | la_code + year_quarter,
                 data = urban_panel, cluster = ~la_code)
cat("Urban-only:\n")
summary(m_urban)

# ============================================================================
# 4. Exclude 2020 (COVID lockdown year)
# ============================================================================

cat("\n=== Excluding 2020 ===\n")

low_no2020 <- low[year >= 2021]
m_no2020 <- feols(n_collisions ~ treat | la_code + year_quarter,
                  data = low_no2020, cluster = ~la_code)
cat("Excluding 2020:\n")
summary(m_no2020)

# ============================================================================
# 5. Permutation test (randomization inference)
# ============================================================================

cat("\n=== Permutation test ===\n")

set.seed(42)
n_perms <- 1000
true_coef <- coef(feols(n_collisions ~ treat | la_code + year_quarter,
                        data = low))["treat"]

# Randomly reassign Welsh status across LAs
all_las <- unique(low$la_code)
n_welsh <- sum(unique(low[, .(la_code, welsh)])$welsh)

perm_coefs <- numeric(n_perms)
for (i in seq_len(n_perms)) {
  fake_welsh <- sample(all_las, n_welsh)
  low[, perm_welsh := as.integer(la_code %in% fake_welsh)]
  low[, perm_treat := perm_welsh * post]
  perm_fit <- feols(n_collisions ~ perm_treat | la_code + year_quarter,
                    data = low)
  perm_coefs[i] <- coef(perm_fit)["perm_treat"]
}

ri_pval <- mean(abs(perm_coefs) >= abs(true_coef))
cat(sprintf("\nRandomization Inference:\n  True coef: %.3f\n  RI p-value: %.4f\n",
            true_coef, ri_pval))

# Clean up temp column
low[, c("perm_welsh", "perm_treat") := NULL]

# ============================================================================
# Save robustness results
# ============================================================================

save(m_pois, m_notrans, m_urban, m_no2020, ri_pval, perm_coefs, true_coef,
     file = file.path(data_dir, "robustness_models.RData"))

cat("\n=== Robustness checks complete ===\n")
