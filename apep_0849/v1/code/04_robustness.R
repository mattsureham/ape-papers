# 04_robustness.R — Robustness and heterogeneity
# apep_0849: Taiwan IIA R&D Tax Credit Transition

source("00_packages.R")

tw <- fread("../data/tw_panel.csv")
panel <- fread("../data/analysis_panel.csv")

semi_classes <- c("257", "438")
opto_classes <- c("345", "349", "362", "359", "385", "348", "315")

cat("=== ROBUSTNESS ===\n\n")

# ── 1. Placebo year ────────────────────────────────────────────────────────
cat("1. Placebo 2007\n")
tw_pre <- tw[filing_year <= 2009]
tw_pre[, placebo_post := ifelse(filing_year >= 2007, 1L, 0L)]
m_plac <- feols(ln_patents ~ treated_class:placebo_post | uspc_mainclass + year_id,
                data = tw_pre, cluster = ~uspc_mainclass)
cat("  ", round(coef(m_plac)["treated_class:placebo_post"], 4),
    "(", round(se(m_plac)["treated_class:placebo_post"], 4), ")\n")

# ── 2. Heterogeneity: Semi vs Opto vs Comm ────────────────────────────────
cat("\n2. Heterogeneity\n")
tw[, semi := ifelse(uspc_mainclass %in% semi_classes, 1L, 0L)]
tw[, opto := ifelse(uspc_mainclass %in% opto_classes, 1L, 0L)]

m_semi <- feols(ln_patents ~ semi:post | uspc_mainclass + year_id,
                data = tw, cluster = ~uspc_mainclass)
m_opto <- feols(ln_patents ~ opto:post | uspc_mainclass + year_id,
                data = tw, cluster = ~uspc_mainclass)
cat("  Semi:", round(coef(m_semi)["semi:post"], 4),
    "(", round(se(m_semi)["semi:post"], 4), ")\n")
cat("  Opto:", round(coef(m_opto)["opto:post"], 4),
    "(", round(se(m_opto)["opto:post"], 4), ")\n")

# ── 3. Leave-one-out ──────────────────────────────────────────────────────
cat("\n3. Leave-one-out (top 5 treated classes)\n")
top_treated <- tw[treated_class == 1, .N, by = uspc_mainclass][order(-N)][1:5, uspc_mainclass]
for (dc in top_treated) {
  tw_loo <- tw[uspc_mainclass != dc]
  m <- feols(ln_patents ~ treated_class:post | uspc_mainclass + year_id,
             data = tw_loo, cluster = ~uspc_mainclass)
  cat(sprintf("  Drop %s: %.4f (%.4f)\n", dc,
              coef(m)["treated_class:post"], se(m)["treated_class:post"]))
}

# ── 4. Share ───────────────────────────────────────────────────────────────
cat("\n4. Share DiD\n")
panel[, is_taiwan := ifelse(assignee_country == "TW", 1L, 0L)]
share <- panel[, .(
  total = sum(n_patents),
  treated_n = sum(n_patents[treated_class == 1])
), by = .(assignee_country, filing_year)]
share[, treated_share := treated_n / total]
share[, post := ifelse(filing_year >= 2010, 1L, 0L)]
share[, is_taiwan := ifelse(assignee_country == "TW", 1L, 0L)]
share[, year_id := as.integer(factor(filing_year))]
m_share <- feols(treated_share ~ is_taiwan:post | assignee_country + year_id,
                 data = share, cluster = ~assignee_country)
cat("  ", round(coef(m_share)["is_taiwan:post"], 4),
    "(", round(se(m_share)["is_taiwan:post"], 4), ")\n")

# ── 5. MDE ─────────────────────────────────────────────────────────────────
cat("\n5. Power\n")
m1 <- feols(ln_patents ~ treated_class:post | uspc_mainclass + year_id,
            data = tw, cluster = ~uspc_mainclass)
se_main <- se(m1)["treated_class:post"]
mde <- 1.96 * se_main + 0.84 * se_main
sd_y <- tw[post == 0, sd(ln_patents)]
cat(sprintf("  SE=%.4f, MDE(5%%,80%%)=%.4f, SDE=%.4f, SD(Y)=%.4f\n",
            se_main, mde, mde/sd_y, sd_y))

# Save
rob <- list(
  placebo = list(coef = coef(m_plac)["treated_class:placebo_post"],
                 se = se(m_plac)["treated_class:placebo_post"]),
  semi = list(coef = coef(m_semi)["semi:post"], se = se(m_semi)["semi:post"]),
  opto = list(coef = coef(m_opto)["opto:post"], se = se(m_opto)["opto:post"]),
  share = list(coef = coef(m_share)["is_taiwan:post"], se = se(m_share)["is_taiwan:post"]),
  mde = list(mde = mde, sde = mde/sd_y, sd_y = sd_y)
)
saveRDS(rob, "../data/robustness_results.rds")
cat("\nDone.\n")
