# tests/test_load_data.R
# Load package code for testing
source("R/data_load.R")
source("R/helpers.R")
source("R/analysis.R")
source("R/visualize.R")

res <- load_data()
# Basic smoke tests
stopifnot(is.list(res))
stopifnot(!is.null(res$air))
stopifnot(!is.null(res$plants))
stopifnot(nrow(res$plants) == 50)
message("test_load_data: OK")
