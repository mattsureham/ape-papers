################################################################################
# 04_robustness.R — Robustness checks
# Paper: apep_0701 — FUNDEB Fiscal Equalization and Education Spending
#
# (A) Placebo: Health spending (should not respond to FUNDEB)
# (B) Alternative clustering: municipality-level
# (C) Northeast subsample (highest-intensity treated states)
# (D) Log per-capita education spending (population-normalized)
# (E) Pre-treatment spending intensity (heterogeneity)
################################################################################

source("code/00_packages.R")
setwd(here::here())

panel     <- readRDS("data/panel_rds.rds")
results   <- readRDS("data/results.rds")
total_raw <- read_csv("data/total_spending.csv", show_col_types = FALSE)
edu_raw   <- read_csv("data/edu_total.csv", show_col_types = FALSE)

cat("Data loaded for robustness. N =", nrow(panel), "\n")

# ─────────────────────────────────────────────────────────────────
# (A) PLACEBO: Health spending (not earmarked like education)
# If FUNDEB caused a general budget expansion, health would also increase.
# If null → effect is education-specific (consistent with earmarking)
# ─────────────────────────────────────────────────────────────────
cat("\n=== (A) Placebo: Health spending ===\n")

library(bigrquery); library(DBI)
bq_project <- "scl-librechat"
bq_auth(path = path.expand("~/.config/gcloud/application_default_credentials.json"))
con <- dbConnect(bigquery(), project = bq_project, billing = bq_project)

health_query <- "
  SELECT ano, sigla_uf, id_municipio, SUM(valor) AS health_spending
  FROM `basedosdados.br_me_siconfi.municipio_despesas_funcao`
  WHERE ano BETWEEN 2002 AND 2011
    AND estagio_bd = 'Despesas Empenhadas'
    AND (
      (ano <= 2003 AND conta = 'Saúde')
      OR (ano >= 2004 AND id_conta_bd = '3.10.000')
    )
  GROUP BY ano, sigla_uf, id_municipio
"

cat("Fetching health spending...\n")
health <- dbGetQuery(con, health_query)
cat("Health spending rows:", nrow(health), "\n")

panel_health <- panel %>%
  left_join(health %>% rename(year = ano) %>% mutate(id_municipio = as.numeric(id_municipio)),
            by = c("id_municipio","year","sigla_uf")) %>%
  mutate(
    health_spending = pmax(health_spending, 1, na.rm = TRUE),
    log_health = log(health_spending)
  ) %>%
  filter(!is.na(log_health), is.finite(log_health))

placebo_health <- feols(
  log_health ~ treated:post | id_municipio + year,
  data    = panel_health,
  cluster = ~sigla_uf
)

cat("Placebo (health) coef:", round(coef(placebo_health)["treated:post"], 5),
    "| p =", round(fixest::pvalue(placebo_health)["treated:post"], 4), "\n")

# ─────────────────────────────────────────────────────────────────
# (B) Alternative clustering: municipality-level SEs
# Addresses concern that state-level treatment → state-level clustering
# ─────────────────────────────────────────────────────────────────
cat("\n=== (B) Municipality-level clustering ===\n")

robust_mun_clust <- feols(
  log_edu_total ~ treated:post | id_municipio + year,
  data    = panel,
  cluster = ~id_municipio
)

cat("Municipality-clustered coef:", round(coef(robust_mun_clust)["treated:post"], 5),
    "| p =", round(fixest::pvalue(robust_mun_clust)["treated:post"], 4), "\n")

# ─────────────────────────────────────────────────────────────────
# (C) Northeast subsample
# The Northeast received the bulk of complementação (7 of 10 treated states)
# Subsample that captures the highest-intensity transfer states
# ─────────────────────────────────────────────────────────────────
cat("\n=== (C) Northeast subsample ===\n")

# Northeast state codes (IBGE): AL=27, BA=29, CE=23, MA=21, PB=25, PE=26, PI=22, RN=24, SE=28
ne_states <- c("AL","BA","CE","MA","PB","PE","PI","RN","SE")

panel_ne <- panel %>%
  filter(sigla_uf %in% ne_states)

panel_other <- panel %>%
  filter(!sigla_uf %in% ne_states)

robust_ne <- feols(
  log_edu_total ~ treated:post | id_municipio + year,
  data    = panel_ne,
  cluster = ~sigla_uf
)

robust_other <- feols(
  log_edu_total ~ treated:post | id_municipio + year,
  data    = panel_other,
  cluster = ~sigla_uf
)

cat("Northeast coef:", round(coef(robust_ne)["treated:post"], 5),
    "| p =", round(fixest::pvalue(robust_ne)["treated:post"], 4), "\n")
cat("Other regions coef:", round(coef(robust_other)["treated:post"], 5),
    "| p =", round(fixest::pvalue(robust_other)["treated:post"], 4), "\n")

# ─────────────────────────────────────────────────────────────────
# (D) Log per-capita education spending
# Uses interpolated population as denominator
# ─────────────────────────────────────────────────────────────────
cat("\n=== (D) Log per-capita education spending ===\n")

robust_pc <- feols(
  log_edu_pc ~ treated:post | id_municipio + year,
  data    = panel %>% filter(!is.na(log_edu_pc), is.finite(log_edu_pc)),
  cluster = ~sigla_uf
)

cat("Per-capita DiD coef:", round(coef(robust_pc)["treated:post"], 5),
    "| p =", round(fixest::pvalue(robust_pc)["treated:post"], 4), "\n")

# ─────────────────────────────────────────────────────────────────
# (E) Heterogeneity: Below vs above median pre-treatment spending
# Complementação targets states below the national floor — do
# the lowest-spending municipalities show stronger effects?
# ─────────────────────────────────────────────────────────────────
cat("\n=== (E) Heterogeneity by pre-treatment spending ===\n")

# Pre-treatment (2006) education spending quartile
pre_2006 <- panel %>%
  filter(year == 2006) %>%
  mutate(
    below_median = as.integer(log_edu_total < median(log_edu_total, na.rm = TRUE)),
    q25 = quantile(log_edu_total, 0.25, na.rm = TRUE),
    q75 = quantile(log_edu_total, 0.75, na.rm = TRUE)
  ) %>%
  select(id_municipio, below_median)

panel_hetero <- panel %>%
  left_join(pre_2006, by = "id_municipio")

het_below <- feols(
  log_edu_total ~ treated:post | id_municipio + year,
  data    = filter(panel_hetero, below_median == 1),
  cluster = ~sigla_uf
)

het_above <- feols(
  log_edu_total ~ treated:post | id_municipio + year,
  data    = filter(panel_hetero, below_median == 0),
  cluster = ~sigla_uf
)

cat("Below median pre-spending coef:", round(coef(het_below)["treated:post"], 5),
    "| p =", round(fixest::pvalue(het_below)["treated:post"], 4), "\n")
cat("Above median pre-spending coef:", round(coef(het_above)["treated:post"], 5),
    "| p =", round(fixest::pvalue(het_above)["treated:post"], 4), "\n")

# ─────────────────────────────────────────────────────────────────
# Save robustness results
# ─────────────────────────────────────────────────────────────────
robustness <- list(
  placebo_health  = placebo_health,
  robust_mun_clust = robust_mun_clust,
  robust_ne       = robust_ne,
  robust_other    = robust_other,
  robust_pc       = robust_pc,
  het_below       = het_below,
  het_above       = het_above
)

saveRDS(robustness, "data/robustness.rds")
cat("\nRobustness results saved.\n")
