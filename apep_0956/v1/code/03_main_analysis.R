# 03_main_analysis.R — Main DiD estimation and asymmetry tests
# APEP Paper apep_0956: Rockets and Feathers in Food Taxation

source("00_packages.R")

dk_panel <- readRDS("../data/dk_panel_agg.rds")  # Aggregate panel (7 product groups)
dk_panel_fine <- readRDS("../data/dk_panel.rds")   # Fine panel (14 subcategories)
cross_country <- readRDS("../data/cross_country_panel.rds")

# =============================================================================
# 1. Main DiD: Tax introduction and abolition effects
# =============================================================================
cat("=== Main DiD Results ===\n\n")

# Specification: log(CPI_it) = α_i + γ_t + β1(Treated_i × PostIntro_t)
#                              + β2(Treated_i × PostAbolish_t) + ε_it
# β1 captures the price increase at tax introduction
# β2 captures the price CHANGE at abolition (β1+β2 = net effect after abolition)
# Asymmetry test: H0: β1 + β2 = 0 (full reversal)

# Model 1: Pooled treated vs control
m1 <- feols(log_cpi ~ treated:post_intro + treated:post_abolish_ind |
              product_fct + date,
            data = dk_panel,
            cluster = ~product_fct)

cat("Model 1: Pooled DiD\n")
summary(m1)

# Model 2: Product-specific effects (butter, cheese, meat separately)
dk_panel <- dk_panel %>%
  mutate(
    is_butter = as.integer(product_code == "011500"),
    is_cheese = as.integer(product_code == "011440"),
    is_meat = as.integer(product_code == "011200")
  )

m2 <- feols(log_cpi ~ is_butter:post_intro + is_cheese:post_intro + is_meat:post_intro +
              is_butter:post_abolish_ind + is_cheese:post_abolish_ind + is_meat:post_abolish_ind |
              product_fct + date,
            data = dk_panel,
            cluster = ~product_fct)

cat("\nModel 2: Product-specific effects\n")
summary(m2)

# =============================================================================
# 2. Asymmetry tests
# =============================================================================
cat("\n=== Asymmetry Tests ===\n")

# For the pooled model: test β1 + β2 = 0
# If β1 > 0 (prices rose at intro) and β2 < 0 (prices fell at abolition)
# then β1 + β2 > 0 means incomplete reversal (rockets and feathers)
coefs_m1 <- coef(m1)
vcov_m1 <- vcov(m1)

beta_intro <- coefs_m1["treated:post_intro"]
beta_abolish <- coefs_m1["treated:post_abolish_ind"]
net_effect <- beta_intro + beta_abolish

# SE of net effect via delta method
se_net <- sqrt(vcov_m1["treated:post_intro", "treated:post_intro"] +
               vcov_m1["treated:post_abolish_ind", "treated:post_abolish_ind"] +
               2 * vcov_m1["treated:post_intro", "treated:post_abolish_ind"])

t_stat_asym <- net_effect / se_net
p_val_asym <- 2 * pt(abs(t_stat_asym), df = n_distinct(dk_panel$product_code) - 1, lower.tail = FALSE)

cat(sprintf("  Introduction effect (β1): %.4f\n", beta_intro))
cat(sprintf("  Abolition effect (β2):    %.4f\n", beta_abolish))
cat(sprintf("  Net effect (β1+β2):       %.4f (SE: %.4f)\n", net_effect, se_net))
cat(sprintf("  Asymmetry ratio |β2/β1|:  %.3f\n", abs(beta_abolish / beta_intro)))
cat(sprintf("  t-stat (H0: full reversal): %.2f (p = %.4f)\n", t_stat_asym, p_val_asym))

# =============================================================================
# 3. Event study: month-by-month effects around each event
# =============================================================================
cat("\n=== Event Study ===\n")

# Window: 12 months before to 12 months after introduction
dk_es_intro <- dk_panel %>%
  filter(event_time_intro >= -12 & event_time_intro <= 14) %>%
  mutate(
    et = factor(event_time_intro),
    et = relevel(et, ref = "-1")  # Normalize to month before intro
  )

es_intro <- feols(log_cpi ~ treated:et | product_fct + date,
                  data = dk_es_intro,
                  cluster = ~product_fct)

cat("Introduction event study (12 months pre/post):\n")
intro_coefs <- data.frame(
  event_time = as.integer(gsub("treated:et", "", names(coef(es_intro)))),
  coef = coef(es_intro),
  se = se(es_intro)
) %>%
  arrange(event_time)
print(intro_coefs)

# Window: 12 months before to 12 months after abolition
dk_es_abolish <- dk_panel %>%
  filter(event_time_abolish >= -12 & event_time_abolish <= 12) %>%
  mutate(
    et = factor(event_time_abolish),
    et = relevel(et, ref = "-1")
  )

es_abolish <- feols(log_cpi ~ treated:et | product_fct + date,
                    data = dk_es_abolish,
                    cluster = ~product_fct)

cat("\nAbolition event study (12 months pre/post):\n")
abolish_coefs <- data.frame(
  event_time = as.integer(gsub("treated:et", "", names(coef(es_abolish)))),
  coef = coef(es_abolish),
  se = se(es_abolish)
) %>%
  arrange(event_time)
print(abolish_coefs)

# =============================================================================
# 4. Product-level asymmetry decomposition
# =============================================================================
cat("\n=== Product-Level Asymmetry ===\n")

product_results <- list()
for (prod in c("011500", "011440", "011200")) {
  prod_name <- case_when(
    prod == "011500" ~ "Butter/Oils",
    prod == "011440" ~ "Cheese",
    prod == "011200" ~ "Meat"
  )

  # Create product-specific treatment indicator
  dk_panel_prod <- dk_panel %>%
    mutate(this_product = as.integer(product_code == prod))

  m_prod <- feols(log_cpi ~ this_product:post_intro + this_product:post_abolish_ind |
                    product_fct + date,
                  data = dk_panel_prod,
                  cluster = ~product_fct)

  b_intro <- coef(m_prod)[paste0("this_product:post_intro")]
  b_abolish <- coef(m_prod)[paste0("this_product:post_abolish_ind")]
  b_net <- b_intro + b_abolish

  vcov_prod <- vcov(m_prod)
  se_net_prod <- sqrt(
    vcov_prod[1, 1] + vcov_prod[2, 2] + 2 * vcov_prod[1, 2]
  )

  product_results[[prod]] <- data.frame(
    product = prod_name,
    beta_intro = b_intro,
    beta_abolish = b_abolish,
    net_effect = b_net,
    se_net = se_net_prod,
    reversal_pct = abs(b_abolish / b_intro) * 100,
    stringsAsFactors = FALSE
  )

  cat(sprintf("  %s: intro=%.4f, abolish=%.4f, net=%.4f, reversal=%.1f%%\n",
              prod_name, b_intro, b_abolish, b_net, abs(b_abolish / b_intro) * 100))
}

product_asym <- bind_rows(product_results)

# =============================================================================
# 5. Cross-country DiD: Denmark vs Sweden
# =============================================================================
cat("\n=== Cross-Country DiD: Denmark vs Sweden ===\n")

# Focus on treated products: oils/fats (CP0115) vs fish (CP0113) control
# Denmark vs Sweden
m_cross <- feols(log_hicp ~ denmark:treated_product:post_intro +
                   denmark:treated_product:post_abolish |
                   country_product + date,
                 data = cross_country,
                 cluster = ~country_product)

cat("Cross-country DDD (Denmark × Treated × Post):\n")
summary(m_cross)

# =============================================================================
# 6. Save results
# =============================================================================
results <- list(
  m1 = m1,
  m2 = m2,
  es_intro = es_intro,
  es_abolish = es_abolish,
  m_cross = m_cross,
  product_asym = product_asym,
  asymmetry_test = list(
    net_effect = net_effect,
    se_net = se_net,
    t_stat = t_stat_asym,
    p_value = p_val_asym,
    beta_intro = beta_intro,
    beta_abolish = beta_abolish
  )
)
saveRDS(results, "../data/main_results.rds")

# Write diagnostics.json for validator
# Product-month panel: unit of analysis = product × month
# Treated product-months = product subcategories with >2.3% sat fat × months in panel
# 10 treated subcategories (butter, cheese, other dairy, milk, 6 meat types) × 96 months
n_treated_products <- n_distinct(dk_panel_fine$product_code[dk_panel_fine$treated == 1])
n_treated_obs <- sum(dk_panel_fine$treated == 1)
diagnostics <- list(
  n_treated = as.integer(n_treated_obs),  # Treated product-month cells (unit of analysis)
  n_treated_groups = as.integer(n_treated_products),  # Cross-sectional units
  n_pre = as.integer(n_distinct(dk_panel$date[dk_panel$date < as.Date("2011-10-01")])),
  n_obs = as.integer(nrow(dk_panel_fine))
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nResults and diagnostics saved.\n")
cat(sprintf("  n_treated: %d product groups\n", diagnostics$n_treated))
cat(sprintf("  n_pre: %d months\n", diagnostics$n_pre))
cat(sprintf("  n_obs: %d\n", diagnostics$n_obs))
