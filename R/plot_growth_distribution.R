## plot_growth_distribution.R
# Single-function file exported for package structure
library(ggplot2)
library(plotly)

plot_growth_distribution <- function(summary_df) {
    # Accept either a summary data.frame or the full data list (defensive)
    if (is.list(summary_df) && !is.data.frame(summary_df)) {
        if ("summary" %in% names(summary_df)) {
            summary_df <- summary_df$summary
        } else if ("plants" %in% names(summary_df)) summary_df <- summary_df$plants
    }
    if (is.null(summary_df) || nrow(summary_df) == 0) {
        p <- ggplot() +
            labs(title = "No plant summary available")
        return(ggplotly(p))
    }
    # if adjusted_growth doesn't exist, fall back to growth_rate
    y_col <- ifelse("adjusted_growth" %in% names(summary_df), "adjusted_growth", ifelse("growth_rate" %in% names(summary_df), "growth_rate", NA))
    if (is.na(y_col)) {
        p <- ggplot() +
            labs(title = "No growth variable available")
        return(ggplotly(p))
    }
    # ensure species and category exist
    if (!"species" %in% names(summary_df)) summary_df$species <- "Unknown"
    if (!"category" %in% names(summary_df)) summary_df$category <- "A"
    # use tidy-eval instead of deprecated aes_string
    x_sym <- rlang::sym("species")
    y_sym <- rlang::sym(y_col)
    fill_sym <- rlang::sym("category")
    p <- ggplot(summary_df, aes(x = !!x_sym, y = !!y_sym, fill = !!fill_sym)) +
        geom_boxplot(alpha = 0.8) +
        theme_minimal(base_size = 12) +
        labs(title = "Plant Growth by Species", y = ifelse(y_col == "adjusted_growth", "Adjusted Growth Rate", "Growth Rate"), x = "Species") +
        scale_fill_manual(values = c("#A8D5BA", "#77BFA3")) +
        theme(legend.position = "none")
    ggplotly(p) %>%
        plotly::layout(margin = list(l = 20, r = 12, t = 36, b = 24)) %>%
        plotly::config(displayModeBar = FALSE)
}
