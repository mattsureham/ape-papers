## 02_clean_data.R — Construct panel from ZH municipal finance + merger data
## apep_1165: Swiss Municipal Mergers and Functional Spending

source("00_packages.R")

data_dir <- "../data"

# ==============================================================================
# PART 1: Parse merger events
# ==============================================================================
cat("=== Parsing merger events ===\n")

mutations_raw <- jsonlite::fromJSON(file.path(data_dir, "mutations_all.json"))
mutations <- as.data.frame(mutations_raw, stringsAsFactors = FALSE)
names(mutations) <- c("mut_nr", "hist_nr", "canton", "district_nr",
                       "district_name", "bfs_nr", "municipality", "aufhebung", "aufnahme")

# Ensure bfs_nr is integer throughout
mutations$bfs_nr <- as.integer(mutations$bfs_nr)
mutations$mut_nr <- as.integer(mutations$mut_nr)

# Identify ZH mergers
zh_dissolved <- mutations %>%
  filter(canton == "ZH", aufhebung == "Aufhebung") %>%
  select(mut_nr, bfs_nr, municipality)

cat("ZH dissolved municipalities:", nrow(zh_dissolved), "\n")

# Find successor municipalities for each merger event
zh_successors <- mutations %>%
  filter(canton == "ZH",
         mut_nr %in% zh_dissolved$mut_nr,
         aufnahme %in% c("Neugründung", "Gebietsänderung")) %>%
  select(mut_nr, successor_bfs = bfs_nr, successor_name = municipality, aufnahme)

# Link dissolved -> successor
zh_mergers <- zh_dissolved %>%
  inner_join(zh_successors, by = "mut_nr", relationship = "many-to-many") %>%
  distinct()

cat("ZH merger linkages (dissolved -> successor):", nrow(zh_mergers), "\n")
cat("Unique merger events:", n_distinct(zh_mergers$mut_nr), "\n")

# Get merger years from mutation numbers (approximate from the sequence)
# Need to find when each merger happened - use the BFS mutation number timeline
# Mutations are chronologically ordered; we need dates
# For now, we'll extract merger year from the data panel (first year a dissolved
# municipality disappears or successor appears)

# ==============================================================================
# PART 2: Load Zurich functional spending data
# ==============================================================================
cat("\n=== Loading Zurich functional spending data ===\n")

# Function to read a ZH indicator CSV
read_zh_indicator <- function(indicator_id, data_dir) {
  fpath <- file.path(data_dir, paste0("zh_", indicator_id, ".csv"))
  df <- data.table::fread(fpath, encoding = "UTF-8")
  df
}

# Load all functional spending indicators
spending_ids <- c(420, 421, 422, 423, 424, 425, 426, 427, 428, 429)
spending_names <- c("administration", "education", "finance_taxes",
                     "health", "culture_sport", "public_order",
                     "social_security", "environment", "transport", "economy")

all_spending <- list()
for (i in seq_along(spending_ids)) {
  df <- read_zh_indicator(spending_ids[i], data_dir)
  df$function_name <- spending_names[i]
  df$indicator_id <- spending_ids[i]
  all_spending[[i]] <- df
}

spending_panel <- bind_rows(all_spending)
cat("Combined spending panel:", nrow(spending_panel), "rows\n")
cat("Columns:", paste(names(spending_panel), collapse = ", "), "\n")

# Standardize column names
spending_panel <- spending_panel %>%
  rename(
    bfs_nr = BFS_NR,
    muni_name = GEBIET_NAME,
    year = INDIKATOR_JAHR,
    value = INDIKATOR_VALUE
  ) %>%
  select(bfs_nr, muni_name, year, value, function_name, indicator_id)

# Check year range
cat("Year range:", min(spending_panel$year, na.rm = TRUE), "-",
    max(spending_panel$year, na.rm = TRUE), "\n")
cat("Unique municipalities:", n_distinct(spending_panel$bfs_nr), "\n")

# Convert value to numeric (might have "" or NA)
spending_panel$value <- as.numeric(spending_panel$value)

# ==============================================================================
# PART 3: Determine merger timing
# ==============================================================================
cat("\n=== Determining merger timing ===\n")

# A dissolved municipality disappears from the panel after its merger year.
# We detect the last year each dissolved BFS number appears in the spending data.
dissolved_bfs <- unique(zh_mergers$bfs_nr)

# Check which dissolved municipalities appear in the spending data
dissolved_in_panel <- spending_panel %>%
  filter(bfs_nr %in% dissolved_bfs, function_name == "administration") %>%
  group_by(bfs_nr, muni_name) %>%
  summarise(first_year = min(year, na.rm = TRUE),
            last_year = max(year, na.rm = TRUE),
            n_years = n(),
            .groups = "drop")

cat("Dissolved municipalities found in spending data:", nrow(dissolved_in_panel), "\n")
print(dissolved_in_panel)

# For municipalities that merged: merger_year = last_year + 1
# (the municipality exists until year T, then is dissolved effective year T+1)
merger_timing <- dissolved_in_panel %>%
  mutate(merger_year = last_year + 1) %>%
  select(bfs_nr, muni_name, merger_year, first_year, last_year)

# Also identify successor municipalities
successor_bfs <- unique(zh_mergers$successor_bfs)
successor_in_panel <- spending_panel %>%
  filter(bfs_nr %in% successor_bfs, function_name == "administration") %>%
  group_by(bfs_nr, muni_name) %>%
  summarise(first_year = min(year, na.rm = TRUE),
            last_year = max(year, na.rm = TRUE),
            .groups = "drop")

cat("\nSuccessor municipalities in panel:", nrow(successor_in_panel), "\n")

# ==============================================================================
# PART 4: Construct analysis panel
# ==============================================================================
cat("\n=== Constructing analysis panel ===\n")

# Strategy: Track SUCCESSOR municipalities in the post-merger period.
# Pre-merger: sum or average the spending of constituent municipalities.
# Post-merger: use the successor's spending directly.
#
# For the DiD: compare successor municipalities (pre = constituent average, post = actual)
# against never-merged municipalities.

# Identify never-merged municipalities (present in data, never dissolved)
all_bfs_in_panel <- spending_panel %>%
  filter(function_name == "administration") %>%
  distinct(bfs_nr) %>%
  pull(bfs_nr)

never_merged_bfs <- setdiff(all_bfs_in_panel, c(dissolved_bfs, successor_bfs))
cat("Never-merged municipalities:", length(never_merged_bfs), "\n")

# But some successors appear in the panel throughout — they just absorbed others
# For the DiD, we track successors that:
# 1) Exist in the panel both before and after the merger
# 2) Have sufficient pre-treatment data

# Link merger timing to successors
merger_link <- zh_mergers %>%
  mutate(bfs_nr = as.integer(bfs_nr),
         successor_bfs = as.integer(successor_bfs)) %>%
  left_join(merger_timing %>% select(bfs_nr, merger_year), by = "bfs_nr") %>%
  group_by(mut_nr, successor_bfs, successor_name) %>%
  summarise(
    merger_year = max(merger_year, na.rm = TRUE),
    n_dissolved = n(),
    dissolved_names = paste(municipality, collapse = "; "),
    .groups = "drop"
  ) %>%
  filter(is.finite(merger_year))

cat("\nMerger events with timing:", nrow(merger_link), "\n")
print(merger_link %>% select(successor_bfs, successor_name, merger_year, n_dissolved))

# Check that successors appear in spending data
successors_with_data <- merger_link %>%
  filter(successor_bfs %in% all_bfs_in_panel)

cat("\nSuccessors with spending data:", nrow(successors_with_data), "\n")

# ==============================================================================
# PART 5: Build the final panel
# ==============================================================================
cat("\n=== Building final panel ===\n")

# For the DiD, we need:
# - municipality i, year t, spending by function
# - treated = 1 if municipality is a merger successor
# - first_treat = merger year (for C&S)
# - Controls: never-merged municipalities

# Successor panel: all years for successor BFS numbers
successor_panel <- spending_panel %>%
  filter(bfs_nr %in% successors_with_data$successor_bfs) %>%
  left_join(
    successors_with_data %>% select(successor_bfs, merger_year, n_dissolved),
    by = c("bfs_nr" = "successor_bfs")
  ) %>%
  mutate(
    treated = 1,
    first_treat = merger_year
  )

# Control panel: all years for never-merged municipalities
control_panel <- spending_panel %>%
  filter(bfs_nr %in% never_merged_bfs) %>%
  mutate(
    treated = 0,
    first_treat = 0,  # Never treated (for C&S)
    merger_year = NA_real_,
    n_dissolved = 0
  )

# Combine
panel <- bind_rows(successor_panel, control_panel) %>%
  arrange(bfs_nr, function_name, year) %>%
  mutate(
    post = ifelse(treated == 1 & year >= merger_year, 1, 0)
  )

cat("Final panel:", nrow(panel), "rows\n")
cat("Treated municipalities:", n_distinct(panel$bfs_nr[panel$treated == 1]), "\n")
cat("Control municipalities:", n_distinct(panel$bfs_nr[panel$treated == 0]), "\n")
cat("Year range:", min(panel$year), "-", max(panel$year), "\n")
cat("Functions:", n_distinct(panel$function_name), "\n")

# Panel balance check
panel_balance <- panel %>%
  filter(function_name == "administration") %>%
  group_by(bfs_nr) %>%
  summarise(n_years = n(), .groups = "drop")

cat("\nPanel balance (administration):\n")
cat("  Mean years per municipality:", round(mean(panel_balance$n_years), 1), "\n")
cat("  Min:", min(panel_balance$n_years), " Max:", max(panel_balance$n_years), "\n")

# Save
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
saveRDS(merger_link, file.path(data_dir, "merger_events.rds"))
saveRDS(merger_timing, file.path(data_dir, "merger_timing.rds"))

cat("\n=== Panel construction complete ===\n")

# Summary statistics
cat("\nMerger cohort distribution:\n")
cohort_dist <- successors_with_data %>%
  count(merger_year) %>%
  arrange(merger_year)
print(cohort_dist)
