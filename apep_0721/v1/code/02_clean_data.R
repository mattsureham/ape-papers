## 02_clean_data.R — Construct analysis dataset
## apep_0721: UK NLW Wage Distribution Compression

source("00_packages.R")

cat("=== Loading ASHE data ===\n")
ashe_wide <- readRDS("../data/ashe_wide.rds")

cat(sprintf("Raw: %d LA-year observations\n", nrow(ashe_wide)))

# Compute the bite ratio: NMW / LA median wage in 2015
# NMW in 2015 was £6.50 (adult rate, pre-NLW)
nmw_2015 <- 6.50

bite_2015 <- ashe_wide %>%
  filter(year == 2015) %>%
  mutate(
    bite = nmw_2015 / p50
  ) %>%
  select(la_code, la_name, bite, median_2015 = p50)

cat(sprintf("LAs with 2015 data for bite calculation: %d\n", nrow(bite_2015)))
cat(sprintf("Bite ratio: min=%.3f, max=%.3f, mean=%.3f, sd=%.3f\n",
            min(bite_2015$bite, na.rm = TRUE),
            max(bite_2015$bite, na.rm = TRUE),
            mean(bite_2015$bite, na.rm = TRUE),
            sd(bite_2015$bite, na.rm = TRUE)))

# Merge bite ratio into panel
analysis_df <- ashe_wide %>%
  inner_join(bite_2015 %>% select(la_code, bite, median_2015), by = "la_code") %>%
  mutate(
    # Log wages at each percentile
    log_p10 = log(p10),
    log_p25 = log(p25),
    log_p50 = log(p50),
    log_p60 = log(p60),
    log_p90 = log(p90),

    # Post-NLW indicator (April 2016 introduction)
    post = as.integer(year >= 2016),

    # Interaction: bite × post
    bite_post = bite * post,

    # Percentile ratios (wage compression measures)
    p10_p50 = p10 / p50,
    p25_p50 = p25 / p50,
    p10_p90 = p10 / p90,

    # Time trend
    trend = year - 2015,

    # Treatment intensity dummies for heterogeneity
    high_bite = as.integer(bite >= median(bite_2015$bite, na.rm = TRUE))
  )

# Drop LAs with missing core percentile data (p10, p25, p50 required; p60, p90 optional)
analysis_df <- analysis_df %>%
  filter(
    !is.na(log_p10), !is.na(log_p25), !is.na(log_p50),
    !is.na(bite)
  )

cat(sprintf("\n=== Analysis sample ===\n"))
cat(sprintf("Total observations: %d\n", nrow(analysis_df)))
cat(sprintf("Unique LAs: %d\n", n_distinct(analysis_df$la_code)))
cat(sprintf("Years: %d to %d\n", min(analysis_df$year), max(analysis_df$year)))
cat(sprintf("High-bite LAs: %d, Low-bite: %d\n",
            n_distinct(analysis_df$la_code[analysis_df$high_bite == 1]),
            n_distinct(analysis_df$la_code[analysis_df$high_bite == 0])))

# Summary statistics
cat(sprintf("\nWage percentiles (2015, pre-NLW):\n"))
pre_2015 <- analysis_df %>% filter(year == 2015)
for (p in c("p10", "p25", "p50", "p60", "p90")) {
  vals <- pre_2015[[p]]
  cat(sprintf("  %s: mean=£%.2f, sd=£%.2f\n", p, mean(vals, na.rm = TRUE), sd(vals, na.rm = TRUE)))
}

cat(sprintf("\nWage percentiles (2023, post-NLW):\n"))
post_2023 <- analysis_df %>% filter(year == 2023)
for (p in c("p10", "p25", "p50", "p60", "p90")) {
  vals <- post_2023[[p]]
  cat(sprintf("  %s: mean=£%.2f, sd=£%.2f\n", p, mean(vals, na.rm = TRUE), sd(vals, na.rm = TRUE)))
}

saveRDS(analysis_df, "../data/analysis_dataset.rds")
saveRDS(bite_2015, "../data/bite_2015.rds")

cat("\nAnalysis dataset saved.\n")
