## 05_tables.R — Generate all tables for the paper
source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

analysis_all <- readRDS(file.path(data_dir, "analysis_data.rds"))
station_df   <- readRDS(file.path(data_dir, "stations_clean.rds"))
results      <- readRDS(file.path(data_dir, "rdd_results.rds"))
robustness   <- readRDS(file.path(data_dir, "robustness_results.rds"))

df_post <- analysis_all %>% filter(survey_year >= 2015)

## ===========================================================================
## TABLE 1: Summary Statistics
## ===========================================================================
cat("Generating Table 1: Summary Statistics\n")

# Station-level summary by treatment status
near_threshold <- station_df %>%
  filter(avg_daily_users >= 1000 & avg_daily_users <= 5000)

# Panel A: Stations near threshold
panel_a <- near_threshold %>%
  group_by(above_threshold) %>%
  summarise(
    N = n(),
    mean_users = mean(avg_daily_users),
    sd_users   = sd(avg_daily_users),
    .groups = "drop"
  )

# Panel B: Land prices near threshold
near_threshold_land <- df_post %>%
  filter(nearest_station_users >= 1000 & nearest_station_users <= 5000)

panel_b <- near_threshold_land %>%
  group_by(nearest_station_above) %>%
  summarise(
    N = n(),
    mean_price  = mean(price_yen_sqm),
    sd_price    = sd(price_yen_sqm),
    median_price = median(price_yen_sqm),
    mean_dist   = mean(station_dist_m),
    sd_dist     = sd(station_dist_m),
    .groups = "drop"
  )

# Write Table 1 as LaTeX
tab1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Stations and Land Prices Near the 3,000-User Threshold}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Below Threshold} & \\multicolumn{2}{c}{Above Threshold} \\\\\n",
  " & Mean & SD & Mean & SD \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Station Characteristics (1,000--5,000 users)}} \\\\\n",
  sprintf("Daily passengers & %.0f & %.0f & %.0f & %.0f \\\\\n",
          panel_a$mean_users[1], panel_a$sd_users[1],
          panel_a$mean_users[2], panel_a$sd_users[2]),
  sprintf("Number of stations & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n",
          panel_a$N[1], panel_a$N[2]),
  "[6pt]\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Land Prices Within 2km (Post-Treatment)}} \\\\\n",
  sprintf("Price (1000 yen/sqm) & %.1f & %.1f & %.1f & %.1f \\\\\n",
          panel_b$mean_price[1]/1000, panel_b$sd_price[1]/1000,
          panel_b$mean_price[2]/1000, panel_b$sd_price[2]/1000),
  sprintf("Distance to station (m) & %.0f & %.0f & %.0f & %.0f \\\\\n",
          panel_b$mean_dist[1], panel_b$sd_dist[1],
          panel_b$mean_dist[2], panel_b$sd_dist[2]),
  sprintf("Number of observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\\n",
          format(panel_b$N[1], big.mark = ","), format(panel_b$N[2], big.mark = ",")),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Sample restricted to stations with 1,000--5,000 average daily users ",
  "(Panel A) and land price survey points within 2km of these stations (Panel B). ",
  "Daily passengers are averaged over FY2011--FY2018 from MLIT S12 data. ",
  "Land prices from MLIT L01 Official Land Price Survey, 2015 and 2020 waves pooled. ",
  "The 3,000-user threshold determines eligibility for Japan's Barrier-Free Act mandate.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))

## ===========================================================================
## TABLE 2: Main RDD Results (Cross-sectional + Diff-in-Disc)
## ===========================================================================
cat("Generating Table 2: Main RDD Results\n")

# Re-run key specifications to get all output
rdd_cross <- rdrobust::rdrobust(
  y = df_post$log_price, x = df_post$centered_users, c = 0,
  kernel = "triangular", bwselect = "mserd",
  cluster = df_post$nearest_station_name
)

# Pre-treatment RDD
df_pre <- analysis_all %>% filter(survey_year == 2010)
rdd_pre <- rdrobust::rdrobust(
  y = df_pre$log_price, x = df_pre$centered_users, c = 0,
  kernel = "triangular", bwselect = "mserd",
  cluster = df_pre$nearest_station_name
)

# Diff-in-disc
df_2010 <- analysis_all %>% filter(survey_year == 2010) %>%
  mutate(point_id = paste(round(lon, 5), round(lat, 5)))
df_2020 <- analysis_all %>% filter(survey_year == 2020) %>%
  mutate(point_id = paste(round(lon, 5), round(lat, 5)))
matched <- inner_join(
  df_2010 %>% select(point_id, log_price_2010 = log_price, centered_users,
                     nearest_station_name),
  df_2020 %>% select(point_id, log_price_2020 = log_price),
  by = "point_id"
) %>% mutate(price_change = log_price_2020 - log_price_2010)

rdd_did <- rdrobust::rdrobust(
  y = matched$price_change, x = matched$centered_users, c = 0,
  kernel = "triangular", bwselect = "mserd",
  cluster = matched$nearest_station_name
)

# Helper to format significance stars
stars <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

tab2_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{RDD Estimates: Effect of Barrier-Free Mandate on Land Prices}\n",
  "\\label{tab:main_rdd}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Cross-Section & Pre-Treatment & Diff-in-Disc \\\\\n",
  " & Post-2015 & 2010 & $\\Delta$(2020$-$2010) \\\\\n",
  "\\hline\n",
  sprintf("RDD estimate ($\\hat{\\tau}$) & %.3f%s & %.3f%s & %.3f%s \\\\\n",
          rdd_cross$coef[1], stars(rdd_cross$pv[3]),
          rdd_pre$coef[1], stars(rdd_pre$pv[3]),
          rdd_did$coef[1], stars(rdd_did$pv[3])),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          rdd_cross$se[3], rdd_pre$se[3], rdd_did$se[3]),
  sprintf("Robust 95\\%% CI & [%.3f, %.3f] & [%.3f, %.3f] & [%.3f, %.3f] \\\\\n",
          rdd_cross$ci[3,1], rdd_cross$ci[3,2],
          rdd_pre$ci[3,1], rdd_pre$ci[3,2],
          rdd_did$ci[3,1], rdd_did$ci[3,2]),
  sprintf("Bandwidth & %.0f & %.0f & %.0f \\\\\n",
          rdd_cross$bws[1,1], rdd_pre$bws[1,1], rdd_did$bws[1,1]),
  sprintf("Eff.\\ $N$ (left/right) & %d/%d & %d/%d & %d/%d \\\\\n",
          rdd_cross$Nh[1], rdd_cross$Nh[2],
          rdd_pre$Nh[1], rdd_pre$Nh[2],
          rdd_did$Nh[1], rdd_did$Nh[2]),
  "Polynomial order & 1 & 1 & 1 \\\\\n",
  "Kernel & Triangular & Triangular & Triangular \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Sharp RDD estimates at the 3,000 daily users threshold. ",
  "Dependent variable: log land price (yen/sqm). Column (1): pooled 2015 and 2020 ",
  "cross-section. Column (2): pre-treatment (2010) prices as placebo outcome. ",
  "Column (3): difference-in-discontinuities using matched survey points observed in ",
  "both 2010 and 2020. Bandwidth selected by MSE-optimal procedure of ",
  "\\citet{cattaneo2020}. Robust bias-corrected standard errors in parentheses, ",
  "clustered by station. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2_tex, file.path(table_dir, "tab2_main_rdd.tex"))

## ===========================================================================
## TABLE 3: Validity Tests
## ===========================================================================
cat("Generating Table 3: Validity Tests\n")

# McCrary
mc_test <- rddensity::rddensity(station_df$centered_users, c = 0)

# Covariate balance
rdd_dist <- rdrobust::rdrobust(
  y = df_post$station_dist_m, x = df_post$centered_users, c = 0,
  kernel = "triangular", bwselect = "mserd",
  cluster = df_post$nearest_station_name
)
df_post$is_residential <- as.integer(grepl("住宅", df_post$land_use))
rdd_res <- rdrobust::rdrobust(
  y = df_post$is_residential, x = df_post$centered_users, c = 0,
  kernel = "triangular", bwselect = "mserd",
  cluster = df_post$nearest_station_name
)

tab3_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Validity Tests for the 3,000-User RDD}\n",
  "\\label{tab:validity}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "Test & Statistic & $p$-value \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Density Test}} \\\\\n",
  sprintf("McCrary density test & %.3f & %.3f \\\\\n",
          mc_test$test$t_jk, mc_test$test$p_jk),
  "[6pt]\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Covariate Balance at Threshold}} \\\\\n",
  sprintf("Distance to station (m) & %.1f & %.3f \\\\\n",
          rdd_dist$coef[1], rdd_dist$pv[3]),
  sprintf("Residential land use & %.4f & %.3f \\\\\n",
          rdd_res$coef[1], rdd_res$pv[3]),
  sprintf("Pre-treatment log price (2010) & %.3f & %.3f \\\\\n",
          rdd_pre$coef[1], rdd_pre$pv[3]),
  "[6pt]\n",
  "\\multicolumn{3}{l}{\\textit{Panel C: Placebo Cutoffs}} \\\\\n",
  sprintf("Cutoff at 1,500 users & %.3f & %.3f \\\\\n",
          robustness$placebo_cutoffs$estimate[1],
          robustness$placebo_cutoffs$p_value[1]),
  sprintf("Cutoff at 2,000 users & %.3f & %.3f \\\\\n",
          robustness$placebo_cutoffs$estimate[2],
          robustness$placebo_cutoffs$p_value[2]),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Panel A: \\citet{cattaneo2020density} manipulation test. ",
  "Null hypothesis: density of stations is continuous at 3,000. ",
  "Panel B: RDD estimates using pre-determined covariates as dependent variables. ",
  "A significant coefficient suggests imbalance. Panel C: RDD estimates at false thresholds ",
  "where no policy discontinuity exists. Dependent variable: log land price (post-treatment). ",
  "All specifications use triangular kernel with MSE-optimal bandwidth.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3_tex, file.path(table_dir, "tab3_validity.tex"))

## ===========================================================================
## TABLE 4: Robustness — Bandwidth and Polynomial Sensitivity
## ===========================================================================
cat("Generating Table 4: Robustness\n")

did_bw <- robustness$did_bw_sensitivity

tab4_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness: Diff-in-Disc Bandwidth and Specification Sensitivity}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  "Bandwidth multiplier & 0.50 & 0.75 & 1.00 & 1.25 & 1.50 \\\\\n",
  "\\hline\n",
  sprintf("Bandwidth (users) & %.0f & %.0f & %.0f & %.0f & %.0f \\\\\n",
          did_bw$bandwidth[1], did_bw$bandwidth[2], did_bw$bandwidth[3],
          did_bw$bandwidth[4], did_bw$bandwidth[5]),
  sprintf("Estimate & %.3f & %.3f & %.3f%s & %.3f%s & %.3f%s \\\\\n",
          did_bw$estimate[1], did_bw$estimate[2],
          did_bw$estimate[3], stars(did_bw$p_robust[3]),
          did_bw$estimate[4], stars(did_bw$p_robust[4]),
          did_bw$estimate[5], stars(did_bw$p_robust[5])),
  sprintf("Robust SE & (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          did_bw$se_robust[1], did_bw$se_robust[2], did_bw$se_robust[3],
          did_bw$se_robust[4], did_bw$se_robust[5]),
  sprintf("$p$-value & %.3f & %.3f & %.3f & %.3f & %.3f \\\\\n",
          did_bw$p_robust[1], did_bw$p_robust[2], did_bw$p_robust[3],
          did_bw$p_robust[4], did_bw$p_robust[5]),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Difference-in-discontinuities estimates (2020 minus 2010 log land prices) ",
  "at varying bandwidths around the 3,000-user threshold. Column (3) uses the MSE-optimal bandwidth. ",
  "Triangular kernel, local linear polynomial, robust bias-corrected inference. ",
  "Standard errors clustered by station. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab4_tex, file.path(table_dir, "tab4_robustness.tex"))

## ===========================================================================
## TABLE 5 (Appendix): SDE Table
## ===========================================================================
cat("Generating Table F1: Standardized Effect Sizes\n")

# Main outcome: diff-in-disc estimate for land prices
did_coef <- rdd_did$coef[1]
did_se   <- rdd_did$se[3]

# SD of the outcome (price changes in matched sample)
sd_y <- sd(matched$price_change, na.rm = TRUE)

# SDE = beta / SD(Y) [binary treatment]
sde_main <- did_coef / sd_y
sde_se   <- did_se / sd_y

# Cross-sectional RDD for comparison
cross_coef <- rdd_cross$coef[1]
cross_se   <- rdd_cross$se[3]
sd_y_cross <- sd(df_post$log_price, na.rm = TRUE)
sde_cross  <- cross_coef / sd_y_cross
sde_cross_se <- cross_se / sd_y_cross

# Classification function
classify_sde <- function(sde) {
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  if (sde > 0.005) return("Small positive")
  if (sde > -0.005) return("Null")
  if (sde > -0.05) return("Small negative")
  if (sde > -0.15) return("Moderate negative")
  return("Large negative")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Japan. ",
  "\\textbf{Research question:} Does mandating step-free access (elevators, slopes, tactile paving) ",
  "at railway stations with 3,000 or more daily users increase nearby land prices? ",
  "\\textbf{Policy mechanism:} The 2006 Barrier-Free Act requires public transportation facilities ",
  "exceeding the 3,000 daily users threshold to install step-free access infrastructure, removing ",
  "physical barriers for elderly persons, wheelchair users, and caregivers with strollers. ",
  "\\textbf{Outcome definition:} Log of official land price (yen per square meter) from the MLIT ",
  "L01 National Land Price Survey, measuring assessed market value at fixed survey points. ",
  "\\textbf{Treatment:} Binary indicator for whether the nearest railway station has 3,000 or more ",
  "average daily users and is therefore subject to the barrier-free renovation mandate. ",
  "\\textbf{Data:} MLIT S12 Station Passenger Data (FY2011--FY2018) and L01 Official Land Price ",
  "Data (2010, 2020), matched by geographic proximity within 2km; 12,511 matched survey points. ",
  "\\textbf{Method:} Difference-in-discontinuities (2020 minus 2010 log prices) using local ",
  "linear regression with triangular kernel, MSE-optimal bandwidth, robust bias-corrected ",
  "inference, standard errors clustered by station. ",
  "\\textbf{Sample:} Land price survey points within 2km of railway stations observed in both ",
  "2010 and 2020 waves. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the standard deviation of the ",
  "outcome variable (log price change for diff-in-disc, log price level for cross-section). ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  sprintf("Log land price ($\\Delta$ 2020--2010) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          did_coef, did_se, sd_y, sde_main, sde_se, classify_sde(sde_main)),
  sprintf("Log land price (cross-section) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          cross_coef, cross_se, sd_y_cross, sde_cross, sde_cross_se, classify_sde(sde_cross)),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tabF1_tex, file.path(table_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat(sprintf("Files in %s:\n", table_dir))
cat(paste(list.files(table_dir), collapse = "\n"), "\n")
