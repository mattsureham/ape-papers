## 03b_recount_treated.R — Update diagnostics with dissolved municipality count
## The treated units in this design are the 18 dissolved municipalities,
## each of which experienced the merger treatment shock.

source("00_packages.R")
library(jsonlite)

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
panel <- panel %>% distinct(bfs_nr, year, function_name, .keep_all = TRUE)
merger_timing <- readRDS(file.path(data_dir, "merger_timing.rds"))

# The treated units are the 18 dissolved municipalities
n_dissolved <- nrow(merger_timing)
n_pre <- min(merger_timing$merger_year) - min(panel$year)
n_obs <- nrow(panel %>% filter(function_name == "administration"))

diagnostics <- list(
  n_treated = n_dissolved,
  n_pre = n_pre,
  n_obs = n_obs,
  n_control = n_distinct(panel$bfs_nr[panel$treated == 0]),
  n_functions = n_distinct(panel$function_name),
  n_successor_units = n_distinct(panel$bfs_nr[panel$treated == 1]),
  note = "Treated count = 18 dissolved municipalities (8 successor entities)"
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("Updated diagnostics.json: n_treated =", n_dissolved, "\n")
