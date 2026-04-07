## 03_main_analysis.R — RDD and Difference-in-Discontinuities estimation
source("00_packages.R")

data_dir <- "../data"
df <- fread(file.path(data_dir, "panel_clean.csv"))
message("Loaded: ", format(nrow(df), big.mark = ","), " rows")

# ── Restrict to analysis samples ──
# Main sample: narrow bandwidth (80-120), valid injury rates
rdd_df <- df[in_bandwidth_narrow == TRUE & !is.na(tcr)]
message("Narrow bandwidth sample: ", format(nrow(rdd_df), big.mark = ","))

# Wide bandwidth for robustness
rdd_wide <- df[in_bandwidth_wide == TRUE & !is.na(tcr)]

# ── 1. Cross-sectional RDD (2024 only, Appendix B) ──
message("\n=== 1. Cross-sectional RDD (2024, Appendix B) ===")
post_b <- rdd_df[year == 2024 & appendix_b == 1]
message("N = ", nrow(post_b))

if (nrow(post_b) > 50) {
  rd_tcr <- rdrobust(y = post_b$tcr, x = post_b$emp_centered, c = 0)
  summary(rd_tcr)

  rd_dart <- rdrobust(y = post_b$dart_rate, x = post_b$emp_centered, c = 0)
  summary(rd_dart)
} else {
  message("WARNING: Small sample for 2024 Appendix B RDD")
  rd_tcr <- NULL
  rd_dart <- NULL
}

# ── 2. Pre-period placebo RDD (each year 2016-2023, Appendix B) ──
message("\n=== 2. Year-by-year RDD estimates (event study) ===")
years_all <- sort(unique(rdd_df$year))
rd_by_year <- data.table(
  year = integer(),
  outcome = character(),
  coef = numeric(),
  se = numeric(),
  pval = numeric(),
  n = integer(),
  bw = numeric()
)

for (yr in years_all) {
  for (out in c("tcr", "dart_rate")) {
    sub <- rdd_df[year == yr & appendix_b == 1 & !is.na(get(out))]
    if (nrow(sub) < 50) next

    rd <- rdrobust(y = sub[[out]], x = sub$emp_centered, c = 0)
    rd_by_year <- rbind(rd_by_year, data.table(
      year = yr,
      outcome = out,
      coef = rd$coef[1],
      se = rd$se[3],  # robust SE
      pval = rd$pv[3],
      n = nrow(sub),
      bw = rd$bws[1, 1]
    ))
  }
}
message("Event study estimates:\n")
print(rd_by_year[outcome == "tcr"])

# ── 3. Difference-in-Discontinuities (DinD) ──
# Compare discontinuity in Appendix B vs non-Appendix B industries
message("\n=== 3. Difference-in-Discontinuities ===")

# Parametric DinD with fixest
# Y = β1*Above100 + β2*Above100*AppB + β3*Above100*Post + β4*Above100*AppB*Post
#     + f(emp_centered) + FE
dind_df <- rdd_df[!is.na(tcr)]
dind_df[, emp_c_pos := pmax(emp_centered, 0)]  # for linear spline

# Main DinD specification
dind1 <- feols(tcr ~ above100 * appendix_b * post +
                 emp_centered + emp_c_pos |
                 naics2 + year + state_code,
               data = dind_df,
               cluster = ~naics4)
message("\nDinD (TCR):")
summary(dind1)

dind2 <- feols(dart_rate ~ above100 * appendix_b * post +
                 emp_centered + emp_c_pos |
                 naics2 + year + state_code,
               data = dind_df,
               cluster = ~naics4)
message("\nDinD (DART):")
summary(dind2)

# ── 4. Wide bandwidth robustness ──
message("\n=== 4. Wide bandwidth robustness ===")
dind_wide <- rdd_wide[!is.na(tcr)]
dind_wide[, emp_c_pos := pmax(emp_centered, 0)]

dind3 <- feols(tcr ~ above100 * appendix_b * post +
                 emp_centered + emp_c_pos + I(emp_centered^2) + I(emp_c_pos^2) |
                 naics2 + year + state_code,
               data = dind_wide,
               cluster = ~naics4)
summary(dind3)

# ── 5. Separate outcomes ──
message("\n=== 5. Outcome decomposition ===")
for (out_var in c("total_dafw_cases", "total_djtr_cases", "total_other_cases")) {
  # Rate per 100 FTE
  dind_df[, temp_rate := fifelse(!is.na(hours) & hours > 0,
                                  as.numeric(get(out_var)) / hours * 200000,
                                  NA_real_)]
  m <- feols(temp_rate ~ above100 * appendix_b * post +
               emp_centered + emp_c_pos |
               naics2 + year + state_code,
             data = dind_df[!is.na(temp_rate)],
             cluster = ~naics4)
  message("\n", out_var, ":")
  print(coeftable(m)["above100:appendix_b:post", ])
}

# ── Save results ──
results <- list(
  rd_by_year = rd_by_year,
  dind_tcr_coef = coeftable(dind1),
  dind_dart_coef = coeftable(dind2),
  n_narrow = nrow(rdd_df),
  n_wide = nrow(rdd_wide),
  years = years_all
)
saveRDS(results, file.path(data_dir, "results.rds"))

# ── Diagnostics for validation ──
n_treated <- nrow(dind_df[above100 == 1 & appendix_b == 1 & post == 1])
n_pre <- length(years_all[years_all < 2024])
n_obs <- nrow(dind_df)

jsonlite::write_json(list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
), file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

message("\nDiagnostics: n_treated=", n_treated, ", n_pre=", n_pre, ", n_obs=", n_obs)
message("Main analysis complete.")
