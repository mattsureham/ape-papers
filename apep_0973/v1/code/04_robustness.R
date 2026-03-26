## 04_robustness.R — Robustness checks
## APEP-0973: Plastic Bag Charges and Beach Litter

source("00_packages.R")
setwd(file.path(here::here(), "output", "apep_0973", "v1"))

panel <- as.data.frame(readRDS("data/analysis_panel.rds"))
names(panel)[names(panel) == "gname"] <- "first_treat"
names(panel)[names(panel) == "tname"] <- "time_var"
names(panel)[names(panel) == "idname"] <- "unit_var"
panel$log_bottles <- log(panel$plastic_bottles + 1)

cat("=== Robustness Checks ===\n")

run_cs <- function(yname, data, label) {
  tryCatch({
    out <- att_gt(yname = yname, tname = "time_var", idname = "unit_var",
                  gname = "first_treat", data = data,
                  control_group = "notyettreated",
                  allow_unbalanced_panel = TRUE, base_period = "universal")
    att <- aggte(out, type = "simple", na.rm = TRUE)
    cat(sprintf("  %s: ATT=%.3f SE=%.3f\n", label, att$overall.att, att$overall.se))
    att
  }, error = function(e) {
    cat(sprintf("  %s: FAILED — %s\n", label, e$message))
    list(overall.att = NA, overall.se = NA)
  })
}

# 1. IHS
cs_ihs <- run_cs("ihs_bags", panel, "IHS bags")

# 2. Raw levels
cs_levels <- run_cs("bags", panel, "Raw bag counts")

# 3. Exclude 2020
cs_no2020 <- run_cs("log_bags", panel[panel$time_var != 2020, ], "Excl 2020")

# 4. Drop England
cs_no_eng <- run_cs("log_bags", panel[panel$nation != "England", ], "Drop England")

# 5. Drop Wales
cs_no_wales <- run_cs("log_bags", panel[panel$nation != "Wales", ], "Drop Wales")

# 6. Placebo: bottles
cs_bottles <- run_cs("log_bottles", panel[!is.na(panel$log_bottles), ], "Placebo: bottles")

robust <- list(
  cs_ihs_att = cs_ihs, cs_levels_att = cs_levels,
  cs_no2020_att = cs_no2020, cs_no_eng_att = cs_no_eng,
  cs_no_wales_att = cs_no_wales, cs_bottles = cs_bottles
)
saveRDS(robust, "data/robustness_results.rds")
cat("=== Robustness Complete ===\n")
