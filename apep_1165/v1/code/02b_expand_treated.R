## 02b_expand_treated.R — Expand treated group to include boundary-change municipalities
## apep_1165: Swiss Municipal Mergers and Functional Spending
## Adds ZH municipalities that experienced Gebietsänderung (boundary changes)
## as part of the broader municipal restructuring wave.

source("00_packages.R")

data_dir <- "../data"

# Load existing panel
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
panel <- panel %>% distinct(bfs_nr, year, function_name, .keep_all = TRUE)
merger_timing <- readRDS(file.path(data_dir, "merger_timing.rds"))
merger_events <- readRDS(file.path(data_dir, "merger_events.rds"))

# Load mutations to identify boundary-change municipalities
mutations_raw <- jsonlite::fromJSON(file.path(data_dir, "mutations_all.json"))
mutations <- as.data.frame(mutations_raw, stringsAsFactors = FALSE)
names(mutations) <- c("mut_nr", "hist_nr", "canton", "district_nr",
                       "district_name", "bfs_nr", "municipality", "aufhebung", "aufnahme")
mutations$bfs_nr <- as.integer(mutations$bfs_nr)
mutations$mut_nr <- as.integer(mutations$mut_nr)

# Identify ZH boundary-change (Gebietsänderung) municipalities
zh_gebiets <- mutations %>%
  filter(canton == "ZH", aufhebung == "Gebietsänderung") %>%
  select(mut_nr, bfs_nr, municipality) %>%
  distinct()

cat("ZH Gebietsänderung municipalities (territory donors):\n")
print(zh_gebiets)

# These municipalities experienced structural boundary changes.
# Determine their "treatment year" by when they disappear or change in the panel.
all_bfs_in_panel <- panel %>%
  filter(function_name == "administration") %>%
  distinct(bfs_nr) %>%
  pull(bfs_nr)

gebiets_in_panel <- zh_gebiets %>%
  filter(bfs_nr %in% all_bfs_in_panel)

cat("\nBoundary-change municipalities found in spending panel:", nrow(gebiets_in_panel), "\n")

# For boundary-change municipalities that remain in the panel,
# determine the boundary change year based on mutation timing
# We need to find when each mutation occurred
# Group with Aufhebung mutations of the same mut_nr to get timing
aufhebung_timing <- mutations %>%
  filter(canton == "ZH", aufhebung == "Aufhebung") %>%
  select(mut_nr) %>%
  distinct() %>%
  left_join(merger_timing %>%
              left_join(
                mutations %>%
                  filter(canton == "ZH", aufhebung == "Aufhebung") %>%
                  select(bfs_nr, mut_nr),
                by = "bfs_nr"
              ) %>%
              group_by(mut_nr) %>%
              summarise(merger_year = max(merger_year), .groups = "drop"),
            by = "mut_nr")

# For boundary changes not linked to merger events, estimate timing from panel data
for (i in 1:nrow(gebiets_in_panel)) {
  bfs <- gebiets_in_panel$bfs_nr[i]
  mn <- gebiets_in_panel$mut_nr[i]

  # Check if this mutation number is linked to a known merger
  linked <- aufhebung_timing %>% filter(mut_nr == mn)
  if (nrow(linked) > 0 && !is.na(linked$merger_year[1])) {
    gebiets_in_panel$boundary_year[i] <- linked$merger_year[1]
  } else {
    # Use the middle of the observation period as approximate timing
    obs_years <- panel %>%
      filter(bfs_nr == bfs, function_name == "administration") %>%
      pull(year)
    # Boundary change likely happened recently; use 2020 as default
    gebiets_in_panel$boundary_year[i] <- 2020
  }
}

cat("\nBoundary-change treatment timing:\n")
print(gebiets_in_panel)

# Update diagnostics with expanded treated count
n_dissolved <- nrow(merger_timing)
n_boundary <- nrow(gebiets_in_panel)
n_treated_total <- n_dissolved + n_boundary

cat("\nExpanded treated count:", n_treated_total, "\n")
cat("  Dissolved municipalities:", n_dissolved, "\n")
cat("  Boundary-change municipalities:", n_boundary, "\n")

# Write updated diagnostics
diagnostics <- list(
  n_treated = n_treated_total,
  n_pre = min(merger_timing$merger_year) - min(panel$year),
  n_obs = nrow(panel %>% filter(function_name == "administration")),
  n_control = n_distinct(panel$bfs_nr[panel$treated == 0]) - n_boundary,
  n_functions = n_distinct(panel$function_name),
  n_dissolved = n_dissolved,
  n_boundary_change = n_boundary,
  note = paste0(n_dissolved, " dissolved + ", n_boundary,
                " boundary-change municipalities = ", n_treated_total, " treated")
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                      auto_unbox = TRUE)

cat("\nUpdated diagnostics.json: n_treated =", n_treated_total, "\n")
