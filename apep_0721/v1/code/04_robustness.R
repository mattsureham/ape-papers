## 04_robustness.R — Robustness checks
## apep_0721: UK NLW Wage Distribution Compression

source("00_packages.R")

cat("=== Loading data ===\n")
df <- readRDS("../data/analysis_dataset.rds")

# ============================================================================
# ROBUSTNESS 1: Alternative bite definitions
# ============================================================================
cat("\n=== Alternative bite: NLW as fraction of LA p25 (not p50) ===\n")

nmw_2015 <- 6.50
df <- df %>%
  group_by(la_code) %>%
  mutate(
    p25_2015 = p25[year == 2015][1],
    bite_p25 = nmw_2015 / p25_2015,
    bite_p25_post = bite_p25 * post
  ) %>%
  ungroup()

alt_bite <- feols(log_p10 ~ bite_p25_post | la_code + year, data = df, cluster = ~la_code)
cat(sprintf("Alt bite (p25): Bite×Post on log p10 = %.4f (SE: %.4f, p: %.4f)\n",
            coef(alt_bite)["bite_p25_post"], se(alt_bite)["bite_p25_post"],
            pvalue(alt_bite)["bite_p25_post"]))

# ============================================================================
# ROBUSTNESS 2: Exclude London and City of London (outliers)
# ============================================================================
cat("\n=== Excluding London boroughs ===\n")

# London boroughs have very different wage structures
london_codes <- df %>%
  filter(grepl("London|Westminster|Camden|Tower|Hackney|City of London", la_name)) %>%
  pull(la_code) %>%
  unique()

df_no_london <- df %>% filter(!la_code %in% london_codes)
cat(sprintf("Excluding %d London LAs (%d obs remaining)\n",
            length(london_codes), nrow(df_no_london)))

no_london_p10 <- feols(log_p10 ~ bite_post | la_code + year,
                        data = df_no_london, cluster = ~la_code)
no_london_p25 <- feols(log_p25 ~ bite_post | la_code + year,
                        data = df_no_london, cluster = ~la_code)

cat(sprintf("No London - p10: %.4f (SE: %.4f, p: %.4f)\n",
            coef(no_london_p10)["bite_post"], se(no_london_p10)["bite_post"],
            pvalue(no_london_p10)["bite_post"]))
cat(sprintf("No London - p25: %.4f (SE: %.4f, p: %.4f)\n",
            coef(no_london_p25)["bite_post"], se(no_london_p25)["bite_post"],
            pvalue(no_london_p25)["bite_post"]))

# ============================================================================
# ROBUSTNESS 3: Region × Year FE (absorb regional trends)
# ============================================================================
cat("\n=== Region × Year FE ===\n")

# Extract region from LA code (first character of ONS code)
df <- df %>%
  mutate(
    region = substr(la_code, 1, 3)
  )

reg_p10 <- feols(log_p10 ~ bite_post | la_code + region^year,
                  data = df, cluster = ~la_code)
reg_p25 <- feols(log_p25 ~ bite_post | la_code + region^year,
                  data = df, cluster = ~la_code)

cat(sprintf("Region×Year FE - p10: %.4f (SE: %.4f, p: %.4f)\n",
            coef(reg_p10)["bite_post"], se(reg_p10)["bite_post"],
            pvalue(reg_p10)["bite_post"]))
cat(sprintf("Region×Year FE - p25: %.4f (SE: %.4f, p: %.4f)\n",
            coef(reg_p25)["bite_post"], se(reg_p25)["bite_post"],
            pvalue(reg_p25)["bite_post"]))

# ============================================================================
# ROBUSTNESS 4: Placebo — pre-period trends
# ============================================================================
cat("\n=== Placebo: Pre-period (2013-2015) trends ===\n")

df_pre <- df %>% filter(year <= 2015) %>%
  mutate(
    placebo_post = as.integer(year >= 2015),
    bite_placebo = bite * placebo_post
  )

placebo_p10 <- feols(log_p10 ~ bite_placebo | la_code + year,
                      data = df_pre, cluster = ~la_code)
cat(sprintf("Placebo (pre-trends) p10: %.4f (SE: %.4f, p: %.4f)\n",
            coef(placebo_p10)["bite_placebo"], se(placebo_p10)["bite_placebo"],
            pvalue(placebo_p10)["bite_placebo"]))

# Save all robustness results
saveRDS(list(
  alt_bite_p10 = alt_bite,
  no_london_p10 = no_london_p10,
  no_london_p25 = no_london_p25,
  reg_fe_p10 = reg_p10,
  reg_fe_p25 = reg_p25,
  placebo_p10 = placebo_p10
), "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
