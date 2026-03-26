## 03_main_analysis.R — Main DiD analysis
## apep_1025: Residential Neonicotinoid Bans and Bird Populations

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("=== Analysis Panel Summary ===\n")
cat("Observations:", nrow(panel), "\n")
cat("Routes:", uniqueN(panel$route_id), "\n")
cat("Years:", paste(range(panel$Year), collapse = "–"), "\n")

## ---- Restrict to insectivore panel for main results ----
insect <- panel[diet_guild == "insectivore"]
non_insect <- panel[diet_guild == "non_insectivore"]
cat("\nInsectivore panel:", nrow(insect), "obs\n")
cat("Non-insectivore panel:", nrow(non_insect), "obs\n")

## ---- Pre-treatment summary statistics ----
cat("\n=== Pre-Treatment Summary (2000-2015) ===\n")
pre <- panel[Year <= 2015]
pre_stats <- pre[, .(
  mean_count = mean(total_count),
  sd_count = sd(total_count),
  mean_species = mean(n_species),
  sd_species = sd(n_species),
  n_routes = uniqueN(route_id),
  n_obs = .N
), by = .(diet_guild, ever_treated = treat_year > 0)]
print(pre_stats)

## Save pre-treatment SD for SDE calculation
pre_sd_insect <- pre[diet_guild == "insectivore", sd(log_count)]
pre_sd_noninsect <- pre[diet_guild == "non_insectivore", sd(log_count)]
cat("\nPre-treatment SD(log count), insectivore:", round(pre_sd_insect, 4), "\n")
cat("Pre-treatment SD(log count), non-insectivore:", round(pre_sd_noninsect, 4), "\n")

## ---- 1. TWFE baseline (for comparison) ----
cat("\n=== TWFE Baseline ===\n")
twfe_insect <- feols(log_count ~ treated | route_id + Year,
                     cluster = ~StateNum, data = insect)
twfe_noninsect <- feols(log_count ~ treated | route_id + Year,
                        cluster = ~StateNum, data = non_insect)

cat("TWFE Insectivore:\n")
print(summary(twfe_insect))
cat("\nTWFE Non-insectivore (placebo):\n")
print(summary(twfe_noninsect))

## ---- 2. Callaway-Sant'Anna (main estimator) ----
cat("\n=== Callaway-Sant'Anna Staggered DiD ===\n")

## Prepare data for did package
## CS requires: group variable (first treatment year, 0 for never-treated)
## and id/time panel structure
insect_cs <- copy(insect)
insect_cs[, group := fifelse(treat_year == 0, 0L, as.integer(treat_year))]

## Collapse to route-year (already done, but ensure unique)
stopifnot(nrow(insect_cs) == nrow(unique(insect_cs[, .(route_id, Year)])))

## Create numeric route id for did package
insect_cs[, route_num := as.integer(factor(route_id))]

cat("Running Callaway-Sant'Anna on insectivore panel...\n")
cs_insect <- att_gt(
  yname = "log_count",
  tname = "Year",
  idname = "route_num",
  gname = "group",
  xformla = ~ obs_experience + mean_temp + mean_wind,
  data = as.data.frame(insect_cs[!is.na(obs_experience) & !is.na(mean_temp)]),
  control_group = "notyettreated",
  est_method = "dr",
  base_period = "universal"
)

cat("CS group-time ATTs computed.\n")

## Aggregate to overall ATT
cs_agg <- aggte(cs_insect, type = "simple")
cat("\n--- Overall ATT (insectivore) ---\n")
print(summary(cs_agg))

## Event study aggregation
cs_event <- aggte(cs_insect, type = "dynamic", min_e = -8, max_e = 5)
cat("\n--- Event Study (insectivore) ---\n")
print(summary(cs_event))

## ---- 3. Placebo: Non-insectivore panel ----
cat("\n=== Placebo: Non-insectivore Panel ===\n")
non_insect_cs <- copy(non_insect)
non_insect_cs[, group := fifelse(treat_year == 0, 0L, as.integer(treat_year))]
non_insect_cs[, route_num := as.integer(factor(route_id))]

cs_noninsect <- att_gt(
  yname = "log_count",
  tname = "Year",
  idname = "route_num",
  gname = "group",
  xformla = ~ obs_experience + mean_temp + mean_wind,
  data = as.data.frame(non_insect_cs[!is.na(obs_experience) & !is.na(mean_temp)]),
  control_group = "notyettreated",
  est_method = "dr",
  base_period = "universal"
)

cs_agg_placebo <- aggte(cs_noninsect, type = "simple")
cat("\n--- Overall ATT (non-insectivore placebo) ---\n")
print(summary(cs_agg_placebo))

cs_event_placebo <- aggte(cs_noninsect, type = "dynamic", min_e = -8, max_e = 5)

## ---- 4. Triple-difference ----
cat("\n=== Triple-Difference: Insectivore × Treated × Post ===\n")
## Stack both panels
stacked <- rbind(insect, non_insect)
stacked[, insectivore := as.integer(diet_guild == "insectivore")]
stacked[, post := as.integer(treated == 1)]

## DDD: insectivore × treated × post (route-guild and year-guild FEs)
stacked[, route_guild := paste(route_id, diet_guild, sep = "_")]
stacked[, year_guild := paste(Year, diet_guild, sep = "_")]

ddd <- feols(log_count ~ insectivore:treated | route_guild + year_guild,
             cluster = ~StateNum, data = stacked)

cat("Triple-Difference (insectivore × treated):\n")
print(summary(ddd))

## ---- Save results ----
results <- list(
  twfe_insect = twfe_insect,
  twfe_noninsect = twfe_noninsect,
  cs_insect = cs_insect,
  cs_agg = cs_agg,
  cs_event = cs_event,
  cs_noninsect = cs_noninsect,
  cs_agg_placebo = cs_agg_placebo,
  cs_event_placebo = cs_event_placebo,
  ddd = ddd,
  pre_sd_insect = pre_sd_insect,
  pre_sd_noninsect = pre_sd_noninsect,
  pre_stats = pre_stats
)
saveRDS(results, file.path(data_dir, "results.rds"))

## ---- Diagnostics for validator ----
jsonlite::write_json(list(
  n_treated = uniqueN(insect[treated == 1]$route_id),
  n_pre = length(unique(insect[Year < 2016]$Year)),
  n_obs = nrow(insect)
), file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== All results saved ===\n")
