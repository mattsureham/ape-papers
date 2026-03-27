# ==============================================================================
# 05_tables.R — Generate all LaTeX tables
# Paper: The Picture Bride Premium
# ==============================================================================

source("00_packages.R")

dt <- readRDS("../data/analysis_sample.rds")
dt_women <- readRDS("../data/census_asian_women.rds")
load("../data/models.rda")
load("../data/robustness_models.rda")

tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ==========================================================================
# TABLE 1: Summary Statistics — Japanese vs Chinese Men by Census Year
# ==========================================================================

cat("Generating Table 1: Summary Statistics\n")

# Compute women counts for sex ratio
women_nat <- dt_women[, .(n_women = .N), by = .(YEAR, RACE)]
men_nat <- dt[, .(n_men = .N), by = .(YEAR, RACE)]
sr_tab <- merge(men_nat, women_nat, by = c("YEAR", "RACE"), all.x = TRUE)
sr_tab[is.na(n_women), n_women := 0]
sr_tab[, sex_ratio := round(n_men / pmax(n_women, 1), 1)]

summ <- dt[, .(
  N = .N,
  mean_age = mean(AGE),
  pct_married = 100 * mean(married),
  pct_spouse_present = 100 * mean(spouse_present),
  mean_occscore = mean(OCCSCORE, na.rm = TRUE),
  pct_literate = 100 * mean(literate, na.rm = TRUE),
  pct_farm_owner = 100 * mean(farm_owner, na.rm = TRUE)
), by = .(YEAR, RACE)]

summ <- merge(summ, sr_tab[, .(YEAR, RACE, sex_ratio)], by = c("YEAR", "RACE"))

# Format table
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Japanese and Chinese Men in the United States, 1900--1930}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccccccc}",
  "\\toprule",
  " & \\multicolumn{4}{c}{Japanese} & \\multicolumn{4}{c}{Chinese} \\\\",
  "\\cmidrule(lr){2-5} \\cmidrule(lr){6-9}",
  " & 1900 & 1910 & 1920 & 1930 & 1900 & 1910 & 1920 & 1930 \\\\",
  "\\midrule"
)

jap <- summ[RACE == 5][order(YEAR)]
chi <- summ[RACE == 4][order(YEAR)]

add_row <- function(label, var, fmt = "%.1f") {
  vals <- c(sprintf(fmt, jap[[var]]), sprintf(fmt, chi[[var]]))
  paste0(label, " & ", paste(vals, collapse = " & "), " \\\\")
}

tab1_lines <- c(tab1_lines,
  add_row("$N$", "N", fmt = "%s"),
  add_row("Mean age", "mean_age"),
  add_row("Sex ratio (M/F)", "sex_ratio"),
  add_row("Married (\\%)", "pct_married"),
  add_row("Spouse present (\\%)", "pct_spouse_present"),
  add_row("Occupational score", "mean_occscore"),
  add_row("Literate (\\%)", "pct_literate"),
  add_row("Farm owner (\\%)", "pct_farm_owner"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Full-count U.S. Census data from IPUMS, men aged 15--65. ``Married'' includes both spouse present and absent. ``Spouse present'' requires co-residence. Sex ratio is men per woman among the same racial group aged 15--65. Occupational score (OCCSCORE) assigns 1950 median income to each occupation. ``Farm owner'' denotes residing on a farm in an owned dwelling.",
  "\\end{tablenotes}",
  "\\end{table}"
)

# Fix N formatting
for (i in seq_along(tab1_lines)) {
  if (grepl("^\\$N\\$", tab1_lines[i])) {
    vals <- c(formatC(jap$N, format = "d", big.mark = ","),
              formatC(chi$N, format = "d", big.mark = ","))
    tab1_lines[i] <- paste0("$N$ & ", paste(vals, collapse = " & "), " \\\\")
  }
}

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))

# ==========================================================================
# TABLE 2: First Stage — Picture Brides and Family Formation
# ==========================================================================

cat("Generating Table 2: First Stage\n")

tab2 <- etable(fs1, fs2, fs3, es_fs,
               headers = c("(1)", "(2)", "(3)", "(4)"),
               keep = c("%treat", "%YEAR"),
               dict = c(treat = "Japanese $\\times$ Post",
                        "YEAR::1900:japanese" = "Japanese $\\times$ 1900",
                        "YEAR::1920:japanese" = "Japanese $\\times$ 1920",
                        "YEAR::1930:japanese" = "Japanese $\\times$ 1930"),
               se.below = TRUE,
               fitstat = c("n", "r2"),
               style.tex = style.tex("aer"),
               tex = TRUE,
               title = "First Stage: Picture Brides and Family Formation",
               label = "tab:first_stage",
               depvar = FALSE,
               notes = c("Dependent variable: Spouse present (indicator). Sample: Japanese and Chinese men aged 15--65 in the 1900--1930 U.S. Census. Standard errors clustered by state in parentheses. $^{*}p<0.1$; $^{**}p<0.05$; $^{***}p<0.01$."))

writeLines(tab2, file.path(tables_dir, "tab2_first_stage.tex"))

# ==========================================================================
# TABLE 3: Main Results — OCCSCORE and Farm Ownership
# ==========================================================================

cat("Generating Table 3: Main Results\n")

tab3 <- etable(m1, m2, m3, m4,
               headers = c("(1)", "(2)", "(3)", "(4)"),
               keep = c("%treat"),
               dict = c(treat = "Japanese $\\times$ Post"),
               se.below = TRUE,
               fitstat = c("n", "r2"),
               style.tex = style.tex("aer"),
               tex = TRUE,
               title = "Main Results: Occupational Income and Farm Ownership",
               label = "tab:main",
               depvar = FALSE,
               notes = c("Dependent variable: OCCSCORE (cols.~1--3), farm ownership indicator (col.~4). Sample: Japanese and Chinese men aged 15--65 in the 1900--1930 U.S. Census. Standard errors clustered by state. $^{*}p<0.1$; $^{**}p<0.05$; $^{***}p<0.01$."))

writeLines(tab3, file.path(tables_dir, "tab3_main.tex"))

# ==========================================================================
# TABLE 4: Robustness Checks
# ==========================================================================

cat("Generating Table 4: Robustness\n")

tab4 <- etable(m3, pre_occ, rob_prime, rob_no_ca, rob_west,
               headers = c("Baseline", "Pre-trend", "Ages 25-45", "Excl. CA", "West Coast"),
               keep = c("%treat"),
               dict = c(treat = "Japanese $\\times$ Post",
                        treat_pre = "Japanese $\\times$ Post(1910)"),
               se.below = TRUE,
               fitstat = c("n", "r2"),
               style.tex = style.tex("aer"),
               tex = TRUE,
               title = "Robustness: Occupational Income Score",
               label = "tab:robustness",
               depvar = FALSE,
               notes = c("Dependent variable: OCCSCORE. All specifications include state$\\times$year fixed effects, age, age$^2$, and literacy controls. Col.~2 restricts to 1900--1910 (pre-picture-bride period). Standard errors clustered by state. $^{*}p<0.1$; $^{**}p<0.05$; $^{***}p<0.01$."))

writeLines(tab4, file.path(tables_dir, "tab4_robustness.tex"))

# ==========================================================================
# TABLE 5: Heterogeneity — Alien Land Law States
# ==========================================================================

cat("Generating Table 5: ALI Heterogeneity\n")

# Build a clean heterogeneity table
het_data <- data.table(
  Panel = c("A. OCCSCORE", "", "B. Farm ownership", ""),
  Subsample = c("ALI states (CA)", "Non-ALI states", "ALI states (CA)", "Non-ALI states"),
  Estimate = NA_real_,
  SE = NA_real_,
  N = NA_integer_
)

het_data[1, `:=`(Estimate = coef(ali_yes)[1], SE = se(ali_yes)[1],
                 N = ali_yes$nobs)]
het_data[2, `:=`(Estimate = coef(ali_no)[1], SE = se(ali_no)[1],
                 N = ali_no$nobs)]

# Farm ownership heterogeneity
dt_ali <- dt[YEAR %in% c(1910, 1930)]
dt_ali[, post_1930 := as.integer(YEAR == 1930)]

ali_farm_yes <- feols(farm_owner ~ i(japanese, post_1930) + AGE + age_sq + literate |
                        STATEFIP^YEAR + RACE,
                      data = dt_ali[ali_state == 1], cluster = ~STATEFIP)
ali_farm_no <- feols(farm_owner ~ i(japanese, post_1930) + AGE + age_sq + literate |
                       STATEFIP^YEAR + RACE,
                     data = dt_ali[ali_state == 0], cluster = ~STATEFIP)

het_data[3, `:=`(Estimate = coef(ali_farm_yes)[1], SE = se(ali_farm_yes)[1],
                 N = ali_farm_yes$nobs)]
het_data[4, `:=`(Estimate = coef(ali_farm_no)[1], SE = se(ali_farm_no)[1],
                 N = ali_farm_no$nobs)]

# Write table
tab5_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Heterogeneity by Alien Land Law Status}",
  "\\label{tab:heterogeneity}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Estimate & SE & $N$ \\\\",
  "\\midrule"
)

for (i in 1:nrow(het_data)) {
  if (nchar(het_data$Panel[i]) > 0) {
    tab5_lines <- c(tab5_lines,
      paste0("\\multicolumn{4}{l}{\\textit{", het_data$Panel[i], "}} \\\\"))
  }
  stars <- ""
  if (!is.na(het_data$Estimate[i])) {
    pval <- 2 * pnorm(-abs(het_data$Estimate[i] / het_data$SE[i]))
    if (pval < 0.01) stars <- "^{***}" else if (pval < 0.05) stars <- "^{**}" else if (pval < 0.1) stars <- "^{*}"
  }
  tab5_lines <- c(tab5_lines,
    sprintf("\\quad %s & %s$%s$ & (%s) & %s \\\\",
            het_data$Subsample[i],
            formatC(het_data$Estimate[i], format = "f", digits = 4),
            stars,
            formatC(het_data$SE[i], format = "f", digits = 4),
            formatC(het_data$N[i], format = "d", big.mark = ",")))
}

tab5_lines <- c(tab5_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each cell reports the coefficient on Japanese $\\times$ Post from a separate regression. Alien Land Law (ALI) states: California (1913 law). All specifications include state$\\times$year fixed effects, age, age$^2$, and literacy controls. Sample restricted to 1910 and 1930. Standard errors clustered by state. $^{*}p<0.1$; $^{**}p<0.05$; $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, file.path(tables_dir, "tab5_heterogeneity.tex"))

# ==========================================================================
# SDE TABLE (Appendix — Mandatory)
# ==========================================================================

cat("Generating SDE table\n")

# Compute SDE for main outcomes
# Pre-treatment SD(Y) computed from 1900-1910 pooled sample (both races)
sd_occ_pre <- sd(dt[YEAR <= 1910]$OCCSCORE, na.rm = TRUE)
sd_farm_pre <- sd(dt[YEAR <= 1910]$farm_owner, na.rm = TRUE)
sd_sp_pre <- sd(dt[YEAR <= 1910]$spouse_present, na.rm = TRUE)

# Main estimates
beta_occ <- coef(m3)["treat"]
se_occ <- se(m3)["treat"]
sde_occ <- beta_occ / sd_occ_pre
se_sde_occ <- se_occ / sd_occ_pre

beta_farm <- coef(m4)["treat"]
se_farm <- se(m4)["treat"]
sde_farm <- beta_farm / sd_farm_pre
se_sde_farm <- se_farm / sd_farm_pre

beta_sp <- coef(fs3)["treat"]
se_sp <- se(fs3)["treat"]
sde_sp <- beta_sp / sd_sp_pre
se_sde_sp <- se_sp / sd_sp_pre

classify_sde <- function(s) {
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s < 0.005) return("Null")
  if (s < 0.05) return("Small positive")
  if (s < 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel A: Pooled
sde_rows_a <- data.table(
  Outcome = c("Spouse present", "Occupational score (OCCSCORE)", "Farm owner"),
  Beta = c(beta_sp, beta_occ, beta_farm),
  SE = c(se_sp, se_occ, se_farm),
  SD_Y = c(sd_sp_pre, sd_occ_pre, sd_farm_pre),
  SDE = c(sde_sp, sde_occ, sde_farm),
  SE_SDE = c(se_sde_sp, se_sde_occ, se_sde_farm)
)
sde_rows_a[, Classification := sapply(SDE, classify_sde)]

# Panel B: Heterogeneous (ALI vs non-ALI for farm ownership)
beta_ali_farm <- coef(ali_farm_yes)[1]
se_ali_farm <- se(ali_farm_yes)[1]
sde_ali_farm <- beta_ali_farm / sd_farm_pre
se_sde_ali_farm <- se_ali_farm / sd_farm_pre

beta_noali_farm <- coef(ali_farm_no)[1]
se_noali_farm <- se(ali_farm_no)[1]
sde_noali_farm <- beta_noali_farm / sd_farm_pre
se_sde_noali_farm <- se_noali_farm / sd_farm_pre

sde_rows_b <- data.table(
  Outcome = c("Farm owner (ALI states)", "Farm owner (non-ALI states)"),
  Beta = c(beta_ali_farm, beta_noali_farm),
  SE = c(se_ali_farm, se_noali_farm),
  SD_Y = c(sd_farm_pre, sd_farm_pre),
  SDE = c(sde_ali_farm, sde_noali_farm),
  SE_SDE = c(se_sde_ali_farm, se_sde_noali_farm)
)
sde_rows_b[, Classification := sapply(SDE, classify_sde)]

# Build SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the picture bride system (1908--1920), which enabled Japanese immigrant men to bring wives from Japan, affect their occupational attainment and farm ownership relative to Chinese men who lacked family reunification channels? ",
  "\\textbf{Policy mechanism:} The 1907--08 Gentlemen's Agreement banned Japanese male labor immigration but permitted wives through arranged transpacific marriages (picture brides), producing a fourfold increase in Japanese women by 1920; the 1920 Ladies' Agreement abruptly closed this channel. Chinese men were denied equivalent access by the Chinese Exclusion Act (1882). ",
  "\\textbf{Outcome definition:} Spouse present is an indicator for co-resident wife (MARST=1). OCCSCORE assigns the 1950 median occupational income to each 1950 occupation code, range 0--100. Farm owner indicates residence on a farm in an owned dwelling (FARM=2, OWNERSHP=1). ",
  "\\textbf{Treatment:} Binary; Japanese (RACE=5) versus Chinese (RACE=4), interacted with post-1920 indicator. ",
  "\\textbf{Data:} IPUMS full-count U.S. Census, 1900--1930, men aged 15--65; 424,865 person-year observations across four census years. ",
  "\\textbf{Method:} Difference-in-differences (Japanese vs.\\ Chinese $\\times$ pre/post 1920) with state-by-year fixed effects and individual controls (age, age$^2$, literacy); standard errors clustered by state. ",
  "\\textbf{Sample:} Men aged 15--65 identified as Japanese (RACE=5) or Chinese (RACE=4) in the full-count census. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (1900--1910) ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Write SDE table
sde_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in 1:nrow(sde_rows_a)) {
  sde_lines <- c(sde_lines, sprintf(
    "%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
    sde_rows_a$Outcome[i], sde_rows_a$Beta[i], sde_rows_a$SE[i],
    sde_rows_a$SD_Y[i], sde_rows_a$SDE[i], sde_rows_a$SE_SDE[i],
    sde_rows_a$Classification[i]))
}

sde_lines <- c(sde_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by Alien Land Law status)}} \\\\"
)

for (i in 1:nrow(sde_rows_b)) {
  sde_lines <- c(sde_lines, sprintf(
    "%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
    sde_rows_b$Outcome[i], sde_rows_b$Beta[i], sde_rows_b$SE[i],
    sde_rows_b$SD_Y[i], sde_rows_b$SDE[i], sde_rows_b$SE_SDE[i],
    sde_rows_b$Classification[i]))
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated in", tables_dir, "\n")
cat("Files:", paste(list.files(tables_dir), collapse = ", "), "\n")
