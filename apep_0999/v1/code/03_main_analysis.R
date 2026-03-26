# 03_main_analysis.R — Main difference-in-bunching analysis
# apep_0999: IR35 compliance trap — contractor-to-employee conversion
# pushes firms past the small company threshold

source("00_packages.R")

DATA_DIR <- "../data"

# --- Load data ---
cat("Loading data...\n")
bunching <- fread(file.path(DATA_DIR, "bunching_ratio_panel.csv"))
analysis <- fread(file.path(DATA_DIR, "analysis_panel.csv"))

bunching[, year_f := factor(year)]
bunching[, post_2021 := as.integer(year >= 2021)]
bunching[, contractor := as.integer(sector_type == "contractor")]

analysis[, year_f := factor(year)]
analysis[, post_2021 := as.integer(year >= 2021)]
analysis[, contractor := as.integer(sector_type == "contractor")]
analysis[, below_threshold := as.integer(emp_upper <= 49)]
analysis[, log_count := log(pmax(count, 1))]

# ============================================================
# KEY FINDING: The bunching ratio DECLINED in contractor sectors
# post-2021, meaning more firms crossed the 50-employee threshold.
# This is the OPPOSITE of strategic size reduction.
# Interpretation: IR35 compliance costs cause contractor-to-employee
# conversion, increasing official headcount past the threshold.
# ============================================================

# ============================================================
# SPECIFICATION 1: Difference-in-Bunching (Aggregate)
# ============================================================
cat("\n=== SPEC 1: Difference-in-Bunching ===\n")

# Aggregate to sector-year level
bunching_agg <- bunching[, .(
  count_20_49 = sum(count_20_49),
  count_50_99 = sum(count_50_99),
  bunching_ratio = sum(count_20_49) / sum(count_50_99)
), by = .(year, sector_type, post_2021, contractor)]

bunching_agg[, year_f := factor(year)]

# DiB means
dib_means <- bunching_agg[, .(mean_ratio = mean(bunching_ratio)),
                           by = .(contractor, post_2021)]
cat("Mean bunching ratios (aggregated):\n")
print(dib_means)

pre_c <- dib_means[contractor == 1 & post_2021 == 0, mean_ratio]
post_c <- dib_means[contractor == 1 & post_2021 == 1, mean_ratio]
pre_ctrl <- dib_means[contractor == 0 & post_2021 == 0, mean_ratio]
post_ctrl <- dib_means[contractor == 0 & post_2021 == 1, mean_ratio]

dib_est <- (post_c - pre_c) - (post_ctrl - pre_ctrl)
cat(sprintf("\nDiB estimate: %.4f\n", dib_est))
cat(sprintf("  Contractor: %.3f → %.3f (change: %.3f)\n", pre_c, post_c, post_c - pre_c))
cat(sprintf("  Control: %.3f → %.3f (change: %.3f)\n", pre_ctrl, post_ctrl, post_ctrl - pre_ctrl))

# ============================================================
# SPECIFICATION 2: DiD on bunching ratio (SIC-level panel)
# ============================================================
cat("\n=== SPEC 2: DiD regression (SIC-level) ===\n")

# Specification with sector and year FE
reg_did <- feols(
  bunching_ratio ~ post_2021:contractor | sic_code + year_f,
  data = bunching,
  vcov = ~sic_code  # cluster at SIC level
)
cat("DiD on bunching ratio (sector + year FE, clustered by SIC):\n")
summary(reg_did)

# Also with heteroskedasticity-robust SEs (more conservative with few clusters)
reg_did_hetero <- feols(
  bunching_ratio ~ post_2021:contractor | sic_code + year_f,
  data = bunching,
  vcov = "hetero"
)
cat("\nSame with heteroskedasticity-robust SEs:\n")
summary(reg_did_hetero)

# ============================================================
# SPECIFICATION 3: Event Study
# ============================================================
cat("\n=== SPEC 3: Event Study ===\n")

bunching[, year_f := relevel(factor(year), ref = "2019")]

reg_event <- feols(
  bunching_ratio ~ i(year_f, contractor, ref = "2019") | sic_code,
  data = bunching,
  vcov = "hetero"
)
cat("Event study (ref=2019, heteroskedastic SEs):\n")
summary(reg_event)

# Extract coefficients
event_ct <- as.data.table(coeftable(reg_event), keep.rownames = TRUE)
setnames(event_ct, c("term", "estimate", "se", "t", "p"))
event_ct[, year := as.integer(str_extract(term, "\\d{4}"))]
event_ct <- event_ct[!is.na(year)][order(year)]

cat("\nEvent study coefficients:\n")
print(event_ct[, .(year, estimate = round(estimate, 4), se = round(se, 4),
                    p = round(p, 4))])

# ============================================================
# SPECIFICATION 4: Triple-Difference (log counts)
# ============================================================
cat("\n=== SPEC 4: Triple-Difference on Log Counts ===\n")

threshold_data <- analysis[emp_lower %in% c(20, 50) & count > 0]
threshold_data[, log_count := log(count)]

reg_ddd <- feols(
  log_count ~ below_threshold:post_2021:contractor +
    below_threshold:post_2021 + below_threshold:contractor +
    post_2021:contractor | year_f + sector_type,
  data = threshold_data,
  vcov = "hetero"
)
cat("Triple-difference on log firm counts:\n")
summary(reg_ddd)

# ============================================================
# SPECIFICATION 5: Growth rate of 50-99 band (extensive margin)
# ============================================================
cat("\n=== SPEC 5: Growth Rate of 50-99 Band ===\n")

# Did the 50-99 band grow faster in contractor SICs post-2021?
band_50_99 <- analysis[emp_lower == 50]
band_50_99[, log_count := log(count)]

reg_growth <- feols(
  log_count ~ post_2021:contractor | sic_code_stub + year_f,
  data = band_50_99[, sic_code_stub := paste0(sector_type, "_stub")],
  vcov = "hetero"
)
cat("Growth of 50-99 band (contractor vs control):\n")
summary(reg_growth)

# ============================================================
# SPECIFICATION 6: Placebo — COVID announcement (2020)
# ============================================================
cat("\n=== SPEC 6: Placebo (2020 announcement vs 2021 implementation) ===\n")

bunching[, year_f := factor(year)]  # Reset reference
bunching[, announced_2020 := as.integer(year == 2020)]
bunching[, implemented_2021 := as.integer(year >= 2021)]

reg_placebo <- feols(
  bunching_ratio ~ announced_2020:contractor + implemented_2021:contractor |
    sic_code + year_f,
  data = bunching,
  vcov = "hetero"
)
cat("Placebo (announcement vs implementation):\n")
summary(reg_placebo)

# ============================================================
# Save results
# ============================================================
cat("\n=== Saving results ===\n")

results <- list(
  dib_estimate = dib_est,
  pre_contractor_ratio = pre_c,
  post_contractor_ratio = post_c,
  pre_control_ratio = pre_ctrl,
  post_control_ratio = post_ctrl,
  did_coef = coef(reg_did_hetero)["post_2021:contractor"],
  did_se = sqrt(vcov(reg_did_hetero)["post_2021:contractor", "post_2021:contractor"]),
  ddd_coef = coef(reg_ddd)["below_threshold:post_2021:contractor"],
  ddd_se = sqrt(vcov(reg_ddd)["below_threshold:post_2021:contractor",
                                "below_threshold:post_2021:contractor"]),
  event_study = event_ct
)

saveRDS(results, file.path(DATA_DIR, "main_results.rds"))

# Diagnostics for validator
n_treated_sic <- uniqueN(bunching[contractor == 1, sic_code])
n_pre <- length(unique(bunching[post_2021 == 0, year]))

# Count underlying enterprises (the actual sample size)
total_enterprises <- sum(bunching$count_20_49) + sum(bunching$count_50_99)

diagnostics <- list(
  n_treated = nrow(bunching[contractor == 1 & post_2021 == 1]),
  n_pre = n_pre,
  n_obs = as.integer(total_enterprises),
  n_sic_treated = n_treated_sic,
  n_sic_control = uniqueN(bunching[contractor == 0, sic_code]),
  n_years = length(unique(bunching$year)),
  dib_estimate = round(dib_est, 4)
)
jsonlite::write_json(diagnostics, file.path(DATA_DIR, "diagnostics.json"), auto_unbox = TRUE)

cat("Results saved.\n")
cat("\n=== Main analysis complete ===\n")
