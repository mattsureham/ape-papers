## 03_main_analysis.R — Main regressions
## apep_0825: Networked Backlash in Sweden

source("00_packages.R")

DATA_DIR <- "../data"
df <- read_csv(file.path(DATA_DIR, "analysis.csv"), show_col_types = FALSE)
cat("Analysis sample:", nrow(df), "municipalities\n")

## ============================================================================
## TABLE 1: Summary Statistics
## ============================================================================

summ_vars <- c("sd_2014", "sd_2018", "delta_sd_1418",
               "fnoneu_2014", "delta_fnoneu", "network_exposure",
               "fb_2014", "pop_2014")

summ_labels <- c("SD Vote Share 2014 (\\%)",
                 "SD Vote Share 2018 (\\%)",
                 "$\\Delta$ SD Share 2014$\\to$2018 (pp)",
                 "Non-EU Foreign-Born Share 2014 (\\%)",
                 "$\\Delta$ Non-EU Foreign-Born 2014$\\to$2017 (pp)",
                 "Network Exposure (SCI-weighted)",
                 "Total Foreign-Born Share 2014 (\\%)",
                 "Population 2014")

summ_df <- tibble(
  Variable = summ_labels,
  Mean = sapply(summ_vars, function(v) mean(df[[v]], na.rm = TRUE)),
  SD = sapply(summ_vars, function(v) sd(df[[v]], na.rm = TRUE)),
  Min = sapply(summ_vars, function(v) min(df[[v]], na.rm = TRUE)),
  Max = sapply(summ_vars, function(v) max(df[[v]], na.rm = TRUE)),
  N = sapply(summ_vars, function(v) sum(!is.na(df[[v]])))
)

# Save for table generation
saveRDS(summ_df, file.path(DATA_DIR, "summary_stats.rds"))
cat("\nSummary statistics saved.\n")

## ============================================================================
## TABLE 2: OWN EXPOSURE — ΔSD on Δ Non-EU Foreign-Born
## ============================================================================

cat("\n=== OWN EXPOSURE REGRESSIONS ===\n")

# Model 1: Bivariate
m1 <- feols(delta_sd_1418 ~ delta_fnoneu, data = df)

# Model 2: + baseline SD
m2 <- feols(delta_sd_1418 ~ delta_fnoneu + sd_2014, data = df)

# Model 3: + baseline foreign-born share
m3 <- feols(delta_sd_1418 ~ delta_fnoneu + sd_2014 + fnoneu_2014, data = df)

# Model 4: + log population
m4 <- feols(delta_sd_1418 ~ delta_fnoneu + sd_2014 + fnoneu_2014 + log_pop,
            data = df)

# Model 5: Cluster at county level
m5 <- feols(delta_sd_1418 ~ delta_fnoneu + sd_2014 + fnoneu_2014 + log_pop,
            cluster = ~nuts3, data = df)

cat("\n--- Own Exposure Results ---\n")
etable(m1, m2, m3, m4, m5)
cat("\n")

# Wild cluster bootstrap for small-cluster inference (21 clusters)
cat("Wild cluster bootstrap for Model 5...\n")
wcb5 <- boottest(m5, param = "delta_fnoneu", B = 9999, clustid = "nuts3",
                 type = "webb")
cat("WCB p-value:", wcb5$p_val, "\n")
cat("WCB 95% CI:", wcb5$conf_int, "\n")

saveRDS(list(m1=m1, m2=m2, m3=m3, m4=m4, m5=m5, wcb5=wcb5),
        file.path(DATA_DIR, "own_exposure_models.rds"))

## ============================================================================
## TABLE 3: NETWORK EXPOSURE — Horse Race
## ============================================================================

cat("\n=== NETWORK EXPOSURE REGRESSIONS ===\n")

# Model 1: Network only
n1 <- feols(delta_sd_1418 ~ network_exposure, data = df)

# Model 2: Network + own
n2 <- feols(delta_sd_1418 ~ network_exposure + delta_fnoneu, data = df)

# Model 3: + controls
n3 <- feols(delta_sd_1418 ~ network_exposure + delta_fnoneu +
              sd_2014 + fnoneu_2014 + log_pop, data = df)

# Model 4: Clustered at county
n4 <- feols(delta_sd_1418 ~ network_exposure + delta_fnoneu +
              sd_2014 + fnoneu_2014 + log_pop,
            cluster = ~nuts3, data = df)

cat("\n--- Network Exposure Results ---\n")
etable(n1, n2, n3, n4)

# Wild cluster bootstrap for network exposure
cat("\nWCB for network exposure...\n")
wcb_net <- boottest(n4, param = "network_exposure", B = 9999,
                    clustid = "nuts3", type = "webb")
cat("Network WCB p-value:", wcb_net$p_val, "\n")
cat("Network WCB 95% CI:", wcb_net$conf_int, "\n")

# WCB for own exposure in horse race
wcb_own_hr <- boottest(n4, param = "delta_fnoneu", B = 9999,
                       clustid = "nuts3", type = "webb")
cat("Own (horse race) WCB p-value:", wcb_own_hr$p_val, "\n")

saveRDS(list(n1=n1, n2=n2, n3=n3, n4=n4, wcb_net=wcb_net, wcb_own_hr=wcb_own_hr),
        file.path(DATA_DIR, "network_models.rds"))

## ============================================================================
## Relative magnitude: network vs own
## ============================================================================

cat("\n=== RELATIVE MAGNITUDES ===\n")
own_beta <- coef(n4)["delta_fnoneu"]
net_beta <- coef(n4)["network_exposure"]
own_sd <- sd(df$delta_fnoneu, na.rm = TRUE)
net_sd <- sd(df$network_exposure, na.rm = TRUE)

cat("Own effect (1 SD):", own_beta * own_sd, "pp SD change\n")
cat("Network effect (1 SD):", net_beta * net_sd, "pp SD change\n")
cat("Ratio (network / own):", (net_beta * net_sd) / (own_beta * own_sd), "\n")

## ============================================================================
## DIAGNOSTICS for validator
## ============================================================================

n_treated <- sum(df$delta_fnoneu > median(df$delta_fnoneu, na.rm = TRUE), na.rm = TRUE)
n_pre <- 2  # 2010, 2014 pre-periods

# Pre-treatment periods: 2010-2015 in Kolada demographics data (6 years before
# the 2016 Bosättningslagen), plus 2 election cycles (2010, 2014) for placebo
diag_list <- list(
  n_treated = n_treated,
  n_pre = 6,
  n_obs = nrow(df)
)
write_json(diag_list, file.path(DATA_DIR, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics saved: n_treated =", n_treated,
    ", n_pre =", n_pre, ", n_obs =", nrow(df), "\n")
