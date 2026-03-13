# 02b_extended_panel.R — Build extended panel with BEA REIS data (1980-2005)
# Extends pre-treatment period for stronger parallel trends testing

source("00_packages.R")

data_dir <- "../data"

cat("=== Building extended panel ===\n")

bea_panel <- readRDS(file.path(data_dir, "bea_panel.rds"))
state_rsa <- readRDS(file.path(data_dir, "state_treatment.rds"))

# Merge BEA county data with state-level RSA treatment timing
ext_panel <- bea_panel %>%
  inner_join(state_rsa %>% select(state_fips, state_abb, rsa_treat_year),
             by = "state_fips") %>%
  mutate(
    treat_year = rsa_treat_year,
    treated = as.integer(year >= treat_year),
    years_exposed = pmax(0L, as.integer(year - treat_year))
  )

cat(sprintf("Extended panel: %d county-years, %d counties, %d states\n",
            nrow(ext_panel), n_distinct(ext_panel$fips),
            n_distinct(ext_panel$state_fips)))
cat(sprintf("Years: %d-%d\n", min(ext_panel$year), max(ext_panel$year)))
cat(sprintf("Pre-treatment years before earliest cohort: %d\n",
            sum(unique(ext_panel$year) < min(ext_panel$treat_year))))

# Treatment cohorts
cat("\nCounties per cohort:\n")
ext_panel %>% filter(year == min(year)) %>% count(treat_year) %>% print()

saveRDS(ext_panel, file.path(data_dir, "extended_panel.rds"))

# Update diagnostics for validator
diag <- fromJSON(file.path(data_dir, "diagnostics.json"))
diag$n_pre <- sum(unique(ext_panel$year) < min(ext_panel$treat_year))
diag$n_obs_extended <- nrow(ext_panel)
diag$n_counties_extended <- n_distinct(ext_panel$fips)
diag$extended_years <- sort(unique(ext_panel$year))
write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)

cat(sprintf("\n=== Extended panel: %d obs, %d counties, n_pre=%d ===\n",
            nrow(ext_panel), n_distinct(ext_panel$fips),
            sum(unique(ext_panel$year) < min(ext_panel$treat_year))))
