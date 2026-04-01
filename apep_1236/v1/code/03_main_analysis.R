# 03_main_analysis.R — Main DiD analysis of PFAS freeze on housing supply

library(tidyverse)
library(fixest)
library(jsonlite)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) > 0) setwd(file.path(script_dir, ".."))

panel <- readRDS("data/panel.rds")

# Normalize Fryslân → Friesland
panel$province[panel$province == "Fryslân"] <- "Friesland"

cat("Panel:", nrow(panel), "obs,", n_distinct(panel$region), "municipalities\n")

# ============================================================
# 1. Main DiD: PFAS freeze effect
# ============================================================
cat("\n=== MAIN ANALYSIS ===\n")

# Spec 1: Basic DiD with two periods (freeze and post-relaxation)
m1 <- feols(
  new_construction ~ treat_freeze + treat_postrelax | region + ym_factor,
  data = panel,
  cluster = "region"
)
cat("\n--- Model 1: Binary DiD (freeze + post-relax) ---\n")
summary(m1)

# Spec 2: Log outcome (intensive margin)
m2 <- feols(
  log_new ~ treat_freeze + treat_postrelax | region + ym_factor,
  data = panel,
  cluster = "region"
)
cat("\n--- Model 2: Log new construction ---\n")
summary(m2)

# Spec 3: Simple post dummy (combine freeze + post-relax)
m3 <- feols(
  new_construction ~ treat_post | region + ym_factor,
  data = panel,
  cluster = "region"
)
cat("\n--- Model 3: Combined post effect ---\n")
summary(m3)

# Spec 4: Poisson (count outcome)
m4 <- fepois(
  new_construction ~ treat_freeze + treat_postrelax | region + ym_factor,
  data = panel,
  cluster = "region"
)
cat("\n--- Model 4: Poisson ---\n")
summary(m4)

# ============================================================
# 2. Event study
# ============================================================
cat("\n=== EVENT STUDY ===\n")

# Create event time bins (binned at endpoints)
panel <- panel %>%
  mutate(
    et_bin = case_when(
      event_time <= -24 ~ -24L,
      event_time >= 48 ~ 48L,
      TRUE ~ event_time
    ),
    et_factor = factor(et_bin)
  )

# Event study specification
es <- feols(
  new_construction ~ i(et_factor, high_pfas, ref = -1) | region + ym_factor,
  data = panel,
  cluster = "region"
)
cat("\n--- Event study coefficients ---\n")
es_coefs <- coeftable(es) %>%
  as.data.frame() %>%
  tibble::rownames_to_column("term") %>%
  filter(grepl("et_factor", term)) %>%
  mutate(
    event_time = as.integer(gsub(".*::([-0-9]+):.*", "\\1", term))
  ) %>%
  arrange(event_time)

print(es_coefs %>% select(event_time, Estimate, `Std. Error`, `Pr(>|t|)`))

# Pre-trends test: joint significance of pre-period coefficients
pre_coefs <- es_coefs %>% filter(event_time < -1)
cat("\nPre-trend coefficients (t < -1):", nrow(pre_coefs), "\n")
cat("Max absolute pre-trend coef:", max(abs(pre_coefs$Estimate)), "\n")
cat("Mean absolute pre-trend coef:", mean(abs(pre_coefs$Estimate)), "\n")

# ============================================================
# 3. Province-specific analysis
# ============================================================
cat("\n=== PROVINCE-SPECIFIC EFFECTS ===\n")

# Zuid-Holland only (contains Chemours factory)
panel_zh <- panel %>% filter(province == "Zuid-Holland" | !high_pfas)
m_zh <- feols(
  new_construction ~ treat_freeze + treat_postrelax | region + ym_factor,
  data = panel_zh,
  cluster = "region"
)
cat("\n--- Zuid-Holland treatment effect ---\n")
summary(m_zh)

# Noord-Brabant only (downstream)
panel_nb <- panel %>% filter(province == "Noord-Brabant" | !high_pfas)
m_nb <- feols(
  new_construction ~ treat_freeze + treat_postrelax | region + ym_factor,
  data = panel_nb,
  cluster = "region"
)
cat("\n--- Noord-Brabant treatment effect ---\n")
summary(m_nb)

# ============================================================
# 4. Effect on housing stock growth (net additions)
# ============================================================
cat("\n=== NET ADDITIONS (new - demolition) ===\n")

panel$net_addition <- panel$new_construction - panel$demolition

m_net <- feols(
  net_addition ~ treat_freeze + treat_postrelax | region + ym_factor,
  data = panel,
  cluster = "region"
)
cat("\n--- Net additions ---\n")
summary(m_net)

# ============================================================
# 5. Extensive margin: zero construction months
# ============================================================
cat("\n=== EXTENSIVE MARGIN (prob of zero) ===\n")

panel$zero_new <- as.integer(panel$new_construction == 0)

m_ext <- feols(
  zero_new ~ treat_freeze + treat_postrelax | region + ym_factor,
  data = panel,
  cluster = "region"
)
cat("\n--- Probability of zero construction ---\n")
summary(m_ext)

# ============================================================
# 6. Save results
# ============================================================
dir.create("data", showWarnings = FALSE)

# Model results for tables
results <- list(
  m1_levels = m1,
  m2_log = m2,
  m3_combined = m3,
  m4_poisson = m4,
  m_zh = m_zh,
  m_nb = m_nb,
  m_net = m_net,
  m_ext = m_ext,
  es = es,
  es_coefs = es_coefs
)
saveRDS(results, "data/main_results.rds")

# Diagnostics for validator
n_treated <- n_distinct(panel$region[panel$high_pfas])
n_control <- n_distinct(panel$region[!panel$high_pfas])
n_pre <- sum(panel$date < as.Date("2019-07-01")) / n_distinct(panel$region)

diag <- list(
  n_treated = n_treated,
  n_control = n_control,
  n_pre = as.integer(n_pre),
  n_obs = nrow(panel),
  n_muni = n_distinct(panel$region),
  outcome_sd = sd(panel$new_construction[panel$date < as.Date("2019-07-01")], na.rm = TRUE),
  outcome_mean = mean(panel$new_construction[panel$date < as.Date("2019-07-01")], na.rm = TRUE)
)
write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== DIAGNOSTICS ===\n")
cat("Treated municipalities:", n_treated, "\n")
cat("Control municipalities:", n_control, "\n")
cat("Pre-treatment months:", as.integer(n_pre), "\n")
cat("Total observations:", nrow(panel), "\n")
cat("Pre-period outcome SD:", diag$outcome_sd, "\n")
cat("Pre-period outcome mean:", diag$outcome_mean, "\n")
