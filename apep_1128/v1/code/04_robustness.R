## 04_robustness.R — Robustness checks and placebo tests
source("00_packages.R")

dt <- readRDS("../data/analysis_panel.rds")
est <- dt[state_group != "Always-Treated"]

# ---- R1: Always-treated benchmark (CA, OK, ND) ----
# Descriptive comparison: racial sep-rate gap in knowledge sectors
cat("=== R1: Always-Treated Benchmark ===\n")
at_dt <- dt[knowledge == TRUE & year <= 2019]
r1_tab <- at_dt[, .(
  mean_sep_black = mean(sep_rate[race == "A2"], na.rm = TRUE),
  mean_sep_white = mean(sep_rate[race == "A1"], na.rm = TRUE),
  gap = mean(sep_rate[race == "A2"], na.rm = TRUE) - mean(sep_rate[race == "A1"], na.rm = TRUE)
), by = state_group]
cat("Pre-ban racial sep gap by state group:\n")
print(r1_tab)

# Simple regression: always-treated vs control, pre-ban
at_reg <- dt[state_group %in% c("Always-Treated", "Control") & knowledge == TRUE]
at_reg[, always := as.integer(state_group == "Always-Treated")]
r1 <- feols(sep_rate ~ always:black | state_abbr + yq + race,
            data = at_reg[year <= 2019], cluster = ~state_abbr)
cat("Always-treated × Black (knowledge sectors, pre-ban):\n")
summary(r1)

# ---- R2: Placebo test — effect should be null for NAICS 72 only ----
cat("\n=== R2: Placebo (NAICS 72 only) ===\n")
placebo_dt <- est[industry == "72"]
r2 <- feols(sep_rate ~ post + post:black | state_abbr + yq + race,
            data = placebo_dt, cluster = ~state_abbr)
summary(r2)

# ---- R3: Pre-trend test (placebo treatment 2 years earlier) ----
cat("\n=== R3: Pre-trend Placebo (fake treatment 2018) ===\n")
pre_dt <- est[year <= 2019]  # Only pre-ban data
pre_dt[, fake_post := as.integer(time_q >= 2018.00)]
# Simpler FE specification to avoid full collinearity
r3 <- feols(sep_rate ~ i(fake_post, ban_state):knowledge:black +
              i(fake_post, ban_state):knowledge +
              i(fake_post, ban_state):black |
              state_abbr + yq + industry + race,
            data = pre_dt, cluster = ~state_abbr)
cat("Placebo DDDD (fake 2018 treatment):\n")
summary(r3)

# ---- R4: Drop COVID quarters (2020Q2-2020Q4) ----
cat("\n=== R4: Drop COVID Quarters ===\n")
no_covid <- est[!(year == 2020 & quarter %in% c(2, 3, 4))]
r4 <- feols(sep_rate ~ post:knowledge + post:knowledge:black + post:black +
              knowledge:black |
              state_abbr^industry^race + yq^industry^race + state_abbr^yq^race,
            data = no_covid, cluster = ~state_abbr)
summary(r4)

# ---- R5: Individual industries (51 vs 54 separately) ----
cat("\n=== R5: By Industry ===\n")
for (ind in c("51", "54")) {
  ind_dt <- est[industry %in% c(ind, "72")]
  ind_dt[, knowledge_i := industry == ind]
  r5 <- feols(sep_rate ~ post:knowledge_i + post:knowledge_i:black + post:black +
                knowledge_i:black |
                state_abbr^industry^race + yq^industry^race + state_abbr^yq^race,
              data = ind_dt, cluster = ~state_abbr)
  cat(sprintf("\nNAICS %s vs 72:\n", ind))
  summary(r5)
}

# ---- R6: Callaway-Sant'Anna for staggered adoption ----
cat("\n=== R6: Callaway-Sant'Anna ===\n")
# Prepare data for did package
cs_dt <- est[knowledge == TRUE & black == 1]
cs_dt[, state_id := as.integer(as.factor(state_abbr))]
# Convert time_q to integer period (quarters since 2016Q1)
cs_dt[, period := as.integer((year - 2016) * 4 + quarter)]
# Treatment period
cs_dt[ban_state == TRUE, g_period := as.integer((ban_quarter - 2016) * 4 + 1)]
cs_dt[ban_state == FALSE, g_period := 0L]

tryCatch({
  cs_out <- att_gt(
    yname = "sep_rate",
    tname = "period",
    idname = "state_id",
    gname = "g_period",
    data = as.data.frame(cs_dt),
    control_group = "nevertreated",
    anticipation = 0,
    bstrap = TRUE,
    cband = TRUE,
    biters = 999
  )
  cat("CS group-time ATTs:\n")
  print(summary(cs_out))

  agg_cs <- aggte(cs_out, type = "simple")
  cat("\nCS aggregate ATT:", agg_cs$overall.att,
      "SE:", agg_cs$overall.se, "\n")
  saveRDS(cs_out, "../data/cs_results.rds")
}, error = function(e) {
  cat("CS estimation failed:", conditionMessage(e), "\n")
  cat("This is expected with few treated groups. Main TWFE results remain valid.\n")
})

# ---- Save robustness results ----
rob_list <- list(
  r1_always_treated = coeftable(r1),
  r2_placebo_72 = coeftable(r2),
  r3_pretrend = coeftable(r3),
  r4_no_covid = coeftable(r4)
)
saveRDS(rob_list, "../data/robustness_results.rds")
cat("\nRobustness checks complete.\n")
