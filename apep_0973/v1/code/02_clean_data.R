## 02_clean_data.R — Construct analysis panel
## APEP-0973: Plastic Bag Charges and Beach Litter

source("00_packages.R")
setwd(file.path(here::here(), "output", "apep_0973", "v1"))

uk <- readRDS("data/uk_beach_litter.rds")

cat("=== Constructing Analysis Panel ===\n")

# Collapse to beach-year level (some beaches have multiple surveys per year)
panel <- uk |>
  group_by(beach_id, beach_name, nation, treat_year, year, beach_num) |>
  summarize(
    n_surveys = n(),
    bags = mean(total_bags, na.rm = TRUE),
    carrier_bags = mean(bags, na.rm = TRUE),  # carrier bags only (code 2)
    total_litter = mean(total_litter, na.rm = TRUE),
    nonbag_litter = mean(nonbag_litter, na.rm = TRUE),
    plastic_bottles = mean(plastic_bottles, na.rm = TRUE),
    plastic_food = mean(plastic_food, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    post = ifelse(year >= treat_year, 1L, 0L),
    # Log transformations
    log_bags = log(bags + 1),
    log_total = log(total_litter + 1),
    log_nonbag = log(nonbag_litter + 1),
    # IHS transformations
    ihs_bags = log(bags + sqrt(bags^2 + 1)),
    # Bag share of total litter
    bag_share = ifelse(total_litter > 0, bags / total_litter, 0),
    # For did package
    gname = as.integer(treat_year),
    tname = as.integer(year),
    idname = as.integer(beach_num)
  )

cat(sprintf("  Panel: %d beach-year obs, %d beaches, %d years\n",
            nrow(panel), n_distinct(panel$beach_id), n_distinct(panel$year)))

# Summary statistics
cat("\n=== Summary Statistics ===\n")

summ <- panel |>
  group_by(nation, post = ifelse(year >= treat_year, "Post", "Pre")) |>
  summarize(
    mean_bags = mean(bags, na.rm = TRUE),
    sd_bags = sd(bags, na.rm = TRUE),
    mean_total = mean(total_litter, na.rm = TRUE),
    mean_nonbag = mean(nonbag_litter, na.rm = TRUE),
    mean_bag_share = mean(bag_share, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

print(summ)

# Overall pre-treatment SDs (for SDE)
pre_panel <- panel |> filter(year < treat_year)
cat(sprintf("\nPre-treatment SD(log_bags): %.3f\n", sd(pre_panel$log_bags, na.rm = TRUE)))
cat(sprintf("Pre-treatment SD(bag_share): %.4f\n", sd(pre_panel$bag_share, na.rm = TRUE)))
cat(sprintf("Pre-treatment SD(log_total): %.3f\n", sd(pre_panel$log_total, na.rm = TRUE)))

# Check balance
cat("\n=== Panel Balance Check ===\n")
unit_counts <- panel |> count(beach_id)
cat(sprintf("  Min years per beach: %d, Max: %d, Median: %d\n",
            min(unit_counts$n), max(unit_counts$n), median(unit_counts$n)))

saveRDS(panel, "data/analysis_panel.rds")
cat("\n=== Analysis panel saved ===\n")
