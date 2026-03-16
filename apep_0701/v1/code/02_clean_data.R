################################################################################
# 02_clean_data.R — Construct analysis panel
# Paper: apep_0701 — FUNDEB Fiscal Equalization and Education Spending
#
# Creates:
#   - Municipality × year panel (2002-2011)
#   - Treatment indicator: complementação state (state-level, binary)
#   - Outcomes: log education spending, education share, secondary share
################################################################################

source("code/00_packages.R")
setwd(here::here())

# Load raw data
edu_total      <- read_csv("data/edu_total.csv",     show_col_types = FALSE)
edu_detail     <- read_csv("data/edu_detail.csv",    show_col_types = FALSE)
total_spending <- read_csv("data/total_spending.csv",show_col_types = FALSE)
pop_raw        <- read_csv("data/population.csv",    show_col_types = FALSE)
comp_states    <- read_csv("data/complementacao_states.csv", show_col_types = FALSE)

cat("=== Data loaded ===\n")
cat("edu_total:", nrow(edu_total), "rows,", n_distinct(edu_total$id_municipio), "municipalities\n")
cat("edu_detail:", nrow(edu_detail), "rows\n")
cat("total_spending:", nrow(total_spending), "rows\n")

# ─────────────────────────────────────────────────────────────────
# (A) Population: interpolate missing years (2007, 2010)
# SIDRA provides 2002-2006, 2008-2009, 2011; we need all years 2002-2011
# ─────────────────────────────────────────────────────────────────
all_years <- 2002:2011
all_mun   <- unique(pop_raw$id_municipio)

pop_interp <- expand_grid(id_municipio = all_mun, ano = all_years) %>%
  left_join(pop_raw, by = c("id_municipio", "ano")) %>%
  group_by(id_municipio) %>%
  arrange(ano) %>%
  mutate(
    population = ifelse(is.na(population),
                        zoo::na.approx(population, na.rm = FALSE),
                        population)
  ) %>%
  # Fill remaining NAs (end-of-series) with nearest observed
  fill(population, .direction = "downup") %>%
  ungroup()

cat("\nPopulation interpolated:", nrow(pop_interp), "rows\n")
cat("Missing after interpolation:", sum(is.na(pop_interp$population)), "\n")

# ─────────────────────────────────────────────────────────────────
# (B) Merge into main panel: municipality × year (2002-2011)
# ─────────────────────────────────────────────────────────────────

panel <- edu_total %>%
  rename(ano = ano, edu_total_spending = edu_total) %>%
  # Add total municipal spending
  left_join(total_spending %>% select(id_municipio, ano, total_spending),
            by = c("id_municipio","ano")) %>%
  # Add population
  left_join(pop_interp %>% select(id_municipio, ano, population),
            by = c("id_municipio","ano")) %>%
  # Add education detail (primary/secondary, available 2004-2011)
  left_join(edu_detail %>% select(id_municipio, ano,
                                   edu_primary, edu_secondary, edu_early_childhood),
            by = c("id_municipio","ano")) %>%
  # Add treatment indicator
  left_join(comp_states %>% rename(sigla_uf = sigla_uf, complementacao = complementacao),
            by = "sigla_uf") %>%
  mutate(complementacao = replace_na(complementacao, 0L))

cat("Panel after merge:", nrow(panel), "rows\n")

# ─────────────────────────────────────────────────────────────────
# (C) Construct outcome variables
# ─────────────────────────────────────────────────────────────────

panel <- panel %>%
  mutate(
    # Positive spending constraint
    edu_total_spending = pmax(edu_total_spending, 1),
    total_spending     = pmax(total_spending, 1),

    # Log total education spending (main outcome)
    log_edu_total = log(edu_total_spending),

    # Education share of total municipal spending
    edu_share = edu_total_spending / total_spending,

    # Log per-capita education spending (2002-2011, interpolated pop)
    edu_pc      = edu_total_spending / pmax(population, 100),
    log_edu_pc  = log(edu_pc),

    # Secondary share of education (2004-2011 only)
    edu_sub_total = edu_primary + edu_secondary + edu_early_childhood,
    share_secondary = ifelse(edu_sub_total > 0,
                             edu_secondary / edu_sub_total, NA_real_),
    share_primary   = ifelse(edu_sub_total > 0,
                             edu_primary   / edu_sub_total, NA_real_),

    # Log spending by level (add 1 to handle zeros)
    log_edu_secondary = log(edu_secondary + 1),
    log_edu_primary   = log(edu_primary   + 1),

    # Post-FUNDEB indicator
    post    = as.integer(ano >= 2007),
    treated = as.integer(complementacao == 1),

    # Year variable
    year = ano,

    # Interaction (for DDD)
    treat_post = treated * post
  ) %>%
  filter(
    !is.na(log_edu_total),
    is.finite(log_edu_total)
  )

cat("Panel after outcome construction:", nrow(panel), "rows\n")
cat("Years:", paste(sort(unique(panel$year)), collapse=","), "\n")
cat("Municipalities:", n_distinct(panel$id_municipio), "\n")
cat("Treated municipalities:", sum(panel$treated == 1 & panel$year == 2006), "\n")
cat("Control municipalities:", sum(panel$treated == 0 & panel$year == 2006), "\n")

# Summary statistics
cat("\nOutcome summaries (2006 baseline):\n")
pre_data <- panel %>% filter(year == 2006)
cat("log_edu_total: mean=", round(mean(pre_data$log_edu_total, na.rm=TRUE), 3),
    "sd=", round(sd(pre_data$log_edu_total, na.rm=TRUE), 3), "\n")
cat("edu_share: mean=", round(mean(pre_data$edu_share, na.rm=TRUE), 3),
    "sd=", round(sd(pre_data$edu_share, na.rm=TRUE), 3), "\n")
cat("share_secondary (2006): mean=", round(mean(pre_data$share_secondary, na.rm=TRUE), 4),
    "sd=", round(sd(pre_data$share_secondary, na.rm=TRUE), 4), "\n")

# ─────────────────────────────────────────────────────────────────
# (D) DDD stacked panel: primary vs secondary spending (2004-2011)
# Stack each municipality-year twice: once for primary, once for secondary
# ─────────────────────────────────────────────────────────────────

panel_ddd <- panel %>%
  filter(year >= 2004, !is.na(edu_primary), !is.na(edu_secondary)) %>%
  bind_rows(
    panel %>%
      filter(year >= 2004, !is.na(edu_primary), !is.na(edu_secondary)) %>%
      mutate(
        level = "primary",
        log_level_spending = log_edu_primary,
        secondary_ind = 0L
      ),
    panel %>%
      filter(year >= 2004, !is.na(edu_primary), !is.na(edu_secondary)) %>%
      mutate(
        level = "secondary",
        log_level_spending = log_edu_secondary,
        secondary_ind = 1L
      )
  ) %>%
  # Remove double rows created by bind_rows() on full panel
  filter(!is.na(level)) %>%
  filter(is.finite(log_level_spending)) %>%
  mutate(
    treat_post_secondary = treated * post * secondary_ind,
    mun_level_id = paste(id_municipio, level, sep="_")
  )

cat("\nDDD stacked panel:", nrow(panel_ddd), "rows\n")
cat("Unique mun-level units:", n_distinct(panel_ddd$mun_level_id), "\n")
cat("Years in DDD:", paste(sort(unique(panel_ddd$year)), collapse=","), "\n")

# ─────────────────────────────────────────────────────────────────
# (E) Balanced panel: municipalities with complete 2002-2011 data
# ─────────────────────────────────────────────────────────────────

required_years <- 2002:2011

mun_complete <- panel %>%
  group_by(id_municipio) %>%
  filter(all(required_years %in% year)) %>%
  pull(id_municipio) %>%
  unique()

panel_balanced <- panel %>%
  filter(id_municipio %in% mun_complete)

cat("\nBalanced panel (all 10 years):\n")
cat("Municipalities:", length(mun_complete), "\n")
cat("Rows:", nrow(panel_balanced), "\n")
cat("Treated (balanced, 2006):", sum(panel_balanced$treated == 1 & panel_balanced$year == 2006), "\n")
cat("Control (balanced, 2006):", sum(panel_balanced$treated == 0 & panel_balanced$year == 2006), "\n")

# ─────────────────────────────────────────────────────────────────
# Save outputs
# ─────────────────────────────────────────────────────────────────
write_csv(panel,          "data/panel.csv")
write_csv(panel_balanced, "data/panel_balanced.csv")
write_csv(panel_ddd,      "data/panel_ddd.csv")

cat("\n=== Data saved ===\n")
cat("panel:", nrow(panel), "rows\n")
cat("panel_balanced:", nrow(panel_balanced), "rows\n")
cat("panel_ddd:", nrow(panel_ddd), "rows\n")
