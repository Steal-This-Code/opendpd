
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

## Fetching Data

The package provides functions starting with `get_` to retrieve data
from different datasets. They handle API pagination automatically and
allow filtering via dedicated arguments or a custom `where` clause.

## Police Incidents

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

## Police Arrests

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

## Arrest Charges

Retrieve details about charges associated with arrests.

``` r
# Get Felony charges during April 2024
charges_apr_felony <- get_charges(
  start_date = "2024-04-01",
  end_date = "2024-04-30",
  severity = "FELONY",
  limit = 50
)
#> Starting data retrieval...
#> No more data found.
#> Total records retrieved: 0
#> Query returned no matching records.
print(head(charges_apr_felony))
#> # A tibble: 0 × 0
```

## Use of Force

Retrieve Response to Resistance / Use of Force data. Requires specifying
the year, as data is stored in separate yearly datasets (currently
supports 2017-2020). Column names may vary by year.

``` r
# Get UoF incidents for 2020 where force type involved 'Physical Force'
uof_2020_physical <- get_uof(
  year = 2020,
  force_type = "Physical Force",
  limit = 25
)
#> Starting data retrieval for year 2020...
#> No more data found for year 2020.
#> Total records retrieved for year 2020 : 0
#> Query returned no matching records for year 2020.
print(head(uof_2020_physical))
#> # A tibble: 0 × 0
```

## Exploring Filter Values

Before filtering with the `get_` functions, you might want to see the
available options for certain fields.

``` r
# See distinct divisions in the Incidents dataset
incident_divisions <- list_distinct_values(field = "division", dataset = "incidents")
#> Querying distinct values for field: 'division' from dataset: incidents
print(incident_divisions)
#>  [1] "Central"       "CENTRAL"       "North Central" "NORTH CENTRAL"
#>  [5] "NorthEast"     "NORTHEAST"     "NorthWest"     "NORTHWEST"    
#>  [9] "South Central" "SOUTH CENTRAL" "SouthEast"     "SOUTHEAST"    
#> [13] "SouthWest"     "SOUTHWEST"

# See distinct severities in the Charges dataset
charge_severities <- list_distinct_values(field = "severity", dataset = "charges")
#> Querying distinct values for field: 'severity' from dataset: charges
print(charge_severities)
#> [1] "F"  "M"  "N"  "SF"

# See distinct penalty classes ('pclass') from Charges data
charge_pclasses <- list_distinct_values(field = "pclass", dataset = "charges")
#> Querying distinct values for field: 'pclass' from dataset: charges
print(charge_pclasses)
#>  [1] "F*" "F1" "F2" "F3" "FS" "M*" "MA" "MB" "MC" "NA" "SF"

# See distinct arrest districts ('arldistrict') from Arrests data
arrest_districts <- list_distinct_values(field = "arldistrict", dataset = "arrests")
#> Querying distinct values for field: 'arldistrict' from dataset: arrests
print(arrest_districts)
#>   [1] "1"     "10"    "11"    "111"   "112"   "113"   "114"   "115"   "116"  
#>  [10] "12"    "121"   "122"   "123"   "124"   "125"   "13"    "131"   "132"  
#>  [19] "133"   "134"   "135"   "136"   "14"    "141"   "142"   "143"   "144"  
#>  [28] "145"   "146"   "151"   "152"   "153"   "154"   "155"   "156"   "2"    
#>  [37] "211"   "212"   "213"   "214"   "215"   "216"   "217"   "218"   "219"  
#>  [46] "221"   "222"   "223"   "224"   "225"   "226"   "227"   "228"   "229"  
#>  [55] "231"   "232"   "233"   "234"   "235"   "236"   "237"   "238"   "241"  
#>  [64] "242"   "243"   "244"   "245"   "246"   "247"   "248"   "251"   "252"  
#>  [73] "253"   "254"   "255"   "256"   "257"   "258"   "3"     "311"   "312"  
#>  [82] "313"   "314"   "315"   "316"   "317"   "318"   "321"   "322"   "323"  
#>  [91] "324"   "325"   "326"   "327"   "328"   "331"   "332"   "333"   "334"  
#> [100] "335"   "336"   "337"   "338"   "341"   "342"   "343"   "344"   "345"  
#> [109] "346"   "347"   "348"   "351"   "352"   "353"   "354"   "355"   "356"  
#> [118] "357"   "4"     "411"   "412"   "413"   "414"   "415"   "416"   "417"  
#> [127] "421"   "422"   "423"   "424"   "425"   "426"   "431"   "432"   "433"  
#> [136] "434"   "435"   "436"   "437"   "441"   "442"   "443"   "444"   "445"  
#> [145] "446"   "447"   "451"   "452"   "453"   "454"   "455"   "456"   "5"    
#> [154] "512"   "513"   "514"   "515"   "516"   "517"   "521"   "522"   "523"  
#> [163] "524"   "525"   "526"   "532"   "533"   "534"   "535"   "536"   "537"  
#> [172] "538"   "539"   "541"   "542"   "543"   "544"   "545"   "546"   "551"  
#> [181] "552"   "553"   "554"   "555"   "556"   "6"     "611"   "612"   "613"  
#> [190] "614"   "621"   "622"   "623"   "624"   "625"   "631"   "632"   "633"  
#> [199] "634"   "635"   "641"   "642"   "643"   "644"   "651"   "652"   "653"  
#> [208] "654"   "7"     "711"   "712"   "713"   "714"   "715"   "716"   "717"  
#> [217] "721"   "722"   "723"   "724"   "725"   "726"   "727"   "728"   "731"  
#> [226] "732"   "733"   "734"   "735"   "736"   "737"   "741"   "742"   "743"  
#> [235] "744"   "745"   "746"   "747"   "748"   "751"   "752"   "753"   "754"  
#> [244] "755"   "756"   "757"   "8"     "9"     "Adam"  "ADAM"  "Carol" "CAROL"
#> [253] "Dwain" "DWAIN" "Jenni" "JENNI" "Jerry" "JERRY" "Lee M" "LEE M" "Monic"
#> [262] "MONIC" "Phili" "PHILI" "Rick"  "RICK"  "Sandy" "SANDY" "Scott" "SCOTT"
#> [271] "Sheff" "SHEFF" "Tenne" "TENNE" "Vonci" "VONCI"
```

## Cleaning Data

The package includes functions to perform basic cleaning (text
formatting, date parsing) and standardization for specific datasets.
These are typically used after retrieving the data.

## Basic Cleaning (Text and Dates)

Functions like `clean_incidents_data()` and `clean_arrests_data()` apply
standard text cleaning (lowercase, trim whitespace) to common fields and
parse date/time columns into POSIXct objects (using `lubridate`,
requires installation).

``` r
# Fetch raw incident data
raw_incidents <- get_incidents(limit = 20, start_date = "2024-04-01")
#> Starting data retrieval...
#> Reached limit of 20
#> Total records retrieved: 20
#> Data retrieval complete.

# Apply cleaning
# Needs stringr & lubridate: install.packages(c("stringr", "lubridate"))
cleaned_incidents <- clean_incidents_data(raw_incidents)
#> Warning: Specified `text_fields` not found and skipped: type
#> Applying text cleaning (lower, trim, squish) to columns: division, district, sector, beat, premise, offincident, signal, ucr_disp, status
#> Attempting to convert date columns to POSIXct (tz= America/Chicago ): date1, date2_of_occurrence_2, reporteddate, edate, callorgdate, callreceived, callcleared, calldispatched, upzdate

# Check date class and cleaned division
print(class(cleaned_incidents$date1))
#> [1] "POSIXct" "POSIXt"
print(head(cleaned_incidents$division))
#> [1] "central"   "southeast" "central"   "central"   "southwest" "northwest"

# You can also clean arrest data
# raw_arrests <- get_arrests(limit=20)
# cleaned_arrests <- clean_arrests_data(raw_arrests)
```

## Standardizing Categorical Fields

Functions like `standardize_division()` and `standardize_district()` map
variations in specific fields (like police division or council district
in the incidents data) to a standard set of categories and convert them
to factors. This is useful for analysis after basic cleaning.

``` r
# Assuming 'cleaned_incidents' from the previous step
standardized_incidents <- standardize_division(cleaned_incidents)
#> Standardizing column: 'division'
standardized_incidents <- standardize_district(standardized_incidents) # Can chain them
#> Standardizing Council District column: 'district'
#> Warning: 20 value(s) in column 'district' could not be mapped to a standard
#> district (1-14) and became NA.

# See the standardized values and factor levels
print(table(standardized_incidents$division, useNA = "ifany"))
#> 
#>      central    northeast    northwest southcentral    southeast    southwest 
#>            6            2            2            3            4            2 
#> northcentral 
#>            1
print(levels(standardized_incidents$district))
#>  [1] "1"  "2"  "3"  "4"  "5"  "6"  "7"  "8"  "9"  "10" "11" "12" "13" "14"
```

## Data Sources

Data is sourced from the [Dallas Open Data
Portal](https://www.dallasopendata.com/). Specific datasets used include
Police Incidents, Arrests, Arrest Charges, and Response to Resistance
(Use of Force). Field names and data availability are subject to change
based on the source portal.

All data are made available through the [Open Data Commons Attribution
License](http://opendatacommons.org/licenses/by/1.0/)
