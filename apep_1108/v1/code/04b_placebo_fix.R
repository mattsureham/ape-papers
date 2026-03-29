## 04b_placebo_fix.R
## Fix placebo test: randomization inference

source("00_packages.R")
data_dir <- "../data"

panel_zhvi <- readRDS(file.path(data_dir, "panel_zhvi.rds"))
overall_zhvi <- readRDS(file.path(data_dir, "overall_zhvi.rds"))

set.seed(20260329)
n_sims <- 500

treated_counties <- unique(panel_zhvi$county_fips[panel_zhvi$treated])
n_treat <- length(treated_counties)

# Real ATT from C-S
real_att <- overall_zhvi$overall.att
cat("Real ATT:", real_att, "\n")

# Get control counties for random reassignment
all_counties <- unique(panel_zhvi$county_fips)
control_counties <- setdiff(all_counties, treated_counties)

placebo_atts <- numeric(n_sims)

for (i in 1:n_sims) {
  # Randomly select n_treat counties as "placebo treated"
  fake_treated <- sample(control_counties, n_treat)

  # Assign them random treatment times from the real treatment times
  real_treat_times <- panel_zhvi %>%
    filter(treated) %>%
    distinct(county_fips, treat_time) %>%
    pull(treat_time)

  fake_times <- sample(real_treat_times, n_treat, replace = TRUE)

  panel_zhvi$fake_post <- 0
  for (j in seq_along(fake_treated)) {
    panel_zhvi$fake_post[panel_zhvi$county_fips == fake_treated[j] &
                          panel_zhvi$time_index >= fake_times[j]] <- 1
  }

  panel_zhvi$fake_treated <- panel_zhvi$county_fips %in% fake_treated

  mod_p <- tryCatch({
    feols(log_zhvi ~ fake_treated:fake_post | county_fips + time_index,
          data = panel_zhvi, cluster = ~county_fips)
  }, error = function(e) NULL)

  if (!is.null(mod_p)) {
    coef_name <- grep("TRUE:fake_post", names(coef(mod_p)), value = TRUE)
    if (length(coef_name) > 0) {
      placebo_atts[i] <- coef(mod_p)[coef_name[1]]
    } else {
      placebo_atts[i] <- NA
    }
  } else {
    placebo_atts[i] <- NA
  }

  if (i %% 100 == 0) cat("  Placebo:", i, "/", n_sims, "\n")
}

placebo_atts <- placebo_atts[!is.na(placebo_atts)]
p_value_ri <- mean(abs(placebo_atts) >= abs(real_att))

cat("\nPlacebo results:\n")
cat("N valid:", length(placebo_atts), "\n")
cat("Real ATT:", round(real_att, 5), "\n")
cat("Placebo mean:", round(mean(placebo_atts), 5), "\n")
cat("Placebo SD:", round(sd(placebo_atts), 5), "\n")
cat("RI p-value:", round(p_value_ri, 3), "\n")

saveRDS(list(placebo_atts = placebo_atts, real_att = real_att,
             p_value_ri = p_value_ri),
        file.path(data_dir, "placebo_results.rds"))

# Also run donut hole
cat("\n=== Donut Hole ===\n")
panel_donut <- panel_zhvi %>%
  filter(!treated | is.na(event_time) | abs(event_time) > 2) %>%
  mutate(county_id_donut = as.numeric(factor(county_fips)))

cs_donut <- att_gt(
  yname = "log_zhvi",
  tname = "time_index",
  idname = "county_id_donut",
  gname = "first_treat",
  data = panel_donut,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "varying"
)

overall_donut <- aggte(cs_donut, type = "simple")
cat("Donut ATT:", round(overall_donut$overall.att, 5),
    "SE:", round(overall_donut$overall.se, 5), "\n")
saveRDS(overall_donut, file.path(data_dir, "overall_donut.rds"))
