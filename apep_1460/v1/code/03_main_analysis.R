source("code/00_packages.R")

pl <- readRDS("data/poland_panel.rds")
full <- readRDS("data/full_panel.rds")

# ============================================================
# SPECIFICATION 1: Cross-country DD — Poland vs CEE donors
# (Women 60-64 only — main specification)
# ============================================================
cat("=== CROSS-COUNTRY DD: Poland women 60-64 vs CEE donors ===\n")

cross_w60 <- full |>
  filter(sex == "F", age_group == "60-64") |>
  mutate(poland = as.integer(country == "PL"))

spec1 <- feols(
  emp_rate ~ poland:post | country + time_id,
  data = cross_w60,
  panel.id = ~country + time_id,
  vcov = "NW"
)
summary(spec1)

spec1_cluster <- feols(
  emp_rate ~ poland:post | country + time_id,
  data = cross_w60,
  vcov = ~country
)
cat("\nWith country-clustered SEs:\n")
summary(spec1_cluster)

# ============================================================
# SPECIFICATION 2: Cross-country DDD
# Poland × Female × Age60-64 × Post
# ============================================================
cat("\n=== CROSS-COUNTRY DDD ===\n")

cross_ddd <- full |>
  filter(age_group %in% c("55-59", "60-64")) |>
  mutate(
    poland = as.integer(country == "PL"),
    cell = paste(country, sex, age_group, sep = "_")
  )

spec2 <- feols(
  emp_rate ~ poland:female:age_60_64:post +
    poland:female:age_60_64 + poland:female:post + poland:age_60_64:post +
    female:age_60_64:post + female:age_60_64 + female:post + age_60_64:post |
    country + time_id,
  data = cross_ddd,
  vcov = ~country
)
cat("Cross-country DDD (country-clustered):\n")
summary(spec2)

# ============================================================
# SPECIFICATION 3: Within-Poland DD — Women 60-64 vs Women 55-59
# ============================================================
cat("\n=== WITHIN-POLAND DD: Women 60-64 vs 55-59 ===\n")

dd_women <- pl |> filter(sex == "F", age_group %in% c("55-59", "60-64"))

spec3 <- feols(
  emp_rate ~ age_60_64:post + age_60_64 | time_id,
  data = dd_women,
  panel.id = ~age_group + time_id,
  vcov = "NW"
)
summary(spec3)

# ============================================================
# SPECIFICATION 4: Within-Poland DD — Women vs Men in 60-64
# ============================================================
cat("\n=== WITHIN-POLAND DD: Women vs Men (60-64) ===\n")

dd_sex <- pl |> filter(age_group == "60-64")

spec4 <- feols(
  emp_rate ~ female:post + female | time_id,
  data = dd_sex,
  panel.id = ~sex + time_id,
  vcov = "NW"
)
summary(spec4)

# ============================================================
# SPECIFICATION 5: Short-window DD (2015Q1-2020Q4)
# Avoids 2013 reform confound in pre-period + COVID in late post
# ============================================================
cat("\n=== SHORT-WINDOW DD (2015-2020) ===\n")

short <- full |>
  filter(sex == "F", age_group == "60-64", year >= 2015, year <= 2020) |>
  mutate(poland = as.integer(country == "PL"))

spec5 <- feols(
  emp_rate ~ poland:post | country + time_id,
  data = short,
  panel.id = ~country + time_id,
  vcov = "NW"
)
summary(spec5)

# ============================================================
# Save results
# ============================================================
saveRDS(list(
  cross_dd = spec1,
  cross_dd_cluster = spec1_cluster,
  cross_ddd = spec2,
  dd_women = spec3,
  dd_sex = spec4,
  short_window = spec5
), "data/main_results.rds")

# ============================================================
# Diagnostics for validator
# ============================================================
n_pre <- length(unique(cross_w60$time_id[cross_w60$post == 0]))
n_post <- length(unique(cross_w60$time_id[cross_w60$post == 1]))

write_json(list(
  n_treated = 1L,
  n_pre = n_pre,
  n_obs = nrow(cross_w60),
  n_post = n_post,
  n_countries = length(unique(cross_w60$country)),
  cross_dd_coef = as.numeric(coef(spec1)["poland:post"]),
  cross_dd_se = as.numeric(se(spec1)["poland:post"]),
  dd_women_coef = as.numeric(coef(spec3)["age_60_64:post"]),
  dd_women_se = as.numeric(se(spec3)["age_60_64:post"])
), "data/diagnostics.json", auto_unbox = TRUE)

cat("\nSaved data/main_results.rds and data/diagnostics.json\n")
