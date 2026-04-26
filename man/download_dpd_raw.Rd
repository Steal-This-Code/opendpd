% Manually updated to match R/dpd_utils.R
\name{download_dpd_raw}
\alias{download_dpd_raw}
\title{Download Raw Dallas Police Data}
\usage{
download_dpd_raw(
  dataset = c("incidents", "arrests"),
  start_date = NULL,
  end_date = NULL,
  limit = Inf,
  select = NULL,
  where = NULL,
  ...
)
}
\arguments{
\item{dataset}{Which dataset to download. Currently supports `"incidents"`
and `"arrests"`.}

\item{start_date}{Optional. A character string in `'YYYY-MM-DD'` format or a
`Date` object specifying the minimum record date (inclusive) for the
dataset's primary date field.}

\item{end_date}{Optional. A character string in `'YYYY-MM-DD'` format or a
`Date` object specifying the maximum record date (inclusive) for the
dataset's primary date field.}

\item{limit}{The maximum number of raw records to return. Defaults to `Inf`.}

\item{select}{A character vector specifying which columns to retrieve.
If `NULL` (default), all columns are retrieved.}

\item{where}{An optional character string containing a custom SoQL `WHERE`
clause. If supplied, `start_date` and `end_date` are ignored.}

\item{...}{Additional SODA query parameters passed directly to the API URL,
such as `$order`.}
}
\value{
A tibble containing the raw API response for the selected dataset.
}
\description{
Downloads Dallas Police datasets from the Dallas Open Data portal without
applying any package-level cleaning or normalization.
}
\examples{
\dontrun{
raw_incidents <- download_dpd_raw(
  dataset = "incidents",
  start_date = "2024-03-01",
  end_date = "2024-03-31",
  limit = 100
)
print(head(raw_incidents))
}
}
