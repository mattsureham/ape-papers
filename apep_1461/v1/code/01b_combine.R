source("code/00_packages.R")

rds_files <- list.files("data", pattern = "^enoe_\\d{4}Q\\d\\.rds$", full.names = TRUE)
cat(sprintf("Found %d quarterly files\n", length(rds_files)))

keep_cols <- c("ent", "sex", "eda", "niv_ins", "clase1", "clase2",
               "seg_soc", "tip_con", "rama_est1", "rama_est2",
               "hrsocup", "ingocup", "dur9c", "pos_ocu",
               "cd_a", "con", "v_sel", "n_hog", "h_mud", "n_ren",
               "year", "quarter", "yq")

all_quarters <- list()

for (f in rds_files) {
  dt <- readRDS(f)
  avail <- intersect(keep_cols, names(dt))
  dt <- dt[, ..avail]
  all_quarters[[f]] <- dt
  cat(sprintf("  %s: %s obs, %d cols\n", basename(f), format(nrow(dt), big.mark = ","), ncol(dt)))
  rm(dt)
  gc(verbose = FALSE)
}

enoe <- rbindlist(all_quarters, fill = TRUE)
rm(all_quarters)
gc(verbose = FALSE)

cat(sprintf("\nCombined: %s observations across %d quarters\n",
            format(nrow(enoe), big.mark = ","),
            length(unique(paste(enoe$year, enoe$quarter)))))

saveRDS(enoe, "data/enoe_combined.rds")
cat("Saved to data/enoe_combined.rds\n")
