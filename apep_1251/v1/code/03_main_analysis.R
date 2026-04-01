source("code/00_packages.R")

panel <- fread("data/clean/airport_year_panel.csv.gz")
panel <- panel[transition == FALSE]
panel[, airport_fe := factor(Airport_ID)]
panel[, year_fe := factor(year)]
panel[, rel_year := year - 2007]

ppml_total <- fepois(
  total_strikes ~ treated_post | airport_fe + year_fe,
  cluster = ~ airport_fe,
  data = panel
)

ppml_damage <- fepois(
  damaging_strikes ~ treated_post | airport_fe + year_fe,
  cluster = ~ airport_fe,
  data = panel
)

ppml_severe <- fepois(
  severe_strikes ~ treated_post | airport_fe + year_fe,
  cluster = ~ airport_fe,
  data = panel
)

ols_share <- feols(
  damage_share ~ treated_post | airport_fe + year_fe,
  weights = ~ pmax(total_strikes, 1),
  cluster = ~ airport_fe,
  data = panel
)

event_damage <- fepois(
  damaging_strikes ~ i(rel_year, treated, ref = -4) | airport_fe + year_fe,
  cluster = ~ airport_fe,
  data = panel[rel_year >= -10 & rel_year <= 15]
)

event_total <- fepois(
  total_strikes ~ i(rel_year, treated, ref = -4) | airport_fe + year_fe,
  cluster = ~ airport_fe,
  data = panel[rel_year >= -10 & rel_year <= 15]
)

saveRDS(
  list(
    ppml_total = ppml_total,
    ppml_damage = ppml_damage,
    ppml_severe = ppml_severe,
    ols_share = ols_share,
    event_damage = event_damage,
    event_total = event_total
  ),
  "data/clean/main_models.rds"
)

headline <- data.table(
  model = c("ppml_total", "ppml_damage", "ppml_severe", "ols_share"),
  estimate = c(
    coef(ppml_total)[["treated_postTRUE"]],
    coef(ppml_damage)[["treated_postTRUE"]],
    coef(ppml_severe)[["treated_postTRUE"]],
    coef(ols_share)[["treated_postTRUE"]]
  ),
  std_error = c(
    se(ppml_total)[["treated_postTRUE"]],
    se(ppml_damage)[["treated_postTRUE"]],
    se(ppml_severe)[["treated_postTRUE"]],
    se(ols_share)[["treated_postTRUE"]]
  )
)
fwrite(headline, "data/clean/headline_estimates.csv")

jsonlite::write_json(
  list(
    n_treated = panel[treated == TRUE, uniqueN(Airport_ID)],
    n_pre = panel[year <= 2003, uniqueN(year)],
    n_obs = nrow(panel)
  ),
  "data/diagnostics.json",
  auto_unbox = TRUE,
  pretty = TRUE
)
