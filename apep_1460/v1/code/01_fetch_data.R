source("code/00_packages.R")

countries <- c("PL", "CZ", "SK", "HU", "DE", "AT", "LT", "LV", "EE")
ages <- c("Y55-59", "Y60-64", "Y65-69")

cat("Fetching Eurostat lfsq_ergan data...\n")

raw <- get_eurostat(
  id = "lfsq_ergan",
  filters = list(
    geo = countries,
    age = ages,
    sex = c("M", "F"),
    citizen = "TOTAL",
    unit = "PC"
  ),
  time_format = "date"
)

stopifnot("Empty dataset returned from Eurostat" = nrow(raw) > 0)
cat(sprintf("Fetched %d rows from Eurostat\n", nrow(raw)))

df <- raw |>
  rename(
    country = geo,
    emp_rate = values
  ) |>
  mutate(
    year = as.integer(format(time, "%Y")),
    quarter = as.integer(format(time, "%m")) %/% 3 + 1,
    yq = year + (quarter - 1) / 4,
    age_group = case_when(
      age == "Y55-59" ~ "55-59",
      age == "Y60-64" ~ "60-64",
      age == "Y65-69" ~ "65-69"
    ),
    female = as.integer(sex == "F")
  ) |>
  filter(!is.na(emp_rate), year >= 2010, year <= 2024) |>
  select(country, age_group, sex, female, year, quarter, yq, emp_rate)

cat(sprintf("Cleaned dataset: %d rows\n", nrow(df)))
cat(sprintf("Countries: %s\n", paste(unique(df$country), collapse = ", ")))
cat(sprintf("Year range: %d-%d\n", min(df$year), max(df$year)))
cat(sprintf("Age groups: %s\n", paste(unique(df$age_group), collapse = ", ")))

pl <- df |> filter(country == "PL", age_group == "60-64", sex == "F")
cat(sprintf("\nPoland women 60-64 check:\n"))
cat(sprintf("  2017-Q3: %.1f%%\n", pl$emp_rate[pl$year == 2017 & pl$quarter == 3]))
cat(sprintf("  2017-Q4: %.1f%%\n", pl$emp_rate[pl$year == 2017 & pl$quarter == 4]))

stopifnot(
  "Missing Poland data" = "PL" %in% df$country,
  "Missing female data" = 1 %in% df$female,
  "Too few observations" = nrow(df) > 500
)

saveRDS(df, "data/eurostat_panel.rds")
cat("Saved data/eurostat_panel.rds\n")
