\name{plot_climate_trend}
\alias{plot_climate_trend}
\title{Plot precipitation vs. temperature}
\description{
Creates a scatter plot of precipitation vs. temperature and converts it to an interactive plotly object.
}
\usage{
plot_climate_trend(air)
}
\arguments{
\item{air}{A data frame containing climate variables including \code{Temperature} and \code{Precipitation}, or a list with an \code{air} element.}
}
\value{
An interactive plotly object showing Precipitation vs Temperature.
}
\examples{
data <- load_data()
p <- plot_climate_trend(data$air)
class(p)
}
