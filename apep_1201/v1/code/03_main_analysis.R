# ============================================================================
# apep_1201: When the Anchor Drops
# 03_main_analysis.R - Main econometric analysis
# ============================================================================

source("code/00_packages.R")

dt <- safe_read_parquet("data/derived/analysis_panel.parquet")
dt <- dt[!is.na(exit_next_year)]

stopifnot(nrow(dt) > 0L)

dt[, rel_year_factor := fifelse(rel_year < -5L, -5L, fifelse(rel_year > 3L, 3L, rel_year))]

main_exit <- feols(
  exit_next_year ~ i(rel_year, treated, ref = -1) | branch_id + county_year_fe,
  data = dt,
  cluster = ~ county_id
)

post_exit_3y <- feols(
  exit_within_3y ~ treated * post | branch_id + county_year_fe,
  data = dt[!is.na(exit_within_3y)],
  cluster = ~ county_id
)

post_exit <- feols(
  exit_next_year ~ treated * post | branch_id + county_year_fe,
  data = dt,
  cluster = ~ county_id
)

main_deposits <- feols(
  ln_deposits ~ i(rel_year, treated, ref = -1) | branch_id + county_year_fe,
  data = dt,
  cluster = ~ county_id
)

post_deposits <- feols(
  ln_deposits ~ treated * post | branch_id + county_year_fe,
  data = dt,
  cluster = ~ county_id
)

heterogeneity_small <- feols(
  exit_next_year ~ i(rel_year, treated * small_branch, ref = -1) | branch_id + county_year_fe,
  data = dt,
  cluster = ~ county_id
)

heterogeneity_distance <- feols(
  exit_next_year ~ i(rel_year, treated * distance_close, ref = -1) | branch_id + county_year_fe,
  data = dt,
  cluster = ~ county_id
)

if (file.exists("tables/tab_main_effects.tex")) {
  file.remove("tables/tab_main_effects.tex")
}

etable(
  post_exit,
  post_exit_3y,
  post_deposits,
  tex = TRUE,
  file = "tables/tab_main_effects.tex",
  title = "Main Post-Exit Effects",
  dict = c("treated" = "Within 1 mile", "post" = "Post exit", "treated:post" = "Within 1 mile $\\times$ Post exit"),
  fitstat = ~ n + r2
)
insert_table_label("tables/tab_main_effects.tex", "tab:main_effects")

event_table <- as.data.table(summary(main_exit)$coeftable, keep.rownames = "term")
event_table <- event_table[str_detect(term, ":treated$")]
event_table[, rel_year := as.integer(str_match(term, "rel_year::(-?\\d+):treated")[, 2])]
setorder(event_table, rel_year)
fwrite(event_table, "tables/event_study_exit.csv")

event_dep_table <- as.data.table(summary(main_deposits)$coeftable, keep.rownames = "term")
event_dep_table <- event_dep_table[str_detect(term, "treated::")]
event_dep_table[, rel_year := as.integer(str_extract(term, "-?\\d+"))]
setorder(event_dep_table, rel_year)
fwrite(event_dep_table, "tables/event_study_deposits.csv")

saveRDS(main_exit, "data/derived/model_main_exit.rds")
saveRDS(post_exit, "data/derived/model_post_exit.rds")
saveRDS(post_exit_3y, "data/derived/model_post_exit_3y.rds")
saveRDS(main_deposits, "data/derived/model_main_deposits.rds")
saveRDS(post_deposits, "data/derived/model_post_deposits.rds")
saveRDS(heterogeneity_small, "data/derived/model_heterogeneity_small.rds")
saveRDS(heterogeneity_distance, "data/derived/model_heterogeneity_distance.rds")

jsonlite::write_json(
  list(
    n_treated = uniqueN(dt[treated == 1, branch_id]),
    n_pre = length(unique(dt[rel_year < 0, year])),
    n_obs = nrow(dt)
  ),
  "data/diagnostics.json",
  auto_unbox = TRUE,
  pretty = TRUE
)

analysis_summary <- list(
  mean_exit_treated_pre = dt[treated == 1 & rel_year < 0, mean(exit_next_year, na.rm = TRUE)],
  mean_exit_control_pre = dt[treated == 0 & rel_year < 0, mean(exit_next_year, na.rm = TRUE)],
  mean_exit_treated_post = dt[treated == 1 & rel_year >= 0, mean(exit_next_year, na.rm = TRUE)],
  mean_exit_control_post = dt[treated == 0 & rel_year >= 0, mean(exit_next_year, na.rm = TRUE)],
  post_exit_beta = coef(post_exit)[["treated:post"]],
  post_exit_se = se(post_exit)[["treated:post"]],
  post_exit_3y_beta = coef(post_exit_3y)[["treated:post"]],
  post_exit_3y_se = se(post_exit_3y)[["treated:post"]],
  post_deposits_beta = coef(post_deposits)[["treated:post"]],
  post_deposits_se = se(post_deposits)[["treated:post"]]
)

jsonlite::write_json(analysis_summary, "data/derived/analysis_summary.json", auto_unbox = TRUE, pretty = TRUE)

cat("Main analysis complete.\n")
