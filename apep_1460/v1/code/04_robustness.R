source("code/00_packages.R")

pl <- readRDS("data/poland_panel.rds")
full <- readRDS("data/full_panel.rds")

# ---- 1. Placebo: Men 65-69 (partial treatment — retirement age 67 → 65) ----
cat("=== MEN 65-69: Partial treatment (retirement age 67 → 65) ===\n")
men_65 <- full |>
  filter(sex == "M", age_group %in% c("55-59", "65-69")) |>
  mutate(
    poland = as.integer(country == "PL"),
    age_65_69 = as.integer(age_group == "65-69")
  )

men_fit <- feols(
  emp_rate ~ poland:age_65_69:post + poland:age_65_69 + poland:post + age_65_69:post |
    country + time_id,
  data = men_65,
  vcov = ~country
)
summary(men_fit)

# ---- 2. Placebo group: Women 55-59 (untreated — below threshold) ----
cat("\n=== PLACEBO: Women 55-59 (should show no effect) ===\n")
placebo_55 <- full |>
  filter(sex == "F", age_group == "55-59") |>
  mutate(poland = as.integer(country == "PL"))

placebo_fit <- feols(
  emp_rate ~ poland:post | country + time_id,
  data = placebo_55,
  vcov = ~country
)
summary(placebo_fit)

# ---- 3. In-time placebo: 2013 reform ----
cat("\n=== IN-TIME PLACEBO: 2013 reform (pre-2017 data only) ===\n")
pre_2017 <- full |>
  filter(sex == "F", age_group == "60-64", yq < 2017.75) |>
  mutate(
    poland = as.integer(country == "PL"),
    post_2013 = as.integer(yq >= 2013.0)
  )

placebo_2013 <- feols(
  emp_rate ~ poland:post_2013 | country + time_id,
  data = pre_2017,
  panel.id = ~country + time_id,
  vcov = "NW"
)
summary(placebo_2013)

# ---- 4. Asymmetry: 2013 raise vs 2017 reversal ----
cat("\n=== ASYMMETRY: 2013 raise vs 2017 reversal ===\n")

asym_raise <- full |>
  filter(sex == "F", age_group == "60-64", yq >= 2010 & yq < 2017.75) |>
  mutate(
    poland = as.integer(country == "PL"),
    post_2013 = as.integer(yq >= 2013.0)
  )

raise_fit <- feols(
  emp_rate ~ poland:post_2013 | country + time_id,
  data = asym_raise,
  panel.id = ~country + time_id,
  vcov = "NW"
)
cat("2013 raise (retirement age 60 → 67 gradually):\n")
summary(raise_fit)

asym_rev <- full |>
  filter(sex == "F", age_group == "60-64", yq >= 2015 & yq <= 2022) |>
  mutate(
    poland = as.integer(country == "PL"),
    post_rev = as.integer(yq >= 2017.75)
  )

rev_fit <- feols(
  emp_rate ~ poland:post_rev | country + time_id,
  data = asym_rev,
  panel.id = ~country + time_id,
  vcov = "NW"
)
cat("\n2017 reversal (retirement age 67 → 60):\n")
summary(rev_fit)

# ---- 5. SCM for Poland women 60-64 ----
cat("\n=== SYNTHETIC CONTROL ===\n")
scm_data <- full |>
  filter(sex == "F", age_group == "60-64") |>
  select(country, time_id, emp_rate) |>
  filter(!is.na(emp_rate)) |>
  arrange(country, time_id)

time_range <- sort(unique(scm_data$time_id))
pre_times <- time_range[time_range <= 31]
post_times <- time_range[time_range > 31]

countries_complete <- scm_data |>
  group_by(country) |>
  summarize(n = n(), .groups = "drop") |>
  filter(n >= length(time_range) * 0.8) |>
  pull(country)

scm_data <- scm_data |> filter(country %in% countries_complete)

country_map <- data.frame(
  country = sort(unique(scm_data$country)),
  country_num = seq_along(sort(unique(scm_data$country)))
)
scm_data <- scm_data |> left_join(country_map, by = "country")

pl_num <- country_map$country_num[country_map$country == "PL"]
donor_nums <- country_map$country_num[country_map$country != "PL"]

tryCatch({
  dp <- dataprep(
    foo = as.data.frame(scm_data),
    predictors = "emp_rate",
    predictors.op = "mean",
    dependent = "emp_rate",
    unit.variable = "country_num",
    time.variable = "time_id",
    treatment.identifier = pl_num,
    controls.identifier = donor_nums,
    time.predictors.prior = pre_times,
    time.optimize.ssr = pre_times,
    time.plot = time_range
  )

  synth_out <- synth(dp)

  gaps <- dp$Y1plot - (dp$Y0plot %*% synth_out$solution.w)

  scm_results <- data.frame(
    time_id = time_range,
    actual = as.numeric(dp$Y1plot),
    synthetic = as.numeric(dp$Y0plot %*% synth_out$solution.w),
    gap = as.numeric(gaps)
  )

  pre_rmspe <- sqrt(mean(scm_results$gap[scm_results$time_id <= 31]^2))
  post_gap <- mean(scm_results$gap[scm_results$time_id > 31])

  saveRDS(list(
    scm_results = scm_results,
    weights = synth_out$solution.w,
    country_map = country_map,
    pre_rmspe = pre_rmspe,
    post_gap = post_gap
  ), "data/scm_results.rds")

  cat(sprintf("SCM pre-RMSPE: %.3f\n", pre_rmspe))
  cat(sprintf("Mean post-treatment gap: %.2f pp\n", post_gap))
  cat("Weights:\n")
  w_df <- data.frame(
    country = country_map$country[country_map$country != "PL"],
    weight = round(as.numeric(synth_out$solution.w), 3)
  )
  print(w_df[w_df$weight > 0.01, ])

}, error = function(e) {
  cat(sprintf("SCM failed: %s\n", e$message))
  saveRDS(NULL, "data/scm_results.rds")
})

# ---- Save robustness results ----
saveRDS(list(
  men_65_69 = men_fit,
  placebo_55_59 = placebo_fit,
  placebo_2013 = placebo_2013,
  raise_2013 = raise_fit,
  reversal_2017 = rev_fit
), "data/robustness_results.rds")

cat("\nSaved all robustness results\n")
