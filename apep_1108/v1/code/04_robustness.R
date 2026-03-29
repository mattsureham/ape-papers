## 04_robustness.R
## The Housing Cost of Reshoring: CHIPS Act and Local Housing Markets
## Robustness checks: placebos, leave-one-out, heterogeneity

source("00_packages.R")

data_dir <- "../data"

panel_zhvi <- readRDS(file.path(data_dir, "panel_zhvi.rds"))
chips <- read_csv(file.path(data_dir, "chips_announcements.csv"),
                  col_types = cols(county_fips = col_character()))
overall_zhvi <- readRDS(file.path(data_dir, "overall_zhvi.rds"))

panel_zhvi <- panel_zhvi %>%
  mutate(county_id = as.numeric(factor(county_fips)))

# ============================================================
# 1. Placebo test: random announcement dates
# ============================================================
cat("=== Placebo: Random Announcement Dates ===\n")

set.seed(20260329)
n_sims <- 500
placebo_atts <- numeric(n_sims)

treated_counties <- panel_zhvi %>%
  filter(treated) %>%
  pull(county_fips) %>%
  unique()

real_treat_times <- chips$treat_time
if (!"treat_time" %in% names(chips)) {
  chips <- chips %>%
    mutate(
      treat_time = 12 * (year(announce_date) - 2000) + month(announce_date) - 1
    )
  real_treat_times <- chips$treat_time
}

# Get all possible treatment times from actual announcements
possible_times <- unique(panel_zhvi$time_index[
  panel_zhvi$time_index >= min(real_treat_times) - 12 &
  panel_zhvi$time_index <= max(real_treat_times) + 6
])

for (i in 1:n_sims) {
  # Randomly assign announcement dates to treated counties
  panel_placebo <- panel_zhvi
  shuffled_times <- sample(possible_times, length(treated_counties), replace = TRUE)
  placebo_map <- data.frame(
    county_fips = treated_counties,
    fake_treat = shuffled_times,
    stringsAsFactors = FALSE
  )

  panel_placebo <- panel_placebo %>%
    left_join(placebo_map, by = "county_fips", suffix = c("", ".p")) %>%
    mutate(
      first_treat_p = ifelse(!is.na(fake_treat), fake_treat, 0),
      post_p = ifelse(!is.na(fake_treat) & time_index >= fake_treat, 1, 0)
    )

  # Simple static DiD with placebo timing
  mod_p <- tryCatch({
    feols(log_zhvi ~ treated:post_p | county_fips + time_index,
          data = panel_placebo, cluster = ~county_fips)
  }, error = function(e) NULL)

  if (!is.null(mod_p)) {
    placebo_atts[i] <- coef(mod_p)["treated:post_p"]
  } else {
    placebo_atts[i] <- NA
  }

  if (i %% 100 == 0) cat("  Placebo iteration:", i, "/", n_sims, "\n")
}

placebo_atts <- placebo_atts[!is.na(placebo_atts)]
real_att <- overall_zhvi$overall.att
p_value_ri <- mean(abs(placebo_atts) >= abs(real_att))

cat("Real ATT:", round(real_att, 4), "\n")
cat("Placebo mean:", round(mean(placebo_atts), 4), "\n")
cat("Placebo SD:", round(sd(placebo_atts), 4), "\n")
cat("RI p-value:", round(p_value_ri, 3), "\n")

saveRDS(list(placebo_atts = placebo_atts, real_att = real_att,
             p_value_ri = p_value_ri),
        file.path(data_dir, "placebo_results.rds"))

# ============================================================
# 2. Leave-one-out: drop each treated county
# ============================================================
cat("\n=== Leave-One-Out ===\n")

loo_results <- data.frame(
  dropped_county = character(),
  dropped_company = character(),
  att = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

for (tc in treated_counties) {
  panel_loo <- panel_zhvi %>% filter(county_fips != tc)
  panel_loo <- panel_loo %>%
    mutate(county_id_loo = as.numeric(factor(county_fips)))

  cs_loo <- tryCatch({
    att_gt(
      yname = "log_zhvi",
      tname = "time_index",
      idname = "county_id_loo",
      gname = "first_treat",
      data = panel_loo,
      control_group = "nevertreated",
      anticipation = 0,
      base_period = "varying"
    )
  }, error = function(e) NULL)

  if (!is.null(cs_loo)) {
    overall_loo <- aggte(cs_loo, type = "simple")
    company_name <- chips$companies[chips$county_fips == tc]
    if (length(company_name) == 0) company_name <- "Unknown"

    loo_results <- rbind(loo_results, data.frame(
      dropped_county = tc,
      dropped_company = company_name,
      att = overall_loo$overall.att,
      se = overall_loo$overall.se,
      stringsAsFactors = FALSE
    ))
    cat("  Dropped", tc, "(", company_name, "): ATT =",
        round(overall_loo$overall.att, 4), "\n")
  }
}

saveRDS(loo_results, file.path(data_dir, "loo_results.rds"))

# ============================================================
# 3. Heterogeneity by award size
# ============================================================
cat("\n=== Heterogeneity: Large vs Small Awards ===\n")

median_award <- median(chips$total_award_billion)
large_awards <- chips$county_fips[chips$total_award_billion >= median_award]

panel_zhvi <- panel_zhvi %>%
  mutate(large_award = county_fips %in% large_awards)

# Large awards
cs_large <- tryCatch({
  panel_large <- panel_zhvi %>%
    filter(!treated | large_award) %>%
    mutate(county_id_sub = as.numeric(factor(county_fips)))

  att_gt(
    yname = "log_zhvi",
    tname = "time_index",
    idname = "county_id_sub",
    gname = "first_treat",
    data = panel_large,
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "varying"
  )
}, error = function(e) { cat("Large awards C-S failed:", e$message, "\n"); NULL })

if (!is.null(cs_large)) {
  overall_large <- aggte(cs_large, type = "simple")
  cat("Large awards ATT:", round(overall_large$overall.att, 4),
      "SE:", round(overall_large$overall.se, 4), "\n")
  saveRDS(overall_large, file.path(data_dir, "overall_large.rds"))
}

# Small awards
cs_small <- tryCatch({
  panel_small <- panel_zhvi %>%
    filter(!treated | !large_award) %>%
    mutate(county_id_sub = as.numeric(factor(county_fips)))

  att_gt(
    yname = "log_zhvi",
    tname = "time_index",
    idname = "county_id_sub",
    gname = "first_treat",
    data = panel_small,
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "varying"
  )
}, error = function(e) { cat("Small awards C-S failed:", e$message, "\n"); NULL })

if (!is.null(cs_small)) {
  overall_small <- aggte(cs_small, type = "simple")
  cat("Small awards ATT:", round(overall_small$overall.att, 4),
      "SE:", round(overall_small$overall.se, 4), "\n")
  saveRDS(overall_small, file.path(data_dir, "overall_small.rds"))
}

# ============================================================
# 4. Donut hole: exclude 2 months around announcement
# ============================================================
cat("\n=== Donut Hole (exclude +/- 2 months) ===\n")

panel_donut <- panel_zhvi %>%
  filter(!treated | is.na(event_time) | abs(event_time) > 2)

panel_donut <- panel_donut %>%
  mutate(county_id_donut = as.numeric(factor(county_fips)))

cs_donut <- tryCatch({
  att_gt(
    yname = "log_zhvi",
    tname = "time_index",
    idname = "county_id_donut",
    gname = "first_treat",
    data = panel_donut,
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "varying"
  )
}, error = function(e) { cat("Donut C-S failed:", e$message, "\n"); NULL })

if (!is.null(cs_donut)) {
  overall_donut <- aggte(cs_donut, type = "simple")
  cat("Donut ATT:", round(overall_donut$overall.att, 4),
      "SE:", round(overall_donut$overall.se, 4), "\n")
  saveRDS(overall_donut, file.path(data_dir, "overall_donut.rds"))
}

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
