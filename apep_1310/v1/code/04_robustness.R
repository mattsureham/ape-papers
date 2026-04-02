# 04_robustness.R — Robustness and falsification tests
# APEP-1310: The Compression Shock

source("00_packages.R")

results <- readRDS("../data/results.rds")
panel <- results$panel

# ── 1. Placebo test: 2016 MW hike (+24%, 325→380 EUR) ──────────
# Pretend the shock happened in 2016 instead of 2019
# Restrict to 2013-2018 (pre-actual-treatment only)
panel_placebo <- panel %>%
  filter(year <= 2018) %>%
  mutate(
    post_placebo = as.integer(year >= 2016),
    treat_placebo = lt * post_placebo * kaitz_2018
  )

m_placebo_2016 <- feols(
  ln_emp ~ treat_placebo | cs_f + cy_f,
  data = panel_placebo,
  cluster = ~ cs_f
)
cat("=== Placebo: 2016 MW Hike ===\n")
summary(m_placebo_2016)

# ── 2. Placebo test: 2013 base year (no MW hike) ──────────────
panel_placebo2 <- panel %>%
  filter(year <= 2018) %>%
  mutate(
    post_placebo2 = as.integer(year >= 2014),
    treat_placebo2 = lt * post_placebo2 * kaitz_2018
  )

m_placebo_2014 <- feols(
  ln_emp ~ treat_placebo2 | cs_f + cy_f,
  data = panel_placebo2,
  cluster = ~ cs_f
)
cat("\n=== Placebo: 2014 (No MW Hike) ===\n")
summary(m_placebo_2014)

# ── 3. Leave-one-sector-out ────────────────────────────────────
sectors <- unique(panel$sector)
loso_results <- data.frame(
  dropped = character(),
  beta = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

for (s in sectors) {
  m_loso <- feols(
    ln_emp ~ treat_intensity | cs_f + cy_f,
    data = filter(panel, sector != s),
    cluster = ~ cs_f
  )
  loso_results <- rbind(loso_results, data.frame(
    dropped = s,
    beta = coef(m_loso)["treat_intensity"],
    se = se(m_loso)["treat_intensity"],
    stringsAsFactors = FALSE
  ))
}
cat("\n=== Leave-One-Sector-Out ===\n")
print(loso_results)

# ── 4. Leave-one-country-out ──────────────────────────────────
# LT vs LV only
m_lt_lv <- feols(
  ln_emp ~ treat_intensity | cs_f + cy_f,
  data = filter(panel, country != "EST"),
  cluster = ~ cs_f
)
cat("\n=== LT vs LV only ===\n")
summary(m_lt_lv)

# LT vs EE only
m_lt_ee <- feols(
  ln_emp ~ treat_intensity | cs_f + cy_f,
  data = filter(panel, country != "LVA"),
  cluster = ~ cs_f
)
cat("\n=== LT vs EE only ===\n")
summary(m_lt_ee)

# ── 5. Country-level clustering ────────────────────────────────
cat("\n=== Country-Level Clustering ===\n")
m_country_cluster <- feols(
  ln_emp ~ treat_intensity | cs_f + cy_f,
  data = panel,
  cluster = ~ country
)
summary(m_country_cluster)

# ── 6. Permutation inference over sectors ──────────────────────
cat("\n=== Sector Permutation Inference ===\n")
set.seed(42)
actual_beta <- coef(results$main_continuous)["treat_intensity"]

n_perms <- 1000
perm_betas <- numeric(n_perms)

for (i in 1:n_perms) {
  # Randomly permute Kaitz across sectors within Lithuania
  perm_panel <- panel
  kaitz_vals <- unique(panel$kaitz_2018)
  perm_kaitz <- sample(kaitz_vals)
  names(perm_kaitz) <- unique(panel$sector)
  perm_panel$kaitz_perm <- perm_kaitz[perm_panel$sector]
  perm_panel$treat_perm <- perm_panel$lt * perm_panel$post2019 * perm_panel$kaitz_perm

  m_perm <- tryCatch(
    feols(ln_emp ~ treat_perm | cs_f + cy_f, data = perm_panel, cluster = ~ cs_f),
    error = function(e) NULL
  )
  if (!is.null(m_perm)) {
    perm_betas[i] <- coef(m_perm)["treat_perm"]
  } else {
    perm_betas[i] <- NA
  }
}

perm_betas <- perm_betas[!is.na(perm_betas)]
perm_pvalue <- mean(abs(perm_betas) >= abs(actual_beta))
cat("Actual beta:", actual_beta, "\n")
cat("Permutation p-value (two-sided):", perm_pvalue, "\n")
cat("Permutation distribution: mean =", mean(perm_betas),
    ", sd =", sd(perm_betas), "\n")

# ── 7. Wage outcome (check wage compression) ──────────────────
cat("\n=== Wage Compression Check ===\n")
panel$ln_wage <- log(panel$mean_wage)
panel$treat_wage <- panel$lt * panel$post2019 * panel$kaitz_2018

m_wage <- feols(
  ln_wage ~ treat_wage | cs_f + cy_f,
  data = panel,
  cluster = ~ cs_f
)
summary(m_wage)

# ── Save robustness results ───────────────────────────────────
robustness <- list(
  placebo_2016 = m_placebo_2016,
  placebo_2014 = m_placebo_2014,
  loso = loso_results,
  lt_lv = m_lt_lv,
  lt_ee = m_lt_ee,
  perm_pvalue = perm_pvalue,
  perm_betas = perm_betas,
  actual_beta = actual_beta,
  wage_compression = m_wage
)
saveRDS(robustness, "../data/robustness.rds")
cat("\nRobustness results saved.\n")
