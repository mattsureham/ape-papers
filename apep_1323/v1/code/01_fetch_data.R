## 01_fetch_data.R — Fetch REAL data for Nigeria cashless policy paper
## APEP Working Paper apep_1323
##
## Strategy:
##   1. World Bank API — financial indicators for Nigeria + 10 peer countries
##   2. Google Trends (gtrendsR) — state-level search interest for e-payment terms
##   3. CBN website — try to download published e-payment datasets
##
## All data from real API sources. If a source fails, it fails loudly.

source("00_packages.R")

## Additional packages for this script
for (pkg in c("gtrendsR", "countrycode")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ============================================================
## 1. WORLD BANK DATA — Nigeria + Peer Countries
## ============================================================
cat("=== Fetching World Bank indicators ===\n")

## Countries: Nigeria (treated) + SSA peers (donors for SCM/DiD)
countries <- c("NGA", "GHA", "KEN", "ZAF", "TZA", "SEN", "CMR",
               "ETH", "UGA", "CIV", "RWA", "MOZ", "ZMB", "BWA")

## Key indicators for financial inclusion + economic activity
wb_indicators <- c(
  "FB.ATM.TOTL.P5",        # ATMs per 100,000 adults
  "FB.CBK.BRCH.P5",        # Bank branches per 100,000 adults
  "GC.TAX.TOTL.GD.ZS",     # Tax revenue (% GDP)
  "GC.REV.XGRT.GD.ZS",     # Revenue excluding grants (% GDP)
  "NY.GDP.MKTP.KD.ZG",     # GDP growth (annual %)
  "NY.GDP.PCAP.KD",         # GDP per capita (constant 2015 USD)
  "FP.CPI.TOTL.ZG",         # Inflation (annual %)
  "SP.POP.TOTL",             # Population
  "IT.CEL.SETS.P2",         # Mobile subscriptions per 100
  "IT.NET.USER.ZS",          # Internet users (% of population)
  "NE.TRD.GNFS.ZS",         # Trade (% GDP)
  "BX.KLT.DINV.WD.GD.ZS"    # FDI net inflows (% GDP)
)

country_str <- paste(countries, collapse = ";")
wb_all <- data.frame()

for (ind in wb_indicators) {
  url <- sprintf(
    "https://api.worldbank.org/v2/country/%s/indicator/%s?format=json&per_page=5000&date=2005:2022",
    country_str, ind
  )
  resp <- httr::GET(url, httr::timeout(30))

  if (httr::status_code(resp) != 200) {
    cat(sprintf("  FAILED: %s — HTTP %d\n", ind, httr::status_code(resp)))
    next
  }

  body <- httr::content(resp, as = "parsed")
  if (length(body) < 2 || is.null(body[[2]])) {
    cat(sprintf("  EMPTY: %s — no records\n", ind))
    next
  }

  rows <- lapply(body[[2]], function(x) {
    data.frame(
      country = x$country$id %||% NA_character_,
      country_name = x$country$value %||% NA_character_,
      indicator_id = x$indicator$id %||% NA_character_,
      year = as.integer(x$date),
      value = if (is.null(x$value)) NA_real_ else as.numeric(x$value),
      stringsAsFactors = FALSE
    )
  })
  df_ind <- bind_rows(rows)
  wb_all <- bind_rows(wb_all, df_ind)
  n_non_na <- sum(!is.na(df_ind$value))
  cat(sprintf("  OK: %s — %d obs (%d non-NA)\n", ind, nrow(df_ind), n_non_na))
}

stopifnot("World Bank data must have observations" = nrow(wb_all) > 0)

## Pivot to wide format (one column per indicator)
wb_wide <- wb_all %>%
  select(country, country_name, year, indicator_id, value) %>%
  pivot_wider(names_from = indicator_id, values_from = value) %>%
  arrange(country, year)

## Add treatment indicators
wb_wide <- wb_wide %>%
  mutate(
    nigeria = as.integer(country == "NG"),
    post_2012 = as.integer(year >= 2012),
    treated = nigeria * post_2012
  )

saveRDS(wb_wide, file.path(data_dir, "wb_panel.rds"))
cat(sprintf("\nWorld Bank panel: %d obs, %d countries, %d years\n",
            nrow(wb_wide), n_distinct(wb_wide$country), n_distinct(wb_wide$year)))

## Quick data quality check
nga_atm <- wb_wide %>% filter(country == "NG") %>%
  select(year, FB.ATM.TOTL.P5) %>%
  filter(!is.na(FB.ATM.TOTL.P5))
cat(sprintf("  Nigeria ATMs per 100k: %d years of data, range %.1f–%.1f\n",
            nrow(nga_atm),
            min(nga_atm$FB.ATM.TOTL.P5, na.rm = TRUE),
            max(nga_atm$FB.ATM.TOTL.P5, na.rm = TRUE)))

## ============================================================
## 2. GOOGLE TRENDS — State-level e-payment search interest
## ============================================================
cat("\n=== Fetching Google Trends data for Nigerian states ===\n")

## Nigerian states and their cashless policy wave assignment
states_waves <- tribble(
  ~state_name, ~geo_code, ~wave, ~treat_year,
  "Lagos",       "NG-LA", 1, 2012,
  "Rivers",      "NG-RI", 2, 2013,
  "Anambra",     "NG-AN", 2, 2013,
  "Abia",        "NG-AB", 2, 2013,
  "Kano",        "NG-KN", 2, 2013,
  "Ogun",        "NG-OG", 2, 2013,
  "FCT",         "NG-FC", 2, 2013,
  "Adamawa",     "NG-AD", 3, 2014,
  "Akwa Ibom",   "NG-AK", 3, 2014,
  "Bauchi",      "NG-BA", 3, 2014,
  "Bayelsa",     "NG-BY", 3, 2014,
  "Benue",       "NG-BE", 3, 2014,
  "Borno",       "NG-BO", 3, 2014,
  "Cross River", "NG-CR", 3, 2014,
  "Delta",       "NG-DE", 3, 2014,
  "Ebonyi",      "NG-EB", 3, 2014,
  "Edo",         "NG-ED", 3, 2014,
  "Ekiti",       "NG-EK", 3, 2014,
  "Enugu",       "NG-EN", 3, 2014,
  "Gombe",       "NG-GO", 3, 2014,
  "Imo",         "NG-IM", 3, 2014,
  "Jigawa",      "NG-JI", 3, 2014,
  "Kaduna",      "NG-KD", 3, 2014,
  "Katsina",     "NG-KT", 3, 2014,
  "Kebbi",       "NG-KE", 3, 2014,
  "Kogi",        "NG-KO", 3, 2014,
  "Kwara",       "NG-KW", 3, 2014,
  "Nasarawa",    "NG-NA", 3, 2014,
  "Niger",       "NG-NI", 3, 2014,
  "Ondo",        "NG-ON", 3, 2014,
  "Osun",        "NG-OS", 3, 2014,
  "Oyo",         "NG-OY", 3, 2014,
  "Plateau",     "NG-PL", 3, 2014,
  "Sokoto",      "NG-SO", 3, 2014,
  "Taraba",      "NG-TA", 3, 2014,
  "Yobe",        "NG-YO", 3, 2014,
  "Zamfara",     "NG-ZA", 3, 2014
)

cat(sprintf("  %d states: Wave 1=%d, Wave 2=%d, Wave 3=%d\n",
            nrow(states_waves),
            sum(states_waves$wave == 1),
            sum(states_waves$wave == 2),
            sum(states_waves$wave == 3)))

## Fetch Google Trends for e-payment related terms in Nigeria
## We query for "POS" + "mobile banking" + "bank transfer" in NG
## The resolution is by sub-region (state)

search_terms <- c("POS machine", "mobile banking", "bank transfer")
gt_data_list <- list()

for (term in search_terms) {
  cat(sprintf("  Fetching Google Trends: '%s' in Nigeria...\n", term))
  tryCatch({
    gt <- gtrends(
      keyword = term,
      geo = "NG",
      time = "2008-01-01 2019-12-31",
      onlyInterest = FALSE
    )

    ## Extract interest by region (state-level)
    if (!is.null(gt$interest_by_region) && nrow(gt$interest_by_region) > 0) {
      region_data <- gt$interest_by_region %>%
        mutate(search_term = term) %>%
        select(location, hits, search_term)
      gt_data_list[[term]] <- region_data
      cat(sprintf("    OK: %d regions with data\n", nrow(region_data)))
    } else {
      cat(sprintf("    WARNING: No regional data for '%s'\n", term))
    }

    ## Extract interest over time (monthly national)
    if (!is.null(gt$interest_over_time) && nrow(gt$interest_over_time) > 0) {
      time_data <- gt$interest_over_time %>%
        mutate(search_term = term)
      saveRDS(time_data, file.path(data_dir, sprintf("gt_time_%s.rds",
                                                       gsub(" ", "_", term))))
      cat(sprintf("    Time series: %d months\n", nrow(time_data)))
    }

    Sys.sleep(3)  # Rate limiting
  }, error = function(e) {
    cat(sprintf("    ERROR fetching '%s': %s\n", term, e$message))
  })
}

## Combine regional data
if (length(gt_data_list) > 0) {
  gt_regions <- bind_rows(gt_data_list) %>%
    mutate(hits = as.numeric(ifelse(hits == "<1", 0.5, hits)))

  ## Average across search terms per region
  gt_state <- gt_regions %>%
    group_by(location) %>%
    summarise(avg_hits = mean(hits, na.rm = TRUE), .groups = "drop") %>%
    arrange(desc(avg_hits))

  saveRDS(gt_regions, file.path(data_dir, "gt_regions.rds"))
  saveRDS(gt_state, file.path(data_dir, "gt_state_avg.rds"))
  cat(sprintf("\nGoogle Trends regional data: %d regions, %d terms\n",
              n_distinct(gt_regions$location), length(gt_data_list)))
} else {
  cat("\nWARNING: No Google Trends regional data obtained.\n")
}

## ============================================================
## 3. Google Trends TIME SERIES by region (annual aggregation)
## ============================================================
## To get state-year panel: query each term with time filter and
## aggregate monthly → annual

cat("\n=== Building state-year panel from Google Trends ===\n")

## For the staggered DiD we need state × year panel data
## Google Trends API gives monthly national time series +
## cross-sectional regional breakdown. We can combine these.

## We'll use the monthly national time series and allocate to states
## using the regional share. This gives state × month panel.

## First, get the national monthly time series for our main term
gt_panel <- NULL
main_term <- "POS"

cat(sprintf("  Fetching monthly time series for '%s' in Nigeria...\n", main_term))
tryCatch({
  gt_main <- gtrends(
    keyword = main_term,
    geo = "NG",
    time = "2008-01-01 2019-12-31"
  )

  if (!is.null(gt_main$interest_over_time) && nrow(gt_main$interest_over_time) > 0) {
    national_monthly <- gt_main$interest_over_time %>%
      mutate(
        date = as.Date(date),
        year = as.integer(format(date, "%Y")),
        hits = as.numeric(ifelse(hits == "<1", 0.5, hits))
      )

    ## Aggregate to annual
    national_annual <- national_monthly %>%
      group_by(year) %>%
      summarise(national_hits = mean(hits, na.rm = TRUE), .groups = "drop")

    saveRDS(national_monthly, file.path(data_dir, "gt_national_monthly.rds"))
    saveRDS(national_annual, file.path(data_dir, "gt_national_annual.rds"))
    cat(sprintf("    OK: %d months, %d years\n", nrow(national_monthly), nrow(national_annual)))

    ## Now get regional breakdown for sub-periods to construct state shares
    ## Query in sub-periods to get regional variation
    periods <- list(
      pre  = "2008-01-01 2011-12-31",
      w1   = "2012-01-01 2012-12-31",
      w2   = "2013-01-01 2013-12-31",
      w3   = "2014-01-01 2014-12-31",
      post1 = "2015-01-01 2016-12-31",
      post2 = "2017-01-01 2019-12-31"
    )

    region_panels <- list()
    for (pname in names(periods)) {
      cat(sprintf("    Fetching regional data for period: %s\n", pname))
      tryCatch({
        gt_p <- gtrends(keyword = main_term, geo = "NG", time = periods[[pname]])
        Sys.sleep(3)

        if (!is.null(gt_p$interest_by_region) && nrow(gt_p$interest_by_region) > 0) {
          rdata <- gt_p$interest_by_region %>%
            mutate(
              period = pname,
              hits = as.numeric(ifelse(hits == "<1", 0.5, hits))
            ) %>%
            select(location, hits, period)
          region_panels[[pname]] <- rdata
          cat(sprintf("      %d regions\n", nrow(rdata)))
        }
      }, error = function(e) {
        cat(sprintf("      ERROR: %s\n", e$message))
      })
    }

    if (length(region_panels) > 0) {
      gt_panel <- bind_rows(region_panels)
      saveRDS(gt_panel, file.path(data_dir, "gt_panel_periods.rds"))
      cat(sprintf("  Panel: %d region-period obs\n", nrow(gt_panel)))
    }
  }
}, error = function(e) {
  cat(sprintf("  ERROR: %s\n", e$message))
})

## ============================================================
## 4. Try fetching NBS data directly
## ============================================================
cat("\n=== Attempting NBS data download ===\n")

## Try multiple URL patterns for NBS IGR data
nbs_urls <- c(
  "https://nigerianstat.gov.ng/resource/IGR%20by%20States.xlsx",
  "https://nigerianstat.gov.ng/resource/IGR.xlsx",
  "https://nigerianstat.gov.ng/download/1142",
  "https://nigerianstat.gov.ng/resource/REVENUE_ALLOCATION.xlsx"
)

nbs_success <- FALSE
for (url in nbs_urls) {
  cat(sprintf("  Trying: %s\n", url))
  tryCatch({
    dest <- file.path(data_dir, "nbs_igr_raw.xlsx")
    resp <- httr::GET(url, httr::timeout(15),
                      httr::write_disk(dest, overwrite = TRUE))
    if (httr::status_code(resp) == 200 && file.size(dest) > 1000) {
      cat(sprintf("    SUCCESS: Downloaded %.0f KB\n", file.size(dest) / 1024))
      nbs_success <- TRUE
      ## Try to read it
      tryCatch({
        nbs_data <- readxl::read_excel(dest)
        cat(sprintf("    Read: %d rows, %d cols\n", nrow(nbs_data), ncol(nbs_data)))
        saveRDS(nbs_data, file.path(data_dir, "nbs_igr.rds"))
      }, error = function(e) {
        cat(sprintf("    Parse error: %s\n", e$message))
        nbs_success <<- FALSE
      })
      break
    } else {
      cat(sprintf("    HTTP %d or too small (%.0f bytes)\n",
                  httr::status_code(resp), file.size(dest)))
      file.remove(dest)
    }
  }, error = function(e) {
    cat(sprintf("    Error: %s\n", e$message))
  })
}

if (!nbs_success) {
  cat("  NBS direct download failed — will rely on WB + Google Trends data.\n")
}

## ============================================================
## 5. Try CBN e-payment statistics
## ============================================================
cat("\n=== Attempting CBN data download ===\n")

cbn_urls <- c(
  "https://www.cbn.gov.ng/out/2020/STD/1Q%202020%20Payment%20System%20Statistics.xlsx",
  "https://www.cbn.gov.ng/out/2019/STD/Payment%20Statistics.xlsx",
  "https://www.cbn.gov.ng/documents/data.asp"
)

cbn_success <- FALSE
for (url in cbn_urls) {
  cat(sprintf("  Trying: %s\n", url))
  tryCatch({
    dest <- file.path(data_dir, "cbn_epay_raw.xlsx")
    resp <- httr::GET(url, httr::timeout(15),
                      httr::write_disk(dest, overwrite = TRUE))
    if (httr::status_code(resp) == 200 && file.size(dest) > 1000) {
      cat(sprintf("    SUCCESS: Downloaded %.0f KB\n", file.size(dest) / 1024))
      cbn_success <- TRUE
      tryCatch({
        cbn_data <- readxl::read_excel(dest)
        cat(sprintf("    Read: %d rows, %d cols\n", nrow(cbn_data), ncol(cbn_data)))
        saveRDS(cbn_data, file.path(data_dir, "cbn_epay.rds"))
      }, error = function(e) {
        cat(sprintf("    Parse error: %s\n", e$message))
        cbn_success <<- FALSE
      })
      break
    } else {
      cat(sprintf("    HTTP %d or too small\n", httr::status_code(resp)))
      if (file.exists(dest)) file.remove(dest)
    }
  }, error = function(e) {
    cat(sprintf("    Error: %s\n", e$message))
  })
}

if (!cbn_success) {
  cat("  CBN direct download failed — will use WB financial indicators.\n")
}

## ============================================================
## 6. Save metadata and check data availability
## ============================================================
cat("\n=== Data availability summary ===\n")

has_wb <- file.exists(file.path(data_dir, "wb_panel.rds"))
has_gt_regions <- file.exists(file.path(data_dir, "gt_regions.rds"))
has_gt_national <- file.exists(file.path(data_dir, "gt_national_annual.rds"))
has_gt_panel <- !is.null(gt_panel) && nrow(gt_panel) > 0
has_nbs <- nbs_success
has_cbn <- cbn_success

cat(sprintf("  World Bank panel:         %s\n", ifelse(has_wb, "YES", "NO")))
cat(sprintf("  Google Trends regions:    %s\n", ifelse(has_gt_regions, "YES", "NO")))
cat(sprintf("  Google Trends national:   %s\n", ifelse(has_gt_national, "YES", "NO")))
cat(sprintf("  Google Trends state-time: %s\n", ifelse(has_gt_panel, "YES", "NO")))
cat(sprintf("  NBS IGR:                  %s\n", ifelse(has_nbs, "YES", "NO")))
cat(sprintf("  CBN e-payment:            %s\n", ifelse(has_cbn, "YES", "NO")))

## HARD GATE: We need at minimum the WB panel
if (!has_wb) {
  stop("FATAL: World Bank data fetch failed. Cannot proceed without any data.")
}

## For staggered DiD: need state-level variation
## For cross-country: WB panel is sufficient
if (!has_gt_panel && !has_nbs) {
  cat("\n  NOTE: No state-level panel data available.\n")
  cat("  Analysis will use cross-country DiD/SCM with World Bank data.\n")
  cat("  Nigeria (treated) vs SSA peers (control).\n")
}

saveRDS(states_waves, file.path(data_dir, "states_waves.rds"))

cat("\nData fetch complete.\n")
