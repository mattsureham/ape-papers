## 04_robustness.R — Robustness checks and placebos
## APEP apep_1337: Section 301 Tariffs and the Asian-White Manufacturing Wage Gap

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
results <- readRDS("../data/main_results.rds")

## ========================================================
cat("=== Robustness 1: Placebo — Black-White gap ===\n")
## ========================================================
## If tariffs compress Asian-White gap because Asians are overrepresented
## in exposed industries, the effect should NOT appear for Black-White gap
## (Black workers are not overrepresented in electronics/machinery)

## Need to re-fetch Black worker data
env_file <- "../../../../.env"
env_lines <- readLines(env_file, warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (startsWith(line, "AZURE_STORAGE_CONNECTION_STRING=")) {
    val <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line)
    val <- gsub('^["\'](.*)["\']+$', "\\1", val)
    Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = val)
    break
  }
}

source("../../../../scripts/lib/azure_data.R")
USE_N3 <- readRDS("../data/use_n3_flag.rds")
tariff_coverage <- readRDS("../data/tariff_coverage.rds")

con <- apep_azure_connect()

## Fetch Black (A2) + White (A1) data
if (USE_N3) {
  bw_query <- "
  SELECT geography, year, quarter, race, industry,
    \"Emp\" AS emp, \"EarnS\" AS earn, \"HirA\" AS hires, \"Sep\" AS seps
  FROM 'az://derived/qwi/rh/n3/*.parquet'
  WHERE year BETWEEN 2014 AND 2022
    AND race IN ('A1', 'A2')
    AND ownercode = 'A05'
  "
} else {
  bw_query <- "
  SELECT geography, year, quarter, race, industry,
    \"Emp\" AS emp, \"EarnS\" AS earn, \"HirA\" AS hires, \"Sep\" AS seps
  FROM 'az://derived/qwi/rh/ns/*.parquet'
  WHERE year BETWEEN 2014 AND 2022
    AND race IN ('A1', 'A2')
    AND ownercode = 'A05'
  "
}

cat("Fetching Black-White QWI data for placebo...\n")
qwi_bw <- dbGetQuery(con, bw_query)
cat(sprintf("BW rows: %s\n", format(nrow(qwi_bw), big.mark = ",")))
apep_azure_disconnect(con)

## Construct same panel structure
mfg_codes <- if (USE_N3) tariff_coverage$naics3 else "31-33"
svc_codes <- if (USE_N3) {
  ind_codes <- as.character(c(511:519, 521:525, 531:533, 541, 551, 561))
  ind_codes[ind_codes %in% unique(qwi_bw$industry)]
} else {
  c("51", "52", "53", "54", "55", "56")
}
mfg_codes <- mfg_codes[mfg_codes %in% unique(qwi_bw$industry)]

bw_panel <- qwi_bw %>%
  filter(industry %in% c(mfg_codes, svc_codes)) %>%
  mutate(
    is_mfg = industry %in% mfg_codes,
    state_fips = substr(as.character(geography), 1, 2),
    yq = paste0(year, "Q", quarter)
  )

## Merge tariff exposure
if (USE_N3) {
  bw_panel <- bw_panel %>%
    left_join(tariff_coverage, by = c("industry" = "naics3")) %>%
    mutate(tariff_rate_wtd = ifelse(is.na(tariff_rate_wtd), 0, tariff_rate_wtd))
} else {
  avg_tariff <- mean(tariff_coverage$tariff_rate_wtd)
  bw_panel <- bw_panel %>%
    mutate(tariff_rate_wtd = ifelse(is_mfg, avg_tariff, 0))
}

bw_panel <- bw_panel %>%
  mutate(
    post = (year > 2018) | (year == 2018 & quarter >= 3),
    black = (race == "A2")
  ) %>%
  filter(!is.na(earn) & earn > 0 & !is.na(emp) & emp > 0) %>%
  group_by(state_fips, industry, race, year, quarter, yq,
           is_mfg, tariff_rate_wtd, post, black) %>%
  summarise(
    earn_wt = weighted.mean(earn, emp, na.rm = TRUE),
    emp_total = sum(emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    ln_earn = log(earn_wt),
    ind_state = paste0(industry, "_", state_fips),
    ind_race = paste0(industry, "_", race),
    race_yq = paste0(race, "_", year, "Q", quarter),
    ind_yq = paste0(industry, "_", year, "Q", quarter),
    tariff_black_post = tariff_rate_wtd * black * post,
    tariff_post = tariff_rate_wtd * post,
    black_post = black * post
  )

## Placebo DDD: Black-White gap
placebo_bw <- feols(
  ln_earn ~ tariff_black_post + tariff_post + black_post |
    ind_race + race_yq + ind_yq,
  data = bw_panel,
  weights = ~emp_total,
  cluster = ~ind_state
)
cat("Placebo (Black-White):\n")
summary(placebo_bw)

## ========================================================
cat("\n=== Robustness 2: Services-only placebo ===\n")
## ========================================================
## Run the DDD on services only (tariff exposure = 0)
## Should find no differential Asian-White effect

## Services have near-zero tariff exposure, so use the DDD on services subset
## If services show no tariff × Asian × Post effect, it supports the mechanism
svc_panel <- panel %>%
  filter(!is_mfg) %>%
  mutate(
    tariff_asian_post = tariff_rate_wtd * asian * post,
    tariff_post = tariff_rate_wtd * post,
    asian_post = asian * post
  )

if (nrow(svc_panel) > 100 & length(unique(svc_panel$tariff_rate_wtd)) > 1) {
  placebo_svc <- tryCatch({
    feols(
      ln_earn ~ tariff_asian_post + tariff_post + asian_post |
        ind_race + race_yq + ind_yq,
      data = svc_panel,
      weights = ~emp_total,
      cluster = ~ind_state
    )
  }, error = function(e) {
    cat("Services placebo error:", conditionMessage(e), "\n")
    NULL
  })
  if (!is.null(placebo_svc)) {
    cat("Placebo (services only):\n")
    summary(placebo_svc)
  }
} else {
  cat("Insufficient services variation for placebo.\n")
  placebo_svc <- NULL
}

## ========================================================
cat("\n=== Robustness 3: Pre-trends test ===\n")
## ========================================================
## Joint F-test on pre-treatment event study coefficients

main_es <- results$es
## Extract pre-treatment coefficients
es_coefs <- coef(main_es)
pre_coefs <- es_coefs[grepl("event_time_bin::-[2-8].*tariff_asian", names(es_coefs))]
cat("\nPre-treatment DDD event study coefficients:\n")
print(pre_coefs)

## Wald test for joint significance of pre-trend DDD coefficients
if (length(pre_coefs) > 0) {
  pre_test <- tryCatch({
    wald(main_es, keep = "event_time_bin::-[2-8].*tariff_asian")
  }, error = function(e) {
    cat("Wald test error:", conditionMessage(e), "\n")
    NULL
  })
  if (!is.null(pre_test)) {
    cat("Pre-trends Wald test:\n")
    print(pre_test)
  }
}

## ========================================================
cat("\n=== Robustness 4: Exclude California ===\n")
## ========================================================
panel_no_ca <- panel %>% filter(state_fips != "06")
cat(sprintf("Panel without CA: %d obs (original: %d)\n", nrow(panel_no_ca), nrow(panel)))

m_no_ca <- tryCatch({
  feols(
    ln_earn ~ tariff_asian_post + tariff_post + asian_post |
      ind_race + race_yq + ind_yq,
    data = panel_no_ca,
    weights = ~emp_total,
    cluster = ~ind_state
  )
}, error = function(e) {
  cat("CA exclusion error:", conditionMessage(e), "\n")
  ## Fall back: simpler FE
  feols(
    ln_earn ~ tariff_asian_post + tariff_post + asian_post |
      industry + race + yq,
    data = panel_no_ca,
    weights = ~emp_total,
    cluster = ~ind_state
  )
})
cat("Robustness: Exclude California:\n")
summary(m_no_ca)

## ========================================================
cat("\n=== Robustness 5: Anticipation-adjusted treatment ===\n")
## ========================================================
## Trump announced Section 301 results March 22, 2018
## Markets may have priced in tariffs before July implementation
## Re-define post = 2018Q1 (announcement quarter)
panel_antic <- panel %>%
  mutate(
    post_antic = (year > 2018) | (year == 2018 & quarter >= 1),
    tariff_asian_post_antic = tariff_rate_wtd * asian * post_antic,
    tariff_post_antic = tariff_rate_wtd * post_antic,
    asian_post_antic = asian * post_antic
  )

m_antic <- feols(
  ln_earn ~ tariff_asian_post_antic + tariff_post_antic + asian_post_antic |
    ind_race + race_yq + ind_yq,
  data = panel_antic,
  weights = ~emp_total,
  cluster = ~ind_state
)
cat("Anticipation-adjusted DDD (post = 2018Q1):\n")
summary(m_antic)

## Drop binary treatment (collinearity with FE at sector level)
m_binary <- NULL
cat("Binary treatment DDD:\n")
summary(m_binary)

## ========================================================
## ========================================================
cat("\n=== Robustness 6: Pre-COVID sample (2014-2019) ===\n")
## ========================================================
## COVID differentially affected Asian workers (service vs mfg composition)
## Restrict to pre-COVID to isolate tariff effect

panel_precovid <- panel %>%
  filter(year <= 2019) %>%
  mutate(
    post = (year > 2018) | (year == 2018 & quarter >= 3),
    tariff_asian_post = tariff_rate_wtd * asian * post,
    tariff_post = tariff_rate_wtd * post,
    asian_post = asian * post
  )

m_precovid <- feols(
  ln_earn ~ tariff_asian_post + tariff_post + asian_post |
    ind_race + race_yq + ind_yq,
  data = panel_precovid,
  weights = ~emp_total,
  cluster = ~ind_state
)
cat("Pre-COVID (2014-2019) DDD:\n")
summary(m_precovid)

cat("\n=== Save robustness results ===\n")
## ========================================================

saveRDS(list(
  placebo_bw = placebo_bw,
  placebo_svc = placebo_svc,
  m_no_ca = m_no_ca,
  m_antic = m_antic,
  m_precovid = m_precovid
), "../data/robustness_results.rds")

cat("Robustness checks complete.\n")
