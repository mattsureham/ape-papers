source("code/00_packages.R")

df <- readRDS("data/eurostat_panel.rds")

pl <- df |>
  filter(country == "PL") |>
  mutate(
    post = as.integer(yq >= 2017.75),
    age_60_64 = as.integer(age_group == "60-64"),
    age_65_69 = as.integer(age_group == "65-69"),
    treat_dd = female * age_60_64,
    treat_ddd = female * age_60_64 * post,
    time_id = (year - 2010) * 4 + quarter,
    cell_id = paste(sex, age_group, sep = "_")
  )

cat(sprintf("Poland panel: %d observations\n", nrow(pl)))
cat(sprintf("  Pre-reform (2010-Q1 to 2017-Q3): %d\n", sum(pl$post == 0)))
cat(sprintf("  Post-reform (2017-Q4 to 2024-Q4): %d\n", sum(pl$post == 1)))

cells <- pl |>
  group_by(sex, age_group) |>
  summarize(
    n_obs = n(),
    mean_emp = mean(emp_rate, na.rm = TRUE),
    sd_emp = sd(emp_rate, na.rm = TRUE),
    .groups = "drop"
  )
cat("\nCell summary:\n")
print(as.data.frame(cells))

donors <- df |>
  filter(country != "PL") |>
  mutate(
    post = as.integer(yq >= 2017.75),
    age_60_64 = as.integer(age_group == "60-64"),
    age_65_69 = as.integer(age_group == "65-69"),
    treat_dd = female * age_60_64,
    treat_ddd = female * age_60_64 * post,
    time_id = (year - 2010) * 4 + quarter,
    cell_id = paste(sex, age_group, sep = "_")
  )

cat(sprintf("\nDonor countries panel: %d observations\n", nrow(donors)))

full <- bind_rows(
  pl |> mutate(is_poland = 1L),
  donors |> mutate(is_poland = 0L)
)

saveRDS(pl, "data/poland_panel.rds")
saveRDS(donors, "data/donors_panel.rds")
saveRDS(full, "data/full_panel.rds")
cat("Saved data/poland_panel.rds, donors_panel.rds, full_panel.rds\n")
