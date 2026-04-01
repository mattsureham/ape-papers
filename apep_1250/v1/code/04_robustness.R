source("code/00_packages.R")

ensure_dir("data/results")

panel <- read_csv("data/derived/analysis_panel.csv", show_col_types = FALSE)

region_trends <- feols(
  diff_y ~ loans_per_1000:post | la_code + quarter_id + region[time_index],
  data = panel,
  cluster = ~region
)

short_window <- feols(
  diff_y ~ loans_per_1000:post | la_code + quarter_id,
  data = filter(panel, year >= 2010, year <= 2019),
  cluster = ~region
)

leave_one_out <- map_dfr(
  sort(unique(panel$region)),
  function(drop_region) {
    mod <- feols(
      diff_y ~ loans_per_1000:post | la_code + quarter_id,
      data = filter(panel, region != drop_region),
      cluster = ~region
    )
    tibble(
      dropped_region = drop_region,
      estimate = coef(mod)[1],
      std_error = se(mod)[1],
      p_value = pvalue(mod)[1]
    )
  }
)

set.seed(1242)
region_map <- distinct(panel, region, loans_per_1000) |> arrange(region)

fit_perm_beta <- function(exposure_map) {
  dat <- panel |>
    select(-loans_per_1000) |>
    left_join(exposure_map, by = "region")

  coef(
    feols(
      diff_y ~ loans_per_1000:post | la_code + quarter_id,
      data = dat,
      vcov = ~region
    )
  )[1]
}

beta_hat <- coef(readRDS("data/results/main_models.rds")$main_ddd)[1]
perm_betas <- replicate(
  1000,
  fit_perm_beta(region_map |> mutate(loans_per_1000 = sample(loans_per_1000)))
)

perm_results <- tibble(
  beta_hat = beta_hat,
  p_perm = mean(abs(perm_betas) >= abs(beta_hat)),
  perm_q10 = quantile(perm_betas, 0.10),
  perm_q50 = quantile(perm_betas, 0.50),
  perm_q90 = quantile(perm_betas, 0.90)
)

saveRDS(
  list(
    region_trends = region_trends,
    short_window = short_window,
    leave_one_out = leave_one_out,
    perm_results = perm_results,
    perm_betas = perm_betas
  ),
  "data/results/robustness_results.rds"
)

write_csv(leave_one_out, "data/results/leave_one_out.csv")
write_csv(perm_results, "data/results/permutation_results.csv")

cat("Robustness analysis complete.\n")

