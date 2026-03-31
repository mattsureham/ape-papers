# ============================================================================
# apep_1201: When the Anchor Drops
# 04_robustness.R - Robustness and heterogeneity checks
# ============================================================================

source("code/00_packages.R")

dt <- safe_read_parquet("data/derived/analysis_panel.parquet")
dt <- dt[!is.na(exit_next_year)]

small_branch_sample <- feols(
  exit_next_year ~ treated * post | branch_id + county_year_fe,
  data = dt[small_branch == 1],
  cluster = ~ county_id
)

drop_ap <- feols(
  exit_next_year ~ treated * post | branch_id + county_year_fe,
  data = dt[chain != "A_AND_P"],
  cluster = ~ county_id
)

only_2018 <- feols(
  exit_next_year ~ treated * post | branch_id + county_year_fe,
  data = dt[event_year == 2018],
  cluster = ~ county_id
)

deposits_only_positive <- feols(
  ln_deposits ~ treated * post | branch_id + county_year_fe,
  data = dt[deposits > 0],
  cluster = ~ county_id
)

distance_sample <- feols(
  exit_next_year ~ treated * post | branch_id + county_year_fe,
  data = dt[distance_miles <= 3 | treated == 1],
  cluster = ~ county_id
)

if (file.exists("tables/tab_robustness.tex")) {
  file.remove("tables/tab_robustness.tex")
}

etable(
  drop_ap,
  only_2018,
  deposits_only_positive,
  distance_sample,
  tex = TRUE,
  file = "tables/tab_robustness.tex",
  title = "Robustness Checks",
  dict = c("treated" = "Within 1 mile", "post" = "Post exit", "treated:post" = "Within 1 mile $\\times$ Post exit"),
  fitstat = ~ n + r2
)
insert_table_label("tables/tab_robustness.tex", "tab:robustness")

saveRDS(small_branch_sample, "data/derived/model_small_branch_sample.rds")
saveRDS(drop_ap, "data/derived/model_drop_ap.rds")
saveRDS(only_2018, "data/derived/model_only_2018.rds")
saveRDS(deposits_only_positive, "data/derived/model_deposits_positive.rds")
saveRDS(distance_sample, "data/derived/model_distance_sample.rds")

cat("Robustness analysis complete.\n")
