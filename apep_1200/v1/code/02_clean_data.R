# 02_clean_data.R — Construct analysis-ready dataset
# APEP-1200: Swiss Mass Immigration Initiative Close-Vote RDD

source("00_packages.R")

cat("=== Constructing Analysis Dataset ===\n")

mii <- readRDS("../data/mii_votes.rds")
pop_raw <- readRDS("../data/bfs_population.rds")

# ---------------------------------------------------------------
# 1. Clean population data — extract municipality-level
# ---------------------------------------------------------------

cat("\n--- Cleaning population data ---\n")

# Rename columns for easier handling
names(pop_raw) <- c("year", "geo", "citizenship", "sex", "component", "population")

# Filter to municipalities only (those starting with "......")
pop_mun <- pop_raw %>%
  filter(grepl("^\\.{6}", geo)) %>%
  mutate(
    # Extract BFS municipality number from the label
    mun_id = as.integer(str_extract(geo, "\\d+")),
    mun_name_bfs = str_trim(str_remove(geo, "^\\.{6}\\d+\\s*")),
    year = as.integer(year),
    population = as.numeric(population),
    is_foreign = grepl("Foreign", citizenship, ignore.case = TRUE)
  )

cat("Municipal population observations:", nrow(pop_mun), "\n")
cat("Unique municipalities:", n_distinct(pop_mun$mun_id), "\n")
cat("Years:", paste(sort(unique(pop_mun$year)), collapse = ", "), "\n")

# Reshape: municipality × year with total and foreign population
pop_panel <- pop_mun %>%
  select(mun_id, mun_name_bfs, year, is_foreign, population) %>%
  mutate(type = ifelse(is_foreign, "pop_foreign", "pop_total")) %>%
  select(-is_foreign) %>%
  pivot_wider(names_from = type, values_from = population, values_fn = first)

# Compute foreign share
pop_panel <- pop_panel %>%
  mutate(
    foreign_share = pop_foreign / pop_total * 100,
    log_pop = log(pop_total)
  )

cat("\nPanel dimensions:", nrow(pop_panel), "obs,",
    n_distinct(pop_panel$mun_id), "municipalities,",
    length(unique(pop_panel$year)), "years\n")

# ---------------------------------------------------------------
# 2. Construct RDD outcomes: pre-post changes
# ---------------------------------------------------------------

cat("\n--- Computing pre-post changes ---\n")

# Pre-period: 2010-2013 (before Feb 2014 vote)
# Post-period: 2015-2018 (after vote, before 2017 implementation law effects settle)

pre <- pop_panel %>%
  filter(year >= 2010 & year <= 2013) %>%
  group_by(mun_id, mun_name_bfs) %>%
  summarise(
    pop_total_pre = mean(pop_total, na.rm = TRUE),
    pop_foreign_pre = mean(pop_foreign, na.rm = TRUE),
    foreign_share_pre = mean(foreign_share, na.rm = TRUE),
    .groups = "drop"
  )

post <- pop_panel %>%
  filter(year >= 2015 & year <= 2018) %>%
  group_by(mun_id, mun_name_bfs) %>%
  summarise(
    pop_total_post = mean(pop_total, na.rm = TRUE),
    pop_foreign_post = mean(pop_foreign, na.rm = TRUE),
    foreign_share_post = mean(foreign_share, na.rm = TRUE),
    .groups = "drop"
  )

outcomes <- inner_join(pre, post, by = c("mun_id", "mun_name_bfs")) %>%
  mutate(
    # Change in foreign population share (pp)
    delta_foreign_share = foreign_share_post - foreign_share_pre,
    # Change in total population (%)
    delta_pop_pct = (pop_total_post - pop_total_pre) / pop_total_pre * 100,
    # Change in foreign population (%)
    delta_foreign_pct = (pop_foreign_post - pop_foreign_pre) /
      pmax(pop_foreign_pre, 1) * 100,
    # Log population for controls
    log_pop_pre = log(pop_total_pre)
  )

cat("Outcome data:", nrow(outcomes), "municipalities\n")

# ---------------------------------------------------------------
# 3. Merge vote data with outcomes
# ---------------------------------------------------------------

cat("\n--- Merging vote and outcome data ---\n")

# Match on mun_id
analysis <- inner_join(mii, outcomes, by = "mun_id")

cat("Matched:", nrow(analysis), "municipalities\n")
cat("Unmatched vote records:", sum(!mii$mun_id %in% outcomes$mun_id), "\n")
cat("Unmatched pop records:", sum(!outcomes$mun_id %in% mii$mun_id), "\n")

# Drop municipalities with missing data
analysis <- analysis %>%
  filter(!is.na(yes_margin) & !is.na(delta_foreign_share) &
         !is.na(pop_total_pre) & pop_total_pre > 0)

cat("After dropping missing:", nrow(analysis), "municipalities\n")

# ---------------------------------------------------------------
# 4. Summary statistics
# ---------------------------------------------------------------

cat("\n=== Summary Statistics ===\n")
cat("Municipalities:", nrow(analysis), "\n")
cat("Mean yes-share:", round(mean(analysis$yes_pct), 1), "%\n")
cat("SD yes-share:", round(sd(analysis$yes_pct), 1), "%\n")
cat("Above 50%:", sum(analysis$above_50), "(", round(100*mean(analysis$above_50), 1), "%)\n")
cat("\nOutcomes:\n")
cat("  Mean pre foreign share:", round(mean(analysis$foreign_share_pre), 1), "%\n")
cat("  Mean post foreign share:", round(mean(analysis$foreign_share_post), 1), "%\n")
cat("  Mean change in foreign share:", round(mean(analysis$delta_foreign_share), 2), "pp\n")
cat("  SD change in foreign share:", round(sd(analysis$delta_foreign_share), 2), "pp\n")
cat("  Mean change in total pop:", round(mean(analysis$delta_pop_pct), 2), "%\n")

cat("\nBy treatment group:\n")
analysis %>%
  group_by(above_50) %>%
  summarise(
    n = n(),
    mean_yes = round(mean(yes_pct), 1),
    mean_foreign_pre = round(mean(foreign_share_pre), 1),
    mean_delta_foreign = round(mean(delta_foreign_share), 2),
    mean_delta_pop = round(mean(delta_pop_pct), 2),
    mean_pop = round(mean(pop_total_pre))
  ) %>%
  print()

# ---------------------------------------------------------------
# 5. Validate and save
# ---------------------------------------------------------------

stopifnot("Need at least 1000 municipalities" = nrow(analysis) >= 1000)
stopifnot("Need variation in forcing variable" = sd(analysis$yes_margin) > 5)

saveRDS(analysis, "../data/analysis.rds")
saveRDS(pop_panel, "../data/pop_panel.rds")
write.csv(analysis, "../data/analysis.csv", row.names = FALSE)

cat("\n✓ Analysis dataset saved:", nrow(analysis), "municipalities\n")
cat("=== Data cleaning complete ===\n")
