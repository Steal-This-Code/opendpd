# R/get_arrests.R

#' Fetch Dallas Police Arrest Data
#'
#' Retrieves arrest data from the Dallas Open Data portal API
#' (SODA endpoint sdr7-6v3j).
#'
#' @description
#' This function queries the Socrata Open Data API (SODA) for Dallas Police
#' Arrests. It allows filtering by date range, geographic areas (zip, beat,
#' district, sector) and supports retrieving large datasets through automatic pagination.
#' Note: Filtering by charge description/category via dedicated arguments has been
#' removed due to field name inconsistencies; use the 'where' argument for this.
#' Geographic conversion has also been removed due to missing coordinate fields
#' in the confirmed field list.
#'
#' If the `where` argument is provided, it overrides all other filter arguments.
#'
#' @param start_date Optional. A character string in 'YYYY-MM-DD' format or a
#'   Date object specifying the minimum arrest date (inclusive, based on `ararrestdate` field).
#' @param end_date Optional. A character string in 'YYYY-MM-DD' format or a
#'   Date object specifying the maximum arrest date (inclusive, based on `ararrestdate` field).
#' @param zip_code Optional. A character or numeric vector of Zip Code(s) where the
#'   arrest occurred (`arlzip`).
#' @param beat Optional. A character or numeric vector of Police Beat(s) where the
#'   arrest occurred (`arlbeat`).
#' @param sector Optional. A character or numeric vector of Police Sector(s) where the
#'   arrest occurred (`arlsector`).
#' @param district Optional. A character vector of Police District names where the
#'   arrest occurred (`arldistrict`).
#' @param limit The maximum number of records to return. Defaults to 1000.
#'   Use `limit = Inf` to attempt retrieving all matching records.
#' @param select A character vector specifying which columns to retrieve.
#'   If NULL (default), all columns are retrieved.
#' @param where An optional character string containing a custom SoQL WHERE clause
#'   (e.g., `"charge_category = 'TRAFFIC'"` or `"race = 'BLACK'"`).
#'   Overrides other filter arguments if provided.
#' @param ... Additional SODA query parameters passed directly to the API URL,
#'   (e.g., `$order = "ararrestdate DESC"`).
#'
#' @return A `tibble` containing the requested arrest data.
#' @export
#'
#' @importFrom httr GET http_type content stop_for_status modify_url user_agent
#' @importFrom jsonlite fromJSON
#' @importFrom dplyr bind_rows as_tibble tibble filter select mutate all_of arrange relocate last_col
#' @importFrom rlang check_installed is_installed inform .data warn abort
#' @importFrom utils URLencode
#'
#' @examples
#' \dontrun{
#' # Get 10 most recent arrests
#' recent_arrests <- get_arrests(limit = 10, `$order` = "ararrestdate DESC")
#' print(recent_arrests)
#'
#' # Get arrests in specific beats during March 2024
#' march_arrests_beat <- get_arrests(
#'   start_date = "2024-03-01", end_date = "2024-03-31",
#'   beat = c(114, 121), # Using numbers as arlbeat is numeric
#'   limit = 100
#' )
#' print(march_arrests_beat)
#'
#' # Use 'where' to filter by charge category (using name from web metadata)
#' # Note: Field names like 'charge_category' might be inconsistent, verify first!
#' traffic_arrests <- get_arrests(
#'   where = "charge_category = 'TRAFFIC'",
#'   limit = 50,
#'   start_date = "2024-04-01", end_date = "2024-04-30"
#' )
#' print(traffic_arrests)
#' }
get_arrests <- function(start_date = NULL, end_date = NULL,
                        # Geography Filters - Updated based on user list
                        zip_code = NULL,
                        beat = NULL,
                        sector = NULL,
                        district = NULL,
                        # Control Parameters
                        limit = 1000, select = NULL, where = NULL, ...) {

  # --- Input Validation & Dependency Checks ---
  rlang::check_installed("httr", reason = "to fetch data from the API.")
  rlang::check_installed("jsonlite", reason = "to parse JSON data.")
  rlang::check_installed("dplyr", reason = "for data manipulation.")
  if (!is.numeric(limit) || limit <= 0) stop("`limit` must be a positive number or Inf.", call. = FALSE)

  # --- Base URL and Query Parameters ---
  base_url <- "https://www.dallasopendata.com/resource/sdr7-6v3j.json"
  ua <- httr::user_agent("dallasopendata/0.1.0 (https://github.com/galvanthony/dallasopendata)") # Customize!
  query_params <- list(...)

  # --- Filtering Logic ---
  all_where_clauses <- list()

  # -- Corrected Helper function for creating IN clauses --
  #    Handles numeric types without quotes
  sql_in_clause <- function(field, values) {
    if (is.null(values) || length(values) == 0) return(NULL)
    quoted_values <- sapply(values, function(v) {
      if (is.character(v)) {
        # Escape single quotes within strings
        v_escaped <- gsub("'", "''", v)
        paste0("'", v_escaped, "'")
      } else if (is.numeric(v) || is.logical(v)) {
        # Use as is for numbers/logicals (no quotes)
        as.character(v)
      } else {
        # Fallback: treat as string with escaping (safer)
        v_escaped <- gsub("'", "''", as.character(v))
        paste0("'", v_escaped, "'")
      }
    })
    # Format as: field IN ('val1', 123, 'val3')
    paste0(field, " IN (", paste(quoted_values, collapse = ", "), ")")
  }


  if (is.null(where)) {
    # -- Date filtering (using 'ararrestdate') --
    if (!is.null(start_date)) {
      tryCatch({
        start_date_fmt <- format(as.Date(start_date), "%Y-%m-%dT00:00:00")
        all_where_clauses <- c(all_where_clauses, paste0("ararrestdate >= '", start_date_fmt, "'"))
      }, error = function(e) stop("`start_date` invalid.", call. = FALSE))
    }
    if (!is.null(end_date)) {
      tryCatch({
        end_date_exclusive_fmt <- format(as.Date(end_date) + 1, "%Y-%m-%dT00:00:00")
        all_where_clauses <- c(all_where_clauses, paste0("ararrestdate < '", end_date_exclusive_fmt, "'"))
      }, error = function(e) stop("`end_date` invalid.", call. = FALSE))
    }

    # -- Geography Filters (using 'arl' fields from user list) --
    if (!is.null(zip_code)) { # Field: arlzip (Text)
      if(!is.character(zip_code) && !is.numeric(zip_code)) stop("`zip_code` invalid type.", call. = FALSE)
      clause <- sql_in_clause("arlzip", as.character(zip_code))
      if (!is.null(clause)) all_where_clauses <- c(all_where_clauses, clause)
    }
    if (!is.null(beat)) { # Field: arlbeat (Number)
      if(!is.numeric(beat) && !is.character(beat)) stop("`beat` must be numeric or character.", call. = FALSE)
      beat_vals <- tryCatch(as.numeric(beat), warning=function(w) beat)
      clause <- sql_in_clause("arlbeat", beat_vals)
      if (!is.null(clause)) all_where_clauses <- c(all_where_clauses, clause)
    }
    if (!is.null(sector)) { # Field: arlsector (Number)
      if(!is.numeric(sector) && !is.character(sector)) stop("`sector` must be numeric or character.", call. = FALSE)
      sector_vals <- tryCatch(as.numeric(sector), warning=function(w) sector)
      clause <- sql_in_clause("arlsector", sector_vals)
      if (!is.null(clause)) all_where_clauses <- c(all_where_clauses, clause)
    }
    if (!is.null(district)) { # Field: arldistrict (Text)
      if(!is.character(district)) stop("`district` must be char.", call. = FALSE)
      clause <- sql_in_clause("arldistrict", district)
      if (!is.null(clause)) all_where_clauses <- c(all_where_clauses, clause)
    }

    # -- Combine --
    if (length(all_where_clauses) > 0) {
      query_params[["$where"]] <- paste(all_where_clauses, collapse = " AND ")
    }
  } else { # User provided 'where'
    if (!is.character(where) || length(where) != 1) stop("`where` must be string.", call. = FALSE)
    # Update warning message
    other_filters_present <- !is.null(start_date) || !is.null(end_date) ||
      !is.null(zip_code) || !is.null(beat) ||
      !is.null(sector) || !is.null(district)
    if (other_filters_present) {
      rlang::warn("Using 'where'; ignoring other filter arguments: start_date, end_date, zip_code, beat, sector, district.")
    }
    query_params[["$where"]] <- where
  }

  # --- Column Selection Logic ---
  if (!is.null(select)) {
    if (!is.character(select)) stop("`select` must be char vector.", call. = FALSE)
    query_params[["$select"]] <- paste(unique(select), collapse = ",")
  }

  # --- Data Retrieval with Pagination ---
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

  # Removed geographic conversion section

  rlang::inform("Data retrieval complete.")
  return(final_data) # Returns a tibble
}
