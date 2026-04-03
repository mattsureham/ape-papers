# 01b_fetch_by_state.R — Download BR data for selected large states
# apep_1341: RCRA Hazardous Waste Generator Thresholds

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE)

# Download for largest 15 states by generator count
# (covers ~60% of US generators)
target_states <- c("CA", "TX", "NY", "OH", "PA", "IL", "MI", "NJ",
                   "FL", "IN", "NC", "WI", "MA", "GA", "MN")

batch_size <- 2000

for (state in target_states) {
  state_rds <- file.path(data_dir, sprintf("br_2023_%s.rds", state))
  if (file.exists(state_rds)) {
    cat(sprintf("Already have %s\n", state))
    next
  }

  cat(sprintf("Fetching %s...\n", state))
  all_chunks <- list()
  offset <- 0

  repeat {
    url <- sprintf(
      "https://data.epa.gov/efservice/BR_REPORTING/report_cycle/2023/activity_location/%s/ROWS/%d:%d/JSON",
      state, offset, offset + batch_size - 1)

    resp <- tryCatch(GET(url, timeout(180)), error = function(e) NULL)
    if (is.null(resp)) {
      Sys.sleep(10)
      resp <- tryCatch(GET(url, timeout(180)), error = function(e) NULL)
    }
    if (is.null(resp) || status_code(resp) != 200) {
      cat(sprintf("  Stopped at offset %d\n", offset))
      break
    }

    chunk <- tryCatch(fromJSON(content(resp, as="text", encoding="UTF-8")), error = function(e) NULL)
    if (is.null(chunk) || nrow(chunk) == 0) break

    keep_cols <- intersect(names(chunk),
      c("handler_id", "activity_location", "report_cycle",
        "generation_tons", "calculated_generator_status",
        "primary_naics", "source_code", "waste_code_group"))
    chunk <- chunk[, keep_cols, drop = FALSE]
    all_chunks[[length(all_chunks) + 1]] <- chunk

    n_total <- sum(sapply(all_chunks, nrow))
    if (offset %% 10000 == 0 || nrow(chunk) < batch_size) {
      cat(sprintf("  %s: %d rows, %d handlers\n", state, n_total,
          length(unique(bind_rows(all_chunks)$handler_id))))
    }

    if (nrow(chunk) < batch_size) break
    offset <- offset + batch_size
    Sys.sleep(0.5)
  }

  if (length(all_chunks) > 0) {
    state_data <- bind_rows(all_chunks)
    saveRDS(state_data, state_rds)
    cat(sprintf("  Saved %s: %d rows, %d handlers\n", state,
        nrow(state_data), length(unique(state_data$handler_id))))
  }
}

# Combine all state files with the original data
cat("\nCombining all data files...\n")
all_files <- c(
  list.files(data_dir, pattern = "br_2023_[A-Z]{2}\\.rds$", full.names = TRUE),
  list.files(data_dir, pattern = "br_20(19|21|23)_raw\\.rds$", full.names = TRUE)
)
cat("Files to combine:", length(all_files), "\n")

all_br <- bind_rows(lapply(all_files, readRDS))
# Deduplicate
all_br <- distinct(all_br, handler_id, report_cycle, generation_tons,
                   waste_code_group, source_code, .keep_all = TRUE)

cat("Combined: ", nrow(all_br), "rows,", length(unique(all_br$handler_id)), "handlers\n")
saveRDS(all_br, file.path(data_dir, "br_reporting_combined.rds"))

cat("\n01b_fetch_by_state.R complete.\n")
