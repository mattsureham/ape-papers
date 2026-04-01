## 03_main_analysis.R — Primary regressions
## Child Labor Law Relaxations and Teen Employment

source("00_packages.R")
library(fixest)
library(did)
library(data.table)

# --- Load data ---
all_ind <- readRDS("../data/all_industry_panel.rds")
setDT(all_ind)

ind_panel <- readRDS("../data/industry_panel.rds")
setDT(ind_panel)

cat("=== MAIN ANALYSIS ===\n\n")

# =========================================================================
# 1. Triple-Difference: State × Time × Age
# =========================================================================
cat("--- 1. Triple-Difference (DDD) ---\n")

# Restrict to teens (A01) and prime-age adults (A03: 25-34) as control age
ddd_data <- all_ind[agegrp %in% c("A01", "A03")]

# Create interaction terms
ddd_data[, treat_post := treated * post]
ddd_data[, treat_teen := treated * teen]
ddd_data[, post_teen := post * teen]
ddd_data[, ddd := treated * post * teen]

# Primary DDD specification with state×age, time×age, state×time FE
# Y = β(Treated × Post × Teen) + FE
ddd_main <- feols(
  log_emp ~ ddd + treat_post + treat_teen + post_teen |
    statefip^agegrp + time^agegrp + statefip^time,
  data = ddd_data,
  cluster = ~statefip
)

cat("DDD on log employment:\n")
summary(ddd_main)

# --- DDD on other outcomes ---
ddd_hires <- feols(
  log_hires ~ ddd + treat_post + treat_teen + post_teen |
    statefip^agegrp + time^agegrp + statefip^time,
  data = ddd_data,
  cluster = ~statefip
)

ddd_sep <- feols(
  log_sep ~ ddd + treat_post + treat_teen + post_teen |
    statefip^agegrp + time^agegrp + statefip^time,
  data = ddd_data,
  cluster = ~statefip
)

ddd_earn <- feols(
  log_earns ~ ddd + treat_post + treat_teen + post_teen |
    statefip^agegrp + time^agegrp + statefip^time,
  data = ddd_data,
  cluster = ~statefip
)

# =========================================================================
# 2. Callaway-Sant'Anna Staggered DiD (teen employment only)
# =========================================================================
cat("\n--- 2. Callaway-Sant'Anna (Teen Employment) ---\n")

# State-level teen panel (A01 only, all industries)
teen_panel <- all_ind[agegrp == "A01", .(
  log_emp = log_emp[1],
  Emp = Emp[1],
  HirA = HirA[1],
  Sep = Sep[1],
  EarnS = EarnS[1],
  first_treat = first_treat[1],
  treated = treated[1],
  statefip = statefip[1]
), by = .(statefip, time)]

# CS estimator
cs_out <- att_gt(
  yname = "log_emp",
  tname = "time",
  idname = "statefip",
  gname = "first_treat",
  data = as.data.frame(teen_panel),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

cat("CS group-time ATTs:\n")
summary(cs_out)

# Event study aggregation
es <- aggte(cs_out, type = "dynamic", min_e = -8, max_e = 8)
cat("\nEvent study:\n")
summary(es)

# Overall ATT
agg <- aggte(cs_out, type = "simple")
cat("\nOverall ATT:\n")
summary(agg)

# =========================================================================
# 3. Industry Heterogeneity: High-teen vs Low-teen industries
# =========================================================================
cat("\n--- 3. Industry Heterogeneity ---\n")

# DDD by industry type
ind_ddd <- ind_panel[agegrp %in% c("A01", "A03")]
ind_ddd[, treat_post := treated * post]
ind_ddd[, treat_teen := treated * teen]
ind_ddd[, post_teen := post * teen]
ind_ddd[, ddd := treated * post * teen]

# High-teen industries (food service, retail, arts, other services)
ddd_high_teen <- feols(
  log_emp ~ ddd + treat_post + treat_teen + post_teen |
    statefip^agegrp + time^agegrp + statefip^time,
  data = ind_ddd[high_teen_industry == 1],
  cluster = ~statefip
)

# Low-teen industries
ddd_low_teen <- feols(
  log_emp ~ ddd + treat_post + treat_teen + post_teen |
    statefip^agegrp + time^agegrp + statefip^time,
  data = ind_ddd[high_teen_industry == 0],
  cluster = ~statefip
)

cat("High-teen industries DDD:\n")
cat(sprintf("  β = %.4f (SE = %.4f, p = %.3f)\n",
            coef(ddd_high_teen)["ddd"],
            se(ddd_high_teen)["ddd"],
            pvalue(ddd_high_teen)["ddd"]))

cat("Low-teen industries DDD:\n")
cat(sprintf("  β = %.4f (SE = %.4f, p = %.3f)\n",
            coef(ddd_low_teen)["ddd"],
            se(ddd_low_teen)["ddd"],
            pvalue(ddd_low_teen)["ddd"]))

# =========================================================================
# 4. Individual industry DDD (food service, retail)
# =========================================================================
cat("\n--- 4. Individual Industry DDD ---\n")

# Food service (NAICS 72)
ddd_food <- feols(
  log_emp ~ ddd + treat_post + treat_teen + post_teen |
    statefip^agegrp + time^agegrp + statefip^time,
  data = ind_ddd[industry == "72"],
  cluster = ~statefip
)

# Retail (NAICS 44-45)
ddd_retail <- feols(
  log_emp ~ ddd + treat_post + treat_teen + post_teen |
    statefip^agegrp + time^agegrp + statefip^time,
  data = ind_ddd[industry == "44-45"],
  cluster = ~statefip
)

cat("Food service DDD:\n")
cat(sprintf("  β = %.4f (SE = %.4f, p = %.3f)\n",
            coef(ddd_food)["ddd"],
            se(ddd_food)["ddd"],
            pvalue(ddd_food)["ddd"]))

cat("Retail DDD:\n")
cat(sprintf("  β = %.4f (SE = %.4f, p = %.3f)\n",
            coef(ddd_retail)["ddd"],
            se(ddd_retail)["ddd"],
            pvalue(ddd_retail)["ddd"]))

# =========================================================================
# Save results
# =========================================================================
results <- list(
  ddd_main = ddd_main,
  ddd_hires = ddd_hires,
  ddd_sep = ddd_sep,
  ddd_earn = ddd_earn,
  cs_out = cs_out,
  es = es,
  agg = agg,
  ddd_high_teen = ddd_high_teen,
  ddd_low_teen = ddd_low_teen,
  ddd_food = ddd_food,
  ddd_retail = ddd_retail
)

saveRDS(results, "../data/main_results.rds")

# --- Diagnostics JSON ---
n_treated <- uniqueN(all_ind[treated == 1]$statefip)
n_pre_c1 <- 14  # Q3 2022 is period 15, pre = 1-14
n_pre_c2 <- 18  # Q3 2023 is period 19, pre = 1-18
n_obs <- nrow(ddd_data)

jsonlite::write_json(
  list(
    n_treated = n_treated,
    n_pre = n_pre_c1,
    n_obs = n_obs,
    n_states = uniqueN(all_ind$statefip),
    n_quarters = uniqueN(all_ind$time),
    n_clusters = uniqueN(ddd_data$statefip)
  ),
  "../data/diagnostics.json",
  auto_unbox = TRUE
)

cat("\nMain analysis complete. Results saved.\n")
