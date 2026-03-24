## 03_main_analysis.R — Main DiD regressions and event study
## apep_0851: Abolishing the Tax Haven Next Door

library(fixest)
library(dplyr)
source("00_packages.R")

df <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)
cat("Loaded", nrow(df), "observations from", length(unique(df$country)), "countries\n")

# -----------------------------------------------------------------------
# 1. Simple DiD: Portugal vs Controls, pre vs post announcement
# -----------------------------------------------------------------------
cat("\n=== TWFE DiD: log HPI ===\n")

# Baseline: country + quarter FE
m1 <- feols(log_hpi ~ treated:post_announce | country + yq, data = df,
            cluster = ~country)

# With post_effective instead (Jan 2024 cutoff)
m2 <- feols(log_hpi ~ treated:post_effective | country + yq, data = df,
            cluster = ~country)

# Normalized HPI
m3 <- feols(log_hpi_norm ~ treated:post_announce | country + yq, data = df,
            cluster = ~country)

etable(m1, m2, m3,
       headers = c("Post-Announce", "Post-Effective", "Normalized"),
       se.below = TRUE)

# -----------------------------------------------------------------------
# 2. Event study: quarterly leads and lags
# -----------------------------------------------------------------------
cat("\n=== Event Study ===\n")

# Bin extreme endpoints; omit t = -1 (2023Q2) as reference
df <- df %>%
  mutate(
    et_binned = case_when(
      event_time <= -12 ~ -12L,
      event_time >= 8   ~ 8L,
      TRUE ~ event_time
    ),
    et_binned = as.integer(et_binned)
  )

# Event study with country and calendar-quarter FE
es_model <- feols(log_hpi ~ i(et_binned, treated, ref = -1) | country + yq,
                  data = df, cluster = ~country)

cat("Event study coefficients:\n")
print(summary(es_model))

# Save event study coefficients for table
es_coefs <- as.data.frame(coeftable(es_model))
es_coefs$term <- rownames(es_coefs)

# -----------------------------------------------------------------------
# 3. Heterogeneity: Compare Portugal to "similar" Southern European peers only
# -----------------------------------------------------------------------
cat("\n=== Southern Europe subsample ===\n")
south <- c("PT", "ES", "IT", "EL", "CY", "MT")
df_south <- df %>% filter(country %in% south)

m_south <- feols(log_hpi ~ treated:post_announce | country + yq,
                 data = df_south, cluster = ~country)

# Nordic/Western comparison
north <- c("PT", "NL", "IE", "BE", "FI", "AT", "DE", "FR", "LU")
df_north <- df %>% filter(country %in% north)

m_north <- feols(log_hpi ~ treated:post_announce | country + yq,
                 data = df_north, cluster = ~country)

etable(m1, m_south, m_north,
       headers = c("Full Sample", "Southern EU", "Northern/Western EU"),
       se.below = TRUE)

# -----------------------------------------------------------------------
# 4. Save key results
# -----------------------------------------------------------------------
results <- list(
  main_coef = coef(m1)["treated:post_announce"],
  main_se = se(m1)["treated:post_announce"],
  main_n = nobs(m1),
  n_countries = length(unique(df$country)),
  n_quarters = length(unique(df$yq)),
  n_portugal = sum(df$treated),
  south_coef = coef(m_south)["treated:post_announce"],
  south_se = se(m_south)["treated:post_announce"],
  north_coef = coef(m_north)["treated:post_announce"],
  north_se = se(m_north)["treated:post_announce"],
  effective_coef = coef(m2)["treated:post_effective"],
  effective_se = se(m2)["treated:post_effective"]
)

write_json(results, "../data/main_results.json", auto_unbox = TRUE, pretty = TRUE)

# Diagnostics for validator
diagnostics <- list(
  n_treated = 1,  # Portugal
  n_pre = length(unique(df$yq[df$yq < 2023.5])),
  n_obs = nrow(df)
)
write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

# Save model objects for table generation
save(m1, m2, m3, m_south, m_north, es_model, df,
     file = "../data/models.RData")

cat("\n=== Main analysis complete ===\n")
cat("Main DiD coefficient (log HPI, post-announce):", round(results$main_coef, 4),
    "SE:", round(results$main_se, 4), "\n")
