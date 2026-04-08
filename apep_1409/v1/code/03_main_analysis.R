# =============================================================================
# 03_main_analysis.R — Main DiD estimation
# Paper: From the Ballot Box to the Bureau (apep_1409)
# =============================================================================

source("00_packages.R")
library(fixest)
library(did)
library(dplyr)

panel <- readRDS("../data/analysis_panel.rds")

# =============================================================================
# 1. PREPARE DATA
# =============================================================================

# Drop observations with zero foreign pop (can't compute rate)
panel <- panel |>
  filter(foreign_pop > 0, !is.na(nat_rate), is.finite(nat_rate))

cat(sprintf("Analysis sample: %d obs, %d communes, %d years\n",
            nrow(panel), n_distinct(panel$bfs_nr), n_distinct(panel$year)))

# =============================================================================
# 2. BASIC DiD — TWFE
# =============================================================================

cat("\n=== TABLE 1: Main DiD Results ===\n")

# Column 1: Simple DiD
m1 <- feols(nat_rate ~ ballot:post | bfs_nr + year,
            data = panel, cluster = ~canton_abbr)

# Column 2: Add canton-specific trends
m2 <- feols(nat_rate ~ ballot:post | bfs_nr + year + canton_abbr[year],
            data = panel, cluster = ~canton_abbr)

# Column 3: Log naturalizations (intensive margin)
m3 <- feols(log_nat ~ ballot:post | bfs_nr + year,
            data = panel, cluster = ~canton_abbr)

# Column 4: Naturalization rate per total population
m4 <- feols(nat_rate_pop ~ ballot:post | bfs_nr + year,
            data = panel, cluster = ~canton_abbr)

# Column 5: Binary outcome — any naturalization in municipality-year
panel$any_nat <- as.integer(panel$naturalizations > 0)
m5 <- feols(any_nat ~ ballot:post | bfs_nr + year,
            data = panel, cluster = ~canton_abbr)

etable(m1, m2, m3, m4, m5,
       headers = c("Nat Rate", "Canton Trends", "Log Nat", "Rate/Pop", "Any Nat"),
       se.below = TRUE)

# =============================================================================
# 3. EVENT STUDY — TWFE
# =============================================================================

cat("\n=== EVENT STUDY ===\n")

# Create event time variable (relative to 2004, with 2003 as base year)
panel <- panel |>
  mutate(event_time = year - 2004)

# Bin endpoints: -10 and earlier, +10 and later
panel <- panel |>
  mutate(event_time_binned = case_when(
    event_time <= -10 ~ -10L,
    event_time >= 15 ~ 15L,
    TRUE ~ as.integer(event_time)
  ))

# Event study with TWFE
es_twfe <- feols(nat_rate ~ i(event_time_binned, ballot, ref = -1) | bfs_nr + year,
                 data = panel, cluster = ~canton_abbr)

cat("Event study coefficients:\n")
summary(es_twfe)

# Save event study coefficients for plotting
es_coefs <- as.data.frame(coeftable(es_twfe))
es_coefs$event_time <- as.integer(gsub(".*::(-?[0-9]+):.*", "\\1",
                                        rownames(es_coefs)))
es_coefs <- es_coefs |>
  rename(estimate = Estimate, se = `Std. Error`, pval = `Pr(>|t|)`) |>
  mutate(ci_low = estimate - 1.96 * se,
         ci_high = estimate + 1.96 * se)

saveRDS(es_coefs, "../data/event_study_coefs.rds")

# =============================================================================
# 4. CALLAWAY-SANT'ANNA (Heterogeneity-Robust)
# =============================================================================

cat("\n=== CALLAWAY-SANT'ANNA ===\n")

# For C-S, need group variable = first treatment period
# All ballot cantons treated in 2004 (common treatment timing)
# So C-S with common treatment is essentially the same as TWFE
# But we can use it for the formal parallel trends test

# Create first_treat variable
panel <- panel |>
  mutate(first_treat = ifelse(ballot == 1, 2004, 0))  # 0 = never treated

# C-S requires balanced panel. Check balance.
panel_balanced <- panel |>
  group_by(bfs_nr) |>
  filter(n() == max(panel$year) - min(panel$year) + 1) |>
  ungroup()

cat(sprintf("Balanced panel: %d obs, %d communes\n",
            nrow(panel_balanced), n_distinct(panel_balanced$bfs_nr)))

# If too many are dropped, use unbalanced approach
if (n_distinct(panel_balanced$bfs_nr) < 500) {
  cat("WARNING: Too few balanced communes. Using allow_unbalanced_panel.\n")
  cs_data <- panel
  allow_unbal <- TRUE
} else {
  cs_data <- panel_balanced
  allow_unbal <- FALSE
}

tryCatch({
  cs_out <- att_gt(
    yname = "nat_rate",
    tname = "year",
    idname = "bfs_nr",
    gname = "first_treat",
    data = cs_data,
    control_group = "nevertreated",
    allow_unbalanced_panel = allow_unbal,
    base_period = "universal"
  )

  cat("\nC-S Group-Time ATTs:\n")
  summary(cs_out)

  # Aggregate to event study
  cs_es <- aggte(cs_out, type = "dynamic")
  cat("\nC-S Event Study:\n")
  summary(cs_es)

  # Aggregate to simple ATT
  cs_att <- aggte(cs_out, type = "simple")
  cat("\nC-S Simple ATT:\n")
  summary(cs_att)

  saveRDS(cs_out, "../data/cs_results.rds")
  saveRDS(cs_es, "../data/cs_event_study.rds")
  saveRDS(cs_att, "../data/cs_att.rds")

}, error = function(e) {
  cat("C-S estimation error:", conditionMessage(e), "\n")
  cat("Proceeding with TWFE results only.\n")
})

# =============================================================================
# 5. HETEROGENEITY BY CANTON
# =============================================================================

cat("\n=== CANTON-LEVEL HETEROGENEITY ===\n")

# Estimate canton-specific treatment effects
het_canton <- feols(nat_rate ~ i(canton_abbr, post) | bfs_nr + year,
                    data = panel |> filter(ballot == 1),
                    cluster = ~canton_abbr)

cat("Canton-specific post-2003 effects (ballot cantons):\n")
summary(het_canton)

# =============================================================================
# 6. DIAGNOSTICS
# =============================================================================

cat("\n=== DIAGNOSTICS ===\n")

# Sample size info for validator
n_treated <- n_distinct(panel$bfs_nr[panel$ballot == 1])
n_control <- n_distinct(panel$bfs_nr[panel$ballot == 0])
n_pre <- length(unique(panel$year[panel$year < 2004]))
n_post <- length(unique(panel$year[panel$year >= 2004]))
n_obs <- nrow(panel)

cat(sprintf("Treated communes: %d\n", n_treated))
cat(sprintf("Control communes: %d\n", n_control))
cat(sprintf("Pre-treatment years: %d\n", n_pre))
cat(sprintf("Post-treatment years: %d\n", n_post))
cat(sprintf("Total observations: %d\n", n_obs))

# Pre-treatment means
pre_stats <- panel |>
  filter(year < 2004) |>
  group_by(treatment_group) |>
  summarize(
    mean_nat_rate = mean(nat_rate, na.rm = TRUE),
    sd_nat_rate = sd(nat_rate, na.rm = TRUE),
    mean_nat = mean(naturalizations, na.rm = TRUE),
    mean_fpop = mean(foreign_pop, na.rm = TRUE),
    .groups = "drop"
  )
cat("\nPre-treatment summary:\n")
print(pre_stats)

# Save diagnostics for validator
diag <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_control = n_control,
  n_post = n_post,
  pre_mean_treated = pre_stats$mean_nat_rate[pre_stats$treatment_group == "ballot"],
  pre_sd_treated = pre_stats$sd_nat_rate[pre_stats$treatment_group == "ballot"],
  pre_mean_control = pre_stats$mean_nat_rate[pre_stats$treatment_group == "admin"],
  pre_sd_control = pre_stats$sd_nat_rate[pre_stats$treatment_group == "admin"]
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

# Save main results for tables
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5),
        "../data/main_results.rds")

cat("\n03_main_analysis.R complete.\n")
