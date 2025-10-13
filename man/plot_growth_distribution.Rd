\name{plot_growth_distribution}
\alias{plot_growth_distribution}
\title{Plot growth distribution by species}
\description{
Creates a boxplot (ggplot2) of adjusted plant growth by species and converts it to an interactive plotly object.
}
\usage{
plot_growth_distribution(summary_df)
}
\arguments{
\item{summary_df}{A data frame or list that contains a \code{summary} element with \code{species}, \code{adjusted_growth}, and \code{category}.}
}
\value{
A plotly object representing the boxplot of adjusted growth rates by species.
}
\examples{
res <- load_data()
sample <- analyze_relationships(res$air, res$plants)$summary
p <- plot_growth_distribution(sample)
class(p)
}
\name{plot_growth_distribution}
\alias{plot_growth_distribution}
\title{Plot growth distribution by species}
\description{
Creates a boxplot (ggplot2) of adjusted plant growth by species and converts
it to an interactive plotly object.
}
\usage{
plot_growth_distribution(summary_df)
}
\arguments{
\item{summary_df}{A data frame or tibble produced by \code{analyze_relationships()} that includes \code{species}, \code{adjusted_growth}, and \code{category}.}
}
\value{
A plotly object representing the boxplot of adjusted growth rates by species.
}
\examples{
## Create a sample summary and render the interactive plot
sample <- analyze_relationships(load_data()$air, load_data()$plants)$summary
p <- plot_growth_distribution(sample)
class(p)
}
