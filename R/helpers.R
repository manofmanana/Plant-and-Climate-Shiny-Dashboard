# R/helpers.R
# Purpose: Utility functions used across app

scale01 <- function(x) {
    (x - min(x, na.rm = TRUE)) / (max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
}

# Format numeric values for pretty display
format_num <- function(x, digits = 2) {
    format(round(x, digits), nsmall = digits)
}

# Simple correlation helper
cor_summary <- function(df, var1, var2) {
    cor_val <- cor(df[[var1]], df[[var2]], use = "complete.obs")
    paste0("Correlation between ", var1, " and ", var2, ": ", round(cor_val, 2))
}
