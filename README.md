
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

# See distinct force types in the 2019 UoF dataset
uof_forcetypes_2019 <- list_distinct_values(field = "forcetype", dataset = "uof", year = 2019)
#> Querying distinct values for field: 'forcetype' from dataset: uof 2019
print(uof_forcetypes_2019)
#>   [1] "40mm Less Lethal"                                                                                                                                              
#>   [2] "40mm Less Lethal, BD - Grabbed, Take Down - Body, Leg Restraint System"                                                                                        
#>   [3] "40mm Less Lethal, Held Suspect Down, BD - Grabbed"                                                                                                             
#>   [4] "40mm Less Lethal, OC Spray"                                                                                                                                    
#>   [5] "40mm Less Lethal, Pressure Points"                                                                                                                             
#>   [6] "40mm Less Lethal, Take Down - Arm"                                                                                                                             
#>   [7] "Baton Strike/Open Mode, Hand/Arm/Elbow Strike, OC Spray, Held Suspect Down"                                                                                    
#>   [8] "BD - Grabbed"                                                                                                                                                  
#>   [9] "BD - Grabbed, BD - Grabbed"                                                                                                                                    
#>  [10] "BD - Grabbed, BD - Grabbed, BD - Grabbed"                                                                                                                      
#>  [11] "BD - Grabbed, BD - Grabbed, BD - Grabbed, Held Suspect Down"                                                                                                   
#>  [12] "BD - Grabbed, BD - Grabbed, Take Down - Arm, Held Suspect Down"                                                                                                
#>  [13] "BD - Grabbed, BD - Grabbed, Take Down - Body, Verbal Command"                                                                                                  
#>  [14] "BD - Grabbed, BD - Grabbed, Take Down - Body, Verbal Command, BD - Grabbed"                                                                                    
#>  [15] "BD - Grabbed, BD - Pushed"                                                                                                                                     
#>  [16] "BD - Grabbed, BD - Pushed, BD - Grabbed"                                                                                                                       
#>  [17] "BD - Grabbed, BD - Pushed, BD - Tripped, Feet/Leg/Knee Strike, Held Suspect Down, Pressure Points"                                                             
#>  [18] "BD - Grabbed, BD - Pushed, BD - Tripped, Held Suspect Down"                                                                                                    
#>  [19] "BD - Grabbed, BD - Pushed, Hand Controlled Escort, Held Suspect Down"                                                                                          
#>  [20] "BD - Grabbed, BD - Pushed, Held Suspect Down"                                                                                                                  
#>  [21] "BD - Grabbed, BD - Pushed, Held Suspect Down, BD - Grabbed, BD - Grabbed"                                                                                      
#>  [22] "BD - Grabbed, BD - Pushed, Held Suspect Down, Verbal Command, Verbal Command, BD - Grabbed, BD - Pushed"                                                       
#>  [23] "BD - Grabbed, BD - Pushed, OC Spray"                                                                                                                           
#>  [24] "BD - Grabbed, BD - Pushed, Take Down - Body, Joint Locks, Hand/Arm/Elbow Strike, Verbal Command, Held Suspect Down, Leg Restraint System"                      
#>  [25] "BD - Grabbed, BD - Pushed, Take Down - Head"                                                                                                                   
#>  [26] "BD - Grabbed, BD - Tripped"                                                                                                                                    
#>  [27] "BD - Grabbed, BD - Tripped, BD - Pushed"                                                                                                                       
#>  [28] "BD - Grabbed, BD - Tripped, Take Down - Arm, Take Down - Body, Verbal Command, Held Suspect Down, Joint Locks"                                                 
#>  [29] "BD - Grabbed, BD - Tripped, Verbal Command, Pressure Points, Take Down - Arm"                                                                                  
#>  [30] "BD - Grabbed, Feet/Leg/Knee Strike"                                                                                                                            
#>  [31] "BD - Grabbed, Feet/Leg/Knee Strike, Feet/Leg/Knee Strike, Verbal Command, Joint Locks, Held Suspect Down"                                                      
#>  [32] "BD - Grabbed, Feet/Leg/Knee Strike, Held Suspect Down, Take Down - Head, Verbal Command"                                                                       
#>  [33] "BD - Grabbed, Feet/Leg/Knee Strike, Verbal Command"                                                                                                            
#>  [34] "BD - Grabbed, Foot Pursuit"                                                                                                                                    
#>  [35] "BD - Grabbed, Foot Pursuit, Held Suspect Down"                                                                                                                 
#>  [36] "BD - Grabbed, Foot Pursuit, Held Suspect Down, Take Down - Body, Verbal Command, Weapon display at Person"                                                     
#>  [37] "BD - Grabbed, Foot Pursuit, Verbal Command, Taser"                                                                                                             
#>  [38] "BD - Grabbed, Hand Controlled Escort, Feet/Leg/Knee Strike, Verbal Command"                                                                                    
#>  [39] "BD - Grabbed, Hand Controlled Escort, Handcuffing Take Down"                                                                                                   
#>  [40] "BD - Grabbed, Hand Controlled Escort, Held Suspect Down"                                                                                                       
#>  [41] "BD - Grabbed, Hand Controlled Escort, Held Suspect Down, Handcuffing Take Down, Take Down - Body, Verbal Command"                                              
#>  [42] "BD - Grabbed, Hand Controlled Escort, Verbal Command"                                                                                                          
#>  [43] "BD - Grabbed, Hand Controlled Escort, Verbal Command, Leg Restraint System"                                                                                    
#>  [44] "BD - Grabbed, Hand/Arm/Elbow Strike, Feet/Leg/Knee Strike, Weapon display at Person"                                                                           
#>  [45] "BD - Grabbed, Hand/Arm/Elbow Strike, Held Suspect Down"                                                                                                        
#>  [46] "BD - Grabbed, Hand/Arm/Elbow Strike, Take Down - Head, Verbal Command"                                                                                         
#>  [47] "BD - Grabbed, Handcuffing Take Down, Held Suspect Down, Verbal Command"                                                                                        
#>  [48] "BD - Grabbed, Handcuffing Take Down, Pressure Points, BD - Pushed, Pressure Points"                                                                            
#>  [49] "BD - Grabbed, Held Suspect Down"                                                                                                                               
#>  [50] "BD - Grabbed, Held Suspect Down, BD - Pushed"                                                                                                                  
#>  [51] "BD - Grabbed, Held Suspect Down, Handcuffing Take Down"                                                                                                        
#>  [52] "BD - Grabbed, Held Suspect Down, Handcuffing Take Down, Verbal Command"                                                                                        
#>  [53] "BD - Grabbed, Held Suspect Down, Take Down - Arm"                                                                                                              
#>  [54] "BD - Grabbed, Held Suspect Down, Take Down - Body, Foot Pursuit"                                                                                               
#>  [55] "BD - Grabbed, Held Suspect Down, Take Down - Body, Verbal Command, BD - Pushed"                                                                                
#>  [56] "BD - Grabbed, Held Suspect Down, Taser"                                                                                                                        
#>  [57] "BD - Grabbed, Held Suspect Down, Taser Display at Person"                                                                                                      
#>  [58] "BD - Grabbed, Held Suspect Down, Verbal Command"                                                                                                               
#>  [59] "BD - Grabbed, Held Suspect Down, Verbal Command, Foot Pursuit"                                                                                                 
#>  [60] "BD - Grabbed, Held Suspect Down, Verbal Command, Joint Locks"                                                                                                  
#>  [61] "BD - Grabbed, Held Suspect Down, Verbal Command, Take Down - Arm, Take Down - Head"                                                                            
#>  [62] "BD - Grabbed, Held Suspect Down, Verbal Command, Take Down - Body"                                                                                             
#>  [63] "BD - Grabbed, Held Suspect Down, Verbal Command, Verbal Command, Hand Controlled Escort"                                                                       
#>  [64] "BD - Grabbed, Joint Locks, Hand Controlled Escort, Held Suspect Down, Verbal Command"                                                                          
#>  [65] "BD - Grabbed, Joint Locks, Held Suspect Down"                                                                                                                  
#>  [66] "BD - Grabbed, Joint Locks, Take Down - Body"                                                                                                                   
#>  [67] "BD - Grabbed, Joint Locks, Take Down - Body, Held Suspect Down"                                                                                                
#>  [68] "BD - Grabbed, Joint Locks, Verbal Command"                                                                                                                     
#>  [69] "BD - Grabbed, Pressure Points"                                                                                                                                 
#>  [70] "BD - Grabbed, Take Down - Arm"                                                                                                                                 
#>  [71] "BD - Grabbed, Take Down - Arm, Verbal Command, Taser"                                                                                                          
#>  [72] "BD - Grabbed, Take Down - Body, Foot Pursuit"                                                                                                                  
#>  [73] "BD - Grabbed, Take Down - Body, Hand Controlled Escort"                                                                                                        
#>  [74] "BD - Grabbed, Take Down - Body, Joint Locks, Taser"                                                                                                            
#>  [75] "BD - Grabbed, Take Down - Body, Verbal Command, BD - Tripped"                                                                                                  
#>  [76] "BD - Grabbed, Take Down - Body, Verbal Command, Taser Display at Person, Joint Locks"                                                                          
#>  [77] "BD - Grabbed, Take Down - Group, Held Suspect Down"                                                                                                            
#>  [78] "BD - Grabbed, Take Down - Head, Handcuffing Take Down"                                                                                                         
#>  [79] "BD - Grabbed, Taser"                                                                                                                                           
#>  [80] "BD - Grabbed, Taser Display at Person, BD - Pushed"                                                                                                            
#>  [81] "BD - Grabbed, Taser Display at Person, Feet/Leg/Knee Strike"                                                                                                   
#>  [82] "BD - Grabbed, Taser Display at Person, Hand Controlled Escort"                                                                                                 
#>  [83] "BD - Grabbed, Verbal Command"                                                                                                                                  
#>  [84] "BD - Grabbed, Verbal Command, BD - Grabbed"                                                                                                                    
#>  [85] "BD - Grabbed, Verbal Command, BD - Grabbed, Hand Controlled Escort, BD - Pushed, BD - Grabbed, BD - Grabbed, BD - Grabbed"                                     
#>  [86] "BD - Grabbed, Verbal Command, BD - Pushed"                                                                                                                     
#>  [87] "BD - Grabbed, Verbal Command, BD - Pushed, BD - Grabbed, Take Down - Body, Held Suspect Down, Hand Controlled Escort"                                          
#>  [88] "BD - Grabbed, Verbal Command, Foot Pursuit"                                                                                                                    
#>  [89] "BD - Grabbed, Verbal Command, Hand Controlled Escort"                                                                                                          
#>  [90] "BD - Grabbed, Verbal Command, Held Suspect Down"                                                                                                               
#>  [91] "BD - Grabbed, Verbal Command, Held Suspect Down, BD - Grabbed"                                                                                                 
#>  [92] "BD - Grabbed, Verbal Command, Held Suspect Down, Hand Controlled Escort"                                                                                       
#>  [93] "BD - Grabbed, Verbal Command, Held Suspect Down, Take Down - Body"                                                                                             
#>  [94] "BD - Grabbed, Verbal Command, Leg Restraint System"                                                                                                            
#>  [95] "BD - Grabbed, Verbal Command, Take Down - Arm, Held Suspect Down"                                                                                              
#>  [96] "BD - Grabbed, Verbal Command, Taser"                                                                                                                           
#>  [97] "BD - Grabbed, Weapon display at Person, Handcuffing Take Down"                                                                                                 
#>  [98] "BD - Pushed"                                                                                                                                                   
#>  [99] "BD - Pushed, BD - Grabbed, Hand Controlled Escort, Hand/Arm/Elbow Strike, Take Down - Body, Handcuffing Take Down"                                             
#> [100] "BD - Pushed, BD - Grabbed, Taser Display at Person, Handcuffing Take Down, Joint Locks, Held Suspect Down, Take Down - Arm"                                    
#> [101] "BD - Pushed, BD - Pushed"                                                                                                                                      
#> [102] "BD - Pushed, BD - Pushed, BD - Grabbed, Held Suspect Down, Held Suspect Down, Leg Restraint System"                                                            
#> [103] "BD - Pushed, BD - Pushed, Verbal Command, BD - Grabbed"                                                                                                        
#> [104] "BD - Pushed, BD - Tripped, Held Suspect Down, Verbal Command"                                                                                                  
#> [105] "BD - Pushed, Foot Pursuit"                                                                                                                                     
#> [106] "BD - Pushed, Foot Pursuit, Handcuffing Take Down, Held Suspect Down, Verbal Command"                                                                           
#> [107] "BD - Pushed, Foot Pursuit, Held Suspect Down"                                                                                                                  
#> [108] "BD - Pushed, Hand/Arm/Elbow Strike, Verbal Command"                                                                                                            
#> [109] "BD - Pushed, Handcuffing Take Down"                                                                                                                            
#> [110] "BD - Pushed, Handcuffing Take Down, Verbal Command"                                                                                                            
#> [111] "BD - Pushed, Held Suspect Down"                                                                                                                                
#> [112] "BD - Pushed, Held Suspect Down, Foot Pursuit"                                                                                                                  
#> [113] "BD - Pushed, Held Suspect Down, Hand Controlled Escort, Verbal Command, Held Suspect Down"                                                                     
#> [114] "BD - Pushed, Held Suspect Down, Joint Locks"                                                                                                                   
#> [115] "BD - Pushed, Held Suspect Down, Verbal Command"                                                                                                                
#> [116] "BD - Pushed, Joint Locks, BD - Grabbed"                                                                                                                        
#> [117] "BD - Pushed, Joint Locks, Take Down - Arm, Baton Strike/Open Mode, Verbal Command, Held Suspect Down"                                                          
#> [118] "BD - Pushed, OC Spray"                                                                                                                                         
#> [119] "BD - Pushed, Take Down - Arm, Joint Locks"                                                                                                                     
#> [120] "BD - Pushed, Take Down - Body"                                                                                                                                 
#> [121] "BD - Pushed, Taser"                                                                                                                                            
#> [122] "BD - Pushed, Verbal Command"                                                                                                                                   
#> [123] "BD - Pushed, Verbal Command, Joint Locks"                                                                                                                      
#> [124] "BD - Pushed, Verbal Command, Verbal Command, Weapon display at Person"                                                                                         
#> [125] "BD - Pushed, Weapon display at Person"                                                                                                                         
#> [126] "BD - Tripped"                                                                                                                                                  
#> [127] "BD - Tripped, BD - Grabbed"                                                                                                                                    
#> [128] "BD - Tripped, BD - Grabbed, Take Down - Arm, Held Suspect Down, Verbal Command"                                                                                
#> [129] "BD - Tripped, BD - Tripped"                                                                                                                                    
#> [130] "BD - Tripped, Hand Controlled Escort"                                                                                                                          
#> [131] "BD - Tripped, Hand Controlled Escort, Held Suspect Down, Joint Locks, Verbal Command, Take Down - Head"                                                        
#> [132] "BD - Tripped, Handcuffing Take Down, Joint Locks, Take Down - Arm"                                                                                             
#> [133] "BD - Tripped, Held Suspect Down"                                                                                                                               
#> [134] "BD - Tripped, Held Suspect Down, Take Down - Arm"                                                                                                              
#> [135] "BD - Tripped, Held Suspect Down, Take Down - Body, Verbal Command"                                                                                             
#> [136] "BD - Tripped, Held Suspect Down, Verbal Command, Weapon display at Person"                                                                                     
#> [137] "BD - Tripped, Joint Locks"                                                                                                                                     
#> [138] "BD - Tripped, Take Down - Arm, Held Suspect Down"                                                                                                              
#> [139] "BD - Tripped, Verbal Command"                                                                                                                                  
#> [140] "BD - Tripped, Verbal Command, Held Suspect Down"                                                                                                               
#> [141] "BD - Tripped, Weapon display at Person"                                                                                                                        
#> [142] "Combat Stance, BD - Pushed"                                                                                                                                    
#> [143] "Combat Stance, BD - Pushed, OC Spray, Held Suspect Down, Take Down - Body, Verbal Command, Hand/Arm/Elbow Strike, Foot Pursuit"                                
#> [144] "Feet/Leg/Knee Strike"                                                                                                                                          
#> [145] "Feet/Leg/Knee Strike, BD - Grabbed"                                                                                                                            
#> [146] "Feet/Leg/Knee Strike, Feet/Leg/Knee Strike, Held Suspect Down"                                                                                                 
#> [147] "Feet/Leg/Knee Strike, Hand/Arm/Elbow Strike, Joint Locks, Held Suspect Down"                                                                                   
#> [148] "Feet/Leg/Knee Strike, Held Suspect Down"                                                                                                                       
#> [149] "Feet/Leg/Knee Strike, Joint Locks, Pressure Points, Verbal Command, Hand Controlled Escort, Held Suspect Down"                                                 
#> [150] "Feet/Leg/Knee Strike, Take Down - Arm"                                                                                                                         
#> [151] "Feet/Leg/Knee Strike, Take Down - Body"                                                                                                                        
#> [152] "Feet/Leg/Knee Strike, Take Down - Body, Held Suspect Down"                                                                                                     
#> [153] "Feet/Leg/Knee Strike, Take Down - Body, Pressure Points, Verbal Command, Foot Pursuit"                                                                         
#> [154] "Feet/Leg/Knee Strike, Taser Display at Person"                                                                                                                 
#> [155] "Feet/Leg/Knee Strike, Taser, Verbal Command"                                                                                                                   
#> [156] "Feet/Leg/Knee Strike, Verbal Command, Take Down - Body, Held Suspect Down"                                                                                     
#> [157] "Foot Pursuit"                                                                                                                                                  
#> [158] "Foot Pursuit, BD - Grabbed"                                                                                                                                    
#> [159] "Foot Pursuit, BD - Grabbed, Held Suspect Down"                                                                                                                 
#> [160] "Foot Pursuit, BD - Grabbed, Take Down - Body"                                                                                                                  
#> [161] "Foot Pursuit, BD - Pushed, Vehicle Pursuit, Verbal Command"                                                                                                    
#> [162] "Foot Pursuit, Feet/Leg/Knee Strike, Hand/Arm/Elbow Strike"                                                                                                     
#> [163] "Foot Pursuit, Hand Controlled Escort"                                                                                                                          
#> [164] "Foot Pursuit, Hand/Arm/Elbow Strike"                                                                                                                           
#> [165] "Foot Pursuit, Hand/Arm/Elbow Strike, Handcuffing Take Down, Take Down - Head"                                                                                  
#> [166] "Foot Pursuit, Hand/Arm/Elbow Strike, Held Suspect Down"                                                                                                        
#> [167] "Foot Pursuit, Hand/Arm/Elbow Strike, Take Down - Body"                                                                                                         
#> [168] "Foot Pursuit, Hand/Arm/Elbow Strike, Take Down - Body, Taser, Feet/Leg/Knee Strike"                                                                            
#> [169] "Foot Pursuit, Held Suspect Down"                                                                                                                               
#> [170] "Foot Pursuit, Held Suspect Down, OC Spray, Verbal Command"                                                                                                     
#> [171] "Foot Pursuit, Held Suspect Down, Take Down - Arm"                                                                                                              
#> [172] "Foot Pursuit, Held Suspect Down, Take Down - Body"                                                                                                             
#> [173] "Foot Pursuit, Held Suspect Down, Take Down - Body, Verbal Command"                                                                                             
#> [174] "Foot Pursuit, Held Suspect Down, Taser Display at Person"                                                                                                      
#> [175] "Foot Pursuit, Held Suspect Down, Verbal Command"                                                                                                               
#> [176] "Foot Pursuit, Take Down - Arm"                                                                                                                                 
#> [177] "Foot Pursuit, Take Down - Arm, Take Down - Body, Verbal Command, Take Down - Arm, Held Suspect Down"                                                           
#> [178] "Foot Pursuit, Take Down - Arm, Verbal Command"                                                                                                                 
#> [179] "Foot Pursuit, Take Down - Body"                                                                                                                                
#> [180] "Foot Pursuit, Take Down - Body, Feet/Leg/Knee Strike"                                                                                                          
#> [181] "Foot Pursuit, Take Down - Body, Held Suspect Down"                                                                                                             
#> [182] "Foot Pursuit, Take Down - Body, Joint Locks"                                                                                                                   
#> [183] "Foot Pursuit, Take Down - Body, Verbal Command"                                                                                                                
#> [184] "Foot Pursuit, Take Down - Body, Verbal Command, Held Suspect Down"                                                                                             
#> [185] "Foot Pursuit, Taser Display at Person"                                                                                                                         
#> [186] "Foot Pursuit, Taser Display at Person, Joint Locks"                                                                                                            
#> [187] "Foot Pursuit, Taser Display at Person, Verbal Command"                                                                                                         
#> [188] "Foot Pursuit, Taser, Held Suspect Down"                                                                                                                        
#> [189] "Foot Pursuit, Taser, Verbal Command, BD - Grabbed"                                                                                                             
#> [190] "Foot Pursuit, Verbal Command"                                                                                                                                  
#> [191] "Foot Pursuit, Verbal Command, BD - Grabbed"                                                                                                                    
#> [192] "Foot Pursuit, Verbal Command, BD - Pushed, Held Suspect Down"                                                                                                  
#> [193] "Foot Pursuit, Verbal Command, Hand Controlled Escort, Taser Display at Person"                                                                                 
#> [194] "Foot Pursuit, Verbal Command, Held Suspect Down"                                                                                                               
#> [195] "Foot Pursuit, Verbal Command, Take Down - Body"                                                                                                                
#> [196] "Foot Pursuit, Verbal Command, Take Down - Body, Hand/Arm/Elbow Strike"                                                                                         
#> [197] "Foot Pursuit, Verbal Command, Take Down - Body, Held Suspect Down"                                                                                             
#> [198] "Foot Pursuit, Verbal Command, Weapon display at Person"                                                                                                        
#> [199] "Foot Pursuit, Verbal Command, Weapon display at Person, Verbal Command"                                                                                        
#> [200] "Foot Pursuit, Weapon display at Person"                                                                                                                        
#> [201] "Foot Pursuit, Weapon display at Person, Held Suspect Down"                                                                                                     
#> [202] "Foot Pursuit, Weapon display at Person, Take Down - Body, Held Suspect Down, Verbal Command, Feet/Leg/Knee Strike"                                             
#> [203] "Foot Pursuit, Weapon display at Person, Take Down - Head"                                                                                                      
#> [204] "Foot Pursuit, Weapon display at Person, Verbal Command"                                                                                                        
#> [205] "Hand Controlled Escort"                                                                                                                                        
#> [206] "Hand Controlled Escort, BD - Grabbed"                                                                                                                          
#> [207] "Hand Controlled Escort, BD - Grabbed, Feet/Leg/Knee Strike, Hand Controlled Escort"                                                                            
#> [208] "Hand Controlled Escort, BD - Pushed"                                                                                                                           
#> [209] "Hand Controlled Escort, BD - Pushed, BD - Pushed"                                                                                                              
#> [210] "Hand Controlled Escort, BD - Pushed, BD - Tripped"                                                                                                             
#> [211] "Hand Controlled Escort, BD - Pushed, Held Suspect Down, Hand Controlled Escort"                                                                                
#> [212] "Hand Controlled Escort, BD - Tripped, Held Suspect Down, Take Down - Body"                                                                                     
#> [213] "Hand Controlled Escort, Hand Controlled Escort"                                                                                                                
#> [214] "Hand Controlled Escort, Hand Controlled Escort, Pressure Points, Take Down - Arm, Held Suspect Down, Joint Locks"                                              
#> [215] "Hand Controlled Escort, Hand/Arm/Elbow Strike"                                                                                                                 
#> [216] "Hand Controlled Escort, Handcuffing Take Down"                                                                                                                 
#> [217] "Hand Controlled Escort, Handcuffing Take Down, Held Suspect Down, Verbal Command"                                                                              
#> [218] "Hand Controlled Escort, Handcuffing Take Down, Take Down - Arm"                                                                                                
#> [219] "Hand Controlled Escort, Handcuffing Take Down, Verbal Command"                                                                                                 
#> [220] "Hand Controlled Escort, Held Suspect Down"                                                                                                                     
#> [221] "Hand Controlled Escort, Held Suspect Down, Joint Locks, Leg Restraint System"                                                                                  
#> [222] "Hand Controlled Escort, Held Suspect Down, Joint Locks, Verbal Command, Leg Restraint System"                                                                  
#> [223] "Hand Controlled Escort, Held Suspect Down, Take Down - Head, Verbal Command"                                                                                   
#> [224] "Hand Controlled Escort, Held Suspect Down, Verbal Command, Take Down - Arm, Joint Locks"                                                                       
#> [225] "Hand Controlled Escort, Joint Locks"                                                                                                                           
#> [226] "Hand Controlled Escort, Joint Locks, Feet/Leg/Knee Strike, Held Suspect Down"                                                                                  
#> [227] "Hand Controlled Escort, Joint Locks, Take Down - Arm, Held Suspect Down"                                                                                       
#> [228] "Hand Controlled Escort, Joint Locks, Verbal Command, Leg Restraint System, Held Suspect Down"                                                                  
#> [229] "Hand Controlled Escort, Leg Restraint System"                                                                                                                  
#> [230] "Hand Controlled Escort, OC Spray"                                                                                                                              
#> [231] "Hand Controlled Escort, Pressure Points, Verbal Command, Held Suspect Down"                                                                                    
#> [232] "Hand Controlled Escort, Take Down - Arm, Foot Pursuit, Verbal Command"                                                                                         
#> [233] "Hand Controlled Escort, Take Down - Body"                                                                                                                      
#> [234] "Hand Controlled Escort, Take Down - Body, Hand/Arm/Elbow Strike, Held Suspect Down"                                                                            
#> [235] "Hand Controlled Escort, Take Down - Group, Verbal Command, BD - Grabbed"                                                                                       
#> [236] "Hand Controlled Escort, Taser Display at Person"                                                                                                               
#> [237] "Hand Controlled Escort, Taser, Held Suspect Down"                                                                                                              
#> [238] "Hand Controlled Escort, Verbal Command"                                                                                                                        
#> [239] "Hand Controlled Escort, Verbal Command, BD - Pushed"                                                                                                           
#> [240] "Hand Controlled Escort, Verbal Command, Hand Controlled Escort"                                                                                                
#> [241] "Hand Controlled Escort, Verbal Command, Handcuffing Take Down, Leg Restraint System"                                                                           
#> [242] "Hand Controlled Escort, Verbal Command, Held Suspect Down"                                                                                                     
#> [243] "Hand Controlled Escort, Verbal Command, Take Down - Body, Held Suspect Down, Feet/Leg/Knee Strike, Pressure Points, Take Down - Body"                          
#> [244] "Hand Controlled Escort, Verbal Command, Take Down - Head"                                                                                                      
#> [245] "Hand Controlled Escort, Weapon display at Person, Verbal Command"                                                                                              
#> [246] "Hand/Arm/Elbow Strike"                                                                                                                                         
#> [247] "Hand/Arm/Elbow Strike, BD - Grabbed, Take Down - Body, Verbal Command, BD - Grabbed"                                                                           
#> [248] "Hand/Arm/Elbow Strike, BD - Pushed, BD - Grabbed, BD - Tripped"                                                                                                
#> [249] "Hand/Arm/Elbow Strike, Feet/Leg/Knee Strike, Held Suspect Down, Verbal Command"                                                                                
#> [250] "Hand/Arm/Elbow Strike, Foot Pursuit"                                                                                                                           
#> [251] "Hand/Arm/Elbow Strike, Hand Controlled Escort, OC Spray"                                                                                                       
#> [252] "Hand/Arm/Elbow Strike, Hand Controlled Escort, Take Down - Body, Verbal Command"                                                                               
#> [253] "Hand/Arm/Elbow Strike, Hand/Arm/Elbow Strike"                                                                                                                  
#> [254] "Hand/Arm/Elbow Strike, Hand/Arm/Elbow Strike, Feet/Leg/Knee Strike, Weapon display at Person, Verbal Command"                                                  
#> [255] "Hand/Arm/Elbow Strike, Held Suspect Down"                                                                                                                      
#> [256] "Hand/Arm/Elbow Strike, Held Suspect Down, Joint Locks, Take Down - Arm, Taser, Verbal Command"                                                                 
#> [257] "Hand/Arm/Elbow Strike, Held Suspect Down, Taser"                                                                                                               
#> [258] "Hand/Arm/Elbow Strike, Held Suspect Down, Verbal Command, Take Down - Body"                                                                                    
#> [259] "Hand/Arm/Elbow Strike, Joint Locks"                                                                                                                            
#> [260] "Hand/Arm/Elbow Strike, Take Down - Arm"                                                                                                                        
#> [261] "Hand/Arm/Elbow Strike, Take Down - Body"                                                                                                                       
#> [262] "Hand/Arm/Elbow Strike, Take Down - Body, Held Suspect Down"                                                                                                    
#> [263] "Hand/Arm/Elbow Strike, Take Down - Group, Pressure Points, Verbal Command"                                                                                     
#> [264] "Hand/Arm/Elbow Strike, Take Down - Group, Verbal Command, Pressure Points, Joint Locks, Feet/Leg/Knee Strike"                                                  
#> [265] "Hand/Arm/Elbow Strike, Taser"                                                                                                                                  
#> [266] "Hand/Arm/Elbow Strike, Taser, Held Suspect Down"                                                                                                               
#> [267] "Hand/Arm/Elbow Strike, Verbal Command, Feet/Leg/Knee Strike, Take Down - Arm, Verbal Command, Joint Locks, Pressure Points, Verbal Command"                    
#> [268] "Handcuffing Take Down"                                                                                                                                         
#> [269] "Handcuffing Take Down, BD - Grabbed, Held Suspect Down"                                                                                                        
#> [270] "Handcuffing Take Down, Foot Pursuit"                                                                                                                           
#> [271] "Handcuffing Take Down, Held Suspect Down"                                                                                                                      
#> [272] "Handcuffing Take Down, Held Suspect Down, Take Down - Body, Verbal Command, Hand/Arm/Elbow Strike"                                                             
#> [273] "Handcuffing Take Down, Held Suspect Down, Verbal Command"                                                                                                      
#> [274] "Handcuffing Take Down, Take Down - Arm"                                                                                                                        
#> [275] "Handcuffing Take Down, Take Down - Body, Held Suspect Down"                                                                                                    
#> [276] "Handcuffing Take Down, Verbal Command"                                                                                                                         
#> [277] "Handcuffing Take Down, Verbal Command, BD - Tripped, BD - Grabbed"                                                                                             
#> [278] "Handcuffing Take Down, Verbal Command, Hand/Arm/Elbow Strike, Held Suspect Down"                                                                               
#> [279] "Handcuffing Take Down, Verbal Command, Held Suspect Down"                                                                                                      
#> [280] "Handcuffing Take Down, Verbal Command, Take Down - Group"                                                                                                      
#> [281] "Held Suspect Down"                                                                                                                                             
#> [282] "Held Suspect Down, BD - Grabbed"                                                                                                                               
#> [283] "Held Suspect Down, BD - Grabbed, BD - Tripped, Verbal Command, Joint Locks"                                                                                    
#> [284] "Held Suspect Down, BD - Grabbed, Foot Pursuit"                                                                                                                 
#> [285] "Held Suspect Down, BD - Grabbed, Hand/Arm/Elbow Strike"                                                                                                        
#> [286] "Held Suspect Down, BD - Grabbed, Held Suspect Down, Feet/Leg/Knee Strike"                                                                                      
#> [287] "Held Suspect Down, BD - Grabbed, Joint Locks"                                                                                                                  
#> [288] "Held Suspect Down, BD - Grabbed, Taser Display at Person"                                                                                                      
#> [289] "Held Suspect Down, BD - Pushed, Verbal Command"                                                                                                                
#> [290] "Held Suspect Down, Feet/Leg/Knee Strike"                                                                                                                       
#> [291] "Held Suspect Down, Feet/Leg/Knee Strike, Feet/Leg/Knee Strike"                                                                                                 
#> [292] "Held Suspect Down, Foot Pursuit"                                                                                                                               
#> [293] "Held Suspect Down, Foot Pursuit, Verbal Command"                                                                                                               
#> [294] "Held Suspect Down, Hand Controlled Escort"                                                                                                                     
#> [295] "Held Suspect Down, Hand Controlled Escort, Verbal Command"                                                                                                     
#> [296] "Held Suspect Down, Hand/Arm/Elbow Strike"                                                                                                                      
#> [297] "Held Suspect Down, Handcuffing Take Down"                                                                                                                      
#> [298] "Held Suspect Down, Handcuffing Take Down, Verbal Command"                                                                                                      
#> [299] "Held Suspect Down, Handcuffing Take Down, Verbal Command, Hand Controlled Escort"                                                                              
#> [300] "Held Suspect Down, Held Suspect Down"                                                                                                                          
#> [301] "Held Suspect Down, Held Suspect Down, Hand Controlled Escort, Take Down - Group"                                                                               
#> [302] "Held Suspect Down, Held Suspect Down, Joint Locks, Verbal Command, Pressure Points"                                                                            
#> [303] "Held Suspect Down, Held Suspect Down, Verbal Command"                                                                                                          
#> [304] "Held Suspect Down, Joint Locks"                                                                                                                                
#> [305] "Held Suspect Down, Joint Locks, BD - Grabbed, BD - Tripped, Verbal Command"                                                                                    
#> [306] "Held Suspect Down, Joint Locks, Hand/Arm/Elbow Strike"                                                                                                         
#> [307] "Held Suspect Down, Joint Locks, Take Down - Arm"                                                                                                               
#> [308] "Held Suspect Down, Joint Locks, Verbal Command"                                                                                                                
#> [309] "Held Suspect Down, Leg Restraint System"                                                                                                                       
#> [310] "Held Suspect Down, Leg Restraint System, Held Suspect Down, BD - Grabbed"                                                                                      
#> [311] "Held Suspect Down, Leg Restraint System, Verbal Command"                                                                                                       
#> [312] "Held Suspect Down, Other Impact Weapon"                                                                                                                        
#> [313] "Held Suspect Down, Pressure Points"                                                                                                                            
#> [314] "Held Suspect Down, Pressure Points, BD - Grabbed"                                                                                                              
#> [315] "Held Suspect Down, Pressure Points, Verbal Command"                                                                                                            
#> [316] "Held Suspect Down, Pressure Points, Verbal Command, Hand/Arm/Elbow Strike"                                                                                     
#> [317] "Held Suspect Down, Take Down - Arm"                                                                                                                            
#> [318] "Held Suspect Down, Take Down - Arm, Verbal Command"                                                                                                            
#> [319] "Held Suspect Down, Take Down - Body"                                                                                                                           
#> [320] "Held Suspect Down, Take Down - Body, Joint Locks"                                                                                                              
#> [321] "Held Suspect Down, Take Down - Body, Verbal Command"                                                                                                           
#> [322] "Held Suspect Down, Take Down - Body, Verbal Command, Foot Pursuit"                                                                                             
#> [323] "Held Suspect Down, Take Down - Body, Verbal Command, Hand Controlled Escort"                                                                                   
#> [324] "Held Suspect Down, Take Down - Group"                                                                                                                          
#> [325] "Held Suspect Down, Take Down - Head"                                                                                                                           
#> [326] "Held Suspect Down, Taser"                                                                                                                                      
#> [327] "Held Suspect Down, Verbal Command"                                                                                                                             
#> [328] "Held Suspect Down, Verbal Command, BD - Grabbed"                                                                                                               
#> [329] "Held Suspect Down, Verbal Command, Feet/Leg/Knee Strike"                                                                                                       
#> [330] "Held Suspect Down, Verbal Command, Hand Controlled Escort, BD - Grabbed"                                                                                       
#> [331] "Held Suspect Down, Verbal Command, Hand Controlled Escort, BD - Pushed"                                                                                        
#> [332] "Held Suspect Down, Verbal Command, Handcuffing Take Down, BD - Tripped"                                                                                        
#> [333] "Held Suspect Down, Verbal Command, Joint Locks"                                                                                                                
#> [334] "Held Suspect Down, Verbal Command, Joint Locks, BD - Grabbed, Take Down - Group"                                                                               
#> [335] "Held Suspect Down, Verbal Command, Joint Locks, Take Down - Body"                                                                                              
#> [336] "Held Suspect Down, Verbal Command, Other Impact Weapon"                                                                                                        
#> [337] "Held Suspect Down, Verbal Command, Pressure Points, Hand Controlled Escort"                                                                                    
#> [338] "Held Suspect Down, Verbal Command, Pressure Points, K-9 Deployment"                                                                                            
#> [339] "Held Suspect Down, Verbal Command, Pressure Points, Take Down - Body"                                                                                          
#> [340] "Held Suspect Down, Verbal Command, Take Down - Arm, Held Suspect Down"                                                                                         
#> [341] "Held Suspect Down, Verbal Command, Take Down - Arm, Joint Locks"                                                                                               
#> [342] "Joint Locks"                                                                                                                                                   
#> [343] "Joint Locks, BD - Grabbed"                                                                                                                                     
#> [344] "Joint Locks, BD - Grabbed, Held Suspect Down, Weapon display at Person"                                                                                        
#> [345] "Joint Locks, BD - Grabbed, Take Down - Arm, Held Suspect Down, Verbal Command, Leg Restraint System, Held Suspect Down"                                        
#> [346] "Joint Locks, BD - Pushed"                                                                                                                                      
#> [347] "Joint Locks, BD - Pushed, BD - Grabbed"                                                                                                                        
#> [348] "Joint Locks, Feet/Leg/Knee Strike"                                                                                                                             
#> [349] "Joint Locks, Foot Pursuit"                                                                                                                                     
#> [350] "Joint Locks, Hand Controlled Escort"                                                                                                                           
#> [351] "Joint Locks, Hand Controlled Escort, Held Suspect Down"                                                                                                        
#> [352] "Joint Locks, Hand Controlled Escort, Take Down - Arm, Held Suspect Down"                                                                                       
#> [353] "Joint Locks, Hand Controlled Escort, Verbal Command"                                                                                                           
#> [354] "Joint Locks, Hand/Arm/Elbow Strike"                                                                                                                            
#> [355] "Joint Locks, Handcuffing Take Down"                                                                                                                            
#> [356] "Joint Locks, Held Suspect Down"                                                                                                                                
#> [357] "Joint Locks, Held Suspect Down, Hand Controlled Escort"                                                                                                        
#> [358] "Joint Locks, Held Suspect Down, Hand/Arm/Elbow Strike"                                                                                                         
#> [359] "Joint Locks, Held Suspect Down, Handcuffing Take Down, Take Down - Arm"                                                                                        
#> [360] "Joint Locks, Held Suspect Down, Verbal Command"                                                                                                                
#> [361] "Joint Locks, Held Suspect Down, Verbal Command, Hand Controlled Escort"                                                                                        
#> [362] "Joint Locks, Held Suspect Down, Verbal Command, Taser, Foot Pursuit"                                                                                           
#> [363] "Joint Locks, Joint Locks, Feet/Leg/Knee Strike, Verbal Command, Feet/Leg/Knee Strike, Handcuffing Take Down, Take Down - Body"                                 
#> [364] "Joint Locks, Joint Locks, Joint Locks, Held Suspect Down, Verbal Command, Handcuffing Take Down"                                                               
#> [365] "Joint Locks, Leg Restraint System"                                                                                                                             
#> [366] "Joint Locks, Pressure Points, Hand/Arm/Elbow Strike"                                                                                                           
#> [367] "Joint Locks, Pressure Points, Verbal Command"                                                                                                                  
#> [368] "Joint Locks, Take Down - Arm"                                                                                                                                  
#> [369] "Joint Locks, Take Down - Arm, Hand/Arm/Elbow Strike"                                                                                                           
#> [370] "Joint Locks, Take Down - Arm, Held Suspect Down"                                                                                                               
#> [371] "Joint Locks, Take Down - Body"                                                                                                                                 
#> [372] "Joint Locks, Take Down - Body, BD - Grabbed"                                                                                                                   
#> [373] "Joint Locks, Take Down - Body, Verbal Command"                                                                                                                 
#> [374] "Joint Locks, Taser"                                                                                                                                            
#> [375] "Joint Locks, Taser Display at Person, BD - Grabbed, BD - Pushed"                                                                                               
#> [376] "Joint Locks, Taser Display at Person, Taser, Verbal Command"                                                                                                   
#> [377] "Joint Locks, Verbal Command"                                                                                                                                   
#> [378] "Joint Locks, Verbal Command, BD - Pushed, Held Suspect Down"                                                                                                   
#> [379] "Joint Locks, Verbal Command, Hand Controlled Escort"                                                                                                           
#> [380] "Joint Locks, Verbal Command, Held Suspect Down"                                                                                                                
#> [381] "Joint Locks, Verbal Command, Take Down - Arm"                                                                                                                  
#> [382] "Joint Locks, Weapon display at Person"                                                                                                                         
#> [383] "K-9 Deployment"                                                                                                                                                
#> [384] "K-9 Deployment, Verbal Command"                                                                                                                                
#> [385] "K-9 Deployment, Weapon display at Person"                                                                                                                      
#> [386] "Leg Restraint System"                                                                                                                                          
#> [387] "Leg Restraint System, BD - Grabbed"                                                                                                                            
#> [388] "Leg Restraint System, Held Suspect Down, Verbal Command"                                                                                                       
#> [389] "Leg Restraint System, Taser Display at Person, Handcuffing Take Down, Held Suspect Down"                                                                       
#> [390] "Leg Restraint System, Verbal Command"                                                                                                                          
#> [391] "LVNR, Take Down - Head"                                                                                                                                        
#> [392] "OC Spray"                                                                                                                                                      
#> [393] "OC Spray, Hand Controlled Escort"                                                                                                                              
#> [394] "OC Spray, Take Down - Head"                                                                                                                                    
#> [395] "OC Spray, Taser"                                                                                                                                               
#> [396] "OC Spray, Taser Display at Person, Hand/Arm/Elbow Strike"                                                                                                      
#> [397] "Other Impact Weapon"                                                                                                                                           
#> [398] "Pepperball Impact"                                                                                                                                             
#> [399] "Pressure Points"                                                                                                                                               
#> [400] "Pressure Points, BD - Grabbed"                                                                                                                                 
#> [401] "Pressure Points, BD - Grabbed, Hand Controlled Escort"                                                                                                         
#> [402] "Pressure Points, Hand Controlled Escort"                                                                                                                       
#> [403] "Pressure Points, Hand Controlled Escort, BD - Grabbed"                                                                                                         
#> [404] "Pressure Points, Hand/Arm/Elbow Strike"                                                                                                                        
#> [405] "Pressure Points, Held Suspect Down"                                                                                                                            
#> [406] "Pressure Points, Pressure Points"                                                                                                                              
#> [407] "Pressure Points, Verbal Command"                                                                                                                               
#> [408] "Pressure Points, Verbal Command, Held Suspect Down"                                                                                                            
#> [409] "Take Down - Arm"                                                                                                                                               
#> [410] "Take Down - Arm, BD - Grabbed"                                                                                                                                 
#> [411] "Take Down - Arm, BD - Grabbed, Joint Locks, BD - Grabbed, Held Suspect Down"                                                                                   
#> [412] "Take Down - Arm, BD - Tripped"                                                                                                                                 
#> [413] "Take Down - Arm, Feet/Leg/Knee Strike"                                                                                                                         
#> [414] "Take Down - Arm, Foot Pursuit"                                                                                                                                 
#> [415] "Take Down - Arm, Hand Controlled Escort"                                                                                                                       
#> [416] "Take Down - Arm, Hand/Arm/Elbow Strike"                                                                                                                        
#> [417] "Take Down - Arm, Hand/Arm/Elbow Strike, Hand/Arm/Elbow Strike, Held Suspect Down"                                                                              
#> [418] "Take Down - Arm, Handcuffing Take Down, Held Suspect Down"                                                                                                     
#> [419] "Take Down - Arm, Handcuffing Take Down, Take Down - Arm, Held Suspect Down, Verbal Command"                                                                    
#> [420] "Take Down - Arm, Held Suspect Down"                                                                                                                            
#> [421] "Take Down - Arm, Held Suspect Down, Joint Locks"                                                                                                               
#> [422] "Take Down - Arm, Held Suspect Down, Pressure Points"                                                                                                           
#> [423] "Take Down - Arm, Held Suspect Down, Verbal Command"                                                                                                            
#> [424] "Take Down - Arm, Held Suspect Down, Verbal Command, Hand/Arm/Elbow Strike"                                                                                     
#> [425] "Take Down - Arm, Joint Locks"                                                                                                                                  
#> [426] "Take Down - Arm, Joint Locks, Held Suspect Down"                                                                                                               
#> [427] "Take Down - Arm, Pressure Points"                                                                                                                              
#> [428] "Take Down - Arm, Take Down - Arm"                                                                                                                              
#> [429] "Take Down - Arm, Take Down - Body, BD - Tripped"                                                                                                               
#> [430] "Take Down - Arm, Take Down - Body, Held Suspect Down"                                                                                                          
#> [431] "Take Down - Arm, Take Down - Body, Verbal Command, Hand Controlled Escort"                                                                                     
#> [432] "Take Down - Arm, Take Down - Head, Held Suspect Down"                                                                                                          
#> [433] "Take Down - Arm, Taser"                                                                                                                                        
#> [434] "Take Down - Arm, Verbal Command"                                                                                                                               
#> [435] "Take Down - Arm, Verbal Command, Handcuffing Take Down"                                                                                                        
#> [436] "Take Down - Arm, Verbal Command, Held Suspect Down"                                                                                                            
#> [437] "Take Down - Arm, Verbal Command, Held Suspect Down, Handcuffing Take Down"                                                                                     
#> [438] "Take Down - Arm, Verbal Command, Taser"                                                                                                                        
#> [439] "Take Down - Body"                                                                                                                                              
#> [440] "Take Down - Body, Baton Display, Held Suspect Down"                                                                                                            
#> [441] "Take Down - Body, BD - Grabbed"                                                                                                                                
#> [442] "Take Down - Body, BD - Grabbed, Held Suspect Down, Foot Pursuit"                                                                                               
#> [443] "Take Down - Body, BD - Tripped"                                                                                                                                
#> [444] "Take Down - Body, Foot Pursuit"                                                                                                                                
#> [445] "Take Down - Body, Foot Pursuit, Held Suspect Down"                                                                                                             
#> [446] "Take Down - Body, Hand Controlled Escort"                                                                                                                      
#> [447] "Take Down - Body, Hand Controlled Escort, Held Suspect Down, Verbal Command, BD - Grabbed"                                                                     
#> [448] "Take Down - Body, Hand Controlled Escort, Joint Locks, Held Suspect Down"                                                                                      
#> [449] "Take Down - Body, Hand/Arm/Elbow Strike"                                                                                                                       
#> [450] "Take Down - Body, Hand/Arm/Elbow Strike, Hand/Arm/Elbow Strike, OC Spray, LVNR"                                                                                
#> [451] "Take Down - Body, Hand/Arm/Elbow Strike, Held Suspect Down"                                                                                                    
#> [452] "Take Down - Body, Hand/Arm/Elbow Strike, Held Suspect Down, Foot Pursuit"                                                                                      
#> [453] "Take Down - Body, Hand/Arm/Elbow Strike, Weapon display at Person"                                                                                             
#> [454] "Take Down - Body, Held Suspect Down"                                                                                                                           
#> [455] "Take Down - Body, Held Suspect Down, BD - Grabbed, Verbal Command"                                                                                             
#> [456] "Take Down - Body, Held Suspect Down, BD - Pushed"                                                                                                              
#> [457] "Take Down - Body, Held Suspect Down, Feet/Leg/Knee Strike"                                                                                                     
#> [458] "Take Down - Body, Held Suspect Down, Foot Pursuit"                                                                                                             
#> [459] "Take Down - Body, Held Suspect Down, Hand Controlled Escort, Taser, Verbal Command"                                                                            
#> [460] "Take Down - Body, Held Suspect Down, Handcuffing Take Down"                                                                                                    
#> [461] "Take Down - Body, Held Suspect Down, Held Suspect Down, Verbal Command"                                                                                        
#> [462] "Take Down - Body, Held Suspect Down, Verbal Command"                                                                                                           
#> [463] "Take Down - Body, Held Suspect Down, Verbal Command, Held Suspect Down"                                                                                        
#> [464] "Take Down - Body, Held Suspect Down, Verbal Command, Joint Locks"                                                                                              
#> [465] "Take Down - Body, Held Suspect Down, Verbal Command, Weapon display at Person"                                                                                 
#> [466] "Take Down - Body, Take Down - Body"                                                                                                                            
#> [467] "Take Down - Body, Take Down - Body, Feet/Leg/Knee Strike"                                                                                                      
#> [468] "Take Down - Body, Taser"                                                                                                                                       
#> [469] "Take Down - Body, Taser Display at Person"                                                                                                                     
#> [470] "Take Down - Body, Taser Display at Person, Hand/Arm/Elbow Strike"                                                                                              
#> [471] "Take Down - Body, Taser Display at Person, Taser, Verbal Command"                                                                                              
#> [472] "Take Down - Body, Taser, Verbal Command"                                                                                                                       
#> [473] "Take Down - Body, Taser, Verbal Command, Foot Pursuit"                                                                                                         
#> [474] "Take Down - Body, Verbal Command"                                                                                                                              
#> [475] "Take Down - Body, Verbal Command, Feet/Leg/Knee Strike, Foot Pursuit"                                                                                          
#> [476] "Take Down - Body, Verbal Command, Foot Pursuit"                                                                                                                
#> [477] "Take Down - Body, Verbal Command, Handcuffing Take Down, Pressure Points"                                                                                      
#> [478] "Take Down - Body, Verbal Command, Held Suspect Down"                                                                                                           
#> [479] "Take Down - Body, Verbal Command, Joint Locks"                                                                                                                 
#> [480] "Take Down - Body, Verbal Command, Other Impact Weapon"                                                                                                         
#> [481] "Take Down - Body, Verbal Command, Pressure Points, Held Suspect Down"                                                                                          
#> [482] "Take Down - Body, Verbal Command, Taser, Hand/Arm/Elbow Strike, Held Suspect Down"                                                                             
#> [483] "Take Down - Group"                                                                                                                                             
#> [484] "Take Down - Group, Handcuffing Take Down"                                                                                                                      
#> [485] "Take Down - Group, Held Suspect Down"                                                                                                                          
#> [486] "Take Down - Group, Held Suspect Down, Joint Locks, Verbal Command, Hand/Arm/Elbow Strike, Hand Controlled Escort"                                              
#> [487] "Take Down - Group, Held Suspect Down, Verbal Command"                                                                                                          
#> [488] "Take Down - Group, Joint Locks, Verbal Command"                                                                                                                
#> [489] "Take Down - Group, Verbal Command"                                                                                                                             
#> [490] "Take Down - Head"                                                                                                                                              
#> [491] "Take Down - Head, Feet/Leg/Knee Strike"                                                                                                                        
#> [492] "Take Down - Head, Feet/Leg/Knee Strike, Hand/Arm/Elbow Strike"                                                                                                 
#> [493] "Take Down - Head, Held Suspect Down"                                                                                                                           
#> [494] "Take Down - Head, Take Down - Arm"                                                                                                                             
#> [495] "Take Down - Head, Take Down - Arm, BD - Tripped"                                                                                                               
#> [496] "Take Down - Head, Take Down - Arm, Verbal Command"                                                                                                             
#> [497] "Take Down - Head, Take Down - Body, Held Suspect Down"                                                                                                         
#> [498] "Take Down - Head, Taser Display at Person"                                                                                                                     
#> [499] "Take Down - Head, Verbal Command, Weapon display at Person"                                                                                                    
#> [500] "Taser"                                                                                                                                                         
#> [501] "Taser Display at Person"                                                                                                                                       
#> [502] "Taser Display at Person, BD - Grabbed"                                                                                                                         
#> [503] "Taser Display at Person, BD - Grabbed, BD - Pushed"                                                                                                            
#> [504] "Taser Display at Person, BD - Grabbed, Held Suspect Down, Hand/Arm/Elbow Strike, Joint Locks"                                                                  
#> [505] "Taser Display at Person, BD - Grabbed, Held Suspect Down, Held Suspect Down"                                                                                   
#> [506] "Taser Display at Person, BD - Grabbed, Take Down - Body, Held Suspect Down, Joint Locks"                                                                       
#> [507] "Taser Display at Person, BD - Grabbed, Verbal Command, Take Down - Body, Held Suspect Down"                                                                    
#> [508] "Taser Display at Person, BD - Pushed, Held Suspect Down, BD - Grabbed"                                                                                         
#> [509] "Taser Display at Person, Foot Pursuit"                                                                                                                         
#> [510] "Taser Display at Person, Hand Controlled Escort"                                                                                                               
#> [511] "Taser Display at Person, Hand Controlled Escort, Joint Locks, Verbal Command"                                                                                  
#> [512] "Taser Display at Person, Hand/Arm/Elbow Strike, Held Suspect Down, Verbal Command"                                                                             
#> [513] "Taser Display at Person, Handcuffing Take Down"                                                                                                                
#> [514] "Taser Display at Person, Held Suspect Down"                                                                                                                    
#> [515] "Taser Display at Person, Held Suspect Down, Verbal Command"                                                                                                    
#> [516] "Taser Display at Person, Joint Locks, BD - Grabbed"                                                                                                            
#> [517] "Taser Display at Person, Take Down - Arm"                                                                                                                      
#> [518] "Taser Display at Person, Take Down - Arm, Held Suspect Down"                                                                                                   
#> [519] "Taser Display at Person, Take Down - Body"                                                                                                                     
#> [520] "Taser Display at Person, Take Down - Group"                                                                                                                    
#> [521] "Taser Display at Person, Taser"                                                                                                                                
#> [522] "Taser Display at Person, Taser, Verbal Command"                                                                                                                
#> [523] "Taser Display at Person, Verbal Command"                                                                                                                       
#> [524] "Taser Display at Person, Verbal Command, Foot Pursuit"                                                                                                         
#> [525] "Taser Display at Person, Verbal Command, Handcuffing Take Down"                                                                                                
#> [526] "Taser Display at Person, Verbal Command, Take Down - Body, Pressure Points"                                                                                    
#> [527] "Taser Display at Person, Verbal Command, Weapon display at Person"                                                                                             
#> [528] "Taser Display at Person, Weapon display at Person, Verbal Command"                                                                                             
#> [529] "Taser, BD - Grabbed"                                                                                                                                           
#> [530] "Taser, Feet/Leg/Knee Strike, Foot Pursuit"                                                                                                                     
#> [531] "Taser, Feet/Leg/Knee Strike, Verbal Command, Joint Locks, Pressure Points, Take Down - Group"                                                                  
#> [532] "Taser, Foot Pursuit"                                                                                                                                           
#> [533] "Taser, Foot Pursuit, BD - Pushed, Verbal Command"                                                                                                              
#> [534] "Taser, Foot Pursuit, Held Suspect Down"                                                                                                                        
#> [535] "Taser, Foot Pursuit, Verbal Command"                                                                                                                           
#> [536] "Taser, Hand Controlled Escort, Verbal Command"                                                                                                                 
#> [537] "Taser, Handcuffing Take Down"                                                                                                                                  
#> [538] "Taser, Handcuffing Take Down, Hand Controlled Escort"                                                                                                          
#> [539] "Taser, Held Suspect Down"                                                                                                                                      
#> [540] "Taser, Held Suspect Down, Held Suspect Down"                                                                                                                   
#> [541] "Taser, Joint Locks"                                                                                                                                            
#> [542] "Taser, OC Spray, Take Down - Body"                                                                                                                             
#> [543] "Taser, Take Down - Arm, Held Suspect Down"                                                                                                                     
#> [544] "Taser, Take Down - Body, Foot Pursuit"                                                                                                                         
#> [545] "Taser, Take Down - Body, Held Suspect Down"                                                                                                                    
#> [546] "Taser, Take Down - Body, Weapon display at Person"                                                                                                             
#> [547] "Taser, Take Down - Group"                                                                                                                                      
#> [548] "Taser, Take Down - Head"                                                                                                                                       
#> [549] "Taser, Taser"                                                                                                                                                  
#> [550] "Taser, Taser Display at Person, Verbal Command"                                                                                                                
#> [551] "Taser, Verbal Command"                                                                                                                                         
#> [552] "Taser, Verbal Command, BD - Pushed, BD - Grabbed, Held Suspect Down"                                                                                           
#> [553] "Taser, Verbal Command, Foot Pursuit"                                                                                                                           
#> [554] "Taser, Verbal Command, Hand Controlled Escort"                                                                                                                 
#> [555] "Taser, Weapon display at Person"                                                                                                                               
#> [556] "Vehicle Pursuit, Verbal Command, Weapon display at Person, Held Suspect Down"                                                                                  
#> [557] "Verbal Command"                                                                                                                                                
#> [558] "Verbal Command, 40mm Less Lethal, Taser"                                                                                                                       
#> [559] "Verbal Command, Baton Display"                                                                                                                                 
#> [560] "Verbal Command, BD - Grabbed"                                                                                                                                  
#> [561] "Verbal Command, BD - Grabbed, BD - Grabbed"                                                                                                                    
#> [562] "Verbal Command, BD - Grabbed, BD - Grabbed, BD - Grabbed"                                                                                                      
#> [563] "Verbal Command, BD - Grabbed, BD - Grabbed, Joint Locks, Feet/Leg/Knee Strike, Hand/Arm/Elbow Strike, BD - Pushed, BD - Pushed, BD - Grabbed"                  
#> [564] "Verbal Command, BD - Grabbed, BD - Grabbed, Take Down - Arm, BD - Pushed, BD - Tripped, BD - Grabbed"                                                          
#> [565] "Verbal Command, BD - Grabbed, BD - Grabbed, Weapon display at Person"                                                                                          
#> [566] "Verbal Command, BD - Grabbed, BD - Pushed"                                                                                                                     
#> [567] "Verbal Command, BD - Grabbed, BD - Pushed, BD - Grabbed"                                                                                                       
#> [568] "Verbal Command, BD - Grabbed, BD - Pushed, Held Suspect Down"                                                                                                  
#> [569] "Verbal Command, BD - Grabbed, BD - Pushed, Take Down - Body, Held Suspect Down, BD - Grabbed, Held Suspect Down, Held Suspect Down"                            
#> [570] "Verbal Command, BD - Grabbed, BD - Tripped, BD - Grabbed"                                                                                                      
#> [571] "Verbal Command, BD - Grabbed, BD - Tripped, Held Suspect Down"                                                                                                 
#> [572] "Verbal Command, BD - Grabbed, Foot Pursuit"                                                                                                                    
#> [573] "Verbal Command, BD - Grabbed, Foot Pursuit, Held Suspect Down"                                                                                                 
#> [574] "Verbal Command, BD - Grabbed, Foot Pursuit, Taser Display at Person, Held Suspect Down, Hand Controlled Escort"                                                
#> [575] "Verbal Command, BD - Grabbed, Hand Controlled Escort"                                                                                                          
#> [576] "Verbal Command, BD - Grabbed, Hand/Arm/Elbow Strike, Hand Controlled Escort"                                                                                   
#> [577] "Verbal Command, BD - Grabbed, Handcuffing Take Down, Hand/Arm/Elbow Strike"                                                                                    
#> [578] "Verbal Command, BD - Grabbed, Handcuffing Take Down, Hand/Arm/Elbow Strike, Held Suspect Down, BD - Grabbed"                                                   
#> [579] "Verbal Command, BD - Grabbed, Held Suspect Down"                                                                                                               
#> [580] "Verbal Command, BD - Grabbed, Held Suspect Down, BD - Pushed, Hand/Arm/Elbow Strike, Foot Pursuit"                                                             
#> [581] "Verbal Command, BD - Grabbed, Held Suspect Down, Handcuffing Take Down"                                                                                        
#> [582] "Verbal Command, BD - Grabbed, Held Suspect Down, Leg Restraint System"                                                                                         
#> [583] "Verbal Command, BD - Grabbed, Held Suspect Down, Take Down - Arm"                                                                                              
#> [584] "Verbal Command, BD - Grabbed, Joint Locks"                                                                                                                     
#> [585] "Verbal Command, BD - Grabbed, Joint Locks, Held Suspect Down"                                                                                                  
#> [586] "Verbal Command, BD - Grabbed, Joint Locks, Take Down - Arm"                                                                                                    
#> [587] "Verbal Command, BD - Grabbed, Joint Locks, Taser Display at Person, Held Suspect Down"                                                                         
#> [588] "Verbal Command, BD - Grabbed, Joint Locks, Taser Display at Person, Taser"                                                                                     
#> [589] "Verbal Command, BD - Grabbed, Pressure Points, Hand/Arm/Elbow Strike, BD - Pushed"                                                                             
#> [590] "Verbal Command, BD - Grabbed, Pressure Points, Hand/Arm/Elbow Strike, Handcuffing Take Down"                                                                   
#> [591] "Verbal Command, BD - Grabbed, Take Down - Arm"                                                                                                                 
#> [592] "Verbal Command, BD - Grabbed, Take Down - Arm, Held Suspect Down"                                                                                              
#> [593] "Verbal Command, BD - Grabbed, Take Down - Body"                                                                                                                
#> [594] "Verbal Command, BD - Grabbed, Take Down - Body, Held Suspect Down"                                                                                             
#> [595] "Verbal Command, BD - Grabbed, Take Down - Body, Held Suspect Down, Joint Locks, BD - Grabbed"                                                                  
#> [596] "Verbal Command, BD - Grabbed, Take Down - Group"                                                                                                               
#> [597] "Verbal Command, BD - Grabbed, Take Down - Group, Held Suspect Down"                                                                                            
#> [598] "Verbal Command, BD - Grabbed, Take Down - Group, Verbal Command, Held Suspect Down, BD - Grabbed"                                                              
#> [599] "Verbal Command, BD - Grabbed, Take Down - Head"                                                                                                                
#> [600] "Verbal Command, BD - Grabbed, Taser"                                                                                                                           
#> [601] "Verbal Command, BD - Grabbed, Taser Display at Person, BD - Pushed"                                                                                            
#> [602] "Verbal Command, BD - Grabbed, Taser Display at Person, Hand Controlled Escort, BD - Grabbed"                                                                   
#> [603] "Verbal Command, BD - Grabbed, Taser Display at Person, Taser, BD - Grabbed, Hand/Arm/Elbow Strike"                                                             
#> [604] "Verbal Command, BD - Grabbed, Taser, Take Down - Body"                                                                                                         
#> [605] "Verbal Command, BD - Grabbed, Verbal Command"                                                                                                                  
#> [606] "Verbal Command, BD - Pushed"                                                                                                                                   
#> [607] "Verbal Command, BD - Pushed, BD - Grabbed"                                                                                                                     
#> [608] "Verbal Command, BD - Pushed, BD - Grabbed, BD - Grabbed"                                                                                                       
#> [609] "Verbal Command, BD - Pushed, BD - Pushed"                                                                                                                      
#> [610] "Verbal Command, BD - Pushed, Hand Controlled Escort, Held Suspect Down"                                                                                        
#> [611] "Verbal Command, BD - Pushed, Held Suspect Down"                                                                                                                
#> [612] "Verbal Command, BD - Pushed, Held Suspect Down, Pressure Points, Hand Controlled Escort"                                                                       
#> [613] "Verbal Command, BD - Pushed, Held Suspect Down, Taser"                                                                                                         
#> [614] "Verbal Command, BD - Pushed, Held Suspect Down, Taser Display at Person, Hand/Arm/Elbow Strike"                                                                
#> [615] "Verbal Command, BD - Pushed, Held Suspect Down, Verbal Command"                                                                                                
#> [616] "Verbal Command, BD - Pushed, Taser Display at Person"                                                                                                          
#> [617] "Verbal Command, BD - Pushed, Verbal Command, Hand/Arm/Elbow Strike"                                                                                            
#> [618] "Verbal Command, BD - Tripped"                                                                                                                                  
#> [619] "Verbal Command, BD - Tripped, BD - Tripped, Hand Controlled Escort, Take Down - Body"                                                                          
#> [620] "Verbal Command, BD - Tripped, Held Suspect Down"                                                                                                               
#> [621] "Verbal Command, BD - Tripped, Held Suspect Down, Hand Controlled Escort, Joint Locks, Leg Restraint System, Pressure Points"                                   
#> [622] "Verbal Command, BD - Tripped, Joint Locks, Joint Locks"                                                                                                        
#> [623] "Verbal Command, BD - Tripped, Pressure Points"                                                                                                                 
#> [624] "Verbal Command, BD - Tripped, Taser, Feet/Leg/Knee Strike"                                                                                                     
#> [625] "Verbal Command, Combat Stance, Weapon display at Person, BD - Grabbed, Hand/Arm/Elbow Strike, Held Suspect Down"                                               
#> [626] "Verbal Command, Feet/Leg/Knee Strike"                                                                                                                          
#> [627] "Verbal Command, Feet/Leg/Knee Strike, Held Suspect Down"                                                                                                       
#> [628] "Verbal Command, Feet/Leg/Knee Strike, Held Suspect Down, BD - Grabbed, Held Suspect Down"                                                                      
#> [629] "Verbal Command, Foot Pursuit"                                                                                                                                  
#> [630] "Verbal Command, Foot Pursuit, BD - Grabbed"                                                                                                                    
#> [631] "Verbal Command, Foot Pursuit, BD - Grabbed, BD - Grabbed"                                                                                                      
#> [632] "Verbal Command, Foot Pursuit, BD - Grabbed, Held Suspect Down"                                                                                                 
#> [633] "Verbal Command, Foot Pursuit, BD - Grabbed, Held Suspect Down, Verbal Command, Pressure Points"                                                                
#> [634] "Verbal Command, Foot Pursuit, BD - Grabbed, Take Down - Body, Taser"                                                                                           
#> [635] "Verbal Command, Foot Pursuit, BD - Grabbed, Taser, Verbal Command, Foot Pursuit, Baton Strike/Open Mode, Held Suspect Down, Verbal Command, Baton Display"     
#> [636] "Verbal Command, Foot Pursuit, BD - Grabbed, Verbal Command, Held Suspect Down, Verbal Command, Hand/Arm/Elbow Strike"                                          
#> [637] "Verbal Command, Foot Pursuit, BD - Pushed"                                                                                                                     
#> [638] "Verbal Command, Foot Pursuit, BD - Pushed, Taser Display at Person, Joint Locks"                                                                               
#> [639] "Verbal Command, Foot Pursuit, Hand/Arm/Elbow Strike"                                                                                                           
#> [640] "Verbal Command, Foot Pursuit, Handcuffing Take Down"                                                                                                           
#> [641] "Verbal Command, Foot Pursuit, Held Suspect Down"                                                                                                               
#> [642] "Verbal Command, Foot Pursuit, Held Suspect Down, Joint Locks, Pressure Points"                                                                                 
#> [643] "Verbal Command, Foot Pursuit, Held Suspect Down, Verbal Command"                                                                                               
#> [644] "Verbal Command, Foot Pursuit, Take Down - Arm, Held Suspect Down, Joint Locks"                                                                                 
#> [645] "Verbal Command, Foot Pursuit, Take Down - Body"                                                                                                                
#> [646] "Verbal Command, Foot Pursuit, Take Down - Group, Verbal Command, Hand/Arm/Elbow Strike, Verbal Command"                                                        
#> [647] "Verbal Command, Foot Pursuit, Taser"                                                                                                                           
#> [648] "Verbal Command, Foot Pursuit, Taser Display at Person"                                                                                                         
#> [649] "Verbal Command, Foot Pursuit, Taser Display at Person, BD - Grabbed, Held Suspect Down"                                                                        
#> [650] "Verbal Command, Foot Pursuit, Taser Display at Person, Handcuffing Take Down"                                                                                  
#> [651] "Verbal Command, Foot Pursuit, Taser Display at Person, Take Down - Body, Hand Controlled Escort"                                                               
#> [652] "Verbal Command, Foot Pursuit, Taser, Verbal Command"                                                                                                           
#> [653] "Verbal Command, Foot Pursuit, Verbal Command"                                                                                                                  
#> [654] "Verbal Command, Foot Pursuit, Weapon display at Person"                                                                                                        
#> [655] "Verbal Command, Foot Pursuit, Weapon display at Person, Handcuffing Take Down"                                                                                 
#> [656] "Verbal Command, Foot Pursuit, Weapon display at Person, Take Down - Head"                                                                                      
#> [657] "Verbal Command, Hand Controlled Escort"                                                                                                                        
#> [658] "Verbal Command, Hand Controlled Escort, BD - Grabbed, Take Down - Arm"                                                                                         
#> [659] "Verbal Command, Hand Controlled Escort, BD - Grabbed, Taser, BD - Grabbed, Hand Controlled Escort"                                                             
#> [660] "Verbal Command, Hand Controlled Escort, BD - Pushed"                                                                                                           
#> [661] "Verbal Command, Hand Controlled Escort, BD - Pushed, Take Down - Arm"                                                                                          
#> [662] "Verbal Command, Hand Controlled Escort, Hand Controlled Escort, Joint Locks"                                                                                   
#> [663] "Verbal Command, Hand Controlled Escort, Hand Controlled Escort, Pressure Points"                                                                               
#> [664] "Verbal Command, Hand Controlled Escort, Held Suspect Down"                                                                                                     
#> [665] "Verbal Command, Hand Controlled Escort, Held Suspect Down, Held Suspect Down"                                                                                  
#> [666] "Verbal Command, Hand Controlled Escort, Held Suspect Down, Leg Restraint System"                                                                               
#> [667] "Verbal Command, Hand Controlled Escort, Held Suspect Down, Pressure Points"                                                                                    
#> [668] "Verbal Command, Hand Controlled Escort, Held Suspect Down, Take Down - Body"                                                                                   
#> [669] "Verbal Command, Hand Controlled Escort, Joint Locks"                                                                                                           
#> [670] "Verbal Command, Hand Controlled Escort, Joint Locks, BD - Pushed"                                                                                              
#> [671] "Verbal Command, Hand Controlled Escort, Joint Locks, Held Suspect Down"                                                                                        
#> [672] "Verbal Command, Hand Controlled Escort, Joint Locks, Held Suspect Down, Pressure Points, Feet/Leg/Knee Strike"                                                 
#> [673] "Verbal Command, Hand Controlled Escort, Pressure Points, Hand Controlled Escort, Joint Locks, Joint Locks"                                                     
#> [674] "Verbal Command, Hand Controlled Escort, Pressure Points, Held Suspect Down, Held Suspect Down"                                                                 
#> [675] "Verbal Command, Hand Controlled Escort, Take Down - Arm"                                                                                                       
#> [676] "Verbal Command, Hand Controlled Escort, Take Down - Arm, Held Suspect Down"                                                                                    
#> [677] "Verbal Command, Hand Controlled Escort, Take Down - Arm, Joint Locks, Held Suspect Down"                                                                       
#> [678] "Verbal Command, Hand Controlled Escort, Take Down - Body"                                                                                                      
#> [679] "Verbal Command, Hand Controlled Escort, Take Down - Body, Feet/Leg/Knee Strike, Held Suspect Down"                                                             
#> [680] "Verbal Command, Hand Controlled Escort, Take Down - Body, Feet/Leg/Knee Strike, Leg Restraint System"                                                          
#> [681] "Verbal Command, Hand Controlled Escort, Take Down - Body, Hand/Arm/Elbow Strike, Head Butt, Feet/Leg/Knee Strike"                                              
#> [682] "Verbal Command, Hand Controlled Escort, Take Down - Body, Held Suspect Down"                                                                                   
#> [683] "Verbal Command, Hand Controlled Escort, Take Down - Body, Held Suspect Down, BD - Grabbed"                                                                     
#> [684] "Verbal Command, Hand Controlled Escort, Take Down - Body, Held Suspect Down, Hand/Arm/Elbow Strike"                                                            
#> [685] "Verbal Command, Hand Controlled Escort, Take Down - Body, Held Suspect Down, Take Down - Body, Joint Locks, Foot Pursuit"                                      
#> [686] "Verbal Command, Hand Controlled Escort, Take Down - Body, Joint Locks, Held Suspect Down"                                                                      
#> [687] "Verbal Command, Hand Controlled Escort, Take Down - Body, Pressure Points"                                                                                     
#> [688] "Verbal Command, Hand Controlled Escort, Take Down - Body, Pressure Points, Held Suspect Down"                                                                  
#> [689] "Verbal Command, Hand Controlled Escort, Take Down - Group"                                                                                                     
#> [690] "Verbal Command, Hand Controlled Escort, Take Down - Group, Held Suspect Down"                                                                                  
#> [691] "Verbal Command, Hand Controlled Escort, Take Down - Head, Handcuffing Take Down, Take Down - Group"                                                            
#> [692] "Verbal Command, Hand Controlled Escort, Taser"                                                                                                                 
#> [693] "Verbal Command, Hand Controlled Escort, Taser Display at Person, OC Spray, BD - Tripped, Held Suspect Down, Feet/Leg/Knee Strike"                              
#> [694] "Verbal Command, Hand Controlled Escort, Verbal Command, BD - Grabbed"                                                                                          
#> [695] "Verbal Command, Hand Controlled Escort, Verbal Command, Take Down - Body, Held Suspect Down"                                                                   
#> [696] "Verbal Command, Hand/Arm/Elbow Strike"                                                                                                                         
#> [697] "Verbal Command, Hand/Arm/Elbow Strike, Feet/Leg/Knee Strike, Held Suspect Down"                                                                                
#> [698] "Verbal Command, Hand/Arm/Elbow Strike, Hand/Arm/Elbow Strike"                                                                                                  
#> [699] "Verbal Command, Hand/Arm/Elbow Strike, Handcuffing Take Down"                                                                                                  
#> [700] "Verbal Command, Hand/Arm/Elbow Strike, Held Suspect Down"                                                                                                      
#> [701] "Verbal Command, Hand/Arm/Elbow Strike, Held Suspect Down, Hand Controlled Escort"                                                                              
#> [702] "Verbal Command, Hand/Arm/Elbow Strike, Take Down - Body, Held Suspect Down, Verbal Command"                                                                    
#> [703] "Verbal Command, Hand/Arm/Elbow Strike, Take Down - Body, Joint Locks"                                                                                          
#> [704] "Verbal Command, Hand/Arm/Elbow Strike, Take Down - Group"                                                                                                      
#> [705] "Verbal Command, Hand/Arm/Elbow Strike, Take Down - Group, Handcuffing Take Down"                                                                               
#> [706] "Verbal Command, Hand/Arm/Elbow Strike, Verbal Command"                                                                                                         
#> [707] "Verbal Command, Hand/Arm/Elbow Strike, Verbal Command, Feet/Leg/Knee Strike"                                                                                   
#> [708] "Verbal Command, Handcuffing Take Down"                                                                                                                         
#> [709] "Verbal Command, Handcuffing Take Down, BD - Tripped"                                                                                                           
#> [710] "Verbal Command, Handcuffing Take Down, Foot Pursuit"                                                                                                           
#> [711] "Verbal Command, Handcuffing Take Down, Hand Controlled Escort"                                                                                                 
#> [712] "Verbal Command, Handcuffing Take Down, Held Suspect Down"                                                                                                      
#> [713] "Verbal Command, Handcuffing Take Down, Held Suspect Down, Joint Locks, Hand/Arm/Elbow Strike"                                                                  
#> [714] "Verbal Command, Handcuffing Take Down, Held Suspect Down, Leg Restraint System"                                                                                
#> [715] "Verbal Command, Handcuffing Take Down, Held Suspect Down, LVNR"                                                                                                
#> [716] "Verbal Command, Handcuffing Take Down, Joint Locks"                                                                                                            
#> [717] "Verbal Command, Handcuffing Take Down, Taser Display at Person, Held Suspect Down"                                                                             
#> [718] "Verbal Command, Handcuffing Take Down, Verbal Command"                                                                                                         
#> [719] "Verbal Command, Held Suspect Down"                                                                                                                             
#> [720] "Verbal Command, Held Suspect Down, BD - Grabbed"                                                                                                               
#> [721] "Verbal Command, Held Suspect Down, BD - Pushed"                                                                                                                
#> [722] "Verbal Command, Held Suspect Down, BD - Tripped, Joint Locks, Take Down - Body"                                                                                
#> [723] "Verbal Command, Held Suspect Down, BD - Tripped, Take Down - Body"                                                                                             
#> [724] "Verbal Command, Held Suspect Down, Feet/Leg/Knee Strike"                                                                                                       
#> [725] "Verbal Command, Held Suspect Down, Foot Pursuit"                                                                                                               
#> [726] "Verbal Command, Held Suspect Down, Hand Controlled Escort"                                                                                                     
#> [727] "Verbal Command, Held Suspect Down, Hand Controlled Escort, Leg Restraint System"                                                                               
#> [728] "Verbal Command, Held Suspect Down, Hand Controlled Escort, Taser, Foot Pursuit"                                                                                
#> [729] "Verbal Command, Held Suspect Down, Hand/Arm/Elbow Strike"                                                                                                      
#> [730] "Verbal Command, Held Suspect Down, Hand/Arm/Elbow Strike, Take Down - Arm, Foot Pursuit"                                                                       
#> [731] "Verbal Command, Held Suspect Down, Held Suspect Down"                                                                                                          
#> [732] "Verbal Command, Held Suspect Down, Held Suspect Down, Handcuffing Take Down"                                                                                   
#> [733] "Verbal Command, Held Suspect Down, Held Suspect Down, Held Suspect Down, Take Down - Body, Held Suspect Down"                                                  
#> [734] "Verbal Command, Held Suspect Down, Joint Locks"                                                                                                                
#> [735] "Verbal Command, Held Suspect Down, Pressure Points"                                                                                                            
#> [736] "Verbal Command, Held Suspect Down, Take Down - Arm"                                                                                                            
#> [737] "Verbal Command, Held Suspect Down, Take Down - Body"                                                                                                           
#> [738] "Verbal Command, Held Suspect Down, Take Down - Head"                                                                                                           
#> [739] "Verbal Command, Held Suspect Down, Taser Display at Person, Take Down - Arm, Take Down - Head"                                                                 
#> [740] "Verbal Command, Held Suspect Down, Taser Display at Person, Verbal Command, Taser"                                                                             
#> [741] "Verbal Command, Held Suspect Down, Verbal Command, Feet/Leg/Knee Strike"                                                                                       
#> [742] "Verbal Command, Held Suspect Down, Verbal Command, Foot Pursuit"                                                                                               
#> [743] "Verbal Command, Held Suspect Down, Verbal Command, Handcuffing Take Down"                                                                                      
#> [744] "Verbal Command, Joint Locks"                                                                                                                                   
#> [745] "Verbal Command, Joint Locks, BD - Grabbed"                                                                                                                     
#> [746] "Verbal Command, Joint Locks, BD - Grabbed, Held Suspect Down"                                                                                                  
#> [747] "Verbal Command, Joint Locks, BD - Pushed"                                                                                                                      
#> [748] "Verbal Command, Joint Locks, Feet/Leg/Knee Strike"                                                                                                             
#> [749] "Verbal Command, Joint Locks, Hand Controlled Escort"                                                                                                           
#> [750] "Verbal Command, Joint Locks, Hand Controlled Escort, BD - Grabbed"                                                                                             
#> [751] "Verbal Command, Joint Locks, Hand Controlled Escort, Held Suspect Down"                                                                                        
#> [752] "Verbal Command, Joint Locks, Hand Controlled Escort, Held Suspect Down, Leg Restraint System"                                                                  
#> [753] "Verbal Command, Joint Locks, Handcuffing Take Down"                                                                                                            
#> [754] "Verbal Command, Joint Locks, Held Suspect Down"                                                                                                                
#> [755] "Verbal Command, Joint Locks, Held Suspect Down, BD - Grabbed"                                                                                                  
#> [756] "Verbal Command, Joint Locks, Held Suspect Down, Hand/Arm/Elbow Strike, Take Down - Arm"                                                                        
#> [757] "Verbal Command, Joint Locks, Held Suspect Down, Take Down - Arm, Held Suspect Down, Hand Controlled Escort"                                                    
#> [758] "Verbal Command, Joint Locks, Held Suspect Down, Take Down - Arm, Held Suspect Down, Hand Controlled Escort, Take Down - Head, BD - Pushed"                     
#> [759] "Verbal Command, Joint Locks, Held Suspect Down, Take Down - Arm, Take Down - Body"                                                                             
#> [760] "Verbal Command, Joint Locks, Held Suspect Down, Taser Display at Person, BD - Pushed"                                                                          
#> [761] "Verbal Command, Joint Locks, Joint Locks, Pressure Points, Joint Locks"                                                                                        
#> [762] "Verbal Command, Joint Locks, Pressure Points"                                                                                                                  
#> [763] "Verbal Command, Joint Locks, Take Down - Arm"                                                                                                                  
#> [764] "Verbal Command, Joint Locks, Take Down - Arm, Held Suspect Down"                                                                                               
#> [765] "Verbal Command, Joint Locks, Take Down - Body"                                                                                                                 
#> [766] "Verbal Command, Joint Locks, Take Down - Body, Held Suspect Down"                                                                                              
#> [767] "Verbal Command, Joint Locks, Take Down - Body, Held Suspect Down, Hand Controlled Escort, BD - Pushed"                                                         
#> [768] "Verbal Command, Joint Locks, Take Down - Head"                                                                                                                 
#> [769] "Verbal Command, Leg Restraint System"                                                                                                                          
#> [770] "Verbal Command, Leg Restraint System, Hand Controlled Escort"                                                                                                  
#> [771] "Verbal Command, OC Spray"                                                                                                                                      
#> [772] "Verbal Command, OC Spray, Foot Pursuit"                                                                                                                        
#> [773] "Verbal Command, Pepperball Saturation, Pepperball Impact"                                                                                                      
#> [774] "Verbal Command, Pressure Points"                                                                                                                               
#> [775] "Verbal Command, Pressure Points, Held Suspect Down, Joint Locks"                                                                                               
#> [776] "Verbal Command, Pressure Points, Pressure Points"                                                                                                              
#> [777] "Verbal Command, Pressure Points, Verbal Command"                                                                                                               
#> [778] "Verbal Command, Take Down - Arm"                                                                                                                               
#> [779] "Verbal Command, Take Down - Arm, BD - Pushed, Held Suspect Down"                                                                                               
#> [780] "Verbal Command, Take Down - Arm, BD - Tripped"                                                                                                                 
#> [781] "Verbal Command, Take Down - Arm, BD - Tripped, Held Suspect Down, Joint Locks"                                                                                 
#> [782] "Verbal Command, Take Down - Arm, Feet/Leg/Knee Strike"                                                                                                         
#> [783] "Verbal Command, Take Down - Arm, Foot Pursuit, Taser"                                                                                                          
#> [784] "Verbal Command, Take Down - Arm, Hand Controlled Escort"                                                                                                       
#> [785] "Verbal Command, Take Down - Arm, Hand/Arm/Elbow Strike, Feet/Leg/Knee Strike, Feet/Leg/Knee Strike, Held Suspect Down, BD - Pushed"                            
#> [786] "Verbal Command, Take Down - Arm, Hand/Arm/Elbow Strike, Joint Locks"                                                                                           
#> [787] "Verbal Command, Take Down - Arm, Handcuffing Take Down"                                                                                                        
#> [788] "Verbal Command, Take Down - Arm, Held Suspect Down"                                                                                                            
#> [789] "Verbal Command, Take Down - Arm, Held Suspect Down, BD - Grabbed"                                                                                              
#> [790] "Verbal Command, Take Down - Arm, Held Suspect Down, Feet/Leg/Knee Strike"                                                                                      
#> [791] "Verbal Command, Take Down - Arm, Held Suspect Down, Handcuffing Take Down"                                                                                     
#> [792] "Verbal Command, Take Down - Arm, Joint Locks"                                                                                                                  
#> [793] "Verbal Command, Take Down - Arm, Joint Locks, Held Suspect Down, Handcuffing Take Down"                                                                        
#> [794] "Verbal Command, Take Down - Arm, Joint Locks, Pressure Points"                                                                                                 
#> [795] "Verbal Command, Take Down - Arm, Joint Locks, Verbal Command"                                                                                                  
#> [796] "Verbal Command, Take Down - Arm, Pressure Points, Joint Locks, Held Suspect Down"                                                                              
#> [797] "Verbal Command, Take Down - Arm, Take Down - Arm, Held Suspect Down"                                                                                           
#> [798] "Verbal Command, Take Down - Arm, Take Down - Body, Held Suspect Down, Weapon display at Person"                                                                
#> [799] "Verbal Command, Take Down - Arm, Take Down - Head, Held Suspect Down"                                                                                          
#> [800] "Verbal Command, Take Down - Arm, Taser Display at Person, Take Down - Arm"                                                                                     
#> [801] "Verbal Command, Take Down - Arm, Taser, Foot Pursuit, Taser"                                                                                                   
#> [802] "Verbal Command, Take Down - Arm, Verbal Command"                                                                                                               
#> [803] "Verbal Command, Take Down - Arm, Weapon display at Person, Other Impact Weapon"                                                                                
#> [804] "Verbal Command, Take Down - Body"                                                                                                                              
#> [805] "Verbal Command, Take Down - Body, BD - Grabbed"                                                                                                                
#> [806] "Verbal Command, Take Down - Body, BD - Grabbed, BD - Pushed, Joint Locks, Held Suspect Down, Taser Display at Person"                                          
#> [807] "Verbal Command, Take Down - Body, Feet/Leg/Knee Strike, Held Suspect Down, Hand/Arm/Elbow Strike"                                                              
#> [808] "Verbal Command, Take Down - Body, Hand/Arm/Elbow Strike"                                                                                                       
#> [809] "Verbal Command, Take Down - Body, Handcuffing Take Down"                                                                                                       
#> [810] "Verbal Command, Take Down - Body, Held Suspect Down"                                                                                                           
#> [811] "Verbal Command, Take Down - Body, Held Suspect Down, BD - Pushed"                                                                                              
#> [812] "Verbal Command, Take Down - Body, Held Suspect Down, Foot Pursuit"                                                                                             
#> [813] "Verbal Command, Take Down - Body, Held Suspect Down, Joint Locks"                                                                                              
#> [814] "Verbal Command, Take Down - Body, Held Suspect Down, Leg Restraint System"                                                                                     
#> [815] "Verbal Command, Take Down - Body, Held Suspect Down, Verbal Command, Joint Locks"                                                                              
#> [816] "Verbal Command, Take Down - Body, Joint Locks"                                                                                                                 
#> [817] "Verbal Command, Take Down - Body, Taser"                                                                                                                       
#> [818] "Verbal Command, Take Down - Body, Taser, Feet/Leg/Knee Strike, Take Down - Body, Hand/Arm/Elbow Strike, BD - Grabbed, Hand/Arm/Elbow Strike, Held Suspect Down"
#> [819] "Verbal Command, Take Down - Body, Verbal Command"                                                                                                              
#> [820] "Verbal Command, Take Down - Body, Verbal Command, Hand/Arm/Elbow Strike, Verbal Command"                                                                       
#> [821] "Verbal Command, Take Down - Body, Verbal Command, Hand/Arm/Elbow Strike, Verbal Command, Foot Pursuit"                                                         
#> [822] "Verbal Command, Take Down - Group"                                                                                                                             
#> [823] "Verbal Command, Take Down - Group, Handcuffing Take Down"                                                                                                      
#> [824] "Verbal Command, Take Down - Group, Taser Display at Person, Held Suspect Down"                                                                                 
#> [825] "Verbal Command, Take Down - Head"                                                                                                                              
#> [826] "Verbal Command, Take Down - Head, Hand/Arm/Elbow Strike"                                                                                                       
#> [827] "Verbal Command, Take Down - Head, Held Suspect Down, BD - Grabbed, LVNR"                                                                                       
#> [828] "Verbal Command, Take Down - Head, Held Suspect Down, Taser, Foot Pursuit"                                                                                      
#> [829] "Verbal Command, Take Down - Head, Joint Locks"                                                                                                                 
#> [830] "Verbal Command, Take Down - Head, Take Down - Body, Held Suspect Down, Taser Display at Person"                                                                
#> [831] "Verbal Command, Taser"                                                                                                                                         
#> [832] "Verbal Command, Taser Display at Person"                                                                                                                       
#> [833] "Verbal Command, Taser Display at Person, BD - Grabbed"                                                                                                         
#> [834] "Verbal Command, Taser Display at Person, BD - Grabbed, BD - Tripped"                                                                                           
#> [835] "Verbal Command, Taser Display at Person, BD - Pushed, Take Down - Body, Held Suspect Down, Foot Pursuit"                                                       
#> [836] "Verbal Command, Taser Display at Person, BD - Tripped, Held Suspect Down"                                                                                      
#> [837] "Verbal Command, Taser Display at Person, Feet/Leg/Knee Strike, Hand/Arm/Elbow Strike, Held Suspect Down, BD - Grabbed, Foot Pursuit"                           
#> [838] "Verbal Command, Taser Display at Person, Foot Pursuit"                                                                                                         
#> [839] "Verbal Command, Taser Display at Person, Foot Pursuit, Take Down - Body"                                                                                       
#> [840] "Verbal Command, Taser Display at Person, Handcuffing Take Down"                                                                                                
#> [841] "Verbal Command, Taser Display at Person, Held Suspect Down, Pressure Points, BD - Tripped"                                                                     
#> [842] "Verbal Command, Taser Display at Person, OC Spray, Held Suspect Down"                                                                                          
#> [843] "Verbal Command, Taser Display at Person, Take Down - Arm, BD - Tripped"                                                                                        
#> [844] "Verbal Command, Taser Display at Person, Take Down - Body"                                                                                                     
#> [845] "Verbal Command, Taser Display at Person, Taser"                                                                                                                
#> [846] "Verbal Command, Taser Display at Person, Taser, Joint Locks"                                                                                                   
#> [847] "Verbal Command, Taser Display at Person, Taser, Take Down - Group, Hand/Arm/Elbow Strike"                                                                      
#> [848] "Verbal Command, Taser Display at Person, Taser, Taser"                                                                                                         
#> [849] "Verbal Command, Taser Display at Person, Verbal Command, Foot Pursuit"                                                                                         
#> [850] "Verbal Command, Taser Display at Person, Weapon display at Person, Held Suspect Down, Hand Controlled Escort"                                                  
#> [851] "Verbal Command, Taser, Feet/Leg/Knee Strike, Feet/Leg/Knee Strike"                                                                                             
#> [852] "Verbal Command, Taser, Foot Pursuit"                                                                                                                           
#> [853] "Verbal Command, Taser, Hand/Arm/Elbow Strike, Foot Pursuit, Weapon display at Person"                                                                          
#> [854] "Verbal Command, Taser, Held Suspect Down"                                                                                                                      
#> [855] "Verbal Command, Taser, Take Down - Body"                                                                                                                       
#> [856] "Verbal Command, Taser, Taser, Taser, BD - Grabbed, Held Suspect Down"                                                                                          
#> [857] "Verbal Command, Taser, Verbal Command, Foot Pursuit"                                                                                                           
#> [858] "Verbal Command, Verbal Command, BD - Grabbed, BD - Grabbed, Verbal Command, Held Suspect Down, BD - Grabbed"                                                   
#> [859] "Verbal Command, Verbal Command, Foot Pursuit"                                                                                                                  
#> [860] "Verbal Command, Verbal Command, Foot Pursuit, Take Down - Body, Held Suspect Down"                                                                             
#> [861] "Verbal Command, Verbal Command, Taser Display at Person"                                                                                                       
#> [862] "Verbal Command, Verbal Command, Taser Display at Person, Held Suspect Down"                                                                                    
#> [863] "Verbal Command, Weapon display at Person"                                                                                                                      
#> [864] "Verbal Command, Weapon display at Person, BD - Pushed"                                                                                                         
#> [865] "Verbal Command, Weapon display at Person, BD - Tripped"                                                                                                        
#> [866] "Verbal Command, Weapon display at Person, Feet/Leg/Knee Strike"                                                                                                
#> [867] "Verbal Command, Weapon display at Person, Foot Pursuit"                                                                                                        
#> [868] "Verbal Command, Weapon display at Person, Foot Pursuit, Combat Stance"                                                                                         
#> [869] "Verbal Command, Weapon display at Person, Foot Pursuit, Taser Display at Person"                                                                               
#> [870] "Verbal Command, Weapon display at Person, Hand Controlled Escort, BD - Grabbed"                                                                                
#> [871] "Verbal Command, Weapon display at Person, Hand Controlled Escort, Foot Pursuit, Taser, Held Suspect Down"                                                      
#> [872] "Verbal Command, Weapon display at Person, Hand Controlled Escort, Taser Display at Person"                                                                     
#> [873] "Verbal Command, Weapon display at Person, Hand/Arm/Elbow Strike"                                                                                               
#> [874] "Verbal Command, Weapon display at Person, Handcuffing Take Down, Held Suspect Down"                                                                            
#> [875] "Verbal Command, Weapon display at Person, Handcuffing Take Down, Held Suspect Down, Taser Display at Person"                                                   
#> [876] "Verbal Command, Weapon display at Person, Held Suspect Down"                                                                                                   
#> [877] "Verbal Command, Weapon display at Person, Leg Restraint System, Joint Locks"                                                                                   
#> [878] "Verbal Command, Weapon display at Person, Take Down - Arm"                                                                                                     
#> [879] "Verbal Command, Weapon display at Person, Taser Display at Person"                                                                                             
#> [880] "Verbal Command, Weapon display at Person, Taser Display at Person, BD - Pushed, Take Down - Body, Foot Pursuit"                                                
#> [881] "Verbal Command, Weapon display at Person, Taser Display at Person, Held Suspect Down"                                                                          
#> [882] "Verbal Command, Weapon display at Person, Taser Display at Person, Joint Locks, Feet/Leg/Knee Strike"                                                          
#> [883] "Weapon display at Person"                                                                                                                                      
#> [884] "Weapon display at Person, BD - Grabbed"                                                                                                                        
#> [885] "Weapon display at Person, BD - Grabbed, Feet/Leg/Knee Strike, BD - Pushed"                                                                                     
#> [886] "Weapon display at Person, Feet/Leg/Knee Strike, BD - Pushed"                                                                                                   
#> [887] "Weapon display at Person, Foot Pursuit"                                                                                                                        
#> [888] "Weapon display at Person, Foot Pursuit, Take Down - Body"                                                                                                      
#> [889] "Weapon display at Person, Foot Pursuit, Taser"                                                                                                                 
#> [890] "Weapon display at Person, Hand/Arm/Elbow Strike"                                                                                                               
#> [891] "Weapon display at Person, Handcuffing Take Down"                                                                                                               
#> [892] "Weapon display at Person, Held Suspect Down"                                                                                                                   
#> [893] "Weapon display at Person, Held Suspect Down, Foot Pursuit"                                                                                                     
#> [894] "Weapon display at Person, Held Suspect Down, Verbal Command"                                                                                                   
#> [895] "Weapon display at Person, Joint Locks, Take Down - Body"                                                                                                       
#> [896] "Weapon display at Person, Joint Locks, Taser Display at Person, Verbal Command, Held Suspect Down"                                                             
#> [897] "Weapon display at Person, K-9 Deployment, Held Suspect Down"                                                                                                   
#> [898] "Weapon display at Person, Take Down - Arm, Weapon display at Person"                                                                                           
#> [899] "Weapon display at Person, Take Down - Body, Foot Pursuit"                                                                                                      
#> [900] "Weapon display at Person, Take Down - Body, Verbal Command, Held Suspect Down"                                                                                 
#> [901] "Weapon display at Person, Take Down - Group, Held Suspect Down"                                                                                                
#> [902] "Weapon display at Person, Taser Display at Person"                                                                                                             
#> [903] "Weapon display at Person, Taser Display at Person, Take Down - Group"                                                                                          
#> [904] "Weapon display at Person, Taser Display at Person, Verbal Command"                                                                                             
#> [905] "Weapon display at Person, Taser Display at Person, Verbal Command, Taser, Held Suspect Down, Verbal Command, Hand/Arm/Elbow Strike, Pressure Points"           
#> [906] "Weapon display at Person, Verbal Command"                                                                                                                      
#> [907] "Weapon display at Person, Verbal Command, BD - Pushed, Handcuffing Take Down"                                                                                  
#> [908] "Weapon display at Person, Verbal Command, Foot Pursuit"                                                                                                        
#> [909] "Weapon display at Person, Verbal Command, Handcuffing Take Down"                                                                                               
#> [910] "Weapon display at Person, Verbal Command, Held Suspect Down"                                                                                                   
#> [911] "Weapon display at Person, Verbal Command, Held Suspect Down, Joint Locks"                                                                                      
#> [912] "Weapon display at Person, Verbal Command, Take Down - Arm"                                                                                                     
#> [913] "Weapon display at Person, Verbal Command, Take Down - Arm, Held Suspect Down"                                                                                  
#> [914] "Weapon display at Person, Verbal Command, Take Down - Body, Held Suspect Down"                                                                                 
#> [915] "Weapon display at Person, Verbal Command, Taser Display at Person"
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
