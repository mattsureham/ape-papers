# 03_main_analysis.R — Main DiD analysis
# apep_0849: Taiwan IIA R&D Tax Credit Transition

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")
tw <- fread("../data/tw_panel.csv")

cat("=== MAIN ANALYSIS ===\n")
cat("Taiwan obs:", nrow(tw), "| Full panel:", nrow(panel), "\n\n")

# Core SUI sectors for heterogeneity
semi_classes <- c("257", "438")
opto_classes <- c("345", "349", "362", "359", "385", "348", "315")
comm_classes <- c("455", "375", "370", "343")

# ── Main DiD (Taiwan) ─────────────────────────────────────────────────────
m1 <- feols(ln_patents ~ treated_class:post | uspc_mainclass + year_id,
            data = tw, cluster = ~uspc_mainclass)

m2 <- feols(ln_patents ~ treated_class:post + log(mean_claims + 1) | uspc_mainclass + year_id,
            data = tw, cluster = ~uspc_mainclass)

m3 <- fepois(n_patents ~ treated_class:post | uspc_mainclass + year_id,
             data = tw, cluster = ~uspc_mainclass)

m4 <- feols(mean_claims ~ treated_class:post | uspc_mainclass + year_id,
            data = tw, cluster = ~uspc_mainclass)

m5 <- feols(mean_citations ~ treated_class:post | uspc_mainclass + year_id,
            data = tw, cluster = ~uspc_mainclass)

cat("Main results:\n")
etable(m1, m2, m3, m4, m5,
       headers = c("ln(Pat)", "ln(Pat)+C", "Poisson", "Claims", "Cites"),
       se.below = TRUE)

# ── Placebo (Israel, Korea) ───────────────────────────────────────────────
il <- panel[assignee_country == "IL"]
kr <- panel[assignee_country == "KR"]

m_il <- feols(ln_patents ~ treated_class:post | uspc_mainclass + year_id,
              data = il, cluster = ~uspc_mainclass)
m_kr <- feols(ln_patents ~ treated_class:post | uspc_mainclass + year_id,
              data = kr, cluster = ~uspc_mainclass)

# DDD
panel[, is_taiwan := ifelse(assignee_country == "TW", 1L, 0L)]
m_ddd <- feols(ln_patents ~ is_taiwan:treated_class:post |
                 assignee_country^uspc_mainclass + assignee_country^year_id +
                 uspc_mainclass^year_id,
               data = panel, cluster = ~assignee_country^uspc_mainclass)

cat("\nPlacebo:\n")
etable(m1, m_il, m_kr, m_ddd,
       headers = c("Taiwan", "Israel", "Korea", "DDD"),
       se.below = TRUE)

# ── Event study ───────────────────────────────────────────────────────────
tw[, rel_year := filing_year - 2010]
m_es <- feols(ln_patents ~ i(rel_year, treated_class, ref = -1) | uspc_mainclass + year_id,
              data = tw, cluster = ~uspc_mainclass)
cat("\nEvent study:\n")
print(coeftable(m_es))
saveRDS(m_es, "../data/event_study_model.rds")

# ── Save ──────────────────────────────────────────────────────────────────
results <- list(
  main = list(coef = coef(m1)["treated_class:post"], se = se(m1)["treated_class:post"],
              pval = pvalue(m1)["treated_class:post"]),
  poisson = list(coef = coef(m3)["treated_class:post"], se = se(m3)["treated_class:post"]),
  claims = list(coef = coef(m4)["treated_class:post"], se = se(m4)["treated_class:post"]),
  cites = list(coef = coef(m5)["treated_class:post"], se = se(m5)["treated_class:post"]),
  il = list(coef = coef(m_il)["treated_class:post"], se = se(m_il)["treated_class:post"]),
  kr = list(coef = coef(m_kr)["treated_class:post"], se = se(m_kr)["treated_class:post"]),
  ddd = list(coef = coef(m_ddd)["is_taiwan:treated_class:post"],
             se = se(m_ddd)["is_taiwan:treated_class:post"])
)
saveRDS(results, "../data/main_results.rds")

diagnostics <- list(
  n_treated = tw[treated_class == 1, uniqueN(uspc_mainclass)],
  n_pre = tw[post == 0, uniqueN(filing_year)],
  n_obs = nrow(tw)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics:", toJSON(diagnostics, auto_unbox = TRUE), "\n")
