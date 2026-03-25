## 04_robustness.R — Robustness and heterogeneity for apep_0898
## Grocery exit cascades: anchor store hypothesis

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "results.rds"))

cat("========== ROBUSTNESS CHECKS ==========\n\n")

## ============================================================
## 1. State × Year FE (absorb state-level trends)
## ============================================================
cat("--- 1. State × Year Fixed Effects ---\n")

panel <- panel %>% mutate(state_year = paste0(state, "_", year))

## First stage with state×year FE
syfe_fs <- feols(
  log_grocery ~ bartik_iv | fips + state^year,
  data = panel,
  cluster = ~state
)
cat(sprintf("First stage with state×year FE: %.5f (SE: %.5f)\n",
            coef(syfe_fs)["bartik_iv"], se(syfe_fs)["bartik_iv"]))

## IV with state×year FE
syfe_iv_food <- feols(
  log_foodservice ~ 1 | fips + state^year | log_grocery ~ bartik_iv,
  data = panel,
  cluster = ~state
)
syfe_iv_nongrocery <- feols(
  log_nongrocery ~ 1 | fips + state^year | log_grocery ~ bartik_iv,
  data = panel,
  cluster = ~state
)

cat(sprintf("IV food service (state×year FE): %.4f (SE: %.4f)\n",
            coef(syfe_iv_food)["fit_log_grocery"],
            se(syfe_iv_food)["fit_log_grocery"]))
cat(sprintf("IV non-grocery (state×year FE):  %.4f (SE: %.4f)\n",
            coef(syfe_iv_nongrocery)["fit_log_grocery"],
            se(syfe_iv_nongrocery)["fit_log_grocery"]))

## ============================================================
## 2. Short-run Bartik (0-3 year window only)
## ============================================================
cat("\n--- 2. Short-Run Bartik IV (0-3 year window) ---\n")

## Re-compute Bartik with 3-year window
bankruptcy_exposure <- readRDS(file.path(data_dir, "bankruptcy_exposure.rds"))
chain_bankruptcies <- readRDS(file.path(data_dir, "chain_bankruptcies.rds"))
post2010 <- chain_bankruptcies %>% filter(bankruptcy_year >= 2010)

## Get base year shares
base_year_data <- panel %>%
  filter(year == 2008) %>%
  select(fips, state, grocery_estab) %>%
  group_by(state) %>%
  mutate(state_total = sum(grocery_estab, na.rm = TRUE),
         county_share = ifelse(state_total > 0, grocery_estab / state_total, 0)) %>%
  ungroup() %>%
  select(fips, state, county_share)

post2010_exp <- bankruptcy_exposure %>% filter(bankruptcy_year >= 2010)

bartik_sr <- base_year_data %>%
  cross_join(
    post2010_exp %>%
      select(chain, bankruptcy_year, state_fips, approx_stores) %>%
      rename(exposed_state = state_fips)
  ) %>%
  filter(state == exposed_state) %>%
  cross_join(tibble(year = 2005:2022)) %>%
  mutate(
    active_sr = as.integer(year >= bankruptcy_year & year <= bankruptcy_year + 3),
    contribution_sr = county_share * approx_stores * active_sr
  ) %>%
  group_by(fips, year) %>%
  summarise(bartik_iv_sr = sum(contribution_sr), .groups = "drop")

panel_sr <- panel %>%
  left_join(bartik_sr, by = c("fips", "year")) %>%
  mutate(bartik_iv_sr = replace_na(bartik_iv_sr, 0))

## First stage with short-run Bartik
sr_fs <- feols(
  log_grocery ~ bartik_iv_sr | fips + year,
  data = panel_sr,
  cluster = ~state
)
cat(sprintf("Short-run first stage: %.5f (SE: %.5f)\n",
            coef(sr_fs)["bartik_iv_sr"], se(sr_fs)["bartik_iv_sr"]))

## IV with short-run Bartik
sr_iv_food <- feols(
  log_foodservice ~ 1 | fips + year | log_grocery ~ bartik_iv_sr,
  data = panel_sr,
  cluster = ~state
)
cat(sprintf("Short-run IV food service: %.4f (SE: %.4f)\n",
            coef(sr_iv_food)["fit_log_grocery"],
            se(sr_iv_food)["fit_log_grocery"]))

sr_iv_nongrocery <- feols(
  log_nongrocery ~ 1 | fips + year | log_grocery ~ bartik_iv_sr,
  data = panel_sr,
  cluster = ~state
)
cat(sprintf("Short-run IV non-grocery: %.4f (SE: %.4f)\n",
            coef(sr_iv_nongrocery)["fit_log_grocery"],
            se(sr_iv_nongrocery)["fit_log_grocery"]))

## ============================================================
## 3. Heterogeneity by grocery concentration
## ============================================================
cat("\n--- 3. Heterogeneity: Rural vs Urban ---\n")

## Rural counties (≤5 grocery stores in base year)
iv_food_rural <- feols(
  log_foodservice ~ 1 | fips + year | log_grocery ~ bartik_iv,
  data = panel %>% filter(rural),
  cluster = ~state
)

iv_food_urban <- feols(
  log_foodservice ~ 1 | fips + year | log_grocery ~ bartik_iv,
  data = panel %>% filter(urban),
  cluster = ~state
)

cat(sprintf("IV food service (rural): %.4f (SE: %.4f)\n",
            coef(iv_food_rural)["fit_log_grocery"],
            se(iv_food_rural)["fit_log_grocery"]))
cat(sprintf("IV food service (urban): %.4f (SE: %.4f)\n",
            coef(iv_food_urban)["fit_log_grocery"],
            se(iv_food_urban)["fit_log_grocery"]))

## Non-grocery outcomes
iv_nongrocery_rural <- feols(
  log_nongrocery ~ 1 | fips + year | log_grocery ~ bartik_iv,
  data = panel %>% filter(rural),
  cluster = ~state
)
iv_nongrocery_urban <- feols(
  log_nongrocery ~ 1 | fips + year | log_grocery ~ bartik_iv,
  data = panel %>% filter(urban),
  cluster = ~state
)

cat(sprintf("IV non-grocery (rural): %.4f (SE: %.4f)\n",
            coef(iv_nongrocery_rural)["fit_log_grocery"],
            se(iv_nongrocery_rural)["fit_log_grocery"]))
cat(sprintf("IV non-grocery (urban): %.4f (SE: %.4f)\n",
            coef(iv_nongrocery_urban)["fit_log_grocery"],
            se(iv_nongrocery_urban)["fit_log_grocery"]))

## CS-DiD for rural only
cat("\n--- 3b. CS-DiD: Rural subsample ---\n")
cs_rural <- panel %>%
  filter(rural) %>%
  mutate(county_id = as.integer(factor(fips)),
         g = ifelse(first_treat == 0, 0, first_treat)) %>%
  filter(!is.na(log_foodservice), !is.na(log_grocery))

if (n_distinct(cs_rural$g[cs_rural$g > 0]) >= 2 &&
    n_distinct(cs_rural$fips[cs_rural$g == 0]) >= 10) {
  cs_food_rural <- att_gt(
    yname = "log_foodservice", tname = "year",
    idname = "county_id", gname = "g",
    data = cs_rural, control_group = "nevertreated",
    base_period = "universal"
  )
  att_food_rural <- aggte(cs_food_rural, type = "simple")
  cat(sprintf("CS-DiD ATT food service (rural): %.4f (SE: %.4f)\n",
              att_food_rural$overall.att, att_food_rural$overall.se))

  cs_grocery_rural <- att_gt(
    yname = "log_grocery", tname = "year",
    idname = "county_id", gname = "g",
    data = cs_rural, control_group = "nevertreated",
    base_period = "universal"
  )
  att_grocery_rural <- aggte(cs_grocery_rural, type = "simple")
  cat(sprintf("CS-DiD ATT grocery (rural, first stage): %.4f (SE: %.4f)\n",
              att_grocery_rural$overall.att, att_grocery_rural$overall.se))
} else {
  cat("Insufficient variation in rural subsample for CS-DiD.\n")
}

## ============================================================
## 4. Heterogeneity: Few vs Many Grocers
## ============================================================
cat("\n--- 4. Heterogeneity: Few vs Many Grocers ---\n")

iv_food_few <- feols(
  log_foodservice ~ 1 | fips + year | log_grocery ~ bartik_iv,
  data = panel %>% filter(few_grocers),
  cluster = ~state
)
iv_food_many <- feols(
  log_foodservice ~ 1 | fips + year | log_grocery ~ bartik_iv,
  data = panel %>% filter(!few_grocers),
  cluster = ~state
)

cat(sprintf("IV food service (few grocers):  %.4f (SE: %.4f)\n",
            coef(iv_food_few)["fit_log_grocery"],
            se(iv_food_few)["fit_log_grocery"]))
cat(sprintf("IV food service (many grocers): %.4f (SE: %.4f)\n",
            coef(iv_food_many)["fit_log_grocery"],
            se(iv_food_many)["fit_log_grocery"]))

## ============================================================
## 5. Leave-one-chain-out
## ============================================================
cat("\n--- 5. Leave-One-Chain-Out ---\n")

chain_list <- unique(post2010$chain)
loco_results <- list()

for (ch in chain_list) {
  remaining_exp <- bankruptcy_exposure %>%
    filter(bankruptcy_year >= 2010, chain != ch)

  if (nrow(remaining_exp) == 0) next

  # Recompute Bartik without this chain
  bartik_loco <- base_year_data %>%
    cross_join(
      remaining_exp %>%
        select(chain, bankruptcy_year, state_fips, approx_stores) %>%
        rename(exposed_state = state_fips)
    ) %>%
    filter(state == exposed_state) %>%
    cross_join(tibble(year = 2005:2022)) %>%
    mutate(
      active = as.integer(year >= bankruptcy_year),
      contribution = county_share * approx_stores * active
    ) %>%
    group_by(fips, year) %>%
    summarise(bartik_loco = sum(contribution), .groups = "drop")

  panel_loco <- panel %>%
    left_join(bartik_loco, by = c("fips", "year")) %>%
    mutate(bartik_loco = replace_na(bartik_loco, 0))

  loco_mod <- tryCatch(
    feols(log_nongrocery ~ 1 | fips + year | log_grocery ~ bartik_loco,
          data = panel_loco, cluster = ~state),
    error = function(e) NULL
  )

  if (!is.null(loco_mod)) {
    loco_results[[ch]] <- tibble(
      chain_dropped = ch,
      coef = coef(loco_mod)["fit_log_grocery"],
      se = se(loco_mod)["fit_log_grocery"]
    )
    cat(sprintf("  Drop %s: %.4f (SE: %.4f)\n", ch,
                coef(loco_mod)["fit_log_grocery"],
                se(loco_mod)["fit_log_grocery"]))
  }
}

loco_df <- bind_rows(loco_results)

## ============================================================
## 6. Save robustness results
## ============================================================
robustness <- list(
  syfe_fs = syfe_fs,
  syfe_iv_food = syfe_iv_food,
  syfe_iv_nongrocery = syfe_iv_nongrocery,
  sr_fs = sr_fs,
  sr_iv_food = sr_iv_food,
  sr_iv_nongrocery = sr_iv_nongrocery,
  iv_food_rural = iv_food_rural,
  iv_food_urban = iv_food_urban,
  iv_nongrocery_rural = iv_nongrocery_rural,
  iv_nongrocery_urban = iv_nongrocery_urban,
  iv_food_few = iv_food_few,
  iv_food_many = iv_food_many,
  loco_df = loco_df
)

saveRDS(robustness, file.path(data_dir, "robustness.rds"))
cat("\n========== ROBUSTNESS COMPLETE ==========\n")

## ============================================================
## 7. Placebo: Manufacturing (NAICS 31-33) — not foot-traffic dependent
## ============================================================
cat("\n--- 7. Placebo: Manufacturing (NAICS 31-33) ---\n")

## Fetch manufacturing data from CBP (if not already in panel)
## Manufacturing should NOT respond to grocery foot traffic
## Use NAICS 31-33 (manufacturing) as a negative control

## We need to fetch this separately since it wasn't in original pull
library(httr)
census_key <- Sys.getenv("CENSUS_API_KEY")

fetch_mfg <- function(year, key) {
  if (year >= 2017) nv <- "NAICS2017"
  else if (year >= 2012) nv <- "NAICS2012"
  else if (year >= 2008) nv <- "NAICS2007"
  else nv <- "NAICS2002"
  
  url <- sprintf("https://api.census.gov/data/%d/cbp?get=ESTAB&for=county:*&%s=31-33&key=%s",
                 year, nv, key)
  resp <- tryCatch(GET(url, timeout(60)), error = function(e) NULL)
  if (is.null(resp) || status_code(resp) != 200) return(NULL)
  parsed <- fromJSON(content(resp, "text", encoding = "UTF-8"))
  if (is.null(parsed) || nrow(parsed) < 2) return(NULL)
  df <- as.data.frame(parsed[-1, ], stringsAsFactors = FALSE)
  names(df) <- parsed[1, ]
  df$year <- year
  df$fips <- paste0(df$state, df$county)
  df$mfg_estab <- as.integer(df$ESTAB)
  df[, c("fips", "year", "mfg_estab")]
}

mfg_list <- list()
for (yr in c(2005:2022)) {
  cat(sprintf("  MFG %d... ", yr))
  r <- fetch_mfg(yr, census_key)
  if (!is.null(r) && nrow(r) > 0) {
    mfg_list[[length(mfg_list) + 1]] <- r
    cat(sprintf("OK (%d)\n", nrow(r)))
  } else {
    cat("SKIP\n")
  }
  Sys.sleep(0.3)
}

mfg_df <- bind_rows(mfg_list)

panel_mfg <- panel %>%
  left_join(mfg_df, by = c("fips", "year")) %>%
  mutate(log_mfg = log(pmax(mfg_estab, 1)))

placebo_iv <- feols(
  log_mfg ~ 1 | fips + year | log_grocery ~ bartik_iv,
  data = panel_mfg,
  cluster = ~state
)

cat(sprintf("\nPlacebo IV (manufacturing): %.4f (SE: %.4f)\n",
            coef(placebo_iv)["fit_log_grocery"],
            se(placebo_iv)["fit_log_grocery"]))
cat(sprintf("Placebo p-value: %.4f\n",
            2 * pt(abs(coef(placebo_iv)["fit_log_grocery"] /
                       se(placebo_iv)["fit_log_grocery"]),
                   df = nobs(placebo_iv) - 2, lower.tail = FALSE)))

robustness$placebo_iv_mfg <- placebo_iv
saveRDS(robustness, file.path(data_dir, "robustness.rds"))
