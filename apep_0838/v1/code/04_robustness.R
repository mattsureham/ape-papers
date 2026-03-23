# 04_robustness.R — Robustness checks
source("00_packages.R")

data_dir <- "../data"
load(file.path(data_dir, "models.RData"))

# ============================================================
# 1. Placebo: pre-period only (fake treatment at 2016)
# ============================================================

cat("=== Robustness 1: Placebo treatment at 2016 ===\n")

panel_pre <- panel[year <= 2019]
panel_pre[, placebo_post := as.integer(year >= 2016)]
panel_pre[, placebo_treat := pre_gender_gap * placebo_post]

m_placebo_fs <- feols(female_share ~ placebo_treat | canton_noga + year,
                      data = panel_pre, cluster = ~noga_code)
m_placebo_emp <- feols(log_emp ~ placebo_treat | canton_noga + year,
                       data = panel_pre, cluster = ~noga_code)

cat("Placebo — Female share:\n")
print(summary(m_placebo_fs))
cat("\nPlacebo — Log employment:\n")
print(summary(m_placebo_emp))

# ============================================================
# 2. Alternative treatment: top vs bottom tercile
# ============================================================

cat("\n=== Robustness 2: Tercile-based treatment ===\n")

gap_vals <- unique(panel[!is.na(pre_gender_gap), .(noga_code, pre_gender_gap)])
q33 <- quantile(gap_vals$pre_gender_gap, 1/3, na.rm = TRUE)
q67 <- quantile(gap_vals$pre_gender_gap, 2/3, na.rm = TRUE)
panel[, tercile := fcase(
  pre_gender_gap <= q33, "low",
  pre_gender_gap <= q67, "mid",
  pre_gender_gap > q67, "high",
  default = NA_character_
)]
panel[, top_tercile := as.integer(tercile == "high")]
panel[, top_tercile_post := top_tercile * post]

m_terc_fs <- feols(female_share ~ top_tercile_post | canton_noga + year,
                   data = panel[tercile %in% c("low", "high")], cluster = ~noga_code)
m_terc_emp <- feols(log_emp ~ top_tercile_post | canton_noga + year,
                    data = panel[tercile %in% c("low", "high")], cluster = ~noga_code)

cat("Tercile — Female share:\n")
print(summary(m_terc_fs))

# ============================================================
# 3. Drop COVID-affected 2020 (mandate year = transition)
# ============================================================

cat("\n=== Robustness 3: Drop 2020 (COVID year) ===\n")

panel_no2020 <- panel[year != 2020]
panel_no2020[, post_no2020 := as.integer(year >= 2021)]
panel_no2020[, treat_no2020 := pre_gender_gap * post_no2020]

m_no2020_fs <- feols(female_share ~ treat_no2020 | canton_noga + year,
                     data = panel_no2020, cluster = ~noga_code)
m_no2020_emp <- feols(log_emp ~ treat_no2020 | canton_noga + year,
                      data = panel_no2020, cluster = ~noga_code)

cat("Drop 2020 — Female share:\n")
print(summary(m_no2020_fs))
cat("\nDrop 2020 — Log employment:\n")
print(summary(m_no2020_emp))

# ============================================================
# 4. Wild cluster bootstrap (small clusters)
# ============================================================

cat("\n=== Robustness 4: Wild cluster bootstrap p-values ===\n")

# We have 76 NOGA clusters — moderate, but let's check with WCB
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)

  wcb_fs <- tryCatch({
    boottest(m1, param = "treat_intensity", B = 999, clustid = ~noga_code)
  }, error = function(e) {
    cat("WCB failed for female share:", e$message, "\n")
    NULL
  })

  if (!is.null(wcb_fs)) {
    cat(sprintf("WCB p-value (female share): %.4f\n", wcb_fs$p_val))
  }

  wcb_emp <- tryCatch({
    boottest(m2, param = "treat_intensity", B = 999, clustid = ~noga_code)
  }, error = function(e) {
    cat("WCB failed for employment:", e$message, "\n")
    NULL
  })

  if (!is.null(wcb_emp)) {
    cat(sprintf("WCB p-value (log employment): %.4f\n", wcb_emp$p_val))
  }
} else {
  cat("fwildclusterboot not available, skipping\n")
}

# ============================================================
# 5. Size class analysis: 50-249 bin share over time
# ============================================================

cat("\n=== Robustness 5: Size class dynamics ===\n")

size_panel <- fread(file.path(data_dir, "sizeclass_panel.csv"))
cat("Size class columns:\n")
print(names(size_panel))

# Clean column names
old_cn <- names(size_panel)
setnames(size_panel, c("canton", "year",
                        gsub("[^a-zA-Z0-9]", "_", old_cn[3:ncol(size_panel)])))
cat("Cleaned names:\n")
print(names(size_panel))

# Compute shares
total_est <- size_panel[, rowSums(.SD, na.rm = TRUE), .SDcols = 3:ncol(size_panel)]
size_panel[, total := total_est]

# Check if column names contain the size class info
size_cols <- names(size_panel)[3:(ncol(size_panel)-1)]
cat("Size columns:", paste(size_cols, collapse = " | "), "\n")

# Compute share of medium firms (50-249) in total
med_col <- grep("50", size_cols, value = TRUE)
if (length(med_col) > 0) {
  size_panel[, share_medium := get(med_col[1]) / total]
  size_panel[, post := as.integer(year >= 2020)]

  # Simple pre-post comparison
  pre_med <- size_panel[post == 0, mean(share_medium, na.rm = TRUE)]
  post_med <- size_panel[post == 1, mean(share_medium, na.rm = TRUE)]
  cat(sprintf("\nMedium firm (50-249) share:\n  Pre-2020: %.4f\n  Post-2020: %.4f\n  Change: %.4f\n",
              pre_med, post_med, post_med - pre_med))

  # Regression
  m_size <- feols(share_medium ~ post | canton, data = size_panel, cluster = ~canton)
  cat("\nMedium firm share regression:\n")
  print(summary(m_size))
}

# ============================================================
# 6. UDEMO: Firm births/deaths in relevant size classes
# ============================================================

cat("\n=== Robustness 6: Firm demographics (UDEMO) ===\n")

udemo <- fread(file.path(data_dir, "udemo_demographics.csv"))
setnames(udemo, c("obs_unit", "noga_div", "size_class", "year", "value"))
udemo[, year := as.integer(year)]

# Active firms by NOGA and year (size 10+)
active <- udemo[obs_unit == "Bestand aktiver Unternehmen" &
                  size_class == "10 oder mehr Beschäftigte" &
                  !grepl("Total", noga_div)]

active[, noga_code := str_extract(noga_div, "^[0-9]+")]

# Merge with pre-treatment gap
gap_dt <- unique(panel[, .(noga_code = as.character(noga_code), pre_gender_gap)])[!is.na(pre_gender_gap)]
active <- merge(active, gap_dt, by = "noga_code", all.x = TRUE)
active <- active[!is.na(pre_gender_gap)]
active[, post := as.integer(year >= 2020)]
active[, treat := pre_gender_gap * post]

m_active <- feols(log(value + 1) ~ treat | noga_code + year,
                  data = active, cluster = ~noga_code)
cat("Active firms (10+):\n")
print(summary(m_active))

# Births
births <- udemo[obs_unit == "Unternehmensneugründungen" &
                  size_class == "10 oder mehr Beschäftigte" &
                  !grepl("Total", noga_div)]
births[, noga_code := str_extract(noga_div, "^[0-9]+")]
births <- merge(births, gap_dt, by = "noga_code", all.x = TRUE)
births <- births[!is.na(pre_gender_gap)]
births[, post := as.integer(year >= 2020)]
births[, treat := pre_gender_gap * post]

m_births <- feols(log(value + 1) ~ treat | noga_code + year,
                  data = births, cluster = ~noga_code)
cat("\nFirm births (10+):\n")
print(summary(m_births))

# ============================================================
# Save all robustness models
# ============================================================

save(m_placebo_fs, m_placebo_emp, m_terc_fs, m_terc_emp,
     m_no2020_fs, m_no2020_emp, m_active, m_births,
     file = file.path(data_dir, "robustness_models.RData"))

cat("\nRobustness checks complete.\n")
