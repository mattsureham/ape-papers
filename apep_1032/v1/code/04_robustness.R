## 04_robustness.R — Robustness checks and placebo tests
## APEP-1032: The Deterrence Gap

source("00_packages.R")

analysis <- readRDS("../data/fdic_analysis.rds")
placebo_data <- readRDS("../data/fdic_placebo.rds")

cat("Analysis sample:", nrow(analysis), "obs\n")
cat("Placebo sample:", nrow(placebo_data), "obs\n")

# ═══════════════════════════════════════════════════════════════════════════════
# 1. PLACEBO: Banks $500M–$1B (already had 18-month cycles) vs control
# ═══════════════════════════════════════════════════════════════════════════════

# These banks were already eligible for 18-month cycles before EGRRCPA
# So they should show NO effect — a mechanism-matched placebo

m_placebo <- feols(ncl_ratio ~ treat_post | CERT + time_q,
                   data = placebo_data, cluster = ~CERT)

cat("\n=== Placebo: $500M–$1B vs $3B–$10B ===\n")
summary(m_placebo)

# ═══════════════════════════════════════════════════════════════════════════════
# 2. DONUT HOLE: Exclude banks near thresholds ($900M–$1.1B and $2.7B–$3.3B)
# ═══════════════════════════════════════════════════════════════════════════════

donut <- analysis %>%
  filter(!(ASSET_PRE >= 900000 & ASSET_PRE < 1100000)) %>%
  filter(!(ASSET_PRE >= 2700000 & ASSET_PRE < 3300000))

m_donut <- feols(ncl_ratio ~ treat_post | CERT + time_q,
                 data = donut, cluster = ~CERT)

cat("\n=== Donut Hole (exclude near-threshold banks) ===\n")
cat("  Banks dropped:", n_distinct(analysis$CERT) - n_distinct(donut$CERT), "\n")
summary(m_donut)

# ═══════════════════════════════════════════════════════════════════════════════
# 3. PRE-COVID WINDOW: End sample at 2019Q4
# ═══════════════════════════════════════════════════════════════════════════════

pre_covid <- analysis %>% filter(year <= 2019)

m_precovid <- feols(ncl_ratio ~ treat_post | CERT + time_q,
                    data = pre_covid, cluster = ~CERT)

cat("\n=== Pre-COVID (2016Q1–2019Q4) ===\n")
summary(m_precovid)

# ═══════════════════════════════════════════════════════════════════════════════
# 4. EXCLUDING COVID PERIOD: Drop 2020Q1–2021Q4
# ═══════════════════════════════════════════════════════════════════════════════

no_covid <- analysis %>% filter(year < 2020 | year > 2021)

m_nocovid <- feols(ncl_ratio ~ treat_post | CERT + time_q,
                   data = no_covid, cluster = ~CERT)

cat("\n=== Excluding COVID (drop 2020–2021) ===\n")
summary(m_nocovid)

# ═══════════════════════════════════════════════════════════════════════════════
# 5. ALTERNATIVE CLUSTERING: State-level
# ═══════════════════════════════════════════════════════════════════════════════

# We need state info — use the SC (state code) field
if ("SC" %in% names(analysis) && !all(is.na(analysis$SC))) {
  m_state <- feols(ncl_ratio ~ treat_post | CERT + time_q,
                   data = analysis, cluster = ~SC)
  cat("\n=== State-clustered SEs ===\n")
  summary(m_state)
} else {
  cat("\nState code not available — skipping state clustering\n")
  m_state <- NULL
}

# ═══════════════════════════════════════════════════════════════════════════════
# 6. TRIPLE DIFFERENCE: CRE vs consumer loans within bank
# ═══════════════════════════════════════════════════════════════════════════════

# If deterrence gap operates through risk-shifting, we expect effects
# to be larger for riskier loan categories (CRE) vs safer ones (consumer)

# Create long-format loan composition panel
loan_panel <- analysis %>%
  select(CERT, time_q, treat, post, treat_post, LNLSGR, LNRE, LNCON) %>%
  filter(!is.na(LNLSGR) & LNLSGR > 0) %>%
  pivot_longer(
    cols = c(LNRE, LNCON),
    names_to = "loan_type",
    values_to = "amount"
  ) %>%
  mutate(
    share = amount / LNLSGR * 100,
    risky = as.integer(loan_type == "LNRE"),
    treat_post_risky = treat_post * risky
  )

m_triple <- feols(share ~ treat_post + treat_post_risky | CERT^loan_type + time_q^loan_type,
                  data = loan_panel, cluster = ~CERT)

cat("\n=== Triple Diff: CRE vs Consumer Loans ===\n")
summary(m_triple)

# ═══════════════════════════════════════════════════════════════════════════════
# 7. SAVE ALL ROBUSTNESS MODELS
# ═══════════════════════════════════════════════════════════════════════════════

rob_models <- list(
  placebo = m_placebo,
  donut = m_donut,
  precovid = m_precovid,
  nocovid = m_nocovid,
  state_cluster = m_state,
  triple_diff = m_triple
)
saveRDS(rob_models, "../data/models_robustness.rds")

cat("\n✓ Robustness checks complete.\n")
