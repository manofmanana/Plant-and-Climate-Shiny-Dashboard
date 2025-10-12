# R/analysis.R
# Purpose: Analyze climate and plant growth relationships

library(tidyverse)

analyze_relationships <- function(air, plants) {
    # If the user accidentally passed a load_data() list as either argument,
    # extract the appropriate element.
    if (is.list(air) && "air" %in% names(air)) air <- air$air
    if (is.list(plants) && "plants" %in% names(plants)) plants <- plants$plants
    # If plants is actually the full load_data list, support plants_climate
    if (is.list(plants) && "plants_climate" %in% names(plants)) {
        plants <- plants$plants
        plants_climate <- plants$plants_climate
    } else {
        plants_climate <- NULL
    }

    # Ensure plants is a data frame / tibble so dplyr verbs work
    if (!is.data.frame(plants)) {
        plants <- tryCatch(tibble::as_tibble(plants), error = function(e) as.data.frame(plants))
    }
    # Create a summary dataset showing how climate might affect plant growth
    # protect against missing columns
    if (!("growth_rate" %in% names(plants))) plants$growth_rate <- 1
    if (!("humidity" %in% names(plants))) plants$humidity <- 50
    summary_df <- plants %>%
        dplyr::mutate(
            adjusted_growth = growth_rate * (humidity / 100),
            category = ifelse(adjusted_growth > median(adjusted_growth, na.rm = TRUE), "Thriving", "Stable")
        )

    # If plant-level climate was joined, attach climate features (Temperature/Precipitation/Wind)
    if (!is.null(plants_climate) && nrow(plants_climate) > 0) {
        # join on plant_id if present, otherwise try species + eventDate
        if ("plant_id" %in% names(summary_df) && "plant_id" %in% names(plants_climate)) {
            summary_df <- summary_df %>% dplyr::left_join(
                plants_climate %>% dplyr::select(plant_id, Temperature, Precipitation, Wind),
                by = "plant_id"
            )
        } else if ("eventDate" %in% names(summary_df) && "eventDate" %in% names(plants_climate)) {
            summary_df <- summary_df %>% dplyr::left_join(
                plants_climate %>% dplyr::select(eventDate, Temperature, Precipitation, Wind),
                by = "eventDate"
            )
        }
    }

    # Air correlation summary — use available numeric climate variables
    corr_val <- NA_real_
    if (!is.null(air) && nrow(air) > 0) {
        candidates <- intersect(c("Temperature", "Precipitation", "Wind"), names(air))
        if (length(candidates) >= 2) {
            # compute correlation matrix and return a small summary (mean of upper triangle)
            cm <- cor(air[, candidates], use = "complete.obs")
            # pick the correlation between Temperature and the first other variable
            other <- setdiff(candidates, "Temperature")
            if (length(other) >= 1 && "Temperature" %in% candidates) {
                corr_val <- cm["Temperature", other[1]]
            }
        }
    }

    list(summary = summary_df, climate_corr = corr_val)
}
