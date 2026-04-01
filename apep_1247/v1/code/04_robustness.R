# =============================================================================
# 04_robustness.R — Robustness checks for ARRA Pell Bartik design
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
setDT(panel)
panel[, event_time := year - 2008]

# ---- 1. Placebo timing: Pre-ARRA Pell share × fake post-2005 ----
message("=== Placebo timing test ===")

# If identification is valid, pre_pell_share should NOT predict Black share
# changes in 2006-2008 relative to 2002-2005
pre_panel <- panel[year %in% 2002:2008]
pre_panel[, fake_post := as.integer(year >= 2006)]

placebo_black_share <- feols(black_share ~ pre_pell_share:fake_post | unitid + year,
                             data = pre_panel, cluster = ~unitid)

message("Placebo timing (pre-ARRA Pell × fake post-2006):")
print(summary(placebo_black_share))

# ---- 2. Triple-difference: Race × Pell dose × Post ----
message("\n=== Triple Difference ===")

# Stack enrollment by race, creating a long panel
long_panel <- rbindlist(list(
  panel[, .(unitid, year, race = "Black", enroll = enroll_black,
            log_enroll = log_enroll_black, pre_pell_share, post, event_time)],
  panel[, .(unitid, year, race = "White", enroll = enroll_white,
            log_enroll = log_enroll_white, pre_pell_share, post, event_time)]
))
long_panel[, minority := as.integer(race == "Black")]

# Triple diff: minority × PellShare × Post
# With unitid-year and unitid-race FE
ddd <- feols(log_enroll ~ minority:pre_pell_share:post +
               minority:post + pre_pell_share:post |
               unitid^year + unitid^minority,
             data = long_panel, cluster = ~unitid)

message("Triple-difference (Black vs White × Pell × Post):")
print(summary(ddd))

# ---- 3. Continuous treatment: using dollar dose instead of share ----
message("\n=== Dollar Dose ===")
# bartik_dose = pre_pell_share × $619
dollar_black_share <- feols(black_share ~ bartik_dose:post | unitid + year,
                            data = panel, cluster = ~unitid)
message("Dollar dose (Pell share × $619) on Black share:")
print(summary(dollar_black_share))

# ---- 4. Alternative clustering: state level ----
message("\n=== State Clustering ===")
inst_dir <- readRDS("../data/inst_directory.rds")
setDT(inst_dir)
panel_state <- merge(panel, unique(inst_dir[, .(unitid, state)]), by = "unitid", all.x = TRUE)

state_black_share <- feols(black_share ~ pre_pell_share:post | unitid + year,
                           data = panel_state, cluster = ~state)
message("State-clustered SEs:")
print(summary(state_black_share))

# ---- 5. Tercile-based analysis (non-parametric) ----
message("\n=== Tercile Analysis ===")
# High Pell vs Low Pell (drop medium for cleaner comparison)
panel_hl <- panel[pell_tercile %in% c("High", "Low")]
panel_hl[, high_pell := as.integer(pell_tercile == "High")]

tercile_black <- feols(log_enroll_black ~ high_pell:post | unitid + year,
                       data = panel_hl, cluster = ~unitid)
tercile_share <- feols(black_share ~ high_pell:post | unitid + year,
                       data = panel_hl, cluster = ~unitid)

message("Tercile (High vs Low Pell) on log Black enrollment:")
print(summary(tercile_black))
message("Tercile on Black share:")
print(summary(tercile_share))

# ---- 6. Exclude institutions with very high Pell share (>0.8) ----
message("\n=== Winsorized Sample ===")
winsor_black <- feols(black_share ~ pre_pell_share:post | unitid + year,
                      data = panel[pre_pell_share <= 0.8 & pre_pell_share >= 0.05],
                      cluster = ~unitid)
message("Winsorized sample (Pell share 0.05-0.80):")
print(summary(winsor_black))

# ---- 7. Event study on Black share ----
message("\n=== Event Study: Black Share ===")
es_share_black <- feols(black_share ~ i(event_time, pre_pell_share, ref = 0) | unitid + year,
                        data = panel, cluster = ~unitid)
message("Event study — Black enrollment share:")
print(summary(es_share_black))

# ---- Save robustness results ----
rob_results <- list(
  placebo_black_share = placebo_black_share,
  ddd = ddd,
  dollar_black_share = dollar_black_share,
  state_black_share = state_black_share,
  tercile_black = tercile_black,
  tercile_share = tercile_share,
  winsor_black = winsor_black,
  es_share_black = es_share_black
)
saveRDS(rob_results, "../data/robustness_results.rds")
message("Robustness results saved.")
