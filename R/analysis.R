# R/analysis.R
# Purpose: Analyze climate and plant growth relationships

library(tidyverse)

analyze_relationships <- function(air, plants) {
    # Create a summary dataset showing how climate might affect plant growth
    summary_df <- plants %>%
        mutate(
            adjusted_growth = growth_rate * (humidity / 100),
            category = ifelse(adjusted_growth > median(adjusted_growth), "Thriving", "Stable")
        )

    # Air correlation summary (pretend connection)
    ozone_temp_cor <- cor(air$Ozone_Level, air$Temperature, use = "complete.obs")

    list(summary = summary_df, ozone_temp_cor = ozone_temp_cor)
}
