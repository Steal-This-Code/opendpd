
<!-- README.md is generated from README.Rmd. Please edit that file -->

# opendpd

<!-- badges: start -->
<!-- badges: end -->

The goal of opendpd is to provide an easy-to-use R interface for
accessing various Dallas Police public safety datasets via the Socrata
Open Data API, including functions for data retrieval and basic
cleaning.

## Installation

You can install the development version of opendpd like so:

``` r
# install.packages("remotes") # Uncomment if user might not have remotes
remotes::install_github("Steal-This-Code/opendpd")
```

## Usage

``` recommended
# Optional: Load other packages needed for examples here if necessary
# library(dplyr)
# library(lubridate)
```

\##Fetching Data

The package provides functions starting with `get_` to retrieve data
from different datasets. They handle API pagination automatically and
allow filtering via dedicated arguments or a custom `where` clause.

\###Police Incidents

This is the primary dataset for reported crime incidents.

``` r
# Get the first 50 incidents in the Central division for March 2024
incidents_mar_central <- get_incidents(
  start_date = "2024-03-01",
  end_date = "2024-03-31",
  division = "CENTRAL",
  limit = 50
)
#> Starting data retrieval...
#> Reached limit of 50
#> Total records retrieved: 50
#> Data retrieval complete.
print(head(incidents_mar_central))
#> # A tibble: 6 × 81
#>   incidentnum servyr servnumid      watch signal   offincident premise objattack
#>   <chr>       <chr>  <chr>          <chr> <chr>    <chr>       <chr>   <chr>    
#> 1 038949-2024 2024   038949-2024-01 1     11C/01 … CRIMINAL T… Apartm… N/A      
#> 2 803422-2024 2024   803422-2024-01 1     <NA>     LOST PROPE… Other   <NA>     
#> 3 042983-2024 2024   042983-2024-02 3     PSE/09V… UNAUTHORIZ… Outdoo… N/A      
#> 4 039150-2024 2024   039150-2024-01 2     6X - MA… FOUND PROP… Other   N/A      
#> 5 037410-2024 2024   037410-2024-01 2     55 - TR… MAN DEL CO… Highwa… N/A      
#> 6 807085-2024 2024   807085-2024-01 2     <NA>     THEFT OF P… Depart… <NA>     
#> # ℹ 73 more variables: incident_address <chr>, ra <chr>, beat <chr>,
#> #   division <chr>, sector <chr>, district <chr>, date1 <chr>, year1 <chr>,
#> #   month1 <chr>, day1 <chr>, time1 <chr>, date1dayofyear <chr>,
#> #   date2_of_occurrence_2 <chr>, year2 <chr>, month2 <chr>, day2 <chr>,
#> #   time2 <chr>, date2dayofyear <chr>, reporteddate <chr>, edate <chr>,
#> #   eyear <chr>, emonth <chr>, eday <chr>, etime <chr>, edatedayofyear <chr>,
#> #   cfs_number <chr>, callorgdate <chr>, callreceived <chr>, …

# Get incidents as an sf object (requires sf package)
# Note: Uses State Plane coordinates (EPSG:2276)
# incidents_sf <- get_incidents(limit = 10, convert_geo = TRUE)
# print(class(incidents_sf))
```

\##Police Arrests

Retrieve data on arrests made by Dallas Police.

``` r
# Get arrests for specific beats in March 2024
arrests_mar_beats <- get_arrests(
  start_date = "2024-03-01",
  end_date = "2024-03-31",
  beat = c(114, 121), # Note: Uses 'arlbeat' field from API
  limit = 25
)
#> Starting data retrieval...
#> Retrieved last page.
#> Total records retrieved: 6
#> Data retrieval complete.
print(head(arrests_mar_beats))
#> # A tibble: 6 × 47
#>   incidentnum arrestyr arrestnumber ararrestdate           ararresttime arbkdate
#>   <chr>       <chr>    <chr>        <chr>                  <chr>        <chr>   
#> 1 035233-2024 2024     24-005450    2024-03-02T00:00:00.0… 17:26        2024-03…
#> 2 044075-2024 2024     24-006959    2024-03-18T00:00:00.0… 17:24        2024-03…
#> 3 040322-2024 2024     24-006342    2024-03-11T00:00:00.0… 19:21        2024-03…
#> 4 034447-2024 2024     24-005323    2024-03-01T00:00:00.0… 11:30        2024-03…
#> 5 044075-2024 2024     24-006965    2024-03-18T00:00:00.0… 17:24        2024-03…
#> 6 041137-2024 2024     24-006477    2024-03-13T00:00:00.0… 11:45        2024-03…
#> # ℹ 41 more variables: arladdress <chr>, arlzip <chr>, arlcity <chr>,
#> #   arstate <chr>, arlcounty <chr>, arlra <chr>, arlbeat <chr>,
#> #   arldistrict <chr>, arlsector <chr>, aradow <chr>, arpremises <chr>,
#> #   cfs_number <chr>, arofcr1 <chr>, transport1 <chr>, araction <chr>,
#> #   arweapon <chr>, arresteename <chr>, age <chr>, ageatarresttime <chr>,
#> #   haddress <chr>, hzip <chr>, hcity <chr>, hstate <chr>, height <chr>,
#> #   weight <chr>, hair <chr>, eyes <chr>, race <chr>, ethnic <chr>, …
```
