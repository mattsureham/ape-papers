## 03_main_analysis.R — Main DiD analysis
## PPEO (July 2023) in AZ, CA, NV, TX → new hospice enrollments, for-profit share
## Design: TWFE DiD (common treatment timing → TWFE is appropriate)

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "state_quarter_panel.rds"))

# Restrict to 50 states + DC (drop territories)
valid_states <- c(state.abb, "DC")
panel <- panel[state %in% valid_states]
cat(sprintf("Panel: %d rows (%d states × %d quarters)\n",
            nrow(panel), length(unique(panel$state)), length(unique(panel$year_qtr))))

# ============================================================
# 1. Descriptive Statistics
# ============================================================

cat("\n=== Descriptive Statistics ===\n")

# Pre-period means
pre <- panel[post == 0]
post_data <- panel[post == 1]

desc_table <- rbind(
  data.table(
    group = "Treated (pre)",
    mean_enroll = mean(pre[treated_state == 1]$new_enrollments),
    sd_enroll = sd(pre[treated_state == 1]$new_enrollments),
    mean_fp = mean(pre[treated_state == 1]$new_fp),
    mean_np = mean(pre[treated_state == 1]$new_np),
    n_obs = nrow(pre[treated_state == 1])
  ),
  data.table(
    group = "Control (pre)",
    mean_enroll = mean(pre[treated_state == 0]$new_enrollments),
    sd_enroll = sd(pre[treated_state == 0]$new_enrollments),
    mean_fp = mean(pre[treated_state == 0]$new_fp),
    mean_np = mean(pre[treated_state == 0]$new_np),
    n_obs = nrow(pre[treated_state == 0])
  ),
  data.table(
    group = "Treated (post)",
    mean_enroll = mean(post_data[treated_state == 1]$new_enrollments),
    sd_enroll = sd(post_data[treated_state == 1]$new_enrollments),
    mean_fp = mean(post_data[treated_state == 1]$new_fp),
    mean_np = mean(post_data[treated_state == 1]$new_np),
    n_obs = nrow(post_data[treated_state == 1])
  ),
  data.table(
    group = "Control (post)",
    mean_enroll = mean(post_data[treated_state == 0]$new_enrollments),
    sd_enroll = sd(post_data[treated_state == 0]$new_enrollments),
    mean_fp = mean(post_data[treated_state == 0]$new_fp),
    mean_np = mean(post_data[treated_state == 0]$new_np),
    n_obs = nrow(post_data[treated_state == 0])
  )
)
print(desc_table)

# ============================================================
# 2. Main DiD Regressions — New Enrollments
# ============================================================

cat("\n=== Main DiD: New Enrollments ===\n")

# Specification 1: Simple DiD
m1 <- feols(new_enrollments ~ did | state + year_qtr, data = panel,
            cluster = ~state)

# Specification 2: State-specific linear trends
panel[, state_trend := as.numeric(as.factor(state)) * year_qtr]
m2 <- feols(new_enrollments ~ did | state + year_qtr, data = panel,
            cluster = ~state)

# Specification 3: For-profit enrollments only
m3 <- feols(new_fp ~ did | state + year_qtr, data = panel,
            cluster = ~state)

# Specification 4: Nonprofit enrollments only (placebo)
m4 <- feols(new_np ~ did | state + year_qtr, data = panel,
            cluster = ~state)

cat("--- Model 1: Total new enrollments ---\n")
print(summary(m1))
cat("--- Model 3: For-profit new enrollments ---\n")
print(summary(m3))
cat("--- Model 4: Nonprofit new enrollments (placebo) ---\n")
print(summary(m4))

# ============================================================
# 3. Event Study — Dynamic Treatment Effects
# ============================================================

cat("\n=== Event Study ===\n")

# Create event-time dummies (relative quarters)
# Drop rel_qtr == -1 as reference period
panel[, rel_qtr_f := factor(rel_qtr)]

es1 <- feols(new_enrollments ~ i(rel_qtr, treated_state, ref = -1) |
               state + year_qtr,
             data = panel, cluster = ~state)

cat("Event study coefficients:\n")
es_coefs <- as.data.table(coeftable(es1), keep.rownames = TRUE)
setnames(es_coefs, c("term", "estimate", "se", "tstat", "pval"))
es_coefs[, rel_qtr := as.integer(gsub("rel_qtr::-?[0-9]+:treated_state", "",
                                        gsub(".*::", "", term)))]
# Parse the relative quarter from the coefficient name
es_coefs[, rel_qtr := as.integer(str_extract(term, "-?[0-9]+"))]
print(es_coefs[order(rel_qtr), .(rel_qtr, estimate, se, pval)])

# Save event study for table
saveRDS(es_coefs, file.path(data_dir, "event_study_coefs.rds"))

# ============================================================
# 4. Cross-Sectional Quality Comparison (Post-PPEO)
# ============================================================

cat("\n=== Quality Comparison ===\n")

quality <- readRDS(file.path(data_dir, "quality_cross_section.rds"))
quality <- quality[state %in% valid_states]

# Quality regressions: treated vs control states
# These are conditional comparisons, not causal — quality data is cross-sectional
mq1 <- feols(hci_score ~ treated_state, data = quality, cluster = ~state)
mq2 <- feols(visits_near_death ~ treated_state, data = quality, cluster = ~state)

cat("HCI Score (treated vs control):\n")
print(summary(mq1))
cat("Visits Near Death (treated vs control):\n")
print(summary(mq2))

# ============================================================
# 5. Write diagnostics.json
# ============================================================

diagnostics <- list(
  n_treated = length(unique(panel[treated_state == 1]$state)),
  n_pre = length(unique(panel[post == 0]$year_qtr)),
  n_obs = nrow(panel),
  n_states = length(unique(panel$state)),
  n_quarters = length(unique(panel$year_qtr)),
  n_providers_quality = nrow(quality),
  pre_mean_treated = mean(pre[treated_state == 1]$new_enrollments),
  pre_mean_control = mean(pre[treated_state == 0]$new_enrollments),
  pre_sd_treated = sd(pre[treated_state == 1]$new_enrollments)
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)

cat("\nDiagnostics written.\n")
cat(sprintf("  n_treated: %d\n", diagnostics$n_treated))
cat(sprintf("  n_pre: %d\n", diagnostics$n_pre))
cat(sprintf("  n_obs: %d\n", diagnostics$n_obs))

# Save all models for table generation
saveRDS(list(m1 = m1, m3 = m3, m4 = m4, mq1 = mq1, mq2 = mq2, es1 = es1),
        file.path(data_dir, "main_models.rds"))

cat("\n=== Main analysis complete ===\n")
