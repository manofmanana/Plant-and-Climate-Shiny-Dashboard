\name{plot_temp_timeseries}
\alias{plot_temp_timeseries}
\title{Plot temperature time series}
\description{
Small temperature timeseries for the climate explorer module; accepts an \code{air} data.frame or list.
}
\usage{
plot_temp_timeseries(air)
}
\arguments{
\item{air}{A data frame with \code{date} and \code{Temperature} columns or a list containing an \code{air} element.}
}
\value{
An interactive plotly object showing Temperature over Time.
}
\examples{
res <- load_data()
plot_temp_timeseries(res$air)
}
