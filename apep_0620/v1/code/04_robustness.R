# 04_robustness.R — Robustness checks
# apep_0620: Second-generation refugee dispersal outcomes in Denmark

source("00_packages.R")

analysis <- readRDS("../data/analysis_cross_section.rds")
historical <- readRDS("../data/analysis_historical.rds")
panel <- readRDS("../data/analysis_panel.rds")

cat("=== Robustness Checks ===\n")

# ─────────────────────────────────────────────────────────────────────────────
# 1. Change-based specification (subsample with historical data)
#    Key robustness: control for pre-dispersal immigrant levels
# ─────────────────────────────────────────────────────────────────────────────
cat("\n1. Change-based specification (47 overlapping municipalities)...\n")

# Construct dispersal-era change for overlapping municipalities
hist_change <- historical %>%
  filter(year %in% c(1986, 2000)) %>%
  select(muni, year, imm_share) %>%
  pivot_wider(names_from = year, values_from = imm_share, names_prefix = "imm_") %>%
  mutate(imm_change_86_00 = imm_2000 - imm_1986) %>%
  rename(imm_share_1986 = imm_1986, imm_share_2000 = imm_2000)

hist_1985 <- historical %>%
  filter(year == 1985) %>%
  select(muni, imm_share_1985 = imm_share)

change_data <- analysis %>%
  inner_join(hist_change, by = "muni") %>%
  left_join(hist_1985, by = "muni")

cat(sprintf("  %d municipalities in change sample\n", nrow(change_data)))

# Employment: change-based with pre-dispersal control
r1_emp <- feols(emp_rate_desc ~ imm_change_86_00 + imm_share_1985 + log_pop,
  data = change_data, vcov = "hetero")

# Education: change-based with pre-dispersal control
r1_edu <- feols(share_tertiary ~ imm_change_86_00 + imm_share_1985 + log_pop,
  data = change_data, vcov = "hetero")

cat("  Change specification (employment):\n")
etable(r1_emp, keep = c("imm_change", "imm_share_1985"))

cat("  Change specification (education):\n")
etable(r1_edu, keep = c("imm_change", "imm_share_1985"))

# ─────────────────────────────────────────────────────────────────────────────
# 2. Excluding Copenhagen and other major cities
# ─────────────────────────────────────────────────────────────────────────────
cat("\n2. Excluding major cities...\n")

major_cities <- c("Copenhagen", "Frederiksberg", "Aarhus", "Odense", "Aalborg")
analysis_nocity <- analysis %>%
  filter(!(muni %in% major_cities))

r2_emp <- feols(emp_rate_desc ~ imm_share_2008 + log_pop + total_emp_rate | region,
  data = analysis_nocity, vcov = "hetero")

r2_edu <- feols(share_tertiary ~ imm_share_2008 + log_pop + total_emp_rate | region,
  data = analysis_nocity, vcov = "hetero")

cat(sprintf("  %d municipalities (excl. %d major cities)\n",
  nrow(analysis_nocity), nrow(analysis) - nrow(analysis_nocity)))
cat("  Employment (no cities):\n")
etable(r2_emp, keep = "imm_share")
cat("  Education (no cities):\n")
etable(r2_edu, keep = "imm_share")

# ─────────────────────────────────────────────────────────────────────────────
# 3. Population-weighted regression
# ─────────────────────────────────────────────────────────────────────────────
cat("\n3. Population-weighted specification...\n")

r3_emp <- feols(emp_rate_desc ~ imm_share_2008 + log_pop + total_emp_rate | region,
  data = analysis, weights = ~total_pop, vcov = "hetero")

r3_edu <- feols(share_tertiary ~ imm_share_2008 + log_pop + total_emp_rate | region,
  data = analysis, weights = ~total_pop, vcov = "hetero")

cat("  Weighted employment:\n")
etable(r3_emp, keep = "imm_share")
cat("  Weighted education:\n")
etable(r3_edu, keep = "imm_share")

# ─────────────────────────────────────────────────────────────────────────────
# 4. Alternative treatment: descendant share (instead of immigrant share)
# ─────────────────────────────────────────────────────────────────────────────
cat("\n4. Alternative treatment: descendant share...\n")

analysis <- analysis %>%
  mutate(desc_share_2008 = descendant_pop / total_pop)

r4_emp <- feols(emp_rate_desc ~ desc_share_2008 + log_pop + total_emp_rate | region,
  data = analysis, vcov = "hetero")

r4_edu <- feols(share_tertiary ~ desc_share_2008 + log_pop + total_emp_rate | region,
  data = analysis, vcov = "hetero")

cat("  Employment (descendant share):\n")
etable(r4_emp, keep = "desc_share")
cat("  Education (descendant share):\n")
etable(r4_edu, keep = "desc_share")

# ─────────────────────────────────────────────────────────────────────────────
# 5. Tercile-based specification (non-parametric)
# ─────────────────────────────────────────────────────────────────────────────
cat("\n5. Tercile-based specification...\n")

analysis <- analysis %>%
  mutate(
    imm_tercile = ntile(imm_share_2008, 3),
    imm_tercile_f = factor(imm_tercile, labels = c("Low", "Medium", "High"))
  )

r5_emp <- feols(emp_rate_desc ~ imm_tercile_f + log_pop + total_emp_rate | region,
  data = analysis, vcov = "hetero")

r5_edu <- feols(share_tertiary ~ imm_tercile_f + log_pop + total_emp_rate | region,
  data = analysis, vcov = "hetero")

# Tercile means
cat("  Tercile means:\n")
analysis %>%
  group_by(imm_tercile_f) %>%
  summarise(
    n = n(),
    mean_imm_share = mean(imm_share_2008) * 100,
    mean_emp = mean(emp_rate_desc, na.rm = TRUE),
    mean_edu = mean(share_tertiary, na.rm = TRUE) * 100,
    .groups = "drop"
  ) %>%
  print()

cat("\n  Tercile employment:\n")
etable(r5_emp, keep = "imm_tercile")
cat("  Tercile education:\n")
etable(r5_edu, keep = "imm_tercile")

# ─────────────────────────────────────────────────────────────────────────────
# 6. Placebo outcome: Danish-origin employment in same municipality
# ─────────────────────────────────────────────────────────────────────────────
cat("\n6. Placebo: Danish-origin employment...\n")

r6_placebo <- feols(dk_emp_rate ~ imm_share_2008 + log_pop | region,
  data = analysis, vcov = "hetero")

cat("  Danish-origin employment (placebo):\n")
etable(r6_placebo, keep = "imm_share")

# ─────────────────────────────────────────────────────────────────────────────
# Save robustness models
# ─────────────────────────────────────────────────────────────────────────────
saveRDS(list(
  change_emp = r1_emp, change_edu = r1_edu,
  nocity_emp = r2_emp, nocity_edu = r2_edu,
  weighted_emp = r3_emp, weighted_edu = r3_edu,
  desc_emp = r4_emp, desc_edu = r4_edu,
  tercile_emp = r5_emp, tercile_edu = r5_edu,
  placebo_dk = r6_placebo,
  change_data = change_data
), "../data/robustness_objects.rds")

cat("\n=== Robustness checks complete ===\n")
