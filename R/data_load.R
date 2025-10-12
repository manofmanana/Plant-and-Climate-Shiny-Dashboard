# R/data_load.R
# Purpose: Load and clean plant & climate data

library(tidyverse)

load_data <- function() {
    # Example dataset: built-in 'airquality' + fake plant growth data
    air <- airquality %>%
        drop_na() %>%
        rename(Temperature = Temp, Ozone_Level = Ozone)

    # Example plant dataset (simulating indoor plant moisture + light)
    set.seed(123)
    plants <- tibble(
        plant_id = 1:50,
        species = sample(c("Monstera", "Pothos", "Snake Plant", "Peace Lily"), 50, TRUE),
        light = runif(50, 100, 1000),
        humidity = runif(50, 30, 90),
        growth_rate = runif(50, 0.1, 1.5)
    )

    list(air = air, plants = plants)
}
