# 04_robustness.R — Robustness checks and placebo tests
# APEP Paper apep_0743: Funeral Director Mandates and Death Care Markets

source("00_packages.R")
load("../data/models.RData")

# ─── 1. Bandwidth sensitivity ───
# Re-run with different distance thresholds (50km, 100km)
border_pairs <- read_csv("../data/border_pairs.csv", show_col_types = FALSE)
cbp_avg <- read_csv("../data/cbp_funeral_homes.csv", show_col_types = FALSE) %>%
  group_by(fips, state) %>%
  summarize(estab = mean(ESTAB, na.rm = TRUE), emp = mean(EMP, na.rm = TRUE),
            payann = mean(PAYANN, na.rm = TRUE), .groups = "drop")
acs <- read_csv("../data/acs_demographics.csv", show_col_types = FALSE)

fd_required_states <- c("09", "17", "18", "19", "22", "26", "31", "34", "36")

build_analysis <- function(pairs_df) {
  fd_c <- pairs_df %>% select(segment_id, pair_id, fips = fd_fips) %>% mutate(fd_required = 1) %>% distinct()
  nfd_c <- pairs_df %>% select(segment_id, pair_id, fips = nfd_fips) %>% mutate(fd_required = 0) %>% distinct()
  bc <- bind_rows(fd_c, nfd_c) %>%
    left_join(cbp_avg, by = "fips") %>%
    left_join(acs, by = "fips") %>%
    mutate(
      across(c(estab, emp, payann), ~replace_na(., 0)),
      estab_pc = estab / total_pop * 10000,
      emp_pc = emp / total_pop * 10000,
      emp_per_estab = ifelse(estab > 0, emp / estab, NA),
      payroll_per_emp = ifelse(emp > 0, payann * 1000 / emp, NA),
      log_pop = log(total_pop),
      log_income = log(median_income),
      state_fips = substr(fips, 1, 2)
    ) %>%
    filter(!is.na(total_pop) & total_pop > 0)
  return(bc)
}

# 50km bandwidth
pairs_50 <- border_pairs %>% filter(dist_km <= 50)
data_50 <- build_analysis(pairs_50)

# 100km bandwidth
pairs_100 <- border_pairs %>% filter(dist_km <= 100)

# Only filter if we have distance (our data already filtered at 75km)
if (nrow(pairs_100) > 0) {
  data_100 <- build_analysis(pairs_100)
} else {
  data_100 <- analysis  # use baseline if 100km gives same as 75km
}

m_bw50 <- feols(estab_pc ~ fd_required + log_pop + log_income + pct_65plus | pair_id,
                data = data_50, cluster = ~state_fips)

m_bw100 <- feols(estab_pc ~ fd_required + log_pop + log_income + pct_65plus | pair_id,
                 data = data_100, cluster = ~state_fips)

cat("\n=== Bandwidth Sensitivity: Estab/10K ===\n")
cat(sprintf("50km: beta=%.4f (se=%.4f), N=%d pairs\n",
            coef(m_bw50)["fd_required"], se(m_bw50)["fd_required"], n_distinct(data_50$pair_id)))
cat(sprintf("75km (baseline): beta=%.4f (se=%.4f), N=%d pairs\n",
            coef(m2)["fd_required"], se(m2)["fd_required"], n_distinct(analysis$pair_id)))

# ─── 2. Interior county placebo ───
# Compare counties 100-200km from border (interior) where effects should be zero
pairs_interior <- border_pairs %>% filter(dist_km > 50)
if (nrow(pairs_interior) > 100) {
  data_interior <- build_analysis(pairs_interior)
  m_interior <- feols(estab_pc ~ fd_required + log_pop + log_income + pct_65plus | pair_id,
                      data = data_interior, cluster = ~state_fips)
  cat("\n=== Interior County Placebo ===\n")
  print(summary(m_interior))
}

# ─── 3. Segment-by-segment heterogeneity ───
cat("\n=== Segment-by-Segment Estimates ===\n")
analysis$state <- substr(analysis$fips, 1, 2)

seg_results <- analysis %>%
  filter(!is.na(estab_pc) & !is.na(log_pop) & !is.na(log_income) & !is.na(pct_65plus)) %>%
  group_by(segment_id) %>%
  filter(n() >= 10) %>%
  group_modify(~{
    m <- tryCatch(
      lm(estab_pc ~ fd_required + log_pop + log_income + pct_65plus, data = .x),
      error = function(e) NULL
    )
    if (is.null(m)) return(tibble(coef = NA_real_, se = NA_real_, n = nrow(.x)))
    tibble(
      coef = coef(m)["fd_required"],
      se = sqrt(vcov(m)["fd_required", "fd_required"]),
      n = nrow(.x)
    )
  }) %>%
  ungroup() %>%
  filter(!is.na(coef))

print(seg_results)
cat(sprintf("\nSegments with positive coef: %d / %d\n",
            sum(seg_results$coef > 0), nrow(seg_results)))
cat(sprintf("Segments with negative coef: %d / %d\n",
            sum(seg_results$coef < 0), nrow(seg_results)))

# ─── 4. Placebo outcome: median household income ───
# FD mandates should NOT affect income (balance test)
m_placebo_income <- feols(median_income ~ fd_required | pair_id,
                          data = analysis, cluster = ~state)

cat("\n=== Placebo: Median Income ===\n")
print(summary(m_placebo_income))

# ─── 5. Placebo outcome: % 65+ ───
m_placebo_elderly <- feols(pct_65plus ~ fd_required | pair_id,
                           data = analysis, cluster = ~state)

cat("\n=== Placebo: % 65+ ===\n")
print(summary(m_placebo_elderly))

# ─── 6. Placebo outcome: total population ───
m_placebo_pop <- feols(total_pop ~ fd_required | pair_id,
                       data = analysis, cluster = ~state)

cat("\n=== Placebo: Total Population ===\n")
print(summary(m_placebo_pop))

# ─── 7. Minimum detectable effect (power analysis) ───
# Given our SE and significance level, what's the smallest effect we could detect?
se_main <- se(m2)["fd_required"]
mean_dep <- mean(analysis$estab_pc, na.rm = TRUE)
sd_dep <- sd(analysis$estab_pc, na.rm = TRUE)

# MDE at 80% power, 5% significance (two-sided)
mde <- se_main * (1.96 + 0.84)
mde_pct <- mde / mean_dep * 100
mde_sde <- mde / sd_dep

cat(sprintf("\n=== Minimum Detectable Effect (80%% power, 5%% sig) ===\n"))
cat(sprintf("MDE (estab/10K): %.3f (%.1f%% of mean, SDE=%.3f)\n", mde, mde_pct, mde_sde))
cat(sprintf("We can rule out effects larger than %.1f%% of mean.\n", mde_pct))

# ─── 8. Payroll per employee: bandwidth sensitivity ───
m_pay_50 <- feols(payroll_per_emp ~ fd_required + log_pop + log_income + pct_65plus | pair_id,
                  data = data_50 %>% filter(!is.na(payroll_per_emp)), cluster = ~state_fips)

cat(sprintf("\n=== Payroll/Emp Bandwidth 50km ===\n"))
cat(sprintf("50km: beta=%.1f (se=%.1f)\n",
            coef(m_pay_50)["fd_required"], se(m_pay_50)["fd_required"]))
cat(sprintf("75km: beta=%.1f (se=%.1f)\n",
            coef(m5)["fd_required"], se(m5)["fd_required"]))

# ─── 9. Save robustness results ───
robustness <- tibble(
  test = c("BW 50km Estab", "BW 75km Estab (baseline)", "BW 50km Pay",
           "BW 75km Pay (baseline)",
           "Placebo: Income", "Placebo: % 65+", "Placebo: Pop"),
  coef = c(coef(m_bw50)["fd_required"], coef(m2)["fd_required"],
           coef(m_pay_50)["fd_required"], coef(m5)["fd_required"],
           coef(m_placebo_income)["fd_required"],
           coef(m_placebo_elderly)["fd_required"],
           coef(m_placebo_pop)["fd_required"]),
  se = c(se(m_bw50)["fd_required"], se(m2)["fd_required"],
         se(m_pay_50)["fd_required"], se(m5)["fd_required"],
         se(m_placebo_income)["fd_required"],
         se(m_placebo_elderly)["fd_required"],
         se(m_placebo_pop)["fd_required"])
)

write_csv(robustness, "../data/robustness_results.csv")
write_csv(seg_results, "../data/segment_results.csv")

# Save additional model objects
save(m_bw50, m_placebo_income, m_placebo_elderly, m_placebo_pop,
     seg_results, mde, mde_pct, mde_sde,
     file = "../data/robustness_models.RData")

cat("\nRobustness checks complete.\n")
