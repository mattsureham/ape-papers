# 05_tables.R — Generate all LaTeX tables

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")

tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ══════════════════════════════════════════════════════════════
# TABLE 1: Summary Statistics
# ══════════════════════════════════════════════════════════════
cat("Generating Table 1: Summary Statistics...\n")

summ_pre <- df %>%
  filter(post == 0) %>%
  group_by(treated) %>%
  summarise(
    n_cities = n_distinct(city_en),
    n_obs = n(),
    mean_new_mom = mean(new_mom_pct, na.rm = TRUE),
    sd_new_mom = sd(new_mom_pct, na.rm = TRUE),
    mean_abs_mom = mean(new_abs_mom, na.rm = TRUE),
    sd_abs_mom = sd(new_abs_mom, na.rm = TRUE),
    mean_used_mom = mean(used_mom_pct, na.rm = TRUE),
    sd_used_mom = sd(used_mom_pct, na.rm = TRUE),
    mean_new_used_gap = mean(new_used_gap, na.rm = TRUE),
    sd_new_used_gap = sd(new_used_gap, na.rm = TRUE),
    .groups = "drop"
  )

summ_post <- df %>%
  filter(post == 1) %>%
  group_by(treated) %>%
  summarise(
    n_obs = n(),
    mean_new_mom = mean(new_mom_pct, na.rm = TRUE),
    sd_new_mom = sd(new_mom_pct, na.rm = TRUE),
    mean_abs_mom = mean(new_abs_mom, na.rm = TRUE),
    sd_abs_mom = sd(new_abs_mom, na.rm = TRUE),
    mean_used_mom = mean(used_mom_pct, na.rm = TRUE),
    sd_used_mom = sd(used_mom_pct, na.rm = TRUE),
    mean_new_used_gap = mean(new_used_gap, na.rm = TRUE),
    sd_new_used_gap = sd(new_used_gap, na.rm = TRUE),
    .groups = "drop"
  )

# Format function
fmt <- function(x, d = 3) formatC(x, format = "f", digits = d)

tab1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Pre- and Post-Reform Housing Price Dynamics}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccccccc}\n",
  "\\toprule\n",
  " & \\multicolumn{4}{c}{Pre-Reform (Jan 2019--Feb 2021)} & \\multicolumn{4}{c}{Post-Reform (Mar 2021--Dec 2023)} \\\\\n",
  "\\cmidrule(lr){2-5} \\cmidrule(lr){6-9}\n",
  " & \\multicolumn{2}{c}{Treated (21)} & \\multicolumn{2}{c}{Control (49)} & \\multicolumn{2}{c}{Treated (21)} & \\multicolumn{2}{c}{Control (49)} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7} \\cmidrule(lr){8-9}\n",
  " & Mean & SD & Mean & SD & Mean & SD & Mean & SD \\\\\n",
  "\\midrule\n",
  "MoM price change (\\%) & ",
  fmt(summ_pre$mean_new_mom[2]), " & ", fmt(summ_pre$sd_new_mom[2]), " & ",
  fmt(summ_pre$mean_new_mom[1]), " & ", fmt(summ_pre$sd_new_mom[1]), " & ",
  fmt(summ_post$mean_new_mom[2]), " & ", fmt(summ_post$sd_new_mom[2]), " & ",
  fmt(summ_post$mean_new_mom[1]), " & ", fmt(summ_post$sd_new_mom[1]), " \\\\\n",
  "$|$MoM price change$|$ (\\%) & ",
  fmt(summ_pre$mean_abs_mom[2]), " & ", fmt(summ_pre$sd_abs_mom[2]), " & ",
  fmt(summ_pre$mean_abs_mom[1]), " & ", fmt(summ_pre$sd_abs_mom[1]), " & ",
  fmt(summ_post$mean_abs_mom[2]), " & ", fmt(summ_post$sd_abs_mom[2]), " & ",
  fmt(summ_post$mean_abs_mom[1]), " & ", fmt(summ_post$sd_abs_mom[1]), " \\\\\n",
  "Used house MoM (\\%) & ",
  fmt(summ_pre$mean_used_mom[2]), " & ", fmt(summ_pre$sd_used_mom[2]), " & ",
  fmt(summ_pre$mean_used_mom[1]), " & ", fmt(summ_pre$sd_used_mom[1]), " & ",
  fmt(summ_post$mean_used_mom[2]), " & ", fmt(summ_post$sd_used_mom[2]), " & ",
  fmt(summ_post$mean_used_mom[1]), " & ", fmt(summ_post$sd_used_mom[1]), " \\\\\n",
  "New--used gap (pp) & ",
  fmt(summ_pre$mean_new_used_gap[2]), " & ", fmt(summ_pre$sd_new_used_gap[2]), " & ",
  fmt(summ_pre$mean_new_used_gap[1]), " & ", fmt(summ_pre$sd_new_used_gap[1]), " & ",
  fmt(summ_post$mean_new_used_gap[2]), " & ", fmt(summ_post$sd_new_used_gap[2]), " & ",
  fmt(summ_post$mean_new_used_gap[1]), " & ", fmt(summ_post$sd_new_used_gap[1]), " \\\\\n",
  "\\midrule\n",
  "City-months & \\multicolumn{2}{c}{", summ_pre$n_obs[2], "} & \\multicolumn{2}{c}{",
  summ_pre$n_obs[1], "} & \\multicolumn{2}{c}{", summ_post$n_obs[2],
  "} & \\multicolumn{2}{c}{", summ_post$n_obs[1], "} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} MoM price change is the NBS new construction residential housing price index minus 100, representing the month-on-month percentage change. $|$MoM$|$ is the absolute value (volatility proxy). The new--used gap is $|\\text{new MoM} - \\text{used MoM}|$. Treated cities are the 21 cities in the NBS 70-city panel designated under the February 2021 ``double concentration'' reform. Control cities are the remaining 49.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))

# ══════════════════════════════════════════════════════════════
# TABLE 2: Main Results
# ══════════════════════════════════════════════════════════════
cat("Generating Table 2: Main Results...\n")

star <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

get_row <- function(mod, varname = "treated:post") {
  b <- coef(mod)[varname]
  s <- se(mod)[varname]
  p <- pvalue(mod)[varname]
  n <- nobs(mod)
  list(b = b, s = s, p = p, n = n, stars = star(p))
}

r1 <- get_row(results$m1)
r2 <- get_row(results$m2)
r3 <- get_row(results$m3)
r4 <- get_row(results$m4)
r5 <- get_row(results$m5)

tab2 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of Centralized Land Auctions on Housing Price Dynamics}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & $|$New MoM$|$ & $|$New MoM$|$ & $|$Used MoM$|$ & New--Used & New MoM \\\\\n",
  " & & + Tier ctrl & & Gap & Level \\\\\n",
  "\\midrule\n",
  "Treated $\\times$ Post & ", fmt(r1$b), r1$stars, " & ",
  fmt(r2$b), r2$stars, " & ",
  fmt(r3$b), r3$stars, " & ",
  fmt(r4$b), r4$stars, " & ",
  fmt(r5$b), r5$stars, " \\\\\n",
  " & (", fmt(r1$s), ") & (", fmt(r2$s), ") & (",
  fmt(r3$s), ") & (", fmt(r4$s), ") & (", fmt(r5$s), ") \\\\\n",
  "\\midrule\n",
  "City FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Month FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Tier $\\times$ Post & No & Yes & No & No & No \\\\\n",
  "Observations & ", formatC(r1$n, big.mark = ","), " & ",
  formatC(r2$n, big.mark = ","), " & ",
  formatC(r3$n, big.mark = ","), " & ",
  formatC(r4$n, big.mark = ","), " & ",
  formatC(r5$n, big.mark = ","), " \\\\\n",
  "Clusters & 70 & 70 & 70 & 70 & 70 \\\\\n",
  "Pre-treat mean (treated) & ",
  fmt(summ_pre$mean_abs_mom[2]), " & ",
  fmt(summ_pre$mean_abs_mom[2]), " & ",
  fmt(mean(abs(df$used_mom_pct[df$treated == 1 & df$post == 0]), na.rm = TRUE)), " & ",
  fmt(summ_pre$mean_new_used_gap[2]), " & ",
  fmt(summ_pre$mean_new_mom[2]), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each column reports the coefficient on Treated $\\times$ Post from a city-month panel regression with city and month fixed effects. Standard errors clustered at the city level in parentheses. The sample covers 70 NBS cities from January 2019 to December 2023. Treated cities are the 21 designated under the February 2021 centralized land auction reform. Post is March 2021 onward. Columns (1)--(2) estimate effects on absolute month-on-month new-construction price changes (volatility). Column (3) uses used-housing volatility as a comparison outcome. Column (4) examines the new--used price gap. Column (5) shows effects on price levels. \\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2, file.path(tables_dir, "tab2_main.tex"))

# ══════════════════════════════════════════════════════════════
# TABLE 3: Robustness
# ══════════════════════════════════════════════════════════════
cat("Generating Table 3: Robustness...\n")

rr1 <- get_row(rob$plac1, "treated:post_placebo")
rr2 <- get_row(rob$plac2, "treated:post_placebo")
rr3 <- get_row(rob$rob_no_t1)
rr4 <- get_row(rob$rob_sq)
rr5 <- get_row(rob$rob_narrow)

tab3 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & Placebo & Placebo & Drop & Squared & 12-Month \\\\\n",
  " & Mar 2020 & Sep 2019 & Tier-1 & MoM & Window \\\\\n",
  "\\midrule\n",
  "Treated $\\times$ Post & ", fmt(rr1$b), rr1$stars, " & ",
  fmt(rr2$b), rr2$stars, " & ",
  fmt(rr3$b), rr3$stars, " & ",
  fmt(rr4$b, 4), rr4$stars, " & ",
  fmt(rr5$b), rr5$stars, " \\\\\n",
  " & (", fmt(rr1$s), ") & (", fmt(rr2$s), ") & (",
  fmt(rr3$s), ") & (", fmt(rr4$s, 4), ") & (", fmt(rr5$s), ") \\\\\n",
  "\\midrule\n",
  "City FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Month FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Observations & ", formatC(rr1$n, big.mark = ","), " & ",
  formatC(rr2$n, big.mark = ","), " & ",
  formatC(rr3$n, big.mark = ","), " & ",
  formatC(rr4$n, big.mark = ","), " & ",
  formatC(rr5$n, big.mark = ","), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Outcome is $|$MoM new-construction price change$|$ in all columns except (4), which uses the squared MoM change. Columns (1)--(2) test placebo treatment dates 12 and 18 months before the actual reform, using only pre-reform data. Column (3) drops the four Tier-1 cities (Beijing, Shanghai, Guangzhou, Shenzhen). Column (5) restricts to a symmetric 12-month window around March 2021. Standard errors clustered at the city level. \\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3, file.path(tables_dir, "tab3_robustness.tex"))

# ══════════════════════════════════════════════════════════════
# TABLE 4: Heterogeneity
# ══════════════════════════════════════════════════════════════
cat("Generating Table 4: Heterogeneity...\n")

rh1 <- get_row(rob$het_t1)
rh2 <- get_row(rob$het_t2)

# Split by market temperature (pre-reform price growth)
pre_growth <- df %>%
  filter(post == 0) %>%
  group_by(city_en, treated) %>%
  summarise(pre_growth = mean(new_mom_pct, na.rm = TRUE), .groups = "drop")

median_growth <- median(pre_growth$pre_growth)

hot_cities <- pre_growth$city_en[pre_growth$pre_growth >= median_growth]
cold_cities <- pre_growth$city_en[pre_growth$pre_growth < median_growth]

df_hot <- df %>% filter(city_en %in% hot_cities)
df_cold <- df %>% filter(city_en %in% cold_cities)

het_hot <- feols(new_abs_mom ~ treated:post | city_id + time_id,
                 data = df_hot, cluster = ~city_id)
het_cold <- feols(new_abs_mom ~ treated:post | city_id + time_id,
                  data = df_cold, cluster = ~city_id)

rh3 <- get_row(het_hot)
rh4 <- get_row(het_cold)

tab4 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Heterogeneity by City Characteristics}\n",
  "\\label{tab:heterogeneity}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Tier-1 & Tier-2 & Hot & Cold \\\\\n",
  " & Treated & Treated & Markets & Markets \\\\\n",
  "\\midrule\n",
  "Treated $\\times$ Post & ", fmt(rh1$b), rh1$stars, " & ",
  fmt(rh2$b), rh2$stars, " & ",
  fmt(rh3$b), rh3$stars, " & ",
  fmt(rh4$b), rh4$stars, " \\\\\n",
  " & (", fmt(rh1$s), ") & (", fmt(rh2$s), ") & (",
  fmt(rh3$s), ") & (", fmt(rh4$s), ") \\\\\n",
  "\\midrule\n",
  "City FE & Yes & Yes & Yes & Yes \\\\\n",
  "Month FE & Yes & Yes & Yes & Yes \\\\\n",
  "Observations & ", formatC(rh1$n, big.mark = ","), " & ",
  formatC(rh2$n, big.mark = ","), " & ",
  formatC(rh3$n, big.mark = ","), " & ",
  formatC(rh4$n, big.mark = ","), " \\\\\n",
  "Treated cities & 4 & 17 & ",
  sum(hot_cities %in% unique(df$city_en[df$treated == 1])), " & ",
  sum(cold_cities %in% unique(df$city_en[df$treated == 1])), " \\\\\n",
  "Control cities & ", rh1$n / length(unique(df$date)) - 4, " & ",
  rh2$n / length(unique(df$date)) - 17, " & ",
  sum(hot_cities %in% unique(df$city_en[df$treated == 0])), " & ",
  sum(cold_cities %in% unique(df$city_en[df$treated == 0])), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Outcome is $|$MoM new-construction price change$|$. Columns (1)--(2) split treated cities into Tier-1 (Beijing, Shanghai, Guangzhou, Shenzhen) and Tier-2 cities; each subsample includes all 49 control cities. Columns (3)--(4) split all 70 cities at the pre-reform median of average MoM price growth. Standard errors clustered at the city level. \\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4, file.path(tables_dir, "tab4_heterogeneity.tex"))

# ══════════════════════════════════════════════════════════════
# TABLE F1: SDE Table (MANDATORY)
# ══════════════════════════════════════════════════════════════
cat("Generating Table F1: SDE...\n")

# Compute SDE for main outcomes
sd_y_abs <- sd(df$new_abs_mom[df$post == 0], na.rm = TRUE)
sd_y_used <- sd(df$used_abs_mom[df$post == 0], na.rm = TRUE)
sd_y_gap <- sd(df$new_used_gap[df$post == 0], na.rm = TRUE)
sd_y_level <- sd(df$new_mom_pct[df$post == 0], na.rm = TRUE)

classify <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

sde_rows <- data.frame(
  outcome = c("$|$New MoM$|$", "$|$Used MoM$|$", "New--Used Gap", "New MoM Level"),
  beta = c(coef(results$m1)["treated:post"],
           coef(results$m3)["treated:post"],
           coef(results$m4)["treated:post"],
           coef(results$m5)["treated:post"]),
  se_beta = c(se(results$m1)["treated:post"],
              se(results$m3)["treated:post"],
              se(results$m4)["treated:post"],
              se(results$m5)["treated:post"]),
  sd_y = c(sd_y_abs, sd_y_used, sd_y_gap, sd_y_level),
  stringsAsFactors = FALSE
)

sde_rows <- sde_rows %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se_beta / sd_y,
    class = classify(sde)
  )

# Heterogeneity rows (Tier-1 vs Tier-2 for main outcome)
sde_het <- data.frame(
  outcome = c("$|$New MoM$|$ (Tier-1)", "$|$New MoM$|$ (Tier-2)"),
  beta = c(coef(rob$het_t1)["treated:post"],
           coef(rob$het_t2)["treated:post"]),
  se_beta = c(se(rob$het_t1)["treated:post"],
              se(rob$het_t2)["treated:post"]),
  sd_y = c(sd_y_abs, sd_y_abs),
  stringsAsFactors = FALSE
) %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se_beta / sd_y,
    class = classify(sde)
  )

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} China. ",
  "\\textbf{Research question:} Does centralizing residential land auctions into three annual batches affect month-to-month housing price volatility in designated cities? ",
  "\\textbf{Policy mechanism:} The February 2021 ``double concentration'' reform required 22 major Chinese cities to consolidate all residential land auctions into three annual rounds, replacing the previous continuous auction system and thereby reducing the frequency of land price signals reaching the housing market. ",
  "\\textbf{Outcome definition:} Absolute month-on-month percentage change in the NBS new-construction residential housing price index, measuring short-run price volatility at the city-month level. ",
  "\\textbf{Treatment:} Binary indicator for the 21 treated cities in the NBS 70-city panel designated under the reform (one treated city, Suzhou, is outside the panel). ",
  "\\textbf{Data:} NBS 70-city housing price indices via AKShare, monthly, January 2019 to December 2023, 70 cities, 4,200 city-month observations. ",
  "\\textbf{Method:} Two-way fixed effects DiD with city and month fixed effects, standard errors clustered at city level, wild cluster bootstrap for inference. ",
  "\\textbf{Sample:} All 70 cities in the NBS housing price panel; no cities excluded from main specification. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build table
sde_table <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{llccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)

for (i in 1:nrow(sde_rows)) {
  sde_table <- paste0(sde_table,
    sde_rows$outcome[i], " & ",
    fmt(sde_rows$beta[i], 4), " & ",
    fmt(sde_rows$se_beta[i], 4), " & ",
    fmt(sde_rows$sd_y[i], 3), " & ",
    fmt(sde_rows$sde[i], 3), " & ",
    fmt(sde_rows$se_sde[i], 3), " & ",
    sde_rows$class[i], " \\\\\n"
  )
}

sde_table <- paste0(sde_table,
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (City Tier)}} \\\\\n"
)

for (i in 1:nrow(sde_het)) {
  sde_table <- paste0(sde_table,
    sde_het$outcome[i], " & ",
    fmt(sde_het$beta[i], 4), " & ",
    fmt(sde_het$se_beta[i], 4), " & ",
    fmt(sde_het$sd_y[i], 3), " & ",
    fmt(sde_het$sde[i], 3), " & ",
    fmt(sde_het$se_sde[i], 3), " & ",
    sde_het$class[i], " \\\\\n"
  )
}

sde_table <- paste0(sde_table,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(sde_table, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables written to", tables_dir, "\n")
cat("  tab1_summary.tex\n")
cat("  tab2_main.tex\n")
cat("  tab3_robustness.tex\n")
cat("  tab4_heterogeneity.tex\n")
cat("  tabF1_sde.tex\n")
