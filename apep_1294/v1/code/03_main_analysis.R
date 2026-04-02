## ── 03_main_analysis.R ─────────────────────────────────────────────
## Main DiD analysis: ST reservation and nightlights/deforestation
## Key finding: pre-existing convergence in nightlights means the
## standard DiD is confounded; the paper documents a null at the 2008 break
## ────────────────────────────────────────────────────────────────────
source("code/00_packages.R")

data_dir <- "data"

## ── 1. Load analysis panels ───────────────────────────────────────
nl_panel <- fread(file.path(data_dir, "analysis_panel.csv"))

cat("Nightlights panel:", nrow(nl_panel), "obs,", uniqueN(nl_panel$dist_id), "districts\n")

## ── 2. ANALYSIS A: Nightlights (1994-2013) ────────────────────────

## A1. Naive DiD (will show positive coefficient due to convergence)
m1 <- feols(log_nl ~ treat_st | dist_id + year, data = nl_panel,
            cluster = ~dist_id)

## A2. With SC interaction (horse race)
m2 <- feols(log_nl ~ treat_st + treat_sc | dist_id + year, data = nl_panel,
            cluster = ~dist_id)

## A3. Binary treatment: high-ST districts
m3 <- feols(log_nl ~ treat_high_st | dist_id + year, data = nl_panel,
            cluster = ~dist_id)

## A4. Level outcome
m4 <- feols(dmsp_total_light_cal ~ treat_st | dist_id + year, data = nl_panel,
            cluster = ~dist_id)

cat("\n=== NAIVE DiD (captures convergence, not causal effect) ===\n")
cat("Model 1: Continuous ST:", coef(m1)["treat_st"], "\n")
cat("Model 2: ST + SC:", coef(m2)["treat_st"], "/", coef(m2)["treat_sc"], "\n")
cat("Model 3: Binary:", coef(m3)["treat_high_st"], "\n")

## ── 3. Event Study ────────────────────────────────────────────────
nl_panel[, rel_year := year - 2008]
m_es <- feols(log_nl ~ i(rel_year, st_share, ref = -1) | dist_id + year,
              data = nl_panel, cluster = ~dist_id)

cat("\n=== EVENT STUDY (pre-trends will be visible) ===\n")
es_coefs <- coeftable(m_es)
es_dt <- as.data.table(es_coefs, keep.rownames = TRUE)
names(es_dt) <- c("Term", "Estimate", "SE", "tstat", "pvalue")
es_dt[, rel_year := as.integer(gsub("rel_year::-?\\d+:st_share", "",
                                     gsub("rel_year::", "", gsub(":st_share", "", Term))))]
es_dt[, Calendar := rel_year + 2008]
cat("Pre-treatment coefficients (should be ~0 for clean identification):\n")
print(es_dt[rel_year < 0, .(Calendar, Estimate = round(Estimate, 3), SE = round(SE, 3))])
cat("Post-treatment coefficients:\n")
print(es_dt[rel_year >= 0, .(Calendar, Estimate = round(Estimate, 3), SE = round(SE, 3))])

## ── 4. TREND-BREAK SPECIFICATION ──────────────────────────────────
## Key innovation: test for a BREAK in the convergence trend at 2008
## Rather than testing level shift (which is confounded by convergence),
## test whether the rate of convergence changed at 2008

## Create time trend variable
nl_panel[, time_trend := year - 1994]
nl_panel[, post_trend := pmax(0, year - 2008)]  # 0 pre-2008, 1,2,3,... post

## Trend-break model: does ST × trend change slope at 2008?
m_break <- feols(log_nl ~ st_share:time_trend + st_share:post_trend | dist_id + year,
                 data = nl_panel, cluster = ~dist_id)

cat("\n=== TREND-BREAK SPECIFICATION ===\n")
cat("ST × Trend (pre-existing convergence rate):",
    coef(m_break)["st_share:time_trend"], "\n")
cat("ST × Post-trend (change in rate at 2008):",
    coef(m_break)["st_share:post_trend"], "\n")
print(summary(m_break))

## ── 5. FIRST-DIFFERENCE SPECIFICATION ─────────────────────────────
## If there's a level convergence, first-differencing removes it
## Testing whether the GROWTH RATE of nightlights changed at 2008

nl_panel <- nl_panel[order(dist_id, year)]
nl_panel[, d_log_nl := log_nl - shift(log_nl, 1), by = dist_id]
nl_panel[, d_nl := dmsp_total_light_cal - shift(dmsp_total_light_cal, 1), by = dist_id]

m_fd1 <- feols(d_log_nl ~ treat_st | dist_id + year, data = nl_panel[!is.na(d_log_nl)],
               cluster = ~dist_id)

m_fd2 <- feols(d_log_nl ~ treat_st + treat_sc | dist_id + year,
               data = nl_panel[!is.na(d_log_nl)], cluster = ~dist_id)

cat("\n=== FIRST-DIFFERENCE DiD ===\n")
cat("Growth rate DiD (ST):", coef(m_fd1)["treat_st"], "\n")
print(summary(m_fd1))

## ── 6. FOREST LOSS (with proper ST merge) ─────────────────────────
forest_panel <- fread(file.path(data_dir, "forest_panel.csv"))

## Merge ST shares via state mapping
state_st <- unique(nl_panel[, .(
  st_share_state = weighted.mean(st_share, pc11_pca_tot_p, na.rm = TRUE),
  sc_share_state = weighted.mean(sc_share, pc11_pca_tot_p, na.rm = TRUE)
), by = .(state_id = substr(dist_id, 1, regexpr("_", dist_id) - 1))])

## State name to code mapping
state_map <- data.table(
  NAME_1 = c("Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar",
             "Chhattisgarh", "Goa", "Gujarat", "Haryana",
             "Himachal Pradesh", "Jharkhand", "Karnataka", "Kerala",
             "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya",
             "Mizoram", "Nagaland", "Odisha", "Punjab",
             "Rajasthan", "Sikkim", "Tamil Nadu", "Telangana",
             "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal",
             "Jammu and Kashmir", "NCT of Delhi"),
  state_id = c("28", "12", "18", "10", "22", "30", "24", "06",
               "02", "20", "29", "32", "23", "27", "14", "17",
               "15", "13", "21", "03", "08", "11", "33", "36",
               "16", "09", "05", "19", "01", "07")
)

fp <- merge(forest_panel, state_map, by = "NAME_1", all.x = TRUE)
fp <- merge(fp, state_st, by = "state_id", all.x = TRUE)
fp <- fp[!is.na(st_share_state)]

fp[, treat_st := st_share_state * post2008]
fp[, treat_sc := sc_share_state * post2008]

cat("\nForest panel (with ST):", nrow(fp), "obs,", uniqueN(fp$GID_2), "districts\n")

if (nrow(fp) > 500 && uniqueN(fp[loss_ha > 0]$GID_2) >= 10) {
  m_f1 <- feols(log_loss ~ treat_st | GID_2 + year, data = fp, cluster = ~GID_2)
  m_f2 <- feols(log_loss ~ treat_st + treat_sc | GID_2 + year, data = fp, cluster = ~GID_2)

  ## Interaction with high forest baseline
  tc_med <- median(fp[treecover2000_pct > 0]$treecover2000_pct, na.rm = TRUE)
  fp[, high_forest := as.integer(treecover2000_pct > tc_med)]
  fp[, treat_st_hf := treat_st * high_forest]
  m_f3 <- feols(log_loss ~ treat_st + treat_st_hf | GID_2 + year, data = fp, cluster = ~GID_2)

  cat("\n=== FOREST LOSS RESULTS ===\n")
  print(summary(m_f1))

  ## Forest event study
  fp[, rel_year := year - 2008]
  m_f_es <- feols(log_loss ~ i(rel_year, st_share_state, ref = -1) | GID_2 + year,
                  data = fp, cluster = ~GID_2)
} else {
  cat("Insufficient forest data for analysis. Using partial results.\n")
  m_f1 <- m_f2 <- m_f3 <- m_f_es <- NULL
}

## ── 7. Save results ───────────────────────────────────────────────
results <- list(
  nl_main = m1, nl_placebo = m2, nl_binary = m3, nl_level = m4,
  nl_event = m_es,
  nl_break = m_break,
  nl_fd = m_fd1, nl_fd_placebo = m_fd2,
  forest_main = if (exists("m_f1")) m_f1 else NULL,
  forest_placebo = if (exists("m_f2")) m_f2 else NULL,
  forest_hetero = if (exists("m_f3")) m_f3 else NULL,
  forest_event = if (exists("m_f_es")) m_f_es else NULL
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

## Diagnostics
n_high_st <- uniqueN(nl_panel[high_st == 1]$dist_id)
n_pre <- length(unique(nl_panel[year < 2008]$year))

diag <- list(
  n_treated = n_high_st,
  n_pre = n_pre,
  n_obs = nrow(nl_panel),
  n_districts_nl = uniqueN(nl_panel$dist_id),
  n_districts_forest = uniqueN(fp$GID_2),
  year_range_nl = paste(range(nl_panel$year), collapse = "-"),
  year_range_forest = paste(range(fp$year), collapse = "-")
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\nResults and diagnostics saved.\n")
