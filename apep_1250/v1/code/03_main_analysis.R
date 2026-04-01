source("code/00_packages.R")

ensure_dir("data/results")

panel <- read_csv("data/derived/analysis_panel.csv", show_col_types = FALSE)

main_ddd <- feols(
  diff_y ~ loans_per_1000:post | la_code + quarter_id,
  data = panel,
  cluster = ~region
)

private_did <- feols(
  log_private ~ loans_per_1000:post | la_code + quarter_id,
  data = panel,
  cluster = ~region
)

mortgage_did <- feols(
  log_mortgage ~ loans_per_1000:post | la_code + quarter_id,
  data = panel,
  cluster = ~region
)

event_study <- feols(
  diff_y ~ i(rel_year, loans_per_1000, ref = -1) | la_code + quarter_id,
  data = panel,
  cluster = ~region
)

event_coefs <- {
  ct <- as.data.frame(coeftable(event_study))
  ct$term <- rownames(ct)
  as_tibble(ct)
} |>
  filter(str_detect(term, "rel_year::")) |>
  mutate(
    rel_year = as.integer(str_extract(term, "-?\\d+")),
    p_value = `Pr(>|t|)`
  ) |>
  transmute(rel_year, estimate = Estimate, std.error = `Std. Error`, p_value)

main_results <- tibble(
  model = c("ddd_diff", "private_only", "mortgage_only"),
  estimate = c(coef(main_ddd)[1], coef(private_did)[1], coef(mortgage_did)[1]),
  std_error = c(se(main_ddd)[1], se(private_did)[1], se(mortgage_did)[1]),
  p_value = c(pvalue(main_ddd)[1], pvalue(private_did)[1], pvalue(mortgage_did)[1])
)

treated_cut <- median(distinct(panel, la_code, loans_per_1000)$loans_per_1000, na.rm = TRUE)

diagnostics <- list(
  n_treated = n_distinct(panel$la_code[panel$loans_per_1000 >= treated_cut]),
  n_pre = n_distinct(panel$quarter_id[panel$post == 0]),
  n_obs = nrow(panel),
  n_regions = n_distinct(panel$region),
  n_las = n_distinct(panel$la_code)
)

saveRDS(
  list(
    main_ddd = main_ddd,
    private_did = private_did,
    mortgage_did = mortgage_did,
    event_study = event_study
  ),
  "data/results/main_models.rds"
)

write_csv(main_results, "data/results/main_results.csv")
write_csv(event_coefs, "data/results/event_study.csv")
write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("Main analysis complete.\n")
