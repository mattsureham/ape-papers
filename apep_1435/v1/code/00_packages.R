## 00_packages.R — required R libraries
needed <- c("data.table","fixest","jsonlite","stringr")
for (p in needed) {
  if (!requireNamespace(p, quietly=TRUE)) install.packages(p, repos="https://cloud.r-project.org")
}
cat("Packages OK\n")
