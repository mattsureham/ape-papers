## 02_clean_data.R — Construct analysis panel
## apep_0655: The Employer Side of Deportation

source("00_packages.R")

cat("=== Loading data ===\n")
qwi <- readRDS("../data/qwi_rh_raw.rds")
sc <- readRDS("../data/sc_activation_dates.rds")

# ------------------------------------------------------------------
# 1. Create year-quarter variable and filter
# ------------------------------------------------------------------
cat("=== Constructing panel ===\n")

qwi <- qwi %>%
  mutate(
    county_fips = sprintf("%05d", as.integer(county_fips)),
    yq = year + (quarter - 1) / 4,
    # Calendar quarter as integer for CS-DiD
    cal_q = (year - 2005) * 4 + quarter,
    ethnicity = ifelse(eth_code == "A2", "Hispanic", "Non-Hispanic")
  )

# ------------------------------------------------------------------
# 2. Aggregate to county x quarter x ethnicity (all industries pooled)
# ------------------------------------------------------------------
cat("  Aggregating across industries...\n")

panel_agg <- qwi %>%
  group_by(county_fips, year, quarter, yq, cal_q, ethnicity) %>%
  summarise(
    emp = sum(emp, na.rm = TRUE),
    hir_all = sum(hir_all, na.rm = TRUE),
    hir_new = sum(hir_new, na.rm = TRUE),
    sep = sum(sep, na.rm = TRUE),
    frm_job_gn = sum(frm_job_gn, na.rm = TRUE),
    frm_job_ls = sum(frm_job_ls, na.rm = TRUE),
    # Earnings: weighted by employment
    earn_s = {
      valid <- !is.na(earn_s) & !is.na(emp)
      if (sum(valid) > 0) weighted.mean(earn_s[valid], w = pmax(emp[valid], 1))
      else NA_real_
    },
    n_industries = n(),
    .groups = "drop"
  )

cat(sprintf("  Aggregated panel: %s rows\n", format(nrow(panel_agg), big.mark = ",")))

# ------------------------------------------------------------------
# 3. Merge with SC activation dates
# ------------------------------------------------------------------
cat("  Merging SC activation dates...\n")

sc_slim <- sc %>%
  select(county_fips, act_date, act_year, act_quarter, act_yq) %>%
  mutate(
    county_fips = sprintf("%05d", as.integer(county_fips)),
    # First treatment quarter (calendar quarter index)
    first_treat_q = (act_year - 2005) * 4 + act_quarter
  )

panel <- panel_agg %>%
  left_join(sc_slim, by = "county_fips")

# Counties without SC dates are likely territories — drop them
panel <- panel %>% filter(!is.na(act_date))

cat(sprintf("  Panel after SC merge: %s rows\n", format(nrow(panel), big.mark = ",")))
cat(sprintf("  Counties: %d\n", n_distinct(panel$county_fips)))

# ------------------------------------------------------------------
# 4. Create treatment variables
# ------------------------------------------------------------------
cat("  Creating treatment variables...\n")

panel <- panel %>%
  mutate(
    post_sc = as.integer(yq >= act_yq),
    hispanic = as.integer(ethnicity == "Hispanic"),
    # DDD interaction
    treat_ddd = post_sc * hispanic,
    # Event time (quarters relative to activation)
    event_q = cal_q - first_treat_q,
    # State FIPS for clustering
    state_fips = substr(county_fips, 1, 2),
    # Log outcomes (adding 1 to avoid log(0))
    ln_emp = log(emp + 1),
    ln_hir = log(hir_all + 1),
    ln_sep = log(sep + 1),
    ln_earn = log(earn_s + 1),
    # Net job creation
    net_job_creation = frm_job_gn - frm_job_ls,
    ln_frm_job_gn = log(frm_job_gn + 1),
    ln_frm_job_ls = log(frm_job_ls + 1)
  )

# ------------------------------------------------------------------
# 5. Industry-level panel for heterogeneity analysis
# ------------------------------------------------------------------
cat("  Building industry-level panel...\n")

# Define high-immigrant vs low-immigrant industries
high_imm_industries <- c("23", "72", "56", "11")  # Construction, Accommodation, Admin, Agriculture
low_imm_industries <- c("52", "54", "61")  # Finance, Professional, Education

panel_ind <- qwi %>%
  filter(industry %in% c(high_imm_industries, low_imm_industries)) %>%
  mutate(
    county_fips = sprintf("%05d", as.integer(county_fips)),
    ind_type = case_when(
      industry %in% high_imm_industries ~ "High-Immigrant",
      industry %in% low_imm_industries ~ "Low-Immigrant",
      TRUE ~ "Other"
    )
  ) %>%
  group_by(county_fips, year, quarter, yq, ethnicity, ind_type) %>%
  summarise(
    emp = sum(emp, na.rm = TRUE),
    hir_all = sum(hir_all, na.rm = TRUE),
    sep = sum(sep, na.rm = TRUE),
    frm_job_gn = sum(frm_job_gn, na.rm = TRUE),
    frm_job_ls = sum(frm_job_ls, na.rm = TRUE),
    earn_s = {
      valid <- !is.na(earn_s) & !is.na(emp)
      if (sum(valid) > 0) weighted.mean(earn_s[valid], w = pmax(emp[valid], 1))
      else NA_real_
    },
    .groups = "drop"
  ) %>%
  mutate(cal_q = (year - 2005) * 4 + quarter) %>%
  left_join(sc_slim, by = "county_fips") %>%
  filter(!is.na(act_date)) %>%
  mutate(
    post_sc = as.integer(yq >= act_yq),
    hispanic = as.integer(ethnicity == "Hispanic"),
    treat_ddd = post_sc * hispanic,
    event_q = cal_q - first_treat_q,
    state_fips = substr(county_fips, 1, 2),
    ln_emp = log(emp + 1),
    ln_hir = log(hir_all + 1)
  )

# ------------------------------------------------------------------
# 6. Summary statistics
# ------------------------------------------------------------------
cat("\n=== Panel Summary ===\n")
cat(sprintf("  Total observations: %s\n", format(nrow(panel), big.mark = ",")))
cat(sprintf("  Counties: %d\n", n_distinct(panel$county_fips)))
cat(sprintf("  States: %d\n", n_distinct(panel$state_fips)))
cat(sprintf("  Quarters: %d (%d Q%d to %d Q%d)\n",
            n_distinct(panel$cal_q),
            min(panel$year), min(panel$quarter[panel$year == min(panel$year)]),
            max(panel$year), max(panel$quarter[panel$year == max(panel$year)])))
cat(sprintf("  Hispanic obs: %s\n", format(sum(panel$hispanic), big.mark = ",")))
cat(sprintf("  Non-Hispanic obs: %s\n", format(sum(!panel$hispanic), big.mark = ",")))

# Activation cohort sizes
cohort_sizes <- sc_slim %>%
  mutate(cohort_year = act_year) %>%
  count(cohort_year, name = "n_counties")
cat("\n  SC activation cohorts:\n")
print(cohort_sizes)

# ------------------------------------------------------------------
# 7. Save analysis panels
# ------------------------------------------------------------------
cat("\n=== Saving analysis panels ===\n")
saveRDS(panel, "../data/panel_main.rds")
saveRDS(panel_ind, "../data/panel_industry.rds")

cat(sprintf("  Saved panel_main.rds: %s rows\n", format(nrow(panel), big.mark = ",")))
cat(sprintf("  Saved panel_industry.rds: %s rows\n", format(nrow(panel_ind), big.mark = ",")))
cat("=== Data cleaning complete ===\n")
