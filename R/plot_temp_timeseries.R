## plot_temp_timeseries.R
library(ggplot2)
library(plotly)

plot_temp_timeseries <- function(air) {
    if (is.list(air) && !is.data.frame(air) && "air" %in% names(air)) air <- air$air
    if (is.null(air) || nrow(air) == 0 || !"date" %in% names(air) || !"Temperature" %in% names(air)) {
        p <- ggplot() +
            labs(title = "No temperature data available")
        return(ggplotly(p))
    }
    df <- air %>% arrange(as.Date(date))
    p <- ggplot(df, aes(x = as.Date(date), y = Temperature)) +
        geom_line(color = "#E3C567") +
        theme_minimal() +
        labs(title = "Temperature over Time", x = "Date", y = "Temperature (°C)")
    ggplotly(p) %>%
        plotly::layout(margin = list(l = 12, r = 12, t = 28, b = 16)) %>%
        plotly::config(displayModeBar = FALSE)
}
