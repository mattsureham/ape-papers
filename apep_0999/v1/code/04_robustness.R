# 04_robustness.R — Robustness checks
# apep_0999: IR35 compliance trap

source("00_packages.R")

DATA_DIR <- "../data"

bunching <- fread(file.path(DATA_DIR, "bunching_ratio_panel.csv"))
analysis <- fread(file.path(DATA_DIR, "analysis_panel.csv"))

bunching[, year_f := factor(year)]
bunching[, post_2021 := as.integer(year >= 2021)]
bunching[, contractor := as.integer(sector_type == "contractor")]

analysis[, year_f := factor(year)]
analysis[, post_2021 := as.integer(year >= 2021)]
analysis[, contractor := as.integer(sector_type == "contractor")]
analysis[, log_count := log(pmax(count, 1))]

# ============================================================
# R1: Placebo threshold at 10-19 / 20-49 boundary
# ============================================================
cat("=== R1: Placebo at 20-employee boundary ===\n")

# No policy threshold at 20 employees; should see no differential change
placebo_data <- analysis[emp_lower %in% c(10, 20) & count > 0]
placebo_data[, below_20 := as.integer(emp_upper <= 19)]
placebo_data[, log_count := log(count)]

# Compute ratio: 10-19 / 20-49
placebo_ratio <- dcast(
  placebo_data[, .(count = sum(count)), by = .(year, sector_type, emp_lower)],
  year + sector_type ~ emp_lower,
  value.var = "count"
)
setnames(placebo_ratio, c("10", "20"), c("n_10_19", "n_20_49"))
placebo_ratio[, ratio := n_10_19 / n_20_49]
placebo_ratio[, post_2021 := as.integer(year >= 2021)]
placebo_ratio[, contractor := as.integer(sector_type == "contractor")]

reg_placebo <- feols(
  ratio ~ post_2021:contractor | sector_type + year_f,
  data = placebo_ratio[, year_f := factor(year)],
  vcov = "hetero"
)
cat("Placebo at 20-employee boundary:\n")
summary(reg_placebo)

# ============================================================
# R2: Placebo at 100-249 / 250-499 boundary
# ============================================================
cat("\n=== R2: Placebo at 250-employee boundary ===\n")

placebo_250 <- analysis[emp_lower %in% c(100, 250) & count > 0]
placebo_250_ratio <- dcast(
  placebo_250[, .(count = sum(count)), by = .(year, sector_type, emp_lower)],
  year + sector_type ~ emp_lower,
  value.var = "count"
)
setnames(placebo_250_ratio, c("100", "250"), c("n_100_249", "n_250_499"))
placebo_250_ratio[, ratio := n_100_249 / n_250_499]
placebo_250_ratio[, post_2021 := as.integer(year >= 2021)]
placebo_250_ratio[, contractor := as.integer(sector_type == "contractor")]

reg_placebo_250 <- feols(
  ratio ~ post_2021:contractor | sector_type + year_f,
  data = placebo_250_ratio[, year_f := factor(year)],
  vcov = "hetero"
)
cat("Placebo at 250-employee boundary:\n")
summary(reg_placebo_250)

# ============================================================
# R3: Pre-trend test
# ============================================================
cat("\n=== R3: Pre-trend test ===\n")

pre_data <- bunching[year <= 2020]
pre_data[, year_centered := year - 2019]

reg_pretrend <- feols(
  bunching_ratio ~ year_centered:contractor + year_centered | sic_code,
  data = pre_data,
  vcov = "hetero"
)
cat("Pre-trend test (differential linear trend before 2021):\n")
summary(reg_pretrend)

# ============================================================
# R4: By SIC code (which contractor sectors drive the result?)
# ============================================================
cat("\n=== R4: By SIC code ===\n")

for (sic in unique(bunching[contractor == 1, sic_code])) {
  sic_name <- bunching[sic_code == sic, sic_name[1]]
  sub <- rbind(bunching[sic_code == sic], bunching[contractor == 0])
  reg_sub <- feols(
    bunching_ratio ~ post_2021:contractor | sic_code + year_f,
    data = sub,
    vcov = "hetero"
  )
  ct <- coeftable(reg_sub)
  cat(sprintf("  SIC %s: coef=%.3f, se=%.3f, p=%.3f\n",
              substr(sic_name, 1, 50),
              ct["post_2021:contractor", "Estimate"],
              ct["post_2021:contractor", "Std. Error"],
              ct["post_2021:contractor", "Pr(>|t|)"]))
}

# ============================================================
# R5: Bootstrap inference for DiB
# ============================================================
cat("\n=== R5: Bootstrap inference ===\n")

# Aggregate level for bootstrap
bunching_agg <- bunching[, .(
  bunching_ratio = sum(count_20_49) / sum(count_50_99)
), by = .(year, sector_type, post_2021, contractor)]

boot_dib <- function(data, indices) {
  d <- data[indices]
  m <- d[, .(mr = mean(bunching_ratio)), by = .(contractor, post_2021)]
  if (nrow(m) < 4) return(NA)
  (m[contractor == 1 & post_2021 == 1, mr] - m[contractor == 1 & post_2021 == 0, mr]) -
    (m[contractor == 0 & post_2021 == 1, mr] - m[contractor == 0 & post_2021 == 0, mr])
}

set.seed(42)
boot_res <- boot(bunching_agg, boot_dib, R = 1000)
boot_ci <- boot.ci(boot_res, type = "perc")

cat(sprintf("Bootstrap DiB: %.4f (SE=%.4f)\n", boot_res$t0, sd(boot_res$t, na.rm = TRUE)))
if (!is.null(boot_ci)) {
  cat(sprintf("95%% CI: [%.4f, %.4f]\n", boot_ci$percent[4], boot_ci$percent[5]))
}

# ============================================================
# R6: Exclude COVID years (2020-2021)
# ============================================================
cat("\n=== R6: Excluding 2020-2021 ===\n")

no_covid <- bunching[!year %in% c(2020, 2021)]
no_covid[, post_2022 := as.integer(year >= 2022)]

reg_no_covid <- feols(
  bunching_ratio ~ post_2022:contractor | sic_code + year_f,
  data = no_covid,
  vcov = "hetero"
)
cat("Excluding COVID years (2020-2021), using 2022+ as post:\n")
summary(reg_no_covid)

# ============================================================
# Save robustness results
# ============================================================

robustness <- list(
  placebo_20_coef = coef(reg_placebo)["post_2021:contractor"],
  placebo_20_se = sqrt(vcov(reg_placebo)["post_2021:contractor", "post_2021:contractor"]),
  placebo_20_p = coeftable(reg_placebo)["post_2021:contractor", "Pr(>|t|)"],
  placebo_250_coef = coef(reg_placebo_250)["post_2021:contractor"],
  placebo_250_se = sqrt(vcov(reg_placebo_250)["post_2021:contractor", "post_2021:contractor"]),
  placebo_250_p = coeftable(reg_placebo_250)["post_2021:contractor", "Pr(>|t|)"],
  pretrend_coef = coef(reg_pretrend)["year_centered:contractor"],
  pretrend_se = sqrt(vcov(reg_pretrend)["year_centered:contractor", "year_centered:contractor"]),
  pretrend_p = coeftable(reg_pretrend)["year_centered:contractor", "Pr(>|t|)"],
  boot_se = sd(boot_res$t, na.rm = TRUE),
  boot_ci = if (!is.null(boot_ci)) boot_ci$percent[4:5] else c(NA, NA),
  no_covid_coef = coef(reg_no_covid)["post_2022:contractor"],
  no_covid_se = sqrt(vcov(reg_no_covid)["post_2022:contractor", "post_2022:contractor"]),
  no_covid_p = coeftable(reg_no_covid)["post_2022:contractor", "Pr(>|t|)"]
)

saveRDS(robustness, file.path(DATA_DIR, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
