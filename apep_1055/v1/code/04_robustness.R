## 04_robustness.R — Robustness checks and placebo tests
## apep_1055: USPS Mail Slowdown and Preventable Hospitalizations

source("00_packages.R")

data_dir <- "../data/"
df <- readRDS(file.path(data_dir, "analysis_clean.rds"))

cat("=== Robustness Checks ===\n")

# ============================================================================
# 1. DOSE-RESPONSE — Separate effects by treatment intensity
# ============================================================================
cat("\n--- Dose-response: 1-day vs 2-day slowdown ---\n")

df <- df %>%
  mutate(
    slow_1day = as.integer(mail_slowdown == 1),
    slow_2day = as.integer(mail_slowdown >= 2)
  )

r1 <- feols(
  prev_hosp_rate ~ slow_1day:post + slow_2day:post | fips + year,
  data = df,
  cluster = ~state
)
summary(r1)

# ============================================================================
# 2. BALANCED PANEL ONLY
# ============================================================================
cat("\n--- Balanced panel subsample ---\n")

r2 <- feols(
  prev_hosp_rate ~ mail_slowdown:post + mail_slowdown:post:pharm_desert +
    pharm_desert:post | fips + year,
  data = df %>% filter(balanced),
  cluster = ~state
)
summary(r2)

# ============================================================================
# 3. ALTERNATIVE PHARMACY DESERT DEFINITIONS
# ============================================================================
cat("\n--- Alternative pharmacy desert cutoffs ---\n")

# Tercile-based desert (bottom tercile)
if ("pharmacies_per_10k" %in% names(df) && sum(!is.na(df$pharmacies_per_10k)) > 500) {
  q33 <- quantile(df$pharmacies_per_10k[df$year == min(df$year)], 0.33, na.rm = TRUE)
  df$pharm_desert_t <- as.integer(df$pharmacies_per_10k <= q33)

  r3 <- feols(
    prev_hosp_rate ~ mail_slowdown:post + mail_slowdown:post:pharm_desert_t +
      pharm_desert_t:post | fips + year,
    data = df,
    cluster = ~state
  )
  summary(r3)
} else {
  cat("  Skipped — pharmacy per capita data not available for alternative cutoffs\n")
  # Use distance-based alternative instead
  df$pharm_desert_dist <- as.integer(df$dist_to_pdc > median(df$dist_to_pdc, na.rm = TRUE))

  r3 <- feols(
    prev_hosp_rate ~ mail_slowdown:post + mail_slowdown:post:pharm_desert_dist +
      pharm_desert_dist:post | fips + year,
    data = df,
    cluster = ~state
  )
  summary(r3)
}

# ============================================================================
# 4. PLACEBO OUTCOME — Motor Vehicle Deaths (should NOT respond)
# ============================================================================
cat("\n--- Placebo: Motor vehicle deaths ---\n")

# County Health Rankings also has motor vehicle death rate (measure 039)
# If mail slowdown drives hospitalizations through prescription adherence,
# it should NOT affect motor vehicle deaths

# Check if we already have this variable, else we'll skip with a note
# CHR data may include this — check available columns
chr_2019 <- tryCatch(
  {
    f <- file.path(data_dir, "chr_2019.csv")
    if (file.exists(f)) {
      tmp <- read.csv(f, header = TRUE, stringsAsFactors = FALSE, check.names = FALSE)
      if (nrow(tmp) > 0 && is.na(suppressWarnings(as.numeric(tmp[1, 1])))) {
        tmp <- tmp[-1, ]
      }
      tmp
    } else NULL
  },
  error = function(e) NULL
)

placebo_available <- FALSE

if (!is.null(chr_2019)) {
  # Look for motor vehicle crash death rate column
  mv_col <- grep("motor.*vehicle.*death|MV.*mortality|039.*raw", names(chr_2019),
                  ignore.case = TRUE, value = TRUE)[1]

  if (!is.na(mv_col)) {
    # Build a panel of motor vehicle deaths across years
    placebo_panel <- list()

    for (yr in unique(df$year)) {
      chr_file <- file.path(data_dir, sprintf("chr_%d.csv", yr))
      if (file.exists(chr_file)) {
        tmp <- tryCatch({
          d <- read.csv(chr_file, header = TRUE, stringsAsFactors = FALSE, check.names = FALSE)
          if (nrow(d) > 0 && is.na(suppressWarnings(as.numeric(d[1, 1])))) {
            d <- d[-1, ]
          }
          mv_c <- grep("motor.*vehicle.*death|MV.*mortality|039.*raw", names(d),
                        ignore.case = TRUE, value = TRUE)[1]
          fips_c <- grep("^FIPS$|^fipscode$|^5-digit FIPS", names(d), ignore.case = TRUE, value = TRUE)[1]
          if (is.na(fips_c)) fips_c <- names(d)[1]

          if (!is.na(mv_c)) {
            data.frame(
              fips = sprintf("%05d", as.integer(d[[fips_c]])),
              year = yr,
              mv_death_rate = as.numeric(d[[mv_c]]),
              stringsAsFactors = FALSE
            ) %>% filter(!is.na(mv_death_rate), nchar(fips) == 5)
          } else NULL
        }, error = function(e) NULL)

        if (!is.null(tmp) && nrow(tmp) > 0) {
          placebo_panel[[as.character(yr)]] <- tmp
        }
      }
    }

    if (length(placebo_panel) >= 3) {
      placebo_df <- bind_rows(placebo_panel)
      df_placebo <- df %>%
        left_join(placebo_df, by = c("fips", "year")) %>%
        filter(!is.na(mv_death_rate))

      if (nrow(df_placebo) > 1000) {
        r4 <- feols(
          mv_death_rate ~ mail_slowdown:post | fips + year,
          data = df_placebo,
          cluster = ~state
        )
        cat("Placebo test (motor vehicle deaths):\n")
        summary(r4)
        placebo_available <- TRUE
      }
    }
  }
}

if (!placebo_available) {
  cat("  Motor vehicle death data not available — using pre-period placebo instead\n")
  # Alternative placebo: fake treatment in 2020 (pre-actual-treatment)
  df_pre <- df %>% filter(year <= 2021) %>%
    mutate(fake_post = as.integer(year >= 2020))

  r4 <- feols(
    prev_hosp_rate ~ mail_slowdown:fake_post | fips + year,
    data = df_pre,
    cluster = ~state
  )
  cat("Pre-period placebo test (fake treatment 2020):\n")
  summary(r4)
}

# ============================================================================
# 5. WILD CLUSTER BOOTSTRAP
# ============================================================================
cat("\n--- Wild cluster bootstrap ---\n")

# Main specification with WCB inference (50 state clusters)
m_main <- feols(
  prev_hosp_rate ~ mail_slowdown:post | fips + year,
  data = df,
  cluster = ~state
)

wcb <- tryCatch(
  {
    boot_result <- boottest(
      m_main,
      param = "mail_slowdown:post",
      B = 9999,
      clustid = "state",
      type = "webb"
    )
    cat("Wild cluster bootstrap results:\n")
    print(summary(boot_result))
    boot_result
  },
  error = function(e) {
    cat(sprintf("  WCB error: %s\n", e$message))
    cat("  Falling back to HC1 standard errors\n")
    NULL
  }
)

# ============================================================================
# 6. HETEROGENEITY BY DISTANCE QUARTILE
# ============================================================================
cat("\n--- Heterogeneity by distance quartile ---\n")

r6 <- feols(
  prev_hosp_rate ~ i(dist_quartile, post, ref = 1) | fips + year,
  data = df,
  cluster = ~state
)
summary(r6)

# ============================================================================
# 7. EXCLUDING COVID YEAR (2020)
# ============================================================================
cat("\n--- Excluding 2020 (COVID disruption) ---\n")

r7 <- feols(
  prev_hosp_rate ~ mail_slowdown:post + mail_slowdown:post:pharm_desert +
    pharm_desert:post | fips + year,
  data = df %>% filter(year != 2020),
  cluster = ~state
)
summary(r7)

# ============================================================================
# 8. POPULATION-WEIGHTED REGRESSION
# ============================================================================
cat("\n--- Population-weighted ---\n")

r8 <- feols(
  prev_hosp_rate ~ mail_slowdown:post + mail_slowdown:post:pharm_desert +
    pharm_desert:post | fips + year,
  data = df,
  cluster = ~state,
  weights = ~population
)
summary(r8)

# ============================================================================
# SAVE ROBUSTNESS RESULTS
# ============================================================================
cat("\n=== Saving robustness results ===\n")

robust_results <- list(
  dose_response = r1,
  balanced_panel = r2,
  alt_desert = r3,
  placebo = r4,
  wcb = wcb,
  distance_het = r6,
  no_covid = r7,
  pop_weighted = r8
)

saveRDS(robust_results, file.path(data_dir, "robust_results.rds"))
cat("✓ Robustness results saved\n")
