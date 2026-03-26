## 01b_retry_gtrends.R — Retry rate-limited Google Trends queries
source("00_packages.R")

existing <- readRDS("../data/gtrends_monthly.rds")
all_states <- readRDS("../data/all_states.rds")

# States we already have
got_states <- unique(existing$state_abbr)
# States still needed (rate-limited or no data — skip true zero-volume states)
zero_vol <- c("ID", "MT", "SD", "VT", "WY")  # genuinely low-volume
need_states <- setdiff(all_states$state_abbr, c(got_states, zero_vol))

cat(sprintf("Already have: %d states\nNeed: %d states (%s)\n",
            length(got_states), length(need_states), paste(need_states, collapse=", ")))

if (length(need_states) == 0) {
  cat("All states fetched. Nothing to retry.\n")
  quit(save = "no")
}

new_results <- list()
for (i in seq_along(need_states)) {
  st <- need_states[i]
  geo_code <- paste0("US-", st)
  cat(sprintf("  [%d/%d] Retrying %s...", i, length(need_states), st))

  tryCatch({
    res <- gtrends("catalytic converter theft", geo = geo_code,
                   time = "2017-01-01 2025-12-31", gprop = "web",
                   low_search_volume = TRUE)
    if (!is.null(res$interest_over_time) && nrow(res$interest_over_time) > 0) {
      df <- res$interest_over_time %>%
        mutate(hits = as.numeric(ifelse(hits == "<1", "0.5", hits)),
               state_abbr = st, date = as.Date(date)) %>%
        select(date, hits, state_abbr)
      new_results[[st]] <- df
      cat(sprintf(" %d obs\n", nrow(df)))
    } else {
      cat(" NO DATA\n")
    }
  }, error = function(e) cat(sprintf(" ERROR: %s\n", e$message)))

  Sys.sleep(12)  # longer delay to avoid 429
}

if (length(new_results) > 0) {
  new_df <- bind_rows(new_results)
  combined <- bind_rows(existing, new_df)
  saveRDS(combined, "../data/gtrends_monthly.rds")

  # Rebuild quarterly
  gtrends_quarterly <- combined %>%
    mutate(year = year(date), quarter = quarter(date),
           yq = paste0(year, "Q", quarter)) %>%
    group_by(state_abbr, year, quarter, yq) %>%
    summarise(search_index = mean(hits, na.rm = TRUE),
              n_months = n(), .groups = "drop")
  saveRDS(gtrends_quarterly, "../data/gtrends_quarterly.rds")
  cat(sprintf("\nUpdated: %d total states, %d state-quarter obs\n",
              n_distinct(combined$state_abbr), nrow(gtrends_quarterly)))
} else {
  cat("\nNo new data retrieved.\n")
}
