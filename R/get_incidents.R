# R/get_incidents.R

#' Fetch Dallas Police Incident Data
#'
#' Retrieves incident data from the Dallas Open Data portal API
#' (SODA endpoint qv6i-rri7). Optionally converts coordinates to a geographic object.
#'
#' @description
#' This function queries the Socrata Open Data API (SODA) for Dallas Police
#' Incidents. It allows filtering by date range, NIBRS crime classifications,
#' geographic areas (zip, beat, division, sector, district) and supports
#' retrieving large datasets through automatic pagination.
#'
#' If the `where` argument is provided, it overrides all other filter arguments.
#'
#' If `convert_geo = TRUE`, the function attempts to convert the resulting
#' tibble into a spatial `sf` object using the `x_coordinate` and `y_cordinate`
#' columns, assuming they are in the NAD83 Texas North Central (ftUS) coordinate
#' system (EPSG:2276). Requires the `sf` package to be installed.
#'
#' @param start_date Optional. A character string in 'YYYY-MM-DD' format or a
#'   Date object specifying the minimum incident date (inclusive, based on `date1` field).
#' @param end_date Optional. A character string in 'YYYY-MM-DD' format or a
#'   Date object specifying the maximum incident date (inclusive, based on `date1` field).
#' @param nibrs_group Optional. A character vector of NIBRS Group codes (e.g., 'A', 'B')
#'   to filter incidents.
#' @param nibrs_code Optional. A character vector of specific NIBRS offense codes
#'   (e.g., '13A', '23F') to filter incidents.
#' @param nibrs_crime_against Optional. A character vector specifying the NIBRS
#'   'Crime Against' category (e.g., 'PERSON', 'PROPERTY', 'SOCIETY'). Filters
#'   on the API field `nibrs_crimeagainst`.
#' @param zip_code Optional. A character or numeric vector of Zip Code(s) to filter incidents.
#' @param beat Optional. A character or numeric vector of Police Beat(s) to filter incidents.
#' @param division Optional. A character vector of Police Division names (e.g., 'CENTRAL',
#'   'NORTHWEST') to filter incidents.
#' @param sector Optional. A character or numeric vector of Police Sector(s) to filter incidents.
#' @param district Optional. A character vector of Police District names (e.g., 'SOUTHEAST', 'NORTH CENTRAL')
#'   to filter incidents.
#' @param convert_geo Logical. If `TRUE`, attempt to convert the data frame to an
#'   `sf` object using `x_coordinate` and `y_cordinate`. Requires the `sf`
#'   package to be installed. Defaults to `FALSE`. Assumes coordinates are in
#'   NAD83 Texas North Central (ftUS) (EPSG:2276).
#' @param limit The maximum number of records to return. Defaults to 1000.
#'   Use `limit = Inf` to attempt retrieving all matching records.
#' @param select A character vector specifying which columns to retrieve.
#'   If `convert_geo = TRUE`, ensure `x_coordinate` and `y_cordinate` are included
#'   or conversion will fail. If NULL (default), all columns are retrieved.
#' @param where An optional character string containing a custom SoQL WHERE clause.
#'   Overrides other filter arguments if provided.
#' @param ... Additional SODA query parameters passed directly to the API URL,
#'   (e.g., `$order = "date1 DESC"`).
#'
#' @return A `tibble` by default. If `convert_geo = TRUE` and the `sf` package
#'   is installed and coordinates are valid, returns an `sf` object with point geometry
#'   using CRS EPSG:2276. Otherwise, returns a `tibble` with a warning if conversion failed.
#' @export
#'
#' @importFrom httr GET http_type content stop_for_status modify_url user_agent
#' @importFrom jsonlite fromJSON
#' @importFrom dplyr bind_rows as_tibble tibble filter select mutate all_of arrange relocate last_col
#' @importFrom rlang check_installed is_installed inform .data warn abort
#' @importFrom utils URLencode
# No direct @importFrom sf here, as it's suggested. We use requireNamespace checks.
#'
#' @examples
#' \dontrun{
#' # Get recent data as a standard tibble
#' recent_tibble <- get_incidents(limit = 10, `$order` = "date1 DESC")
#' print(class(recent_tibble))
#'
#' # Get recent data as an sf object (requires the sf package)
#' # install.packages("sf")
#' recent_sf <- get_incidents(limit = 10, `$order` = "date1 DESC", convert_geo = TRUE) # Changed here
#' print(class(recent_sf))
#' if (inherits(recent_sf, "sf")) {
#'   print(sf::st_crs(recent_sf)) # Check CRS - should show EPSG 2276
#'   # Plotting might require transformation depending on the base map context
#'   # Simple plot of the geometry:
#'   # plot(sf::st_geometry(recent_sf))
#'
#'   # Example transformation to WGS84 (Lat/Lon) for use with leaflet, etc.
#'   # recent_sf_wgs84 <- sf::st_transform(recent_sf, crs = 4326)
#'   # print(sf::st_crs(recent_sf_wgs84))
#' }
#'
#' # Filter and get as sf object
#' central_burglaries_sf <- get_incidents(
#'    division = "CENTRAL",
#'    nibrs_code = "220", # Check code for Burglary/B&E
#'    start_date = "2024-03-01",
#'    end_date = "2024-03-31",
#'    convert_geo = TRUE, # Changed here
#'    limit = 50
#' )
#' if (inherits(central_burglaries_sf, "sf")) {
#'    print(central_burglaries_sf)
#' }
#'
#' # Using select - make sure to include coordinates if converting!
#' selected_sf <- get_incidents(
#'    limit = 5,
#'    select = c("date1", "nibrs_code", "x_coordinate", "y_cordinate"),
#'    convert_geo = TRUE # Changed here
#' )
#' print(selected_sf)
#' }
get_incidents <- function(start_date = NULL, end_date = NULL,
                          # NIBRS Crime Filters
                          nibrs_group = NULL,
                          nibrs_code = NULL,
                          nibrs_crime_against = NULL,
                          # Geography Filters
                          zip_code = NULL,
                          beat = NULL,
                          division = NULL,
                          sector = NULL,
                          district = NULL,
                          # Control Parameters
                          convert_geo = FALSE, # *** RENAMED ARGUMENT ***
                          limit = 1000, select = NULL, where = NULL, ...) {

  # --- Input Validation & Dependency Checks ---
  rlang::check_installed("httr", reason = "to fetch data from the API.")
  rlang::check_installed("jsonlite", reason = "to parse JSON data.")
  rlang::check_installed("dplyr", reason = "for data manipulation.")

  if (!is.logical(convert_geo) || length(convert_geo) != 1) { # Changed here
    stop("`convert_geo` must be TRUE or FALSE.", call. = FALSE) # Changed here
  }
  if (!is.numeric(limit) || limit <= 0) {
    stop("`limit` must be a positive number or Inf.", call. = FALSE)
  }

  # --- Base URL and Query Parameters ---
  base_url <- "https://www.dallasopendata.com/resource/qv6i-rri7.json"
  ua <- httr::user_agent("dallasopendata/0.1.0 (https://github.com/galvanthony/dallasopendata)") # Customize!

  query_params <- list(...)

  # --- Filtering Logic ---
  all_where_clauses <- list()
  sql_in_clause <- function(field, values) {
    # (Helper function as defined previously)
    if (is.null(values) || length(values) == 0) return(NULL)
    quoted_values <- sapply(values, function(v) {
      if (is.character(v)) {
        v_escaped <- gsub("'", "''", v)
        paste0("'", v_escaped, "'")
      } else { as.character(v) }
    })
    paste0(field, " IN (", paste(quoted_values, collapse = ", "), ")")
  }

  if (is.null(where)) {
    # -- Date filtering --
    if (!is.null(start_date)) {
      tryCatch({
        start_date_fmt <- format(as.Date(start_date), "%Y-%m-%dT00:00:00")
        all_where_clauses <- c(all_where_clauses, paste0("date1 >= '", start_date_fmt, "'"))
      }, error = function(e) stop("`start_date` invalid.", call. = FALSE))
    }
    if (!is.null(end_date)) {
      tryCatch({
        end_date_exclusive_fmt <- format(as.Date(end_date) + 1, "%Y-%m-%dT00:00:00")
        all_where_clauses <- c(all_where_clauses, paste0("date1 < '", end_date_exclusive_fmt, "'"))
      }, error = function(e) stop("`end_date` invalid.", call. = FALSE))
    }
    # -- NIBRS Filters --
    if (!is.null(nibrs_group)) {
      if(!is.character(nibrs_group)) stop("`nibrs_group` must be char.", call. = FALSE)
      clause <- sql_in_clause("nibrs_group", nibrs_group)
      if (!is.null(clause)) all_where_clauses <- c(all_where_clauses, clause)
    }
    if (!is.null(nibrs_code)) {
      if(!is.character(nibrs_code)) stop("`nibrs_code` must be char.", call. = FALSE)
      clause <- sql_in_clause("nibrs_code", nibrs_code)
      if (!is.null(clause)) all_where_clauses <- c(all_where_clauses, clause)
    }
    if (!is.null(nibrs_crime_against)) {
      if(!is.character(nibrs_crime_against)) stop("`nibrs_crime_against` must be char.", call. = FALSE)
      clause <- sql_in_clause("nibrs_crimeagainst", nibrs_crime_against)
      if (!is.null(clause)) all_where_clauses <- c(all_where_clauses, clause)
    }
    # -- Geography Filters --
    if (!is.null(zip_code)) {
      if(!is.character(zip_code) && !is.numeric(zip_code)) stop("`zip_code` invalid type.", call. = FALSE)
      clause <- sql_in_clause("zip_code", as.character(zip_code))
      if (!is.null(clause)) all_where_clauses <- c(all_where_clauses, clause)
    }
    if (!is.null(beat)) {
      if(!is.character(beat) && !is.numeric(beat)) stop("`beat` invalid type.", call. = FALSE)
      clause <- sql_in_clause("beat", as.character(beat))
      if (!is.null(clause)) all_where_clauses <- c(all_where_clauses, clause)
    }
    if (!is.null(division)) {
      if(!is.character(division)) stop("`division` must be char.", call. = FALSE)
      clause <- sql_in_clause("division", division)
      if (!is.null(clause)) all_where_clauses <- c(all_where_clauses, clause)
    }
    if (!is.null(sector)) {
      if(!is.character(sector) && !is.numeric(sector)) stop("`sector` invalid type.", call. = FALSE)
      clause <- sql_in_clause("sector", as.character(sector))
      if (!is.null(clause)) all_where_clauses <- c(all_where_clauses, clause)
    }
    if (!is.null(district)) {
      if(!is.character(district)) stop("`district` must be char.", call. = FALSE)
      clause <- sql_in_clause("district", district)
      if (!is.null(clause)) all_where_clauses <- c(all_where_clauses, clause)
    }
    # -- Combine --
    if (length(all_where_clauses) > 0) {
      query_params[["$where"]] <- paste(all_where_clauses, collapse = " AND ")
    }
  } else { # User provided 'where'
    if (!is.character(where) || length(where) != 1) stop("`where` must be string.", call. = FALSE)
    other_filters_present <- !is.null(start_date) || !is.null(end_date) || !is.null(nibrs_group) ||
      !is.null(nibrs_code) || !is.null(nibrs_crime_against) || !is.null(zip_code) ||
      !is.null(beat) || !is.null(division) || !is.null(sector) || !is.null(district)
    if (other_filters_present) {
      rlang::warn("Using 'where'; ignoring other filter arguments.")
    }
    query_params[["$where"]] <- where
  }

  # --- Column Selection Logic ---
  if (!is.null(select)) {
    if (!is.character(select)) stop("`select` must be char vector.", call. = FALSE)
    # Ensure coordinate columns are selected if geo conversion is requested
    if (convert_geo && !("x_coordinate" %in% select)) { # Changed here
      select <- c(select, "x_coordinate")
      rlang::inform("Adding 'x_coordinate' to $select for geographic conversion.")
    }
    if (convert_geo && !("y_cordinate" %in% select)) { # Changed here
      select <- c(select, "y_cordinate")
      rlang::inform("Adding 'y_cordinate' to $select for geographic conversion.")
    }
    query_params[["$select"]] <- paste(unique(select), collapse = ",")
  }

  # --- Data Retrieval with Pagination ---
  # (Pagination logic remains the same)
  all_data_chunks <- list()
  current_offset <- 0
  records_retrieved <- 0
  api_max_limit_per_req <- 1000
  fetch_limit_this_req <- if (is.infinite(limit)) { api_max_limit_per_req } else { min(limit - records_retrieved, api_max_limit_per_req) }

  if (fetch_limit_this_req > 0) { rlang::inform("Starting data retrieval...") }
  else { rlang::inform("Limit is zero; returning empty dataset."); return(dplyr::tibble()) }

  repeat {
    if (fetch_limit_this_req <= 0) break
    query_params[["$limit"]] <- fetch_limit_this_req
    query_params[["$offset"]] <- current_offset
    request_url <- httr::modify_url(base_url, query = query_params)
    response <- httr::GET(request_url, ua)
    httr::stop_for_status(response, task = paste("fetch data. URL:", request_url))
    if (httr::http_type(response) != "application/json") stop("API did not return JSON.", call. = FALSE)
    content_text <- httr::content(response, "text", encoding = "UTF-8")
    if(nchar(trimws(content_text)) <= 2) { data_chunk <- tibble::tibble() }
    else {
      tryCatch({ data_chunk <- jsonlite::fromJSON(content_text, flatten = TRUE); data_chunk <- dplyr::as_tibble(data_chunk) },
               error = function(e) { stop("Failed to parse JSON. Error: ", e$message, call. = FALSE) })
    }
    chunk_rows <- nrow(data_chunk)
    if (chunk_rows == 0) { rlang::inform("No more data found."); break }
    all_data_chunks[[length(all_data_chunks) + 1]] <- data_chunk
    records_retrieved <- records_retrieved + chunk_rows
    current_offset <- current_offset + chunk_rows
    if (!is.infinite(limit) && records_retrieved >= limit) { rlang::inform(paste("Reached limit of", limit)); break }
    if (chunk_rows < fetch_limit_this_req) { rlang::inform("Retrieved last page."); break }
    fetch_limit_this_req <- if (is.infinite(limit)) { api_max_limit_per_req } else { min(limit - records_retrieved, api_max_limit_per_req) }
  }
  rlang::inform(paste("Total records retrieved:", records_retrieved))

  # --- Combine and Finalize ---
  if (length(all_data_chunks) == 0) {
    rlang::inform("Query returned no matching records."); return(dplyr::tibble())
  }
  final_data <- dplyr::bind_rows(all_data_chunks)
  if (!is.infinite(limit) && nrow(final_data) > limit) {
    final_data <- final_data[1:limit, , drop = FALSE]
  }

  # <<< --- Geographic Conversion Logic --- >>>
  if (convert_geo && nrow(final_data) > 0) { # Changed here
    # 1. Check if sf package is installed
    if (!requireNamespace("sf", quietly = TRUE)) {
      rlang::warn("Package 'sf' needed for `convert_geo=TRUE` but is not installed. Returning a regular tibble.") # Changed here
    } else {
      # 2. Check if coordinate columns exist
      required_cols <- c("x_coordinate", "y_cordinate")
      if (!all(required_cols %in% names(final_data))) {
        missing_cols <- setdiff(required_cols, names(final_data))
        rlang::warn(paste("Cannot convert to geographic object. Required coordinate columns missing:", # Changed here
                          paste(missing_cols, collapse=", "),
                          "(Did you use '$select' without including them?). Returning a regular tibble."))
      } else {
        # 3. Attempt conversion
        rlang::inform("Attempting conversion to geographic object (sf CRS: EPSG:2276)...") # Changed here
        original_rows <- nrow(final_data)

        # Coerce coordinates to numeric, suppressing warnings for NAs
        suppressWarnings({
          final_data <- dplyr::mutate(final_data,
                                      x_coordinate = as.numeric(.data$x_coordinate),
                                      y_cordinate = as.numeric(.data$y_cordinate)
          )
        })

        # Filter rows with valid coordinates
        final_data_valid <- dplyr::filter(final_data,
                                          !is.na(.data$x_coordinate) & !is.na(.data$y_cordinate)
        )
        n_valid <- nrow(final_data_valid)

        if (n_valid < original_rows) {
          n_dropped <- original_rows - n_valid
          rlang::warn(paste("Removed", n_dropped, "rows with missing or invalid coordinates before geographic conversion.")) # Changed here
        }

        if (n_valid > 0) {
          tryCatch({
            # Convert using the specified State Plane CRS: NAD83 Texas North Central (ftUS)
            final_data <- sf::st_as_sf(final_data_valid,
                                       coords = c("x_coordinate", "y_cordinate"),
                                       crs = 2276, # NAD83 / Texas North Central (ftUS)
                                       remove = FALSE, # Keep original coord columns
                                       na.fail = FALSE) # Already handled NAs
            rlang::inform(paste("Successfully converted", n_valid, "rows to geographic object (sf) with CRS EPSG:2276.")) # Changed here

            # Move geometry column to the end
            final_data <- dplyr::relocate(final_data, "geometry", .after = dplyr::last_col())

          }, error = function(e) {
            rlang::warn(paste("Failed to convert data to geographic object (sf). Error:", e$message, # Changed here
                              "Returning a regular tibble instead."))
            # Return the tibble with valid coords but no geometry on error
            final_data <- final_data_valid
          })
        } else {
          rlang::warn("No rows with valid coordinates found; cannot create geographic object. Returning empty tibble.") # Changed here
          # Return the empty valid tibble
          final_data <- final_data_valid
        }
      } # End check for coordinate columns
    } # End check for sf package install
  } # End if (convert_geo)

  rlang::inform("Data retrieval complete.")
  return(final_data)
}
