## 03_main_analysis.R — Main regressions
## County-pair FE regressions of firm dynamics on log(MW)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) == 0) script_dir <- "code"
setwd(file.path(script_dir, ".."))
source("code/00_packages.R")

cat("=== Loading analysis dataset ===\n")
df <- readRDS("data/pair_panel.rds")
cat("Rows:", nrow(df), "\n")

# Focus datasets
# All-industry, all-age
df_all <- df |> filter(industry == "00", agegrp == "A00")
cat("All-industry, all-age rows:", nrow(df_all), "\n")

# Restaurant sector (NAICS 72)
df_72 <- df |> filter(industry == "72", agegrp == "A00")
cat("Restaurant rows:", nrow(df_72), "\n")

# Retail (44-45)
df_retail <- df |> filter(industry == "44-45", agegrp == "A00")
cat("Retail rows:", nrow(df_retail), "\n")

# Manufacturing (31-33)
df_mfg <- df |> filter(industry == "31-33", agegrp == "A00")

##############################################################################
## Table 1: Main results — effect of log(MW) on employment and earnings
##############################################################################
cat("\n=== Table 1: Employment and Earnings ===\n")

# Main specification: Y = pair_FE + quarter_FE + beta * log(MW)
# Clustering at state-border-segment level
# Border segment = the pair of states for each pair
df_all <- df_all |>
  mutate(border_segment = paste(pmin(state_a, state_b), pmax(state_a, state_b), sep = "_"))

# (1) Log employment — all industries
m1_emp <- feols(log_emp ~ log_mw | pair_id + time_index,
                data = df_all, cluster = ~border_segment)

# (2) Log earnings — all industries
m1_earn <- feols(log_earn ~ log_mw | pair_id + time_index,
                 data = df_all, cluster = ~border_segment)

# (3) Log employment — restaurants
df_72 <- df_72 |>
  mutate(border_segment = paste(pmin(state_a, state_b), pmax(state_a, state_b), sep = "_"))

m1_emp_72 <- feols(log_emp ~ log_mw | pair_id + time_index,
                   data = df_72, cluster = ~border_segment)

# (4) Log earnings — restaurants
m1_earn_72 <- feols(log_earn ~ log_mw | pair_id + time_index,
                    data = df_72, cluster = ~border_segment)

# (5) Log employment — retail
df_retail <- df_retail |>
  mutate(border_segment = paste(pmin(state_a, state_b), pmax(state_a, state_b), sep = "_"))

m1_emp_retail <- feols(log_emp ~ log_mw | pair_id + time_index,
                       data = df_retail, cluster = ~border_segment)

cat("Table 1 models estimated.\n")

# Print key results
cat("\nLog emp (all):", round(coef(m1_emp)["log_mw"], 4),
    "SE:", round(se(m1_emp)["log_mw"], 4), "\n")
cat("Log earn (all):", round(coef(m1_earn)["log_mw"], 4),
    "SE:", round(se(m1_earn)["log_mw"], 4), "\n")
cat("Log emp (restaurant):", round(coef(m1_emp_72)["log_mw"], 4),
    "SE:", round(se(m1_emp_72)["log_mw"], 4), "\n")

# Save Table 1 models
saveRDS(list(
  emp_all = m1_emp,
  earn_all = m1_earn,
  emp_72 = m1_emp_72,
  earn_72 = m1_earn_72,
  emp_retail = m1_emp_retail
), "data/table1_models.rds")

##############################################################################
## Table 2: Firm dynamics — job creation and destruction rates
##############################################################################
cat("\n=== Table 2: Firm Dynamics ===\n")

# (1) Job creation rate — all industries
m2_jc <- feols(jc_rate ~ log_mw | pair_id + time_index,
               data = df_all, cluster = ~border_segment)

# (2) Job destruction rate — all industries
m2_jd <- feols(jd_rate ~ log_mw | pair_id + time_index,
               data = df_all, cluster = ~border_segment)

# (3) Net job creation rate — all industries
m2_net <- feols(net_jc_rate ~ log_mw | pair_id + time_index,
                data = df_all, cluster = ~border_segment)

# (4) Hiring rate — all industries
m2_hire <- feols(hire_rate ~ log_mw | pair_id + time_index,
                 data = df_all, cluster = ~border_segment)

# (5) Separation rate — all industries
m2_sep <- feols(sep_rate ~ log_mw | pair_id + time_index,
                data = df_all, cluster = ~border_segment)

cat("Table 2 models estimated.\n")
cat("JC rate:", round(coef(m2_jc)["log_mw"], 4),
    "SE:", round(se(m2_jc)["log_mw"], 4), "\n")
cat("JD rate:", round(coef(m2_jd)["log_mw"], 4),
    "SE:", round(se(m2_jd)["log_mw"], 4), "\n")
cat("Net JC:", round(coef(m2_net)["log_mw"], 4),
    "SE:", round(se(m2_net)["log_mw"], 4), "\n")
cat("Hire rate:", round(coef(m2_hire)["log_mw"], 4),
    "SE:", round(se(m2_hire)["log_mw"], 4), "\n")
cat("Sep rate:", round(coef(m2_sep)["log_mw"], 4),
    "SE:", round(se(m2_sep)["log_mw"], 4), "\n")

saveRDS(list(
  jc_all = m2_jc,
  jd_all = m2_jd,
  net_all = m2_net,
  hire_all = m2_hire,
  sep_all = m2_sep
), "data/table2_models.rds")

##############################################################################
## Table 3: Firm dynamics by industry (restaurant, retail, manufacturing)
##############################################################################
cat("\n=== Table 3: Firm Dynamics by Industry ===\n")

# Restaurant JC/JD
m3_jc_72 <- feols(jc_rate ~ log_mw | pair_id + time_index,
                  data = df_72, cluster = ~border_segment)
m3_jd_72 <- feols(jd_rate ~ log_mw | pair_id + time_index,
                  data = df_72, cluster = ~border_segment)

# Retail JC/JD
m3_jc_retail <- feols(jc_rate ~ log_mw | pair_id + time_index,
                      data = df_retail, cluster = ~border_segment)
m3_jd_retail <- feols(jd_rate ~ log_mw | pair_id + time_index,
                      data = df_retail, cluster = ~border_segment)

# Manufacturing JC/JD
df_mfg <- df_mfg |>
  mutate(border_segment = paste(pmin(state_a, state_b), pmax(state_a, state_b), sep = "_"))
m3_jc_mfg <- feols(jc_rate ~ log_mw | pair_id + time_index,
                   data = df_mfg, cluster = ~border_segment)
m3_jd_mfg <- feols(jd_rate ~ log_mw | pair_id + time_index,
                   data = df_mfg, cluster = ~border_segment)

cat("Restaurant JC:", round(coef(m3_jc_72)["log_mw"], 4),
    "JD:", round(coef(m3_jd_72)["log_mw"], 4), "\n")
cat("Retail JC:", round(coef(m3_jc_retail)["log_mw"], 4),
    "JD:", round(coef(m3_jd_retail)["log_mw"], 4), "\n")
cat("Manufacturing JC:", round(coef(m3_jc_mfg)["log_mw"], 4),
    "JD:", round(coef(m3_jd_mfg)["log_mw"], 4), "\n")

saveRDS(list(
  jc_72 = m3_jc_72, jd_72 = m3_jd_72,
  jc_retail = m3_jc_retail, jd_retail = m3_jd_retail,
  jc_mfg = m3_jc_mfg, jd_mfg = m3_jd_mfg
), "data/table3_models.rds")

##############################################################################
## Table 4: Age-specific effects (young vs prime-age)
##############################################################################
cat("\n=== Table 4: Age-Specific Effects ===\n")

# Age-specific datasets (all industries)
df_young <- df |> filter(industry == "00", agegrp %in% c("A01", "A02", "A03")) |>
  mutate(border_segment = paste(pmin(state_a, state_b), pmax(state_a, state_b), sep = "_"))
df_prime <- df |> filter(industry == "00", agegrp %in% c("A04", "A05")) |>
  mutate(border_segment = paste(pmin(state_a, state_b), pmax(state_a, state_b), sep = "_"))
df_old <- df |> filter(industry == "00", agegrp %in% c("A06", "A07", "A08")) |>
  mutate(border_segment = paste(pmin(state_a, state_b), pmax(state_a, state_b), sep = "_"))

# Young (14-24): employment, earnings, JC, JD
m4_emp_young <- feols(log_emp ~ log_mw | pair_id + time_index,
                      data = df_young, cluster = ~border_segment)
m4_earn_young <- feols(log_earn ~ log_mw | pair_id + time_index,
                       data = df_young, cluster = ~border_segment)
m4_jc_young <- feols(jc_rate ~ log_mw | pair_id + time_index,
                     data = df_young, cluster = ~border_segment)
m4_jd_young <- feols(jd_rate ~ log_mw | pair_id + time_index,
                     data = df_young, cluster = ~border_segment)

# Prime-age (25-44)
m4_emp_prime <- feols(log_emp ~ log_mw | pair_id + time_index,
                      data = df_prime, cluster = ~border_segment)
m4_earn_prime <- feols(log_earn ~ log_mw | pair_id + time_index,
                       data = df_prime, cluster = ~border_segment)

# Older (45+)
m4_emp_old <- feols(log_emp ~ log_mw | pair_id + time_index,
                    data = df_old, cluster = ~border_segment)
m4_earn_old <- feols(log_earn ~ log_mw | pair_id + time_index,
                     data = df_old, cluster = ~border_segment)

cat("Young emp:", round(coef(m4_emp_young)["log_mw"], 4),
    "SE:", round(se(m4_emp_young)["log_mw"], 4), "\n")
cat("Prime emp:", round(coef(m4_emp_prime)["log_mw"], 4),
    "SE:", round(se(m4_emp_prime)["log_mw"], 4), "\n")
cat("Older emp:", round(coef(m4_emp_old)["log_mw"], 4),
    "SE:", round(se(m4_emp_old)["log_mw"], 4), "\n")

saveRDS(list(
  emp_young = m4_emp_young, earn_young = m4_earn_young,
  jc_young = m4_jc_young, jd_young = m4_jd_young,
  emp_prime = m4_emp_prime, earn_prime = m4_earn_prime,
  emp_old = m4_emp_old, earn_old = m4_earn_old
), "data/table4_models.rds")

##############################################################################
## Diagnostics for validator
##############################################################################
cat("\n=== Writing diagnostics ===\n")

diag <- list(
  n_treated = n_distinct(df_all$pair_id[df_all$eff_mw > 7.25]),  # pairs with above-federal MW
  n_pre = length(unique(df_all$time_index[df_all$year <= 2006])),
  n_obs = nrow(df_all),
  n_pairs = n_distinct(df_all$pair_id),
  n_counties = n_distinct(df_all$fips),
  n_border_segments = n_distinct(df_all$border_segment)
)
write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)

cat("Diagnostics:", toJSON(diag, auto_unbox = TRUE, pretty = TRUE), "\n")
cat("\n=== Main Analysis Complete ===\n")
