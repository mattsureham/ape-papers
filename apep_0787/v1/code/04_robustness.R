## 04_robustness.R — Robustness checks and placebo tests
## apep_0787: PSL mandates and workplace injuries

source("00_packages.R")

data_dir <- "../data"
state_panel <- readRDS(file.path(data_dir, "state_panel.rds"))
industry_panel <- readRDS(file.path(data_dir, "industry_panel.rds"))
state_panel[, treated := as.integer(first_treat > 0 & data_year >= first_treat)]
industry_panel[, treated := as.integer(first_treat > 0 & data_year >= first_treat)]

# ── 1. Sun-Abraham Event Study (fixest::sunab) ──────────────────────────
cat("=== Sun-Abraham Event Study ===\n")

# sunab requires first_treat > 0 for treated, Inf for never-treated
state_panel[, sunab_g := fifelse(first_treat == 0, Inf, as.numeric(first_treat))]

sa_tcr <- feols(tcr ~ sunab(sunab_g, data_year) | state_id + data_year,
                data = state_panel, cluster = ~state_abbr)
sa_dafw <- feols(dafw_rate ~ sunab(sunab_g, data_year) | state_id + data_year,
                 data = state_panel, cluster = ~state_abbr)
sa_djtr <- feols(djtr_rate ~ sunab(sunab_g, data_year) | state_id + data_year,
                 data = state_panel, cluster = ~state_abbr)

cat("Sun-Abraham results:\n")
etable(sa_tcr, sa_dafw, sa_djtr,
       headers = c("TCR", "DAFW", "DJTR"),
       agg = "ATT")

# ── 2. Bacon Decomposition ──────────────────────────────────────────────
cat("\n=== Bacon Decomposition ===\n")
if (!requireNamespace("bacondecomp", quietly = TRUE)) {
  install.packages("bacondecomp", repos = "https://cloud.r-project.org")
}
library(bacondecomp)

bacon_out <- bacon(tcr ~ treated, data = as.data.frame(state_panel),
                   id_var = "state_id", time_var = "data_year")
cat("Bacon decomposition (TCR):\n")
print(aggregate(cbind(estimate, weight) ~ type, data = bacon_out, FUN = mean))

# ── 3. Wild Cluster Bootstrap (few clusters) ────────────────────────────
cat("\n=== Wild Cluster Bootstrap ===\n")
# 8 treated states → need few-cluster inference
# Use fixest's boot with clustered errors

twfe_tcr <- feols(tcr ~ treated | state_id + data_year,
                  data = state_panel, cluster = ~state_abbr)
twfe_djtr <- feols(djtr_rate ~ treated | state_id + data_year,
                   data = state_panel, cluster = ~state_abbr)

# Wild cluster bootstrap via fwildclusterboot
if (!requireNamespace("fwildclusterboot", quietly = TRUE)) {
  install.packages("fwildclusterboot", repos = "https://cloud.r-project.org")
}
library(fwildclusterboot)

cat("Wild cluster bootstrap — TCR:\n")
boot_tcr <- boottest(twfe_tcr, param = "treated", clustid = "state_abbr",
                     B = 9999, type = "webb")
cat("  CI:", boot_tcr$conf_int, "\n")
cat("  p-value:", boot_tcr$p_val, "\n")

cat("Wild cluster bootstrap — DJTR:\n")
boot_djtr <- boottest(twfe_djtr, param = "treated", clustid = "state_abbr",
                      B = 9999, type = "webb")
cat("  CI:", boot_djtr$conf_int, "\n")
cat("  p-value:", boot_djtr$p_val, "\n")

# ── 4. Placebo: Death Rate (rare, not affected by presenteeism) ─────────
cat("\n=== Placebo: Death Rate ===\n")
state_panel[, death_rate := ifelse(fte > 0, (total_deaths / fte) * 100, NA_real_)]

twfe_death <- feols(death_rate ~ treated | state_id + data_year,
                    data = state_panel, cluster = ~state_abbr)
cat("Placebo — Death rate:\n")
etable(twfe_death)

# ── 5. Excluding COVID years (2020-2021) ────────────────────────────────
cat("\n=== Excluding COVID Years ===\n")
no_covid <- state_panel[!(data_year %in% c(2020, 2021))]

twfe_tcr_nc <- feols(tcr ~ treated | state_id + data_year,
                     data = no_covid, cluster = ~state_abbr)
twfe_djtr_nc <- feols(djtr_rate ~ treated | state_id + data_year,
                      data = no_covid, cluster = ~state_abbr)
cat("Excluding COVID (TCR):\n")
etable(twfe_tcr_nc, twfe_djtr_nc,
       headers = c("TCR (no COVID)", "DJTR (no COVID)"))

# ── 6. Industry-level analysis (more variation) ────────────────────────
cat("\n=== Industry-Level TWFE ===\n")
industry_panel[, high := as.integer(hazard_group == "high_hazard")]

twfe_ind_tcr <- feols(tcr ~ treated | cell_id + data_year,
                      data = industry_panel, cluster = ~state_abbr)
twfe_ind_dafw <- feols(dafw_rate ~ treated | cell_id + data_year,
                       data = industry_panel, cluster = ~state_abbr)
twfe_ind_djtr <- feols(djtr_rate ~ treated | cell_id + data_year,
                       data = industry_panel, cluster = ~state_abbr)
cat("Industry-level TWFE:\n")
etable(twfe_ind_tcr, twfe_ind_dafw, twfe_ind_djtr,
       headers = c("TCR", "DAFW", "DJTR"))

# ── 7. Heterogeneity by hazard group ───────────────────────────────────
cat("\n=== Heterogeneity by Industry Hazard ===\n")
high_panel <- industry_panel[hazard_group == "high_hazard"]
low_panel <- industry_panel[hazard_group == "low_hazard"]

het_high_tcr <- feols(tcr ~ treated | cell_id + data_year,
                      data = high_panel, cluster = ~state_abbr)
het_low_tcr <- feols(tcr ~ treated | cell_id + data_year,
                     data = low_panel, cluster = ~state_abbr)
het_high_djtr <- feols(djtr_rate ~ treated | cell_id + data_year,
                       data = high_panel, cluster = ~state_abbr)
het_low_djtr <- feols(djtr_rate ~ treated | cell_id + data_year,
                      data = low_panel, cluster = ~state_abbr)

cat("Heterogeneity — High vs Low hazard:\n")
etable(het_high_tcr, het_low_tcr, het_high_djtr, het_low_djtr,
       headers = c("TCR High", "TCR Low", "DJTR High", "DJTR Low"))

# ── Save robustness results ────────────────────────────────────────────
rob_results <- list(
  sa_tcr = sa_tcr, sa_dafw = sa_dafw, sa_djtr = sa_djtr,
  bacon = bacon_out,
  boot_tcr = boot_tcr, boot_djtr = boot_djtr,
  twfe_death = twfe_death,
  twfe_tcr_nc = twfe_tcr_nc, twfe_djtr_nc = twfe_djtr_nc,
  twfe_ind_tcr = twfe_ind_tcr, twfe_ind_dafw = twfe_ind_dafw,
  twfe_ind_djtr = twfe_ind_djtr,
  het_high_tcr = het_high_tcr, het_low_tcr = het_low_tcr,
  het_high_djtr = het_high_djtr, het_low_djtr = het_low_djtr
)
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))
cat("\nRobustness results saved.\n")
