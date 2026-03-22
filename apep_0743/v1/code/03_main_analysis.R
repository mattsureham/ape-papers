# 03_main_analysis.R — Main border discontinuity analysis
# APEP Paper apep_0743: Funeral Director Mandates and Death Care Markets

source("00_packages.R")

analysis <- read_csv("../data/analysis_data.csv", show_col_types = FALSE)
cat(sprintf("Loaded %d observations\n", nrow(analysis)))

# ─── 1. Summary Statistics Table ───
cat("\n=== Raw Means by FD Status ===\n")
summ <- analysis %>%
  group_by(fd_required) %>%
  summarize(
    n_counties = n_distinct(fips),
    mean_estab = mean(estab, na.rm = TRUE),
    sd_estab = sd(estab, na.rm = TRUE),
    mean_estab_pc = mean(estab_pc, na.rm = TRUE),
    sd_estab_pc = sd(estab_pc, na.rm = TRUE),
    mean_emp = mean(emp, na.rm = TRUE),
    sd_emp = sd(emp, na.rm = TRUE),
    mean_emp_per_estab = mean(emp_per_estab, na.rm = TRUE),
    sd_emp_per_estab = sd(emp_per_estab, na.rm = TRUE),
    mean_payroll_per_emp = mean(payroll_per_emp, na.rm = TRUE),
    sd_payroll_per_emp = sd(payroll_per_emp, na.rm = TRUE),
    mean_pop = mean(total_pop, na.rm = TRUE),
    mean_income = mean(median_income, na.rm = TRUE),
    mean_pct65 = mean(pct_65plus, na.rm = TRUE),
    .groups = "drop"
  )
print(summ)

# ─── 2. Main Border-Pair Fixed Effects Regressions ───
# Y_{c,b} = alpha_b + beta * FD_Required + X'gamma + epsilon
# Cluster SEs at state level (9 FD states + adjacent non-FD states)

analysis$state <- substr(analysis$fips, 1, 2)

# Model 1: Establishments per 10K pop — no controls
m1 <- feols(estab_pc ~ fd_required | pair_id,
            data = analysis, cluster = ~state)

# Model 2: Establishments per 10K pop — with controls
m2 <- feols(estab_pc ~ fd_required + log_pop + log_income + pct_65plus | pair_id,
            data = analysis, cluster = ~state)

# Model 3: Employment per 10K pop
m3 <- feols(emp_pc ~ fd_required + log_pop + log_income + pct_65plus | pair_id,
            data = analysis, cluster = ~state)

# Model 4: Employment per establishment (firm size)
m4 <- feols(emp_per_estab ~ fd_required + log_pop + log_income + pct_65plus | pair_id,
            data = analysis %>% filter(!is.na(emp_per_estab)),
            cluster = ~state)

# Model 5: Annual payroll per employee (price proxy)
m5 <- feols(payroll_per_emp ~ fd_required + log_pop + log_income + pct_65plus | pair_id,
            data = analysis %>% filter(!is.na(payroll_per_emp)),
            cluster = ~state)

cat("\n=== Main Results ===\n")
cat("\nModel 1: Establishments/10K (no controls)\n")
print(summary(m1))
cat("\nModel 2: Establishments/10K (with controls)\n")
print(summary(m2))
cat("\nModel 3: Employment/10K\n")
print(summary(m3))
cat("\nModel 4: Employment per establishment (firm size)\n")
print(summary(m4))
cat("\nModel 5: Payroll per employee (price proxy)\n")
print(summary(m5))

# ─── 3. Segment-level Border Fixed Effects ───
# More conservative: use segment FE instead of pair FE

m2_seg <- feols(estab_pc ~ fd_required + log_pop + log_income + pct_65plus | segment_id,
                data = analysis, cluster = ~state)

m5_seg <- feols(payroll_per_emp ~ fd_required + log_pop + log_income + pct_65plus | segment_id,
                data = analysis %>% filter(!is.na(payroll_per_emp)),
                cluster = ~state)

cat("\n=== Segment FE Results ===\n")
cat("Estab/10K with segment FE:\n")
print(summary(m2_seg))
cat("\nPayroll/emp with segment FE:\n")
print(summary(m5_seg))

# ─── 4. Cremation outcomes ───
m6 <- feols(crem_estab_pc ~ fd_required + log_pop + log_income + pct_65plus | pair_id,
            data = analysis, cluster = ~state)

cat("\n=== Cremation Establishments/10K ===\n")
print(summary(m6))

# ─── 5. Save coefficient summary ───
results <- tibble(
  model = c("Estab/10K (no ctrl)", "Estab/10K (ctrl)", "Emp/10K",
            "Emp/Estab", "Payroll/Emp", "Crem Estab/10K"),
  coef = c(coef(m1)["fd_required"], coef(m2)["fd_required"],
           coef(m3)["fd_required"], coef(m4)["fd_required"],
           coef(m5)["fd_required"], coef(m6)["fd_required"]),
  se = c(se(m1)["fd_required"], se(m2)["fd_required"],
         se(m3)["fd_required"], se(m4)["fd_required"],
         se(m5)["fd_required"], se(m6)["fd_required"]),
  mean_dep = c(mean(analysis$estab_pc, na.rm = TRUE),
               mean(analysis$estab_pc, na.rm = TRUE),
               mean(analysis$emp_pc, na.rm = TRUE),
               mean(analysis$emp_per_estab, na.rm = TRUE),
               mean(analysis$payroll_per_emp, na.rm = TRUE),
               mean(analysis$crem_estab_pc, na.rm = TRUE)),
  sd_dep = c(sd(analysis$estab_pc, na.rm = TRUE),
             sd(analysis$estab_pc, na.rm = TRUE),
             sd(analysis$emp_pc, na.rm = TRUE),
             sd(analysis$emp_per_estab, na.rm = TRUE),
             sd(analysis$payroll_per_emp, na.rm = TRUE),
             sd(analysis$crem_estab_pc, na.rm = TRUE))
)

results <- results %>%
  mutate(
    pct_effect = coef / mean_dep * 100,
    sde = coef / sd_dep,
    t_stat = coef / se,
    p_value = 2 * pt(-abs(t_stat), df = n_distinct(analysis$state) - 1)
  )

print(results)
write_csv(results, "../data/main_results.csv")

# ─── 6. Diagnostics JSON ───
diag <- list(
  n_treated = n_distinct(analysis$fips[analysis$fd_required == 1]),
  n_pre = 6L,  # 6 years of CBP data averaged
  n_obs = nrow(analysis),
  n_pairs = n_distinct(analysis$pair_id),
  n_segments = n_distinct(analysis$segment_id),
  n_states = n_distinct(analysis$state),
  fd_states = paste(sort(unique(analysis$state[analysis$fd_required == 1])), collapse = ","),
  main_coef_estab_pc = unname(coef(m2)["fd_required"]),
  main_se_estab_pc = unname(se(m2)["fd_required"]),
  main_coef_payroll = unname(coef(m5)["fd_required"]),
  main_se_payroll = unname(se(m5)["fd_required"])
)

write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics saved.\n")

# Save model objects for table generation
save(m1, m2, m3, m4, m5, m6, m2_seg, m5_seg, analysis,
     file = "../data/models.RData")
cat("Models saved to models.RData\n")
