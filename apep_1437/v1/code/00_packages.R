pkgs <- c("data.table","fixest","ggplot2","jsonlite","stringr")
for (p in pkgs) if (!requireNamespace(p, quietly=TRUE)) install.packages(p, repos="https://cloud.r-project.org")
invisible(lapply(pkgs, library, character.only=TRUE))
