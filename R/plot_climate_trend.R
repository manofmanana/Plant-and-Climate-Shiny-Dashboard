## plot_climate_trend.R
library(ggplot2)
library(plotly)

plot_climate_trend <- function(air) {
    # Accept either the air data.frame or the full data list
    if (is.list(air) && !is.data.frame(air)) {
        if ("air" %in% names(air)) {
            air <- air$air
        } else {
            stop("plot_climate_trend: expected a data.frame-like 'air' input")
        }
    }
    if (is.null(air) || nrow(air) == 0) {
        p <- ggplot() +
            labs(title = "No climate data available")
        return(ggplotly(p))
    }
    # Use Temperature vs Precipitation as a simple climate explorer
    if (!all(c("Temperature", "Precipitation") %in% names(air))) {
        p <- ggplot() +
            labs(title = "Insufficient climate columns for trend")
        return(ggplotly(p))
    }
    p <- ggplot(air, aes(x = Temperature, y = Precipitation)) +
        geom_point(color = "#77BFA3", alpha = 0.8) +
        geom_smooth(method = "loess", color = "#4B7856") +
        theme_light() +
        labs(title = "Precipitation vs. Temperature", x = "Temperature (°C)", y = "Precipitation (mm)")
    ggplotly(p) %>%
        plotly::layout(margin = list(l = 20, r = 12, t = 36, b = 24)) %>%
        plotly::config(displayModeBar = FALSE)
}
