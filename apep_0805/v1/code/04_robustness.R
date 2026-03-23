## 04_robustness.R — Robustness checks
## apep_0805: Prescribed fire liability reform and wildfire severity

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "results.rds"))

df <- as.data.frame(panel)
df <- df[complete.cases(df[, c("ln_fires", "year", "state_id", "first_treat")]), ]

# ─────────────────────────────────────────────────────────
# 1. Not-yet-treated as control group (instead of never-treated)
# ─────────────────────────────────────────────────────────
cat("=== Robustness: Not-yet-treated control group ===\n")
cs_nyt <- att_gt(
  yname = "ln_fires", tname = "year", idname = "state_id",
  gname = "first_treat", data = df,
  control_group = "notyettreated",
  est_method = "dr", bstrap = TRUE, biters = 1000
)
agg_nyt <- aggte(cs_nyt, type = "simple")
cat("Not-yet-treated control: ATT =", round(agg_nyt$overall.att, 4),
    " SE =", round(agg_nyt$overall.se, 4), "\n")

# ─────────────────────────────────────────────────────────
# 2. Level outcomes (not log-transformed)
# ─────────────────────────────────────────────────────────
cat("\n=== Robustness: Level outcomes ===\n")
twfe_level_fires <- feols(n_fires ~ treated | state_id + year, data = df,
                          cluster = ~state_id)
twfe_level_acres <- feols(total_acres ~ treated | state_id + year, data = df,
                          cluster = ~state_id)
cat("Level fires: ", round(coef(twfe_level_fires)["treated"], 2),
    " (", round(se(twfe_level_fires)["treated"], 2), ")\n")
cat("Level acres: ", round(coef(twfe_level_acres)["treated"], 2),
    " (", round(se(twfe_level_acres)["treated"], 2), ")\n")

# ─────────────────────────────────────────────────────────
# 3. Excluding states reforming very early (pre-1995)
# ─────────────────────────────────────────────────────────
cat("\n=== Robustness: Excluding pre-1995 reformers ===\n")
df_post95 <- df[df$first_treat == 0 | df$first_treat >= 1995, ]
cs_post95 <- att_gt(
  yname = "ln_fires", tname = "year", idname = "state_id",
  gname = "first_treat", data = df_post95,
  control_group = "nevertreated",
  est_method = "dr", bstrap = TRUE, biters = 1000
)
agg_post95 <- aggte(cs_post95, type = "simple")
cat("Post-1995 reformers only: ATT =", round(agg_post95$overall.att, 4),
    " SE =", round(agg_post95$overall.se, 4), "\n")

# ─────────────────────────────────────────────────────────
# 4. Gross negligence vs simple negligence (dose-response)
# ─────────────────────────────────────────────────────────
cat("\n=== Robustness: Gross vs Simple negligence ===\n")
df$gross <- as.integer(!is.na(df$regime) & df$regime == "gross")
df$gross_treated <- df$gross * df$treated

twfe_dose <- feols(ln_fires ~ treated + gross_treated | state_id + year,
                   data = df, cluster = ~state_id)
cat("Simple negligence: ", round(coef(twfe_dose)["treated"], 4),
    " (", round(se(twfe_dose)["treated"], 4), ")\n")
cat("Gross negligence increment: ", round(coef(twfe_dose)["gross_treated"], 4),
    " (", round(se(twfe_dose)["gross_treated"], 4), ")\n")

# ─────────────────────────────────────────────────────────
# 5. Per-capita outcomes (fires per 1000 sq miles of land area)
# ─────────────────────────────────────────────────────────
# State land areas (approximate, in sq miles) — for normalization
state_areas <- data.table(
  state = c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
            "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
            "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
            "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
            "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY","DC"),
  area_sqmi = c(52420,665384,113990,53179,163696,104094,5543,2489,65758,59425,
                10932,83569,57914,36420,56273,82278,40408,52378,35380,12406,
                10554,96714,86936,48432,69707,147040,77348,110572,9349,8723,
                121590,54555,53819,70698,44826,69899,98379,46054,1545,32020,
                77116,42144,268596,84897,9616,42775,71298,24230,65496,97813,68)
)

df2 <- merge(df, as.data.frame(state_areas), by = "state", all.x = TRUE)
df2$fires_per_area <- df2$n_fires / (df2$area_sqmi / 1000)
df2$ln_fires_area <- log(1 + df2$fires_per_area)

cat("\n=== Robustness: Fires per 1000 sq miles ===\n")
twfe_area <- feols(ln_fires_area ~ treated | state_id + year, data = df2,
                   cluster = ~state_id)
cat("Log fires/area: ", round(coef(twfe_area)["treated"], 4),
    " (", round(se(twfe_area)["treated"], 4), ")\n")

# ─────────────────────────────────────────────────────────
# 6. Save robustness results
# ─────────────────────────────────────────────────────────
robust <- list(
  cs_nyt = cs_nyt, agg_nyt = agg_nyt,
  twfe_level_fires = twfe_level_fires, twfe_level_acres = twfe_level_acres,
  cs_post95 = cs_post95, agg_post95 = agg_post95,
  twfe_dose = twfe_dose,
  twfe_area = twfe_area
)
saveRDS(robust, file.path(data_dir, "robustness.rds"))

cat("\n=== All robustness checks complete ===\n")
