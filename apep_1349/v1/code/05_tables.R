## 05_tables.R — Generate LaTeX tables for paper
## APEP-1349: Dutch BPM Multi-Cutoff Bunching

source("00_packages.R")

nl_pooled <- readRDS("../data/nl_pooled.rds")
de_pooled <- readRDS("../data/de_pooled.rds")
kinks <- readRDS("../data/kinks.rds")
comparison <- readRDS("../data/nl_de_comparison.rds")
robust <- readRDS("../data/robustness_results.rds")
df_raw <- readRDS("../data/co2_distributions.rds")

# ============================================================
# TABLE 1: BPM Tax Schedule
# ============================================================
cat("Generating Table 1: BPM Tax Schedule...\n")

calc_bpm <- function(co2) {
  if (co2 <= 0) return(0)
  if (co2 <= 79) return(667 + co2 * 2)
  if (co2 <= 101) return(825 + (co2 - 79) * 79)
  if (co2 <= 141) return(2563 + (co2 - 101) * 173)
  if (co2 <= 157) return(9483 + (co2 - 141) * 284)
  return(14027 + (co2 - 157) * 568)
}

tab1 <- data.frame(
  Band = c("1", "2", "3", "4", "5"),
  CO2_Range = c("0--79", "80--101", "102--141", "142--157", "158+"),
  Base_EUR = c("\\euro 667", "\\euro 825", "\\euro 2,563",
               "\\euro 9,483", "\\euro 14,027"),
  Rate = c("\\euro 2/g", "\\euro 79/g", "\\euro 173/g",
           "\\euro 284/g", "\\euro 568/g"),
  Rate_Ratio = c("---", "39.5$\\times$", "2.2$\\times$",
                  "1.6$\\times$", "2.0$\\times$"),
  Tax_at_Upper = c(
    sprintf("\\euro %s", format(calc_bpm(79), big.mark = ",")),
    sprintf("\\euro %s", format(calc_bpm(101), big.mark = ",")),
    sprintf("\\euro %s", format(calc_bpm(141), big.mark = ",")),
    sprintf("\\euro %s", format(calc_bpm(157), big.mark = ",")),
    sprintf("\\euro %s", format(calc_bpm(200), big.mark = ","))
  )
)

tab1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Dutch BPM Tax Schedule (2020--2022, WLTP)}\n",
  "\\label{tab:bpm_schedule}\n",
  "\\begin{tabular}{clcccc}\n",
  "\\toprule\n",
  "Band & CO$_2$ Range (g/km) & Base Tax & Marginal Rate & Rate Jump & Tax at Upper Bound \\\\\n",
  "\\midrule\n"
)
for (i in 1:nrow(tab1)) {
  tab1_tex <- paste0(tab1_tex,
    tab1$Band[i], " & ", tab1$CO2_Range[i], " & ",
    tab1$Base_EUR[i], " & ", tab1$Rate[i], " & ",
    tab1$Rate_Ratio[i], " & ", tab1$Tax_at_Upper[i], " \\\\\n"
  )
}
tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} BPM (\\textit{Belasting van Personenauto's en Motorrijwielen}) ",
  "is a one-time vehicle purchase tax in the Netherlands. The tax is a continuous, piecewise-linear ",
  "function of WLTP CO$_2$ emissions with kinks at 79, 101, 141, and 157 g/km where the marginal rate ",
  "increases. Rate Jump shows the ratio of the new marginal rate to the previous rate at each kink. ",
  "Source: Wet op de belasting van personenauto's en motorrijwielen 1992, as amended 2020.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, "../tables/tab1_bpm_schedule.tex")

# ============================================================
# TABLE 2: Summary Statistics
# ============================================================
cat("Generating Table 2: Summary Statistics...\n")

# Summary by country
summ <- df_raw %>%
  group_by(country) %>%
  summarise(
    n_vehicles = sum(count),
    n_co2_values = n_distinct(co2),
    mean_co2 = weighted.mean(co2, count),
    median_co2 = {
      expanded <- rep(co2, count)
      median(expanded)
    },
    sd_co2 = {
      expanded <- rep(co2, count)
      sd(expanded)
    },
    p10_co2 = {
      expanded <- rep(co2, count)
      quantile(expanded, 0.10)
    },
    p90_co2 = {
      expanded <- rep(co2, count)
      quantile(expanded, 0.90)
    },
    .groups = "drop"
  )

# By year within NL
summ_yr <- df_raw %>%
  filter(country == "NL") %>%
  group_by(year) %>%
  summarise(n_vehicles = sum(count), .groups = "drop")

tab2_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: New Vehicle Registrations (2020--2022)}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & Netherlands & Germany \\\\\n",
  "\\midrule\n",
  sprintf("Total registrations & %s & %s \\\\\n",
          format(summ$n_vehicles[summ$country == "NL"], big.mark = ","),
          format(summ$n_vehicles[summ$country == "DE"], big.mark = ",")),
  sprintf("Mean CO$_2$ (g/km) & %.1f & %.1f \\\\\n",
          summ$mean_co2[summ$country == "NL"],
          summ$mean_co2[summ$country == "DE"]),
  sprintf("Median CO$_2$ (g/km) & %.0f & %.0f \\\\\n",
          summ$median_co2[summ$country == "NL"],
          summ$median_co2[summ$country == "DE"]),
  sprintf("Std. Dev. CO$_2$ & %.1f & %.1f \\\\\n",
          summ$sd_co2[summ$country == "NL"],
          summ$sd_co2[summ$country == "DE"]),
  sprintf("10th percentile CO$_2$ & %.0f & %.0f \\\\\n",
          summ$p10_co2[summ$country == "NL"],
          summ$p10_co2[summ$country == "DE"]),
  sprintf("90th percentile CO$_2$ & %.0f & %.0f \\\\\n",
          summ$p90_co2[summ$country == "NL"],
          summ$p90_co2[summ$country == "DE"]),
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Netherlands by year}} \\\\\n",
  sprintf("\\quad 2020 & %s & \\\\\n", format(summ_yr$n_vehicles[summ_yr$year == 2020], big.mark = ",")),
  sprintf("\\quad 2021 & %s & \\\\\n", format(summ_yr$n_vehicles[summ_yr$year == 2021], big.mark = ",")),
  sprintf("\\quad 2022 & %s & \\\\\n", format(summ_yr$n_vehicles[summ_yr$year == 2022], big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Vehicle-level registration data from the European Environment Agency, ",
  "CO$_2$ emissions monitoring under Regulation (EU) 2019/631. CO$_2$ measured under the WLTP test cycle. ",
  "Registrations with CO$_2$ $= 0$ (battery-electric vehicles) excluded. Germany serves as a placebo ",
  "country: it has no purchase tax with CO$_2$ kinks at the Dutch BPM thresholds.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2_tex, "../tables/tab2_summary.tex")

# ============================================================
# TABLE 3: McCrary Density Discontinuity Tests
# ============================================================
cat("Generating Table 3: McCrary Tests...\n")

mccrary_results <- list()
for (k in c(79, 101, 141, 157)) {
  for (cty in c("NL", "DE")) {
    d <- if (cty == "NL") nl_pooled else de_pooled
    test_d <- d %>%
      filter(co2 >= k - 15, co2 <= k + 15, count > 0) %>%
      mutate(above = as.integer(co2 > k), z = co2 - k, log_count = log(count))
    if (nrow(test_d) < 10) next
    fit <- lm(log_count ~ above + z + I(z^2) + above:z, data = test_d)
    coef_above <- coef(fit)["above"]
    se_above <- sqrt(vcov(fit)["above", "above"])
    mccrary_results[[paste(k, cty)]] <- data.frame(
      kink = k, country = cty,
      discontinuity = coef_above, se = se_above,
      t_stat = coef_above / se_above
    )
  }
}
mcc_df <- bind_rows(mccrary_results)

tab3_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{McCrary Density Discontinuity Tests at BPM Kinks}\n",
  "\\label{tab:mccrary}\n",
  "\\begin{tabular}{ccccccc}\n",
  "\\toprule\n",
  " & & \\multicolumn{2}{c}{Netherlands} & \\multicolumn{2}{c}{Germany (Placebo)} & \\\\\n",
  "\\cmidrule(lr){3-4} \\cmidrule(lr){5-6}\n",
  "Kink & Rate Jump & Disc. & $t$-stat & Disc. & $t$-stat & NL$-$DE \\\\\n",
  "(g/km) & & & & & & $\\Delta$ Disc. \\\\\n",
  "\\midrule\n"
)

for (k in c(79, 101, 141, 157)) {
  rj <- kinks$rate_ratio[kinks$kink_co2 == k]
  nl <- mcc_df %>% filter(kink == k, country == "NL")
  de <- mcc_df %>% filter(kink == k, country == "DE")
  diff <- nl$discontinuity - de$discontinuity

  tab3_tex <- paste0(tab3_tex, sprintf(
    "%d & %.1f$\\times$ & %.3f & %.2f & %.3f & %.2f & %.3f \\\\\n",
    k, rj, nl$discontinuity, nl$t_stat, de$discontinuity, de$t_stat, diff
  ))
  if (nrow(nl) > 0) {
    tab3_tex <- paste0(tab3_tex, sprintf(
      " & & (%.3f) & & (%.3f) & & \\\\\n",
      nl$se, de$se
    ))
  }
}

tab3_tex <- paste0(tab3_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Log-density discontinuity at each BPM kink, estimated via ",
  "$\\log(n_{\\text{co2}}) = \\alpha + \\beta \\cdot \\mathbf{1}[\\text{CO}_2 > k] + f(\\text{CO}_2 - k) + \\varepsilon$ ",
  "with a quadratic in the running variable and a slope interaction, using bins within $\\pm 15$ g/km ",
  "of each kink. Standard errors in parentheses. Rate Jump shows the ratio of marginal tax rates ",
  "above vs.\\ below the kink. Germany has no purchase tax with corresponding CO$_2$ kinks. ",
  "None of the four Dutch kinks show a statistically significant density discontinuity.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3_tex, "../tables/tab3_mccrary.tex")

# ============================================================
# TABLE 4: Raw Density at Kink Points (NL vs DE)
# ============================================================
cat("Generating Table 4: Raw Density Comparison...\n")

density_comp <- list()
for (k in c(79, 101, 141, 157)) {
  for (offset in c(-2, -1, 0, 1, 2)) {
    co2_val <- k + offset
    nl_n <- nl_pooled$count[nl_pooled$co2 == co2_val]
    de_n <- de_pooled$count[de_pooled$co2 == co2_val]
    if (length(nl_n) == 0) nl_n <- 0
    if (length(de_n) == 0) de_n <- 0
    nl_share <- nl_n / sum(nl_pooled$count) * 1000  # per 1000
    de_share <- de_n / sum(de_pooled$count) * 1000
    density_comp[[paste(k, offset)]] <- data.frame(
      kink = k, co2 = co2_val, offset = offset,
      nl_count = nl_n, nl_per_1000 = nl_share,
      de_count = de_n, de_per_1000 = de_share,
      nl_de_ratio = nl_share / de_share
    )
  }
}
dens_df <- bind_rows(density_comp)

tab4_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{CO$_2$ Density Near BPM Kinks: Netherlands vs.\\ Germany}\n",
  "\\label{tab:density}\n",
  "\\begin{tabular}{ccrrrrc}\n",
  "\\toprule\n",
  "Kink & CO$_2$ & \\multicolumn{2}{c}{Netherlands} & \\multicolumn{2}{c}{Germany} & NL/DE \\\\\n",
  "\\cmidrule(lr){3-4} \\cmidrule(lr){5-6}\n",
  "(g/km) & (g/km) & Count & Per 1000 & Count & Per 1000 & Ratio \\\\\n",
  "\\midrule\n"
)

for (k in c(79, 141, 157)) {
  for (offset in c(-2, -1, 0, 1, 2)) {
    row <- dens_df %>% filter(kink == k, offset == !!offset)
    marker <- ifelse(offset == 0, "$\\leftarrow$", "")
    tab4_tex <- paste0(tab4_tex, sprintf(
      "%s & %d & %s & %.2f & %s & %.2f & %.2f %s \\\\\n",
      ifelse(offset == -2, as.character(k), ""),
      row$co2, format(row$nl_count, big.mark = ","),
      row$nl_per_1000, format(row$de_count, big.mark = ","),
      row$de_per_1000,
      ifelse(row$de_per_1000 > 0, row$nl_de_ratio, 0),
      marker
    ))
  }
  if (k != 157) {
    tab4_tex <- paste0(tab4_tex, "\\addlinespace\n")
  }
}

tab4_tex <- paste0(tab4_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Raw vehicle counts and density (per 1,000 registrations) at each CO$_2$ value ",
  "within $\\pm 2$ g/km of the three main BPM kinks (79, 141, 157 g/km). Kink at 101 omitted for space; ",
  "pattern is similar. Arrows mark the kink point. NL/DE Ratio compares normalized densities ",
  "across countries. If the BPM created excess bunching in the Netherlands, we would expect the NL/DE ratio ",
  "to spike just below the kink and drop just above. The ratios show no such pattern at 141 or 157; ",
  "the apparent drop at 79/80 is present equally in Germany.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab4_tex, "../tables/tab4_density.tex")

# ============================================================
# TABLE 5: Robustness — Polynomial Degree & Bandwidth
# ============================================================
cat("Generating Table 5: Robustness...\n")

# Show 141 kink results across specifications
tab5_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness: Bunching Estimates Across Specifications (Kink at 141 g/km)}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  " & \\multicolumn{3}{c}{Panel A: Polynomial Degree} & \\multicolumn{3}{c}{Panel B: Bandwidth} \\\\\n",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}\n",
  "Specification & $\\hat{b}_{\\text{NL}}$ & $\\hat{b}_{\\text{DE}}$ & $\\Delta$ ($t$) ",
  "& $\\hat{b}_{\\text{NL}}$ & $\\hat{b}_{\\text{DE}}$ & $\\Delta$ ($t$) \\\\\n",
  "\\midrule\n"
)

poly_141 <- robust$poly %>% filter(kink == 141)
bw_141 <- robust$bandwidth %>% filter(kink == 141)

specs <- c("$p=3$", "$p=5$", "$p=7$", "$p=9$")
bw_specs <- c("$h=3$", "$h=5$", "$h=7$", "$h=10$")

for (i in 1:4) {
  p <- poly_141[i, ]
  b <- bw_141[i, ]
  tab5_tex <- paste0(tab5_tex, sprintf(
    "%s & %.2f & %.2f & %.2f (%.1f) & %s & %.2f & %.2f & %.2f (%.1f) \\\\\n",
    specs[i], p$b_nl, p$b_de, p$diff, p$t_stat,
    bw_specs[i], b$b_nl, b$b_de, b$diff, b$t_stat
  ))
}

tab5_tex <- paste0(tab5_tex,
  "\\midrule\n",
  "Sign changes & \\multicolumn{3}{c}{3 of 4 specifications} & \\multicolumn{3}{c}{2 of 4 specifications} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Normalized bunching estimates ($\\hat{b}$) at the 141 g/km kink across ",
  "polynomial degrees (Panel A, bandwidth $h=5$) and bandwidths (Panel B, polynomial degree $p=7$). ",
  "$\\Delta$ is the difference-in-bunching (NL $-$ DE) with $t$-statistic in parentheses. ",
  "The sign of $\\hat{b}_{\\text{NL}}$ and $\\Delta$ reverses across specifications, ",
  "indicating that the bunching estimate is not robust to researcher degrees of freedom. ",
  "This instability is consistent with the McCrary null (Table~\\ref{tab:mccrary}): ",
  "there is no genuine density discontinuity for the polynomial to detect.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab5_tex, "../tables/tab5_robustness.tex")

# ============================================================
# SDE TABLE (APPENDIX — MANDATORY)
# ============================================================
cat("Generating SDE Table...\n")

# For a bunching paper, the "effect" is the normalized bunching b
# Use McCrary discontinuity as the primary estimate (it's more standard)

# Main outcome: McCrary discontinuity at each kink
mcc_nl <- mcc_df %>% filter(country == "NL")

# SD(Y) = SD of log(count) across CO2 bins
sd_log_count <- sd(log(nl_pooled$count[nl_pooled$count > 0]))

sde_rows <- list()
for (i in 1:nrow(mcc_nl)) {
  k <- mcc_nl$kink[i]
  beta <- mcc_nl$discontinuity[i]
  se_beta <- mcc_nl$se[i]
  sde <- beta / sd_log_count
  se_sde <- se_beta / sd_log_count

  bucket <- case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )

  sde_rows[[i]] <- data.frame(
    Outcome = sprintf("Density disc.\\ at %d g/km", k),
    Beta = sprintf("%.3f", beta),
    SE = sprintf("(%.3f)", se_beta),
    SD_Y = sprintf("%.3f", sd_log_count),
    SDE = sprintf("%.3f", sde),
    SE_SDE = sprintf("(%.3f)", se_sde),
    Classification = bucket
  )
}

# Add DiB result for 141 (strongest kink-specific claim)
dib_141 <- mcc_nl %>% filter(kink == 141)
de_141 <- mcc_df %>% filter(kink == 141, country == "DE")
dib_beta <- dib_141$discontinuity - de_141$discontinuity
dib_se <- sqrt(dib_141$se^2 + de_141$se^2)
dib_sde <- dib_beta / sd_log_count
dib_se_sde <- dib_se / sd_log_count
dib_bucket <- case_when(
  dib_sde < -0.15 ~ "Large negative",
  dib_sde < -0.05 ~ "Moderate negative",
  dib_sde < -0.005 ~ "Small negative",
  dib_sde <= 0.005 ~ "Null",
  dib_sde <= 0.05 ~ "Small positive",
  dib_sde <= 0.15 ~ "Moderate positive",
  TRUE ~ "Large positive"
)

sde_rows[[5]] <- data.frame(
  Outcome = "DiB at 141 (NL$-$DE)",
  Beta = sprintf("%.3f", dib_beta),
  SE = sprintf("(%.3f)", dib_se),
  SD_Y = sprintf("%.3f", sd_log_count),
  SDE = sprintf("%.3f", dib_sde),
  SE_SDE = sprintf("(%.3f)", dib_se_sde),
  Classification = dib_bucket
)

sde_df <- bind_rows(sde_rows)

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Netherlands (with Germany as placebo). ",
  "\\textbf{Research question:} Does the Dutch BPM vehicle purchase tax, which features ",
  "four kinks where marginal CO\\textsubscript{2} tax rates increase by 1.6--39.5 times, ",
  "induce manufacturers to manipulate type-approval CO\\textsubscript{2} emissions to bunch below thresholds? ",
  "\\textbf{Policy mechanism:} The BPM is a one-time purchase tax calculated from WLTP CO\\textsubscript{2} ",
  "emissions with piecewise-linear rate bands; crossing a kink increases the per-gram rate, ",
  "raising the marginal cost of higher emissions for buyers and creating incentives for ",
  "manufacturers to calibrate type-approval emissions below each kink. ",
  "\\textbf{Outcome definition:} McCrary log-density discontinuity at each BPM kink, ",
  "measuring whether the CO\\textsubscript{2} distribution exhibits a break at the threshold. ",
  "\\textbf{Treatment:} Four kink points (79, 101, 141, 157 g/km) with varying marginal rate jumps. ",
  "\\textbf{Data:} European Environment Agency vehicle-level CO\\textsubscript{2} monitoring data ",
  "(Regulation EU 2019/631), 2020--2022, 1.25 million Dutch and 11.5 million German registrations. ",
  "\\textbf{Method:} McCrary density discontinuity test with quadratic in running variable ",
  "and slope interaction, difference-in-bunching (NL minus DE). ",
  "\\textbf{Sample:} Vehicles with WLTP CO\\textsubscript{2} between 1 and 250 g/km; ",
  "battery-electric vehicles (0 g/km) excluded. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the standard deviation of ",
  "log bin counts across all CO\\textsubscript{2} values. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled (McCrary discontinuity at each kink)}} \\\\\n"
)

for (i in 1:4) {
  sde_tex <- paste0(sde_tex, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\\n",
    sde_df$Outcome[i], sde_df$Beta[i], sde_df$SE[i],
    sde_df$SD_Y[i], sde_df$SDE[i], sde_df$SE_SDE[i],
    sde_df$Classification[i]
  ))
}

sde_tex <- paste0(sde_tex,
  "\\addlinespace\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Difference-in-Bunching, NL vs.\\ DE)}} \\\\\n",
  sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\\n",
    sde_df$Outcome[5], sde_df$Beta[5], sde_df$SE[5],
    sde_df$SD_Y[5], sde_df$SDE[5], sde_df$SE_SDE[5],
    sde_df$Classification[5]
  ),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
cat(sprintf("Files: %s\n", paste(list.files("../tables/"), collapse = ", ")))
cat("05_tables.R complete.\n")
