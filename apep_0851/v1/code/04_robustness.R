## 04_robustness.R — Robustness checks
## apep_0851: Abolishing the Tax Haven Next Door

source("00_packages.R")

df <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)
load("../data/models.RData")

cat("=== Robustness Checks ===\n")

# -----------------------------------------------------------------------
# 1. Leave-one-out: drop each control country and re-estimate
# -----------------------------------------------------------------------
cat("\n--- Leave-one-out ---\n")
controls <- unique(df$country[df$treated == 0])

loo_results <- map_dfr(controls, function(cc) {
  df_loo <- df %>% filter(country != cc)
  m_loo <- feols(log_hpi ~ treated:post_announce | country + yq,
                 data = df_loo, cluster = ~country)
  tibble(
    dropped = cc,
    coef = coef(m_loo)["treated:post_announce"],
    se = se(m_loo)["treated:post_announce"],
    n = nobs(m_loo)
  )
})

print(loo_results, n = 20)
cat("  LOO range:", round(min(loo_results$coef), 4), "to",
    round(max(loo_results$coef), 4), "\n")

# -----------------------------------------------------------------------
# 2. Placebo test: earlier announcement dates
# -----------------------------------------------------------------------
cat("\n--- Placebo: fake announcement at 2021Q3, 2020Q3 ---\n")

df_pre <- df %>% filter(yq < 2023.5)  # only pre-announcement data

# Placebo 1: 2021Q3
df_pre <- df_pre %>% mutate(placebo_2021 = as.integer(yq >= 2021.5))
m_p1 <- feols(log_hpi ~ treated:placebo_2021 | country + yq,
              data = df_pre, cluster = ~country)

# Placebo 2: 2020Q3
df_pre <- df_pre %>% mutate(placebo_2020 = as.integer(yq >= 2020.5))
m_p2 <- feols(log_hpi ~ treated:placebo_2020 | country + yq,
              data = df_pre, cluster = ~country)

etable(m_p1, m_p2, headers = c("Placebo 2021Q3", "Placebo 2020Q3"))

# -----------------------------------------------------------------------
# 3. Alternative control groups
# -----------------------------------------------------------------------
cat("\n--- Alternative controls ---\n")

# Only Iberian + immediate neighbors
iberian <- c("PT", "ES", "FR", "IT")
m_iber <- feols(log_hpi ~ treated:post_announce | country + yq,
                data = df %>% filter(country %in% iberian), cluster = ~country)

# Only countries with similar pre-trend growth (within 10pp of Portugal)
pre_growth <- df %>%
  filter(yq < 2023.5) %>%
  group_by(country) %>%
  summarize(growth = (last(hpi) - first(hpi)) / first(hpi) * 100, .groups = "drop")

pt_growth <- pre_growth$growth[pre_growth$country == "PT"]
similar <- pre_growth %>%
  filter(abs(growth - pt_growth) < 20 | country == "PT") %>%
  pull(country)

cat("  Similar-growth countries:", paste(similar, collapse = ", "), "\n")

if (length(similar) >= 3) {
  m_similar <- feols(log_hpi ~ treated:post_announce | country + yq,
                     data = df %>% filter(country %in% similar), cluster = ~country)
} else {
  m_similar <- m_iber  # fallback
  cat("  Too few similar-growth countries, using Iberian sample\n")
}

etable(m1, m_iber, m_similar,
       headers = c("Full", "Iberian+", "Similar Growth"))

# -----------------------------------------------------------------------
# 4. Country-specific linear trends
# -----------------------------------------------------------------------
cat("\n--- Country-specific trends ---\n")
# Create numeric time trend
df <- df %>% mutate(time_trend = as.numeric(yq - min(yq)))

m_trends <- feols(log_hpi ~ treated:post_announce + i(country, time_trend) | country + yq,
                  data = df, cluster = ~country)

cat("  With country trends:", round(coef(m_trends)["treated:post_announce"], 4), "\n")

# -----------------------------------------------------------------------
# 5. Different post-period definitions
# -----------------------------------------------------------------------
cat("\n--- Alternative timing ---\n")

# Only immediate post (2023Q3-2024Q2)
df_short <- df %>% filter(yq <= 2024.25)
m_short <- feols(log_hpi ~ treated:post_announce | country + yq,
                 data = df_short, cluster = ~country)

cat("  Short window:", round(coef(m_short)["treated:post_announce"], 4), "\n")

# -----------------------------------------------------------------------
# 6. Save robustness results
# -----------------------------------------------------------------------
rob_results <- list(
  loo_min = min(loo_results$coef),
  loo_max = max(loo_results$coef),
  loo_mean = mean(loo_results$coef),
  placebo_2021_coef = coef(m_p1)["treated:placebo_2021"],
  placebo_2021_se = se(m_p1)["treated:placebo_2021"],
  placebo_2020_coef = coef(m_p2)["treated:placebo_2020"],
  placebo_2020_se = se(m_p2)["treated:placebo_2020"],
  iberian_coef = coef(m_iber)["treated:post_announce"],
  iberian_se = se(m_iber)["treated:post_announce"],
  trends_coef = coef(m_trends)["treated:post_announce"],
  trends_se = se(m_trends)["treated:post_announce"],
  short_coef = coef(m_short)["treated:post_announce"],
  short_se = se(m_short)["treated:post_announce"]
)

write_json(rob_results, "../data/robustness_results.json", auto_unbox = TRUE, pretty = TRUE)

save(loo_results, m_p1, m_p2, m_iber, m_similar, m_trends, m_short,
     file = "../data/robustness_models.RData")

cat("\n=== Robustness checks complete ===\n")
