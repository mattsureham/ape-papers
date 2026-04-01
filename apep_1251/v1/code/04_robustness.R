source("code/00_packages.R")

panel <- fread("data/clean/airport_year_panel.csv.gz")
panel <- panel[transition == FALSE]
panel[, airport_fe := factor(Airport_ID)]
panel[, year_fe := factor(year)]

robust_panel <- copy(panel)
pre_cut <- robust_panel[treated == TRUE & year <= 2003, quantile(total_strikes, 0.95)]
robust_panel <- robust_panel[
  treated == TRUE |
    Airport_ID %in% robust_panel[treated == FALSE & year <= 2003 & total_strikes <= pre_cut, unique(Airport_ID)]
]

ppml_damage_restricted <- fepois(
  damaging_strikes ~ treated_post | airport_fe + year_fe,
  cluster = ~ airport_fe,
  data = robust_panel
)

ppml_total_restricted <- fepois(
  total_strikes ~ treated_post | airport_fe + year_fe,
  cluster = ~ airport_fe,
  data = robust_panel
)

ppml_severe_restricted <- fepois(
  severe_strikes ~ treated_post | airport_fe + year_fe,
  cluster = ~ airport_fe,
  data = robust_panel
)

trend_panel <- copy(panel)
trend_panel[, year_num := year - min(year)]

ols_damage_trends <- feols(
  damaging_strikes ~ treated_post + treated:year_num | airport_fe + year_fe,
  cluster = ~ airport_fe,
  data = trend_panel
)

ols_share_trends <- feols(
  damage_share ~ treated_post + treated:year_num | airport_fe + year_fe,
  weights = ~ pmax(total_strikes, 1),
  cluster = ~ airport_fe,
  data = trend_panel
)

ols_severe_trends <- feols(
  severe_strikes ~ treated_post + treated:year_num | airport_fe + year_fe,
  cluster = ~ airport_fe,
  data = trend_panel
)

saveRDS(
  list(
    ppml_damage_restricted = ppml_damage_restricted,
    ppml_total_restricted = ppml_total_restricted,
    ppml_severe_restricted = ppml_severe_restricted,
    ols_damage_trends = ols_damage_trends,
    ols_share_trends = ols_share_trends,
    ols_severe_trends = ols_severe_trends
  ),
  "data/clean/robust_models.rds"
)
