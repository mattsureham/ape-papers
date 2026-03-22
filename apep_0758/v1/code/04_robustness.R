# 04_robustness.R — Robustness checks for BBCE
source("00_packages.R")

analysis <- readRDS("../data/analysis.rds")

# ── 1. Heterogeneity by baseline SNAP rate ──
cat("=== Heterogeneity by baseline SNAP rate ===\n")
het_snap <- feols(snap_rate ~ bbce_on + I(bbce_on * high_snap_base) | state_id + year,
                  data = analysis %>% filter(!is.na(high_snap_base)),
                  cluster = ~state_id)
print(summary(het_snap))

# ── 2. CS-DiD with not-yet-treated control ──
cat("\n=== CS-DiD with not-yet-treated control ===\n")
cs_groups <- unique(analysis$gname_cs[analysis$gname_cs > 0])
cs_nyt <- NULL

if (length(cs_groups) >= 1) {
  cs_data <- analysis %>% filter(!is.na(snap_rate)) %>% as.data.frame()
  cs_nyt <- tryCatch({
    out <- att_gt(yname = "snap_rate", tname = "year", idname = "state_id",
                  gname = "gname_cs", data = cs_data,
                  control_group = "notyettreated", print_details = FALSE)
    agg <- aggte(out, type = "simple")
    cat("CS-DiD (not-yet-treated) ATT:\n"); print(summary(agg))
    list(att_gt = out, agg = agg)
  }, error = function(e) { message("CS-DiD NYT failed: ", e$message); NULL })
}

# ── 3. Placebo: pre-period fake treatment ──
cat("\n=== Placebo: pre-period test ===\n")
pre_data <- analysis %>% filter(year <= 2008, first_treat >= 2009 | first_treat == 0)
if (nrow(pre_data) > 20) {
  pre_data <- pre_data %>%
    mutate(fake_post = as.integer(year >= 2007),
           fake_treat = as.integer(first_treat > 0) * fake_post)
  placebo <- feols(snap_rate ~ fake_treat | state_id + year,
                   data = pre_data, cluster = ~state_id)
  cat("Placebo (fake treatment at 2007):\n"); print(summary(placebo))
} else {
  placebo <- NULL
  message("Not enough pre-period data for placebo test")
}

# ── 4. Controlling for unemployment ──
cat("\n=== TWFE with unemployment control ===\n")
twfe_ctrl <- feols(snap_rate ~ bbce_on + unemp_rate | state_id + year,
                   data = analysis, cluster = ~state_id)
print(summary(twfe_ctrl))

# Save
rob_results <- list(het_snap = het_snap, cs_nyt = cs_nyt,
                    placebo = placebo, twfe_ctrl = twfe_ctrl)
saveRDS(rob_results, "../data/robustness_results.rds")
cat("Robustness complete.\n")
