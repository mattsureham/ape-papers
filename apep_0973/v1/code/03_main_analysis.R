## 03_main_analysis.R — Callaway-Sant'Anna DiD + TWFE
## APEP-0973: Plastic Bag Charges and Beach Litter

source("00_packages.R")
setwd(file.path(here::here(), "output", "apep_0973", "v1"))

panel <- as.data.frame(readRDS("data/analysis_panel.rds"))

# Rename for did package (avoids parameter name conflicts)
names(panel)[names(panel) == "gname"] <- "first_treat"
names(panel)[names(panel) == "tname"] <- "time_var"
names(panel)[names(panel) == "idname"] <- "unit_var"

cat("=== Panel Summary ===\n")
cat(sprintf("  Obs: %d, Beaches: %d, Years: %d-%d\n",
            nrow(panel), n_distinct(panel$unit_var),
            min(panel$time_var), max(panel$time_var)))

# ==========================================================================
# 1. TWFE Specifications
# ==========================================================================

cat("\n=== 1. TWFE Regressions ===\n")

twfe_bags <- feols(log_bags ~ post | unit_var + time_var, data = panel, cluster = ~nation)
twfe_total <- feols(log_total ~ post | unit_var + time_var, data = panel, cluster = ~nation)
twfe_nonbag <- feols(log_nonbag ~ post | unit_var + time_var, data = panel, cluster = ~nation)
twfe_share <- feols(bag_share ~ post | unit_var + time_var, data = panel, cluster = ~nation)

cat("TWFE — Log Bags:", sprintf("%.3f (%.3f)", coef(twfe_bags)["post"], se(twfe_bags)["post"]), "\n")
cat("TWFE — Log Total:", sprintf("%.3f (%.3f)", coef(twfe_total)["post"], se(twfe_total)["post"]), "\n")
cat("TWFE — Log Non-Bag:", sprintf("%.3f (%.3f)", coef(twfe_nonbag)["post"], se(twfe_nonbag)["post"]), "\n")
cat("TWFE — Bag Share:", sprintf("%.4f (%.4f)", coef(twfe_share)["post"], se(twfe_share)["post"]), "\n")

# ==========================================================================
# 2. Callaway-Sant'Anna
# ==========================================================================

cat("\n=== 2. Callaway-Sant'Anna ===\n")

cs_bags <- att_gt(yname = "log_bags", tname = "time_var", idname = "unit_var",
                  gname = "first_treat", data = panel,
                  control_group = "notyettreated",
                  allow_unbalanced_panel = TRUE, base_period = "universal")
cs_bags_att <- aggte(cs_bags, type = "simple", na.rm = TRUE)
cs_bags_es <- aggte(cs_bags, type = "dynamic", min_e = -5, max_e = 5, na.rm = TRUE)
cat("CS ATT (Log Bags):", sprintf("%.3f (%.3f)\n", cs_bags_att$overall.att, cs_bags_att$overall.se))

cs_nonbag <- att_gt(yname = "log_nonbag", tname = "time_var", idname = "unit_var",
                    gname = "first_treat", data = panel,
                    control_group = "notyettreated",
                    allow_unbalanced_panel = TRUE, base_period = "universal")
cs_nonbag_att <- aggte(cs_nonbag, type = "simple", na.rm = TRUE)
cat("CS ATT (Log Non-Bag — placebo):", sprintf("%.3f (%.3f)\n", cs_nonbag_att$overall.att, cs_nonbag_att$overall.se))

cs_total <- att_gt(yname = "log_total", tname = "time_var", idname = "unit_var",
                   gname = "first_treat", data = panel,
                   control_group = "notyettreated",
                   allow_unbalanced_panel = TRUE, base_period = "universal")
cs_total_att <- aggte(cs_total, type = "simple", na.rm = TRUE)
cat("CS ATT (Log Total):", sprintf("%.3f (%.3f)\n", cs_total_att$overall.att, cs_total_att$overall.se))

cs_share <- att_gt(yname = "bag_share", tname = "time_var", idname = "unit_var",
                   gname = "first_treat", data = panel,
                   control_group = "notyettreated",
                   allow_unbalanced_panel = TRUE, base_period = "universal")
cs_share_att <- aggte(cs_share, type = "simple", na.rm = TRUE)
cat("CS ATT (Bag Share):", sprintf("%.4f (%.4f)\n", cs_share_att$overall.att, cs_share_att$overall.se))

# ==========================================================================
# 3. Sun-Abraham
# ==========================================================================

cat("\n=== 3. Sun-Abraham ===\n")
sa_bags <- feols(log_bags ~ sunab(first_treat, time_var) | unit_var + time_var,
                 data = panel, cluster = ~nation)
cat("Sun-Abraham — Log Bags:\n")
summary(sa_bags)

# ==========================================================================
# 4. Save
# ==========================================================================

results <- list(
  twfe_bags = twfe_bags, twfe_total = twfe_total,
  twfe_nonbag = twfe_nonbag, twfe_share = twfe_share,
  cs_bags = cs_bags, cs_bags_att = cs_bags_att, cs_bags_es = cs_bags_es,
  cs_nonbag_att = cs_nonbag_att, cs_total_att = cs_total_att,
  cs_share_att = cs_share_att, sa_bags = sa_bags
)
saveRDS(results, "data/main_results.rds")

n_treated <- n_distinct(panel$beach_id[panel$first_treat > 0])
n_pre <- min(panel$first_treat) - min(panel$time_var)
jsonlite::write_json(list(n_treated = n_treated, n_pre = n_pre, n_obs = nrow(panel)),
                     "data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\n=== Done: n_treated=%d, n_pre=%d, n_obs=%d ===\n", n_treated, n_pre, nrow(panel)))
