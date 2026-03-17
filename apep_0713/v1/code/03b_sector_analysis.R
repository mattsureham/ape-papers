## 03b_sector_analysis.R — Industry heterogeneity test (NAICS 51 vs others)
## Key mechanism test: if preemption suppresses firm births in digital sectors
## more than non-digital sectors, that supports the broadband competition channel.

source("code/00_packages.R")
library(fixest)
library(did)

preemption <- readRDS("data/preemption_laws.rds")

## ============================================================
## FETCH BDS BY NAICS SECTOR × STATE × YEAR
## ============================================================

## Focus sectors:
## NAICS 51 = Information (direct broadband-dependent)
## NAICS 54 = Professional, Scientific, Technical Services (broadband-intensive)
## NAICS 44 = Retail Trade (placebo — not broadband-critical)
## NAICS 23 = Construction (placebo — not broadband-critical)

target_sectors <- c("51", "54", "44", "23")

fetch_bds_sector <- function(year, naics) {
  url <- paste0(
    "https://api.census.gov/data/timeseries/bds",
    "?get=FIRM,JOB_CREATION_BIRTHS",
    "&for=state:*",
    "&YEAR=", year,
    "&NAICS=", naics,
    ifelse(Sys.getenv("CENSUS_API_KEY") != "",
           paste0("&key=", Sys.getenv("CENSUS_API_KEY")), "")
  )
  resp <- fromJSON(url)
  df <- as.data.frame(resp[-1, ], stringsAsFactors = FALSE)
  names(df) <- resp[1, ]
  df$year_obs <- year
  df$naics_sector <- naics
  df <- df %>%
    mutate(
      firms = as.numeric(FIRM),
      job_births = as.numeric(JOB_CREATION_BIRTHS)
    ) %>%
    filter(firms > 0) %>%
    mutate(firm_birth_rate = job_births / firms) %>%
    select(state, year_obs, naics_sector, firms, job_births, firm_birth_rate)
  return(df)
}

sector_years <- 2004:2023

cat("Fetching NAICS sector data...\n")
sector_data <- list()
for (naics in target_sectors) {
  cat("  NAICS", naics, "...\n")
  yr_list <- lapply(sector_years, function(y) {
    tryCatch(
      fetch_bds_sector(y, naics),
      error = function(e) {
        ## Some state × sector × year combinations may be suppressed
        cat("    Year", y, ":", conditionMessage(e), "\n")
        NULL
      }
    )
  })
  sector_df <- bind_rows(Filter(Negate(is.null), yr_list))
  sector_data[[naics]] <- sector_df
  cat("  NAICS", naics, ":", nrow(sector_df), "rows\n")
}

bds_sector <- bind_rows(sector_data) %>%
  mutate(
    sector_label = case_when(
      naics_sector == "51" ~ "Information (51) — Digital",
      naics_sector == "54" ~ "Prof. Services (54) — Digital",
      naics_sector == "44" ~ "Retail (44) — Placebo",
      naics_sector == "23" ~ "Construction (23) — Placebo",
      TRUE ~ naics_sector
    ),
    digital = as.integer(naics_sector %in% c("51", "54"))
  )

saveRDS(bds_sector, "data/bds_sector.rds")

## ============================================================
## MERGE PREEMPTION AND RUN SECTOR DiD
## ============================================================

state_xwalk <- readRDS("data/acs_broadband.rds") %>%
  distinct(state, NAME) %>%
  rename(state_fip = state, state_name = NAME)

bds_sector_panel <- bds_sector %>%
  rename(state_fip = state, year = year_obs) %>%
  left_join(state_xwalk, by = "state_fip") %>%
  left_join(preemption %>% select(state_fip, year_enacted, year_repealed), by = "state_fip") %>%
  mutate(
    preempted = case_when(
      is.na(year_enacted) ~ 0L,
      !is.na(year_repealed) & year >= year_repealed ~ 0L,
      year >= year_enacted ~ 1L,
      TRUE ~ 0L
    )
  ) %>%
  filter(
    state_fip %in% sprintf("%02d", c(1:2, 4:6, 8:13, 15:42, 44:51, 53:56)),
    !is.na(firm_birth_rate), firm_birth_rate > 0
  ) %>%
  mutate(log_fir = log(firm_birth_rate))

## TWFE by sector: main effect + interaction with digital
twfe_sector <- feols(
  log_fir ~ preempted + preempted:digital | state_fip^naics_sector + year^naics_sector,
  data = bds_sector_panel,
  cluster = ~state_fip
)

cat("\n=== SECTOR DiD: Digital vs Non-Digital ===\n")
print(summary(twfe_sector))

## By individual sector (4 regressions)
sector_results <- lapply(unique(bds_sector_panel$naics_sector), function(s) {
  df_s <- bds_sector_panel %>% filter(naics_sector == s)
  m <- feols(log_fir ~ preempted | state_fip + year,
             data = df_s, cluster = ~state_fip)
  data.frame(
    sector = s,
    label = unique(df_s$sector_label),
    beta = coef(m)[1],
    se   = se(m)[1],
    p    = 2 * pnorm(-abs(coef(m)[1] / se(m)[1]))
  )
}) %>% bind_rows()

cat("\nSector-specific TWFE:\n")
print(sector_results)

saveRDS(list(twfe_sector=twfe_sector, sector_results=sector_results,
             bds_sector_panel=bds_sector_panel),
        "data/sector_results.rds")

cat("\n=== SECTOR ANALYSIS COMPLETE ===\n")
