## 02_clean_data.R — Merge referendum + population, construct analysis panel
## apep_0864: Revealed Hostility

source("00_packages.R")

data_dir <- "../data"

# Load data
mei   <- readRDS(file.path(data_dir, "referendum_mei_2014.rds"))
fabi  <- readRDS(file.path(data_dir, "referendum_fabi_2014.rds"))
pop   <- readRDS(file.path(data_dir, "population_panel.rds"))

cat("=== Merging data ===\n")

# Merge referendum with population panel
# Inner join: only municipalities present in both datasets
panel <- pop |>
  inner_join(mei |> select(bfs_nr, yes_share, canton_id, canton_name, turnout, eligible),
             by = "bfs_nr") |>
  left_join(fabi |> select(bfs_nr, placebo_yes_share), by = "bfs_nr")

cat(sprintf("Merged panel: %d obs, %d municipalities\n",
            nrow(panel), n_distinct(panel$bfs_nr)))

# Construct key variables
panel <- panel |>
  mutate(
    post = as.integer(year >= 2015),  # Vote Feb 2014; first full post-vote year is 2015
    # Treatment intensity: standardized yes-share (mean 0, SD 1)
    yes_share_std = (yes_share - mean(yes_share)) / sd(yes_share),
    # Interaction terms
    treat_post = yes_share_std * post,
    # Log outcomes
    log_foreign = log(pmax(foreign, 1)),
    log_total = log(pmax(total, 1)),
    log_swiss = log(pmax(swiss, 1)),
    # Growth rates (for alternative outcome)
    foreign_growth = foreign / lag(foreign) - 1,
    # Pre-vote foreign share (2013 value for each municipality)
    pre_foreign_share = NA_real_,
    # Quartiles of yes share for heterogeneity
    yes_q = ntile(yes_share, 4),
    # Language region proxy from canton
    language = case_when(
      canton_id %in% c(22, 23, 24, 25, 26) ~ "French",  # GE, VD, VS, NE, JU
      canton_id %in% c(21) ~ "Italian",  # TI
      TRUE ~ "German"
    ),
    # Close vote band for RDD (within 48-52%)
    close_vote = (yes_share >= 0.48 & yes_share <= 0.52),
    majority_yes = as.integer(yes_share > 0.50),
    running_var = yes_share - 0.50
  )

# Fill in pre-vote foreign share
pre_shares <- panel |>
  filter(year == 2013) |>
  select(bfs_nr, pre_foreign_share_val = foreign_share)

panel <- panel |>
  left_join(pre_shares, by = "bfs_nr") |>
  mutate(pre_foreign_share = pre_foreign_share_val) |>
  select(-pre_foreign_share_val)

# Pre-vote total population (2013) for size controls
pre_pop <- panel |>
  filter(year == 2013) |>
  select(bfs_nr, pre_total = total)

panel <- panel |>
  left_join(pre_pop, by = "bfs_nr") |>
  mutate(log_pre_total = log(pmax(pre_total, 1)))

# Drop municipalities with missing key data
panel <- panel |>
  filter(!is.na(foreign_share), !is.na(yes_share), !is.na(pre_foreign_share))

cat(sprintf("Final panel: %d obs, %d municipalities, %d years\n",
            nrow(panel), n_distinct(panel$bfs_nr), n_distinct(panel$year)))

# Summary statistics
cat("\n=== Summary Statistics ===\n")
cat(sprintf("Foreign share: mean=%.3f, SD=%.3f\n",
            mean(panel$foreign_share), sd(panel$foreign_share)))
cat(sprintf("Yes share: mean=%.3f, SD=%.3f, range=[%.3f, %.3f]\n",
            mean(panel$yes_share), sd(panel$yes_share),
            min(panel$yes_share), max(panel$yes_share)))
cat(sprintf("Close-vote municipalities (48-52%%): %d\n",
            n_distinct(panel$bfs_nr[panel$close_vote])))

# Pre-trend check: quick visual on whether high-yes vs low-yes municipalities
# had different foreign share trends before 2014
cat("\n=== Pre-trend diagnostic ===\n")
pre_trends <- panel |>
  filter(year <= 2013) |>
  mutate(high_yes = yes_share > median(yes_share)) |>
  group_by(high_yes, year) |>
  summarize(mean_fs = mean(foreign_share), .groups = "drop")

cat("Mean foreign share by year, high vs low MEI-yes:\n")
pre_trends |>
  pivot_wider(names_from = high_yes, values_from = mean_fs,
              names_prefix = "high_yes_") |>
  mutate(diff = high_yes_TRUE - high_yes_FALSE) |>
  print()

saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
cat("\nSaved analysis panel.\n")
