# =============================================================================
# 03_main_analysis.R — Main regressions: effect of 1924 quota exposure
# =============================================================================

source("00_packages.R")

main <- fread("../data/analysis_main.csv")
placebo <- fread("../data/analysis_placebo.csv")

cat(sprintf("Main panel: %s obs\n", format(nrow(main), big.mark=",")))
cat(sprintf("Placebo panel: %s obs\n", format(nrow(placebo), big.mark=",")))

# ─────────────────────────────────────────────────────────────────────────────
# Table 1: Summary Statistics (written directly)
# ─────────────────────────────────────────────────────────────────────────────

vars <- c("occscore_1920", "occscore_1930", "d_occscore",
          "upgraded", "downgraded", "moved",
          "age_1920", "white", "literate",
          "restricted_share", "fb_share")

labels <- c("OCCSCORE (1920)", "OCCSCORE (1930)", "OCCSCORE Change",
            "Upgraded ($>$5 pts)", "Downgraded ($>$5 pts)", "Geographic Mover",
            "Age (1920)", "White", "Literate",
            "Restricted FB Share", "Total FB Share")

sink("../tables/tab1_summary.tex")
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Native-Born Working-Age Men, 1920--1930}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat("Variable & Mean & Std.\\ Dev. & Min & Max \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{5}{l}{\\textit{Panel A: Individual-Level Variables}} \\\\\n")
for (i in 1:9) {
  v <- vars[i]
  cat(sprintf("%s & %.3f & %.3f & %.0f & %.0f \\\\\n",
              labels[i], mean(main[[v]]), sd(main[[v]]),
              min(main[[v]]), max(main[[v]])))
}
cat("\\midrule\n")
cat("\\multicolumn{5}{l}{\\textit{Panel B: County-Level Treatment Variables}} \\\\\n")
for (i in 10:11) {
  v <- vars[i]
  cat(sprintf("%s & %.4f & %.4f & %.4f & %.4f \\\\\n",
              labels[i], mean(main[[v]]), sd(main[[v]]),
              min(main[[v]]), max(main[[v]])))
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat(sprintf("\\item Notes: N = %s native-born men aged 18--55 in 1920, linked to 1930 census via IPUMS MLP. ",
            format(nrow(main), big.mark=",")))
cat("OCCSCORE is the 1950 occupational income score. ")
cat("Restricted FB Share is the county-level share of 1920 population born in countries targeted by the 1924 Johnson-Reed Act quotas ")
cat("(Italy, Russia, Poland, Austria-Hungary, Czechoslovakia, Lithuania, Yugoslavia, Romania, Greece, Albania, Bulgaria). ")
cat(sprintf("Computed from the 1920 full-count census across %d counties.\n",
            uniqueN(main$county_id)))
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\label{tab:summary}\n")
cat("\\end{table}\n")
sink()

# ─────────────────────────────────────────────────────────────────────────────
# Table 2: Main Results — OCCSCORE Change
# ─────────────────────────────────────────────────────────────────────────────

m1 <- feols(d_occscore ~ restricted_share, data = main, vcov = ~county_id)
m2 <- feols(d_occscore ~ restricted_share + age_1920 + I(age_1920^2) + white + literate,
            data = main, vcov = ~county_id)
m3 <- feols(d_occscore ~ restricted_share + age_1920 + I(age_1920^2) + white + literate | statefip_1920,
            data = main, cluster = ~county_id)
m4 <- feols(d_occscore ~ restricted_share + age_1920 + I(age_1920^2) + white + literate | statefip_1920 + occ1950_1920,
            data = main, cluster = ~county_id)
m5 <- feols(d_occscore ~ restricted_share + age_1920 + I(age_1920^2) + white + literate | statefip_1920^occ1950_1920,
            data = main, cluster = ~county_id)

cat("\n=== MAIN RESULTS ===\n")
etable(m1, m2, m3, m4, m5)

main_beta <- coef(m4)["restricted_share"]
main_se <- se(m4)["restricted_share"]
cat(sprintf("\nPreferred spec (col 4): beta = %.4f, SE = %.4f, t = %.2f\n",
            main_beta, main_se, main_beta/main_se))

# ─────────────────────────────────────────────────────────────────────────────
# Binary outcomes (upgrading, downgrading, mobility, farm exit, industry switch)
# ─────────────────────────────────────────────────────────────────────────────

m_up <- feols(upgraded ~ restricted_share + age_1920 + I(age_1920^2) + white + literate | statefip_1920 + occ1950_1920,
              data = main, cluster = ~county_id)

m_down <- feols(downgraded ~ restricted_share + age_1920 + I(age_1920^2) + white + literate | statefip_1920 + occ1950_1920,
                data = main, cluster = ~county_id)

m_move <- feols(moved ~ restricted_share + age_1920 + I(age_1920^2) + white + literate | statefip_1920 + occ1950_1920,
                data = main, cluster = ~county_id)

m_farm <- feols(left_farm ~ restricted_share + age_1920 + I(age_1920^2) + white + literate | statefip_1920 + occ1950_1920,
                data = main[farm_1920 == 2], cluster = ~county_id)

m_ind <- feols(switched_industry ~ restricted_share + age_1920 + I(age_1920^2) + white + literate | statefip_1920 + occ1950_1920,
               data = main, cluster = ~county_id)

cat("\n=== BINARY OUTCOMES ===\n")
etable(m_up, m_down, m_move, m_farm, m_ind)

# ─────────────────────────────────────────────────────────────────────────────
# Placebo: 1910-1920 panel
# ─────────────────────────────────────────────────────────────────────────────

m_placebo <- feols(d_occscore ~ restricted_share + age_1910 + I(age_1910^2) + white + literate | statefip_1920 + occ1950_1910,
                   data = placebo, cluster = ~county_id)

m_up_placebo <- feols(upgraded ~ restricted_share + age_1910 + I(age_1910^2) + white + literate | statefip_1920 + occ1950_1910,
                      data = placebo, cluster = ~county_id)

cat("\n=== PLACEBO (1910-1920) ===\n")
etable(m_placebo, m_up_placebo)

placebo_beta <- coef(m_placebo)["restricted_share"]
placebo_se <- se(m_placebo)["restricted_share"]
cat(sprintf("Placebo: beta = %.4f, SE = %.4f, t = %.2f\n",
            placebo_beta, placebo_se, placebo_beta/placebo_se))

# ─────────────────────────────────────────────────────────────────────────────
# Save results
# ─────────────────────────────────────────────────────────────────────────────

results <- list(
  main_specs = list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5),
  binary = list(m_up = m_up, m_down = m_down, m_move = m_move, m_farm = m_farm, m_ind = m_ind),
  placebo = list(m_placebo = m_placebo, m_up_placebo = m_up_placebo)
)

saveRDS(results, "../data/main_results.rds")

# diagnostics.json for validator
n_counties <- uniqueN(main$county_id)
n_high_exp <- uniqueN(main[high_exposure == 1, county_id])

diagnostics <- list(
  n_treated = n_high_exp,
  n_pre = 10L,
  n_obs = nrow(main),
  n_counties = n_counties,
  n_placebo = nrow(placebo),
  main_beta = unname(main_beta),
  main_se = unname(main_se),
  placebo_beta = unname(placebo_beta),
  placebo_se = unname(placebo_se)
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\nMain analysis complete. Results saved.\n")
