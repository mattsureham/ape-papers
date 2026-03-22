## 03_main_analysis.R — Main DiD and DDD estimates
## Paper: apep_0738 — Franc Shock and Retail Desertification

source("code/00_packages.R")

canton_panel <- fread("data/canton_retail_panel.csv")
canton_dt <- fread("data/statent_canton_sector.csv")
muni_panel <- fread("data/municipal_panel.csv")

# Reload border exposure
canton_border <- data.table(
  canton = as.character(1:26),
  canton_abbr = c("ZH","BE","LU","UR","SZ","OW","NW","GL","ZG","FR",
                  "SO","BS","BL","SH","AR","AI","SG","GR","AG","TG",
                  "TI","VD","VS","NE","GE","JU"),
  border_exposure = c(0.25,0,0,0,0,0,0,0,0,0,
                      0.15,1.0,0.8,1.0,0,0,0.5,0.4,0.5,0.7,
                      0.9,0.4,0.3,0.5,1.0,0.7)
)

# Add sector groups to canton_dt
canton_dt[, canton := as.character(canton)]
canton_dt[, noga_num := as.integer(noga_div)]
canton_dt[, sector_group := fcase(
  noga_num == 47, "retail",
  noga_num %in% c(55, 56), "hospitality",
  noga_num %in% c(84, 85, 86, 87, 88), "nontradable",
  noga_num %in% 10:33, "manufacturing",
  default = "other_services"
)]

# ============================================================
# 1. Canton-level DiD: Retail establishments
# ============================================================
cat("=== Canton-Level DiD Analysis ===\n")

# Main specification: log retail establishments
# Y_ct = alpha_c + gamma_t + beta * (border_exposure_c * post_t) + eps
m1 <- feols(log_retail_est ~ border_exposure:post | canton + year,
            data = canton_panel, cluster = ~canton)
cat("\nModel 1: Log retail establishments (continuous exposure)\n")
summary(m1)

# Binary border indicator
m2 <- feols(log_retail_est ~ border:post | canton + year,
            data = canton_panel, cluster = ~canton)
cat("\nModel 2: Log retail establishments (binary border)\n")
summary(m2)

# Employment
m3 <- feols(log_retail_emp ~ border_exposure:post | canton + year,
            data = canton_panel, cluster = ~canton)
cat("\nModel 3: Log retail employment (continuous exposure)\n")
summary(m3)

# Retail share of total establishments
m4 <- feols(retail_share ~ border_exposure:post | canton + year,
            data = canton_panel, cluster = ~canton)
cat("\nModel 4: Retail share of total establishments\n")
summary(m4)

# ============================================================
# 2. Event study: Year-by-year coefficients
# ============================================================
cat("\n=== Event Study ===\n")

# Exclude 2014 as base year (event_time = -1)
canton_panel[, et_factor := factor(event_time)]
canton_panel[, et_factor := relevel(et_factor, ref = "-1")]

es1 <- feols(log_retail_est ~ i(event_time, border_exposure, ref = -1) | canton + year,
             data = canton_panel, cluster = ~canton)
cat("\nEvent study: Log retail establishments × border exposure\n")
summary(es1)

es2 <- feols(log_retail_emp ~ i(event_time, border_exposure, ref = -1) | canton + year,
             data = canton_panel, cluster = ~canton)
cat("\nEvent study: Log retail employment × border exposure\n")
summary(es2)

# Extract event study coefficients
es_coefs <- as.data.table(coeftable(es1))
es_coefs[, event_time := as.integer(gsub("event_time::", "", rownames(coeftable(es1))))]
setnames(es_coefs, c("estimate", "se", "t", "p", "event_time"))
fwrite(es_coefs, "data/event_study_coefs.csv")

# ============================================================
# 3. Triple-Difference: Retail vs Non-Tradable × Border × Post
# ============================================================
cat("\n=== Triple-Difference Analysis ===\n")

# Build sector-level panel for DDD
# Use NOGA 47 (retail) vs NOGA 84-88 (nontradable)
ddd_dt <- canton_dt[sector_group %in% c("retail", "nontradable")]
ddd_dt[, retail := as.integer(sector_group == "retail")]

# Merge border info
ddd_dt <- merge(ddd_dt, canton_border[, .(canton, border_exposure)],
                by = "canton", all.x = TRUE)
ddd_dt[is.na(border_exposure), border_exposure := 0]
ddd_dt[, border := as.integer(border_exposure > 0)]
ddd_dt[, post := as.integer(year >= 2015)]

# Aggregate by canton x sector_group x year
ddd_agg <- ddd_dt[, .(est = sum(establishments, na.rm = TRUE),
                       emp = sum(employees, na.rm = TRUE),
                       fte = sum(fte, na.rm = TRUE)),
                   by = .(year, canton, sector_group, retail, border, border_exposure)]
ddd_agg[, log_est := log(pmax(est, 1))]
ddd_agg[, log_emp := log(pmax(emp, 1))]
ddd_agg[, post := as.integer(year >= 2015)]

# DDD: retail × border_exposure × post with canton×year, sector×year, canton×sector FE
ddd1 <- feols(log_est ~ retail:border_exposure:post |
              canton + year + retail + canton^year + retail^year + canton^retail,
              data = ddd_agg, cluster = ~canton)
cat("\nDDD Model: Log establishments (retail × border × post)\n")
summary(ddd1)

ddd2 <- feols(log_emp ~ retail:border_exposure:post |
              canton + year + retail + canton^year + retail^year + canton^retail,
              data = ddd_agg, cluster = ~canton)
cat("\nDDD Model: Log employment (retail × border × post)\n")
summary(ddd2)

# ============================================================
# 4. Municipal-level DiD
# ============================================================
cat("\n=== Municipal-Level DiD ===\n")

m_muni1 <- feols(log_tert_est ~ border_exposure:post | gem_id + year,
                 data = muni_panel, cluster = ~canton_abbr)
cat("\nMunicipal: Log tertiary establishments × border exposure\n")
summary(m_muni1)

m_muni2 <- feols(log_tert_emp ~ border_exposure:post | gem_id + year,
                 data = muni_panel, cluster = ~canton_abbr)
cat("\nMunicipal: Log tertiary employment × border exposure\n")
summary(m_muni2)

# Placebo: Secondary sector (manufacturing)
m_muni_placebo <- feols(log_sec_est ~ border_exposure:post | gem_id + year,
                        data = muni_panel, cluster = ~canton_abbr)
cat("\nMunicipal placebo: Log secondary (manufacturing) establishments\n")
summary(m_muni_placebo)

# ============================================================
# 5. Save key results and diagnostics
# ============================================================
results <- list(
  main_did_est = coef(m1),
  main_did_se = se(m1),
  binary_did_est = coef(m2),
  binary_did_se = se(m2),
  ddd_est = coef(ddd1),
  ddd_se = se(ddd1),
  muni_did_est = coef(m_muni1),
  muni_did_se = se(m_muni1)
)
saveRDS(results, "data/main_results.rds")

# Write diagnostics.json for validator
n_border <- uniqueN(canton_panel[border == 1]$canton)
n_pre <- sum(unique(canton_panel$year) < 2015)
n_obs_canton <- nrow(canton_panel)
n_obs_muni <- nrow(muni_panel)

diagnostics <- list(
  n_treated = n_border,
  n_pre = n_pre,
  n_obs = n_obs_canton + n_obs_muni,
  n_cantons = uniqueN(canton_panel$canton),
  n_municipalities = uniqueN(muni_panel$gem_id),
  n_border_cantons = n_border,
  n_interior_cantons = uniqueN(canton_panel[border == 0]$canton),
  years = sort(unique(canton_panel$year))
)
jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: %d treated cantons, %d pre-periods, %d total obs\n",
            n_border, n_pre, n_obs_canton + n_obs_muni))

# Save model objects for tables
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4,
             es1 = es1, es2 = es2,
             ddd1 = ddd1, ddd2 = ddd2,
             m_muni1 = m_muni1, m_muni2 = m_muni2,
             m_muni_placebo = m_muni_placebo),
        "data/model_objects.rds")

cat("\n=== Main analysis complete ===\n")
