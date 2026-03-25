# 04_robustness.R — Robustness checks for calorie labeling paper
# Placebo tests, alternative specifications, permutation inference

source("00_packages.R")

DATA_DIR <- "../data"
agg_panel <- readRDS(file.path(DATA_DIR, "analysis_panel.rds"))
models <- readRDS(file.path(DATA_DIR, "models.rds"))

cat("=== Robustness checks ===\n\n")

# ---- 1. Placebo: Other size-band transitions (no regulatory threshold) ----
cat("=== Placebo 1: 50-99 vs 100-249 transition (no regulation) ===\n")

panel_sb <- readRDS(file.path(DATA_DIR, "panel_sizeband.rds"))

# Compute 100-249 / 50-99 ratio (placebo — no regulation at this threshold)
placebo_ratio <- panel_sb |>
  filter(sizeband %in% c("50 to 99", "100 to 249")) |>
  group_by(country, sic2, year, england, food) |>
  summarise(
    n_50_99 = sum(enterprises[sizeband == "50 to 99"], na.rm = TRUE),
    n_100_249 = sum(enterprises[sizeband == "100 to 249"], na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    placebo_ratio = ifelse(n_50_99 > 0, n_100_249 / n_50_99, NA),
    post = as.integer(year >= 2023),
    unit_id = paste(country, sic2, sep = "_"),
    country_year = paste(country, year, sep = "_"),
    industry_year = paste(sic2, year, sep = "_"),
    treated = england * food * post
  )

m_placebo <- feols(
  placebo_ratio ~ treated | unit_id + country_year + industry_year,
  data = placebo_ratio |> filter(!is.na(placebo_ratio)),
  cluster = ~unit_id
)
cat("Placebo (100-249/50-99 ratio, triple-diff):\n")
summary(m_placebo)

# ---- 2. Placebo: Fake treatment year (2019) ----
cat("\n=== Placebo 2: Fake treatment year 2019 ===\n")

agg_fake <- agg_panel |>
  filter(year <= 2021) |>
  mutate(
    post_fake = as.integer(year >= 2019),
    treated_fake = england * food * post_fake
  )

m_fake_year <- feols(
  ln_total ~ treated_fake | unit_id + country_year + industry_year,
  data = agg_fake,
  cluster = ~unit_id
)
summary(m_fake_year)

# ---- 3. Alternative control sectors ----
cat("\n=== Alternative controls: Drop accommodation (SIC 55) ===\n")

# Drop SIC 55 (accommodation shares supply chain with food)
agg_no55 <- agg_panel |> filter(sic2 != 55)
m_no55 <- feols(
  ln_total ~ treated | unit_id + country_year + industry_year,
  data = agg_no55,
  cluster = ~unit_id
)
summary(m_no55)

cat("\n=== Alternative controls: Only retail (SIC 47) as control ===\n")
agg_47 <- agg_panel |> filter(sic2 %in% c(56, 47))
m_47_only <- feols(
  ln_total ~ treated | unit_id + country_year + industry_year,
  data = agg_47,
  cluster = ~unit_id
)
summary(m_47_only)

# ---- 4. Levels instead of logs ----
cat("\n=== Levels specification ===\n")

m_levels <- feols(
  total_enterprises ~ treated | unit_id + country_year + industry_year,
  data = agg_panel,
  cluster = ~unit_id
)
summary(m_levels)

# ---- 5. Permutation inference ----
cat("\n=== Permutation inference (randomize treatment assignment) ===\n")

set.seed(42)
n_perms <- 1000
true_coef <- coef(models$m1)["treated"]

perm_coefs <- numeric(n_perms)
for (i in 1:n_perms) {
  # Randomly reassign which country-industry pair is "treated"
  shuffled <- agg_panel
  perm_idx <- sample(unique(shuffled$unit_id), size = 1)
  shuffled$treated_perm <- as.integer(shuffled$unit_id == perm_idx) * shuffled$post

  m_perm <- tryCatch(
    feols(ln_total ~ treated_perm | unit_id + country_year + industry_year,
      data = shuffled, cluster = ~unit_id),
    error = function(e) NULL
  )

  if (!is.null(m_perm) && "treated_perm" %in% names(coef(m_perm))) {
    perm_coefs[i] <- coef(m_perm)["treated_perm"]
  } else {
    perm_coefs[i] <- NA
  }
}

perm_coefs <- perm_coefs[!is.na(perm_coefs)]
perm_pval <- mean(abs(perm_coefs) >= abs(true_coef))

cat(sprintf("True coefficient: %.4f\n", true_coef))
cat(sprintf("Permutation distribution: mean=%.4f, sd=%.4f\n",
  mean(perm_coefs), sd(perm_coefs)))
cat(sprintf("Permutation p-value (two-sided): %.3f\n", perm_pval))
cat(sprintf("N valid permutations: %d\n", length(perm_coefs)))

# ---- 6. COVID robustness: Exclude 2020-2021 ----
cat("\n=== COVID robustness: Exclude 2020-2021 ===\n")

agg_nocovid <- agg_panel |> filter(!(year %in% c(2020, 2021)))
m_nocovid <- feols(
  ln_total ~ treated | unit_id + country_year + industry_year,
  data = agg_nocovid,
  cluster = ~unit_id
)
summary(m_nocovid)

# ---- 7. Save all robustness results ----
rob_results <- list(
  placebo_threshold = m_placebo,
  placebo_year = m_fake_year,
  no_accommodation = m_no55,
  retail_only = m_47_only,
  levels = m_levels,
  no_covid = m_nocovid,
  perm_pval = perm_pval,
  perm_coefs = perm_coefs,
  true_coef = true_coef
)

saveRDS(rob_results, file.path(DATA_DIR, "robustness_models.rds"))
cat("\n✓ Robustness checks complete.\n")
