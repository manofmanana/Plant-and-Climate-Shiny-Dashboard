# R/analysis.R
# Summaries that relate climate to the modeled growth index.

#' Filter plants by species ("All" keeps everything) and minimum humidity.
filter_plants <- function(plants, species = "All", min_humidity = 0) {
    out <- plants
    if (!is.null(species) && nzchar(species) && species != "All") {
        out <- out[out$species == species, , drop = FALSE]
    }
    if (!is.null(min_humidity)) {
        out <- out[!is.na(out$humidity) & out$humidity >= min_humidity, , drop = FALSE]
    }
    out
}

#' Correlation of the growth index with each climate driver.
#'
#' @return data.frame(variable, correlation, n)
analyze_relationships <- function(plants) {
    vars <- c(Temperature = "temperature", Humidity = "humidity", Radiation = "radiation", Precipitation = "precipitation")
    rows <- lapply(names(vars), function(label) {
        x <- plants[[vars[[label]]]]
        ok <- stats::complete.cases(x, plants$growth_index)
        r <- if (sum(ok) >= 3 && stats::sd(x[ok]) > 0 && stats::sd(plants$growth_index[ok]) > 0) {
            stats::cor(x[ok], plants$growth_index[ok])
        } else {
            NA_real_
        }
        data.frame(variable = label, correlation = r, n = sum(ok))
    })
    do.call(rbind, rows)
}

#' One-line description of a correlation, e.g. "strong positive (r = 0.71)".
describe_correlation <- function(r) {
    if (is.na(r)) {
        return("not enough data")
    }
    strength <- if (abs(r) >= 0.6) "strong" else if (abs(r) >= 0.3) "moderate" else "weak"
    direction <- if (r >= 0) "positive" else "negative"
    sprintf("%s %s (r = %.2f)", strength, direction, r)
}

#' Plain-text correlation between two columns of a data frame.
cor_summary <- function(df, var1, var2) {
    if (!(var1 %in% names(df)) || !(var2 %in% names(df))) {
        return(paste0("One or both variables not found: ", var1, ", ", var2))
    }
    r <- stats::cor(df[[var1]], df[[var2]], use = "complete.obs")
    paste0("Correlation between ", var1, " and ", var2, ": ", round(r, 2))
}
