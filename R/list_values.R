# R/list_values.R

#' List Distinct Values for a Field from a Specific Dataset
#'
#' Queries the Dallas Police Open Data API to retrieve unique values
#' for a specified field from a chosen dataset (Incidents, Arrests, Charges,
#' or Use of Force by year).
#'
#' @description
#' This function fetches distinct values for a given field from one of the
#' supported Dallas Police datasets. This is useful for discovering filter options
#' for the corresponding `get_*` functions.
#'
#' Note: The `field` argument requires the **exact API field name** for the
#' chosen `dataset` (and `year`, if applicable), as field names can vary.
#' Check the source dataset documentation or field lists if unsure.
#'
#' @param field A character string specifying the **exact API field name** for which
#'   to retrieve distinct values (e.g., "division", "arlbeat", "chargedesc", "forcetype").
#'   Case-sensitive.
#' @param dataset Character string specifying the dataset to query. Options are:
#'   `"incidents"` (default), `"arrests"`, `"charges"`, `"uof"`.
#' @param year Numeric. Required **only** if `dataset = "uof"`. Specifies the year
#'   (2017-2020) for the Use of Force data. Ignored for other datasets.
#' @param max_values The maximum number of distinct values to retrieve. Defaults
#'   to 5000. Increase if needed, but be mindful of API performance.
#'
#' @return A character or numeric vector containing the unique values for the
#'   specified field, sorted by the API. Returns `NULL` if the query fails,
#'   returns no data, or the field is invalid for the dataset.
#' @export
#'
#' @importFrom httr GET http_type content stop_for_status modify_url user_agent
#' @importFrom jsonlite fromJSON
#' @importFrom rlang check_installed inform warn abort .data list2
#' @importFrom dplyr pull arrange
#'
#' @examples
#' \dontrun{
#'   # Get distinct divisions from Incidents data (default dataset)
#'   incident_divisions <- list_distinct_values(field = "division")
#'   print(incident_divisions)
#'
#'   # Get distinct penalty classes ('pclass') from Charges data
#'   charge_pclasses <- list_distinct_values(field = "pclass", dataset = "charges")
#'   print(charge_pclasses)
#'
#'   # Get distinct arrest beats ('arlbeat') from Arrests data
#'   arrest_beats <- list_distinct_values(field = "arlbeat", dataset = "arrests")
#'   print(arrest_beats) # Note: field is numeric
#'
#'   # Get distinct Force Types from UoF data for 2020
#'   uof_force_types_2020 <- list_distinct_values(field = "forcetype", dataset = "uof", year = 2020)
#'   print(uof_force_types_2020)
#'
#'   # Get distinct Service Types from UoF data for 2019 (needs specific field name)
#'   uof_service_types_2019 <- list_distinct_values(field = "service_ty", dataset = "uof", year = 2019)
#'   print(uof_service_types_2019)
#' }
list_distinct_values <- function(field, dataset = "incidents", year = NULL, max_values = 5000) {

  # --- Input Validation & Dependency Checks ---
  rlang::check_installed("httr", reason = "to fetch data from the API.")
  rlang::check_installed("jsonlite", reason = "to parse JSON data.")
  rlang::check_installed("dplyr", reason = "for data manipulation.")

  # Validate field
  if (!is.character(field) || length(field) != 1 || nchar(field) == 0) {
    stop("`field` must be a single, non-empty character string representing the exact API field name.", call. = FALSE)
  }
  # Validate dataset
  supported_datasets <- c("incidents", "arrests", "charges", "uof")
  if (!is.character(dataset) || length(dataset) != 1 || !dataset %in% supported_datasets) {
    stop(paste("`dataset` must be one of:", paste(supported_datasets, collapse=", ")), call. = FALSE)
  }
  # Validate year (conditionally)
  if (dataset == "uof") {
    if (is.null(year) || !is.numeric(year) || length(year) != 1 || year %% 1 != 0) {
      stop("`year` must be provided as a single integer when `dataset = \"uof\"`.", call. = FALSE)
    }
  } else {
    if (!is.null(year)) {
      rlang::warn("`year` argument is ignored when `dataset` is not \"uof\".")
    }
  }
  # Validate max_values
  if (!is.numeric(max_values) || max_values <= 0) {
    stop("`max_values` must be a positive number.", call. = FALSE)
  }

  # --- Dataset to Resource ID Mapping ---
  resource_id <- NULL
  # Static datasets
  dataset_resource_map <- list(
    "incidents" = "qv6i-rri7",
    "arrests"   = "sdr7-6v3j",
    "charges"   = "9u3q-af6p"
  )
  # UoF datasets (limited to 2017-2020)
  uof_year_resource_map <- list(
    "2020" = "nufk-2iqn",
    "2019" = "46zb-7qgj",
    "2018" = "33un-ry4j",
    "2017" = "tsu5-ca6k"
  )

  # Determine resource_id
  if (dataset == "uof") {
    year_char <- as.character(year)
    if (!year_char %in% names(uof_year_resource_map)) {
      stop("For `dataset = \"uof\"`, `year` must be between 2017 and 2020.", call. = FALSE)
    }
    resource_id <- uof_year_resource_map[[year_char]]
    dataset_label <- paste(dataset, year) # For messages
  } else {
    resource_id <- dataset_resource_map[[dataset]]
    dataset_label <- dataset # For messages
  }

  # --- Base URL and Query Parameters ---
  base_url <- paste0("https://www.dallasopendata.com/resource/", resource_id, ".json")
  ua <- httr::user_agent("dallasopendata/0.1.0 (https://github.com/galvanthony/dallasopendata)") # Customize!

  # Construct SODA query for distinct values, ordered by the field itself
  query_params <- list(
    `$select` = paste0("distinct ", field),
    `$order` = field,
    `$limit` = as.integer(max_values)
  )

  # --- API Request ---
  request_url <- httr::modify_url(base_url, query = query_params)
  rlang::inform(paste("Querying distinct values for field:", shQuote(field), "from dataset:", dataset_label))

  values_vector <- NULL # Initialize return value

  tryCatch({
    response <- httr::GET(request_url, ua)
    # Check for common errors like invalid field name
    if (httr::status_code(response) == 400) {
      # Try to parse error message from Socrata
      error_content <- httr::content(response, "parsed", encoding = "UTF-8")
      error_msg <- error_content$message %||% "Bad Request (HTTP 400)"
      if (grepl("no-such-column", error_msg, ignore.case=TRUE)){
        abort(paste0("API Error: Field ", shQuote(field), " not found or not queryable in dataset ", dataset_label, "."))
      } else {
        abort(paste("API Error:", error_msg))
      }
    }
    # Check for other HTTP errors
    httr::stop_for_status(response, task = paste("fetch distinct values for", field, "from", dataset_label))

    if (httr::http_type(response) != "application/json") {
      stop("API did not return JSON.", call. = FALSE)
    }

    content_text <- httr::content(response, "text", encoding = "UTF-8")

    if(nchar(trimws(content_text)) <= 2 || content_text == "[]") {
      rlang::inform(paste("API returned no distinct values for field:", shQuote(field), "in dataset:", dataset_label))
      # Return empty vector of appropriate type? Or NULL? Let's return NULL for simplicity.
      values_vector <- NULL
    } else {
      data_df <- jsonlite::fromJSON(content_text, flatten = TRUE)
      # Socrata might return the distinct field name with `_1` appended if there are duplicates/joins internally
      # Check for both the original field name and field_name_1
      possible_field_names <- c(field, paste0(field,"_1"))
      actual_field_name <- intersect(possible_field_names, names(data_df))

      if (nrow(data_df) > 0 && length(actual_field_name) == 1) {
        # Extract the column as a vector; sorting is primarily handled by $order
        values_vector <- dplyr::pull(data_df, dplyr::all_of(actual_field_name[1]))

        # Remove potential placeholder NAs often used by Socrata if result is character
        if(is.character(values_vector)) {
          values_vector <- values_vector[!is.na(values_vector) & values_vector != ""]
        } else {
          values_vector <- values_vector[!is.na(values_vector)]
        }

        # Sort in R as a final step, handling potential type issues
        tryCatch({
          values_vector <- sort(values_vector)
        }, error = function(e) {
          rlang::warn("Could not sort distinct values; returning in API order.")
        })


        if(nrow(data_df) == max_values) {
          rlang::warn(paste("Reached the limit of", max_values,
                            "distinct values. Some values might be missing."))
        }
      } else {
        rlang::warn(paste("Could not find field", shQuote(field), "in API response columns:", paste(names(data_df), collapse=", ")))
        # values_vector remains NULL
      }
    }

  }, error = function(e) {
    # Catch errors from httr::stop_for_status or other issues
    # Use rlang::abort to provide a more informative error originating from this function
    rlang::abort(paste("Failed to retrieve distinct values for field:", shQuote(field), "from dataset:", dataset_label),
                 parent = e) # Include the underlying error
  })

  return(values_vector)
}
