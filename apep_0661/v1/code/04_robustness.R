# 04_robustness.R — Robustness checks for apep_0661
# UK Asylum Dispersal and Local Crime: Shift-Share IV

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, log_crime := log(crime_rate + 0.01)]
cat("Panel loaded:", nrow(panel), "obs\n")

make_tex_row <- function(...) paste(c(...), collapse = " & ") |> paste0(" \\\\")

# =============================================================================
# 1. FIRST-STAGE DIAGNOSTICS
# =============================================================================
cat("\n=== 1. First-Stage Diagnostics ===\n")

fs <- feols(dispersal_rate ~ ssiv | csp_id + time_id, cluster = ~csp_id, data = panel)
fs_t <- coef(fs)["ssiv"] / se(fs)["ssiv"]
fs_F <- fs_t^2
cat(sprintf("First-stage F: %.2f (t=%.3f)\n", fs_F, fs_t))
cat(sprintf("Coef: %.8f, SE: %.8f\n", coef(fs)["ssiv"], se(fs)["ssiv"]))

# Reduced form
rf <- feols(crime_rate ~ ssiv | csp_id + time_id, cluster = ~csp_id, data = panel)
cat(sprintf("Reduced form: coef=%.6f, se=%.6f, p=%.4f\n",
            coef(rf)["ssiv"], se(rf)["ssiv"], pvalue(rf)["ssiv"]))

# =============================================================================
# 2. ALTERNATIVE INSTRUMENT CONSTRUCTIONS
# =============================================================================
cat("\n=== 2. Alternative IV constructions ===\n")

# (a) Standardize vacancy share
panel[, vac_std := (vacancy_share - mean(vacancy_share)) / sd(vacancy_share)]
panel[, ssiv_std := vac_std * national_total]
fs_std <- feols(dispersal_rate ~ ssiv_std | csp_id + time_id, cluster = ~csp_id, data = panel)
cat(sprintf("Standardized vacancy: F=%.2f\n", (coef(fs_std)["ssiv_std"] / se(fs_std)["ssiv_std"])^2))

# (b) Log national total
panel[, log_nat := log(national_total + 1)]
panel[, ssiv_log := vacancy_share * log_nat]
fs_log <- feols(dispersal_rate ~ ssiv_log | csp_id + time_id, cluster = ~csp_id, data = panel)
cat(sprintf("Log national shift: F=%.2f\n", (coef(fs_log)["ssiv_log"] / se(fs_log)["ssiv_log"])^2))

# (c) Per-capita national total
panel[, nat_pc := national_total / sum(unique(panel[, .(csp_name, pop = population[1]), by = csp_name])$pop)]
panel[, ssiv_pc := vacancy_share * nat_pc]
fs_pc <- feols(dispersal_rate ~ ssiv_pc | csp_id + time_id, cluster = ~csp_id, data = panel)
cat(sprintf("Per-capita national shift: F=%.2f\n", (coef(fs_pc)["ssiv_pc"] / se(fs_pc)["ssiv_pc"])^2))

# =============================================================================
# 3. OLS ROBUSTNESS
# =============================================================================
cat("\n=== 3. OLS Robustness ===\n")

# (a) Baseline OLS
ols_base <- feols(crime_rate ~ dispersal_rate | csp_id + time_id,
                  cluster = ~csp_id, data = panel)
cat(sprintf("OLS baseline: %.4f (%.4f) p=%.4f\n",
            coef(ols_base)["dispersal_rate"], se(ols_base)["dispersal_rate"],
            pvalue(ols_base)["dispersal_rate"]))

# (b) With region-quarter trends
panel[, region_id := as.integer(factor(substr(csp_name, 1, 3)))]
ols_trends <- feols(crime_rate ~ dispersal_rate | csp_id + time_id + region_id:time_id,
                    cluster = ~csp_id, data = panel)
cat(sprintf("OLS + region trends: %.4f (%.4f) p=%.4f\n",
            coef(ols_trends)["dispersal_rate"], se(ols_trends)["dispersal_rate"],
            pvalue(ols_trends)["dispersal_rate"]))

# (c) Exclude top 10 dispersal CSPs
top10 <- panel[, .(total = sum(asylum_dispersal)), by = csp_name][order(-total)][1:10]$csp_name
cat("Top 10 dispersal CSPs excluded:\n")
cat(paste(" ", top10, collapse = "\n"), "\n")
ols_excl <- feols(crime_rate ~ dispersal_rate | csp_id + time_id,
                  cluster = ~csp_id, data = panel[!csp_name %in% top10])
cat(sprintf("OLS excl. top-10: %.4f (%.4f) p=%.4f\n",
            coef(ols_excl)["dispersal_rate"], se(ols_excl)["dispersal_rate"],
            pvalue(ols_excl)["dispersal_rate"]))

# (d) Pre-COVID only (2016-2019)
ols_pre <- feols(crime_rate ~ dispersal_rate | csp_id + time_id,
                 cluster = ~csp_id, data = panel[cal_year <= 2019])
cat(sprintf("OLS pre-COVID: %.4f (%.4f) p=%.4f\n",
            coef(ols_pre)["dispersal_rate"], se(ols_pre)["dispersal_rate"],
            pvalue(ols_pre)["dispersal_rate"]))

# (e) Post-COVID only (2021+)
ols_post <- feols(crime_rate ~ dispersal_rate | csp_id + time_id,
                  cluster = ~csp_id, data = panel[cal_year >= 2021])
cat(sprintf("OLS post-COVID: %.4f (%.4f) p=%.4f\n",
            coef(ols_post)["dispersal_rate"], se(ols_post)["dispersal_rate"],
            pvalue(ols_post)["dispersal_rate"]))

# =============================================================================
# 4. PLACEBO: LEAD DISPERSAL
# =============================================================================
cat("\n=== 4. Placebo: Lead dispersal ===\n")

setorder(panel, csp_id, time_id)
panel[, lead1_disp := shift(dispersal_rate, n = -1, type = "lead"), by = csp_id]
panel[, lead2_disp := shift(dispersal_rate, n = -2, type = "lead"), by = csp_id]

placebo1 <- feols(crime_rate ~ lead1_disp | csp_id + time_id,
                  cluster = ~csp_id, data = panel[!is.na(lead1_disp)])
cat(sprintf("Placebo (t+1): %.4f (%.4f) p=%.4f\n",
            coef(placebo1)["lead1_disp"], se(placebo1)["lead1_disp"],
            pvalue(placebo1)["lead1_disp"]))

placebo2 <- feols(crime_rate ~ lead2_disp | csp_id + time_id,
                  cluster = ~csp_id, data = panel[!is.na(lead2_disp)])
cat(sprintf("Placebo (t+2): %.4f (%.4f) p=%.4f\n",
            coef(placebo2)["lead2_disp"], se(placebo2)["lead2_disp"],
            pvalue(placebo2)["lead2_disp"]))

# =============================================================================
# 5. DYNAMIC SPECIFICATION
# =============================================================================
cat("\n=== 5. Dynamic specification ===\n")

panel[, lag1_disp := shift(dispersal_rate, n = 1, type = "lag"), by = csp_id]
panel[, lag2_disp := shift(dispersal_rate, n = 2, type = "lag"), by = csp_id]

dynamic <- feols(crime_rate ~ dispersal_rate + lag1_disp + lag2_disp | csp_id + time_id,
                 cluster = ~csp_id, data = panel[!is.na(lag1_disp) & !is.na(lag2_disp)])
cat("Dynamic (contemporaneous + 2 lags):\n")
for (v in c("dispersal_rate", "lag1_disp", "lag2_disp")) {
  cat(sprintf("  %s: %.4f (%.4f) p=%.4f\n", v,
              coef(dynamic)[v], se(dynamic)[v], pvalue(dynamic)[v]))
}

# =============================================================================
# TABLE 4: Robustness Checks (OLS)
# =============================================================================
cat("\n=== Table 4: OLS Robustness ===\n")

get_row <- function(model, varname) {
  b <- coef(model)[varname]
  s <- se(model)[varname]
  p <- pvalue(model)[varname]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(coef = sprintf("%.3f%s", b, stars), se = sprintf("(%.3f)", s),
       n = format(nobs(model), big.mark = ","))
}

r_base <- get_row(ols_base, "dispersal_rate")
r_trends <- get_row(ols_trends, "dispersal_rate")
r_excl <- get_row(ols_excl, "dispersal_rate")
r_pre <- get_row(ols_pre, "dispersal_rate")
r_post <- get_row(ols_post, "dispersal_rate")
r_plac1 <- get_row(placebo1, "lead1_disp")
r_plac2 <- get_row(placebo2, "lead2_disp")

tab4 <- c(
  "\\begin{table}[t]", "\\centering",
  "\\caption{Robustness of OLS Estimates}", "\\label{tab:robustness}", "\\small",
  "\\begin{tabular}{lccc}", "\\hline\\hline",
  " & Dispersal rate & SE & N \\\\", "\\hline",
  "\\multicolumn{4}{l}{\\textit{Panel A: Specification checks}} \\\\",
  make_tex_row("(1) Baseline", r_base$coef, r_base$se, r_base$n),
  make_tex_row("(2) Region $\\times$ quarter FE", r_trends$coef, r_trends$se, r_trends$n),
  make_tex_row("(3) Excl. top-10 dispersal CSPs", r_excl$coef, r_excl$se, r_excl$n),
  "\\hline",
  "\\multicolumn{4}{l}{\\textit{Panel B: Subperiods}} \\\\",
  make_tex_row("(4) Pre-COVID (2016--2019)", r_pre$coef, r_pre$se, r_pre$n),
  make_tex_row("(5) Post-COVID (2021--2024)", r_post$coef, r_post$se, r_post$n),
  "\\hline",
  "\\multicolumn{4}{l}{\\textit{Panel C: Placebo (future dispersal)}} \\\\",
  make_tex_row("(6) Lead $t+1$", r_plac1$coef, r_plac1$se, r_plac1$n),
  make_tex_row("(7) Lead $t+2$", r_plac2$coef, r_plac2$se, r_plac2$n),
  "\\hline\\hline", "\\end{tabular}",
  "\\begin{tablenotes}\\small",
  "\\item \\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$. All models include CSP and quarter fixed effects with standard errors clustered at CSP level. Placebo tests regress current crime on future dispersal rates.",
  "\\end{tablenotes}", "\\end{table}")
writeLines(tab4, file.path(tables_dir, "tab4_robustness.tex"))
cat("Table 4 saved.\n")

# =============================================================================
# 6. CORRELATION OF VACANCY AND CRIME LEVELS
# =============================================================================
cat("\n=== 6. Cross-sectional correlations ===\n")

csp_means <- panel[, .(mean_crime = mean(crime_rate, na.rm = TRUE),
                         mean_disp = mean(dispersal_rate, na.rm = TRUE),
                         vacancy = vacancy_share[1],
                         mean_pop = mean(population, na.rm = TRUE)),
                    by = csp_name]
cat(sprintf("Corr(vacancy, mean_crime): %.3f\n", cor(csp_means$vacancy, csp_means$mean_crime)))
cat(sprintf("Corr(vacancy, mean_dispersal): %.3f\n", cor(csp_means$vacancy, csp_means$mean_disp)))

cat("\n=== Robustness checks complete ===\n")
