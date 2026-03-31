## 04_robustness.R — apep_1223: The Choice Tax
## Robustness checks and placebo tests

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
advice <- fread(file.path(data_dir, "advice_clean.csv"))
age_detail <- fread(file.path(data_dir, "panel_age_detail.csv"))

pot_order <- c("<10K", "10-29K", "30-49K", "50-99K", "100-249K", "250K+")

# ============================================================
# Robustness 1: Exclude COVID period (H1_2020, H2_2020)
# ============================================================
cat("=== Robustness 1: Excluding COVID periods ===\n")

panel_nocovid <- panel[!period %in% c("H1_2020", "H2_2020")]
r1 <- feols(share_fullwd ~ log_pot | period, data = panel_nocovid, cluster = ~period)
cat("Model R1: share_fullwd ~ log_pot | period FE (no COVID)\n")
summary(r1)

# ============================================================
# Robustness 2: Alternative pot-size specification
# ============================================================
cat("\n=== Robustness 2: Pot-size dummies ===\n")

panel[, pot_factor := factor(pot_size, levels = pot_order)]
r2 <- feols(share_fullwd ~ pot_factor | period, data = panel, cluster = ~period)
cat("Model R2: share_fullwd ~ pot_factor | period FE\n")
summary(r2)

# ============================================================
# Robustness 3: Age heterogeneity (mechanism test)
# ============================================================
cat("\n=== Robustness 3: Age heterogeneity ===\n")

# Parse age detail for 2018-24 (we have this from parser)
age_wide <- dcast(age_detail, period + pot_size + age_group ~ method,
                  value.var = "count", fill = 0)
age_wide[, total := annuity + full_withdrawal]
age_wide[total > 0, share_fullwd := full_withdrawal / total]

pot_midpoints <- c(5000, 19500, 39500, 74500, 174500, 375000)
age_wide[, pot_idx := match(pot_size, pot_order)]
age_wide[, pot_mid := pot_midpoints[pot_idx]]
age_wide[, log_pot := log(pot_mid)]

period_order <- c("H2_2015", "H1_2016", "H2_2016", "H1_2017", "H2_2017",
                  "H1_2018", "H2_2018", "H1_2019", "H2_2019",
                  "H1_2020", "H2_2020", "H1_2021", "H2_2021",
                  "H1_2022", "H2_2022", "H1_2023", "H2_2023")
age_wide[, period_num := match(period, period_order)]

# The pot-size gradient should be stronger for 55-64 (just retired, more alternatives)
# than for 75+ (fewer alternatives, simpler needs)
r3_young <- feols(share_fullwd ~ log_pot | period,
                  data = age_wide[age_group == "55-64" & total > 0],
                  cluster = ~period)
r3_old <- feols(share_fullwd ~ log_pot | period,
                data = age_wide[age_group == "75+" & total > 0],
                cluster = ~period)

cat("R3a: 55-64 year olds\n")
summary(r3_young)
cat("R3b: 75+ year olds\n")
summary(r3_old)

# ============================================================
# Robustness 4: Stability test — early vs late periods
# ============================================================
cat("\n=== Robustness 4: Early vs Late ===\n")

panel[, era := ifelse(period_num <= 8, "early", "late")]
r4_early <- feols(share_fullwd ~ log_pot | period, data = panel[era == "early"], cluster = ~period)
r4_late <- feols(share_fullwd ~ log_pot | period, data = panel[era == "late"], cluster = ~period)

cat("R4a: Early (2015-2019)\n")
summary(r4_early)
cat("R4b: Late (2020-2024)\n")
summary(r4_late)

# ============================================================
# Robustness 5: Placebo — Drawdown share gradient over time
# (If choice is just about pot size, drawdown share should
#  be constant over time within each pot-size band)
# ============================================================
cat("\n=== Robustness 5: Drawdown stability ===\n")

panel[, year_num := as.numeric(sub("H[12]_", "", period))]
r5 <- feols(share_drawdown ~ log_pot + log_pot:year_num | period,
            data = panel[period_num >= 6], cluster = ~period)  # 2018+ for consistency
cat("R5: Drawdown share stability\n")
summary(r5)

# ============================================================
# Save robustness models
# ============================================================
save(r1, r2, r3_young, r3_old, r4_early, r4_late, r5,
     file = file.path(data_dir, "robustness_models.RData"))

cat("\nRobustness checks complete.\n")
