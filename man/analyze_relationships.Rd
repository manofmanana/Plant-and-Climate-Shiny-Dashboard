\name{analyze_relationships}
\alias{analyze_relationships}
\title{Analyze relationships between climate and plants}
\description{
Performs a small example analysis combining air quality data and plant
observations to produce a summary dataset and a simple correlation metric.
}
\usage{
analyze_relationships(air, plants)
}
\arguments{
\item{air}{A data frame containing climate variables such as \code{Temperature}, \code{Precipitation}, and \code{Wind}.}
\item{plants}{A data frame or tibble containing plant observations with at least \code{growth_rate} and \code{humidity}.}
}
\value{
A list with two elements:
\item{summary}{A data frame of plant observations with an added \code{adjusted_growth} column and category labels.}
\item{climate_corr}{Numeric correlation between Temperature and another available climate variable in the provided \code{air} data frame.}
}
\examples{
## Example use with internally generated data
data <- load_data()
out <- analyze_relationships(data$air, data$plants)
head(out$summary)
print(out$ozone_temp_cor)
}
