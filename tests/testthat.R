# Run all tests from the project root with:  Rscript tests/testthat.R
library(testthat)
Sys.setenv(NOT_CRAN = "true") # enables the end-to-end app test
test_dir("tests/testthat", reporter = "summary", stop_on_failure = TRUE)
