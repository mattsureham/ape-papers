## 04_robustness.R — Robustness checks
## apep_1154: EU Transposition Delay and Firm Entry

source("00_packages.R")

cat("\n=== Robustness Checks ===\n")

df <- readRDS("../data/analysis_df.rds")
results <- readRDS("../data/results.rds")

# ---- 4a. Placebo: sectors not targeted by directives in limbo ----
# Within a country-year, compare sectors WITH directives in limbo vs sectors WITHOUT
# If we see effects in non-targeted sectors, it's a country-wide shock not limbo-specific
cat("\n--- Placebo: non-targeted sectors ---\n")

# Identify country-years where at least one sector is in limbo
limbo_cy <- df %>%
  group_by(country2, year) %>%
  summarise(has_limbo = max(any_limbo), .groups = "drop") %>%
  filter(has_limbo == 1)

# Sectors that are NEVER in limbo in that country-year are placebos
df_placebo <- df %>%
  semi_join(limbo_cy, by = c("country2", "year")) %>%
  filter(any_limbo == 0)  # Only non-limbo sectors in limbo-active country-years

# Create a placebo treatment: country is experiencing limbo in OTHER sectors
df_placebo <- df_placebo %>%
  left_join(
    df %>%
      group_by(country2, year) %>%
      summarise(country_limbo_count = sum(n_limbo), .groups = "drop"),
    by = c("country2", "year")
  ) %>%
  mutate(placebo_treat = as.integer(country_limbo_count > 0))

if (n_distinct(df_placebo$placebo_treat) > 1 && nrow(df_placebo) > 50) {
  m_placebo <- feols(
    log_births ~ placebo_treat | cs_id + year,
    data = df_placebo,
    cluster = ~country2
  )
  cat("Placebo coefficient:", round(coef(m_placebo)["placebo_treat"], 4),
      "SE:", round(se(m_placebo)["placebo_treat"], 4), "\n")
  cat("Placebo p-value:", round(pvalue(m_placebo)["placebo_treat"], 4), "\n")
} else {
  cat("Insufficient variation for placebo test.\n")
  m_placebo <- NULL
}

# ---- 4b. Drop chronically late transposers ----
cat("\n--- Drop chronic late transposers (IT, FR, ES, DE) ---\n")
chronic_late <- c("IT", "FR", "ES", "DE")
df_no_chronic <- df %>% filter(!(country2 %in% chronic_late))

m_no_chronic <- feols(
  log_births ~ any_limbo | cs_id + year,
  data = df_no_chronic,
  cluster = ~country2
)
cat("Coefficient:", round(coef(m_no_chronic)["any_limbo"], 4),
    "SE:", round(se(m_no_chronic)["any_limbo"], 4), "\n")
cat("N countries:", n_distinct(df_no_chronic$country2), "\n")

# ---- 4c. Callaway-Sant'Anna (if feasible) ----
cat("\n--- Callaway-Sant'Anna ---\n")

# Need: balanced panel with id, time, first_treat, outcome
first_limbo <- df %>%
  filter(any_limbo == 1) %>%
  group_by(cs_id) %>%
  summarise(first_limbo_year = min(year), .groups = "drop")

df_cs <- df %>%
  left_join(first_limbo, by = "cs_id") %>%
  mutate(
    first_treat = ifelse(is.na(first_limbo_year), 0, first_limbo_year),
    unit_id = as.integer(factor(cs_id))
  ) %>%
  filter(!is.na(log_births))

cs_result <- tryCatch({
  att_gt(
    yname = "log_births",
    tname = "year",
    idname = "unit_id",
    gname = "first_treat",
    data = as.data.frame(df_cs),
    control_group = "nevertreated",
    base_period = "universal"
  )
}, error = function(e) {
  cat("C-S error:", e$message, "\n")
  NULL
})

if (!is.null(cs_result)) {
  cs_agg <- aggte(cs_result, type = "simple")
  cat("C-S ATT:", round(cs_agg$overall.att, 4),
      "SE:", round(cs_agg$overall.se, 4), "\n")

  cs_es <- aggte(cs_result, type = "dynamic")
  cat("C-S event study computed.\n")
} else {
  cs_agg <- NULL
  cs_es <- NULL
}

# ---- 4d. Leave-one-country-out ----
cat("\n--- Leave-one-country-out ---\n")
countries <- unique(df$country2)
loo_results <- map_dfr(countries, function(c) {
  df_loo <- df %>% filter(country2 != c)
  m_loo <- feols(
    log_births ~ any_limbo | cs_id + year,
    data = df_loo,
    cluster = ~country2
  )
  tibble(
    dropped = c,
    coef = coef(m_loo)["any_limbo"],
    se = se(m_loo)["any_limbo"]
  )
})

cat("LOO coefficient range: [",
    round(min(loo_results$coef), 4), ",",
    round(max(loo_results$coef), 4), "]\n")
cat("Most influential country when dropped:",
    loo_results$dropped[which.max(abs(loo_results$coef - coef(results$m1)["any_limbo"]))], "\n")

# ---- 4e. Alternative outcome: birth rate in levels ----
cat("\n--- Birth rate (levels) with wild bootstrap ---\n")
m_levels <- results$m4

boot_levels <- tryCatch({
  boottest(m_levels, param = "any_limbo", B = 9999, type = "webb", clustid = "country2")
}, error = function(e) {
  cat("Bootstrap error:", e$message, "\n")
  NULL
})

if (!is.null(boot_levels)) {
  cat("Bootstrap p-value (levels):", round(boot_levels$p_val, 4), "\n")
}

# ---- 4f. Heterogeneity: regulatory vs non-regulatory sectors ----
cat("\n--- Heterogeneity by sector type ---\n")
# Define regulatory-intensive sectors
reg_sectors <- c("K", "D", "Q", "H")  # Finance, Energy, Health, Transport
df <- df %>%
  mutate(reg_intensive = as.integer(nace_section %in% reg_sectors))

m_het <- feols(
  log_births ~ any_limbo + any_limbo:reg_intensive | cs_id + year,
  data = df,
  cluster = ~country2
)
cat("Base effect:", round(coef(m_het)["any_limbo"], 4), "\n")
cat("Additional effect in regulated sectors:",
    round(coef(m_het)["any_limbo:reg_intensive"], 4), "\n")

# ---- Save robustness results ----
rob_results <- list(
  m_placebo = m_placebo,
  m_no_chronic = m_no_chronic,
  cs_result = cs_result,
  cs_agg = cs_agg,
  cs_es = cs_es,
  loo_results = loo_results,
  boot_levels = boot_levels,
  m_het = m_het
)

saveRDS(rob_results, "../data/rob_results.rds")
cat("\n=== Robustness results saved ===\n")
