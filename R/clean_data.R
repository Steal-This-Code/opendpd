# R/clean_data.R

#' Clean Dallas Police Incidents Data
#'
#' Performs basic cleaning on text fields and converts date/time columns
#' for data retrieved using `get_incidents()`.
#'
#' @description
#' This function standardizes common text columns by converting them to
#' lowercase, trimming leading/trailing whitespace, and squishing internal
#' whitespace. It also converts known date/time text columns to POSIXct objects
#' using `lubridate`.
#'
#' @param data A data frame or tibble, typically the output from `get_incidents()`.
#' @param text_fields A character vector specifying the names of text columns to clean.
#'   Defaults to cleaning common categorical fields known to have inconsistencies.
#'   Provide `NULL` to skip text cleaning.
#' @param date_fields A character vector specifying the names of date/time columns
#'   to parse into POSIXct objects. Defaults to known date/time fields in the
#'   Incidents dataset. Provide `NULL` to skip date parsing.
#' @param tz The timezone to assign during date/time parsing. Defaults to
#'   `"America/Chicago"`. See `base::OlsonNames()` for other valid options.
#'
#' @return A tibble with the specified cleaning and parsing applied.
#' @export
#'
#' @importFrom dplyr mutate across all_of contains matches tibble select
#' @importFrom stringr str_to_lower str_trim str_squish
#' @importFrom rlang .data check_installed warn inform is_installed list2 := sym
#' @importFrom tidyselect everything where
#' @importFrom lubridate parse_date_time
#'
#' @examples
#' \dontrun{
#'   # Fetch some raw data
#'   raw_incidents <- get_incidents(limit = 100, start_date = "2024-01-01")
#'
#'   # Apply default cleaning (common text fields + common date fields)
#'   # Requires stringr & lubridate
#'   # install.packages(c("stringr", "lubridate"))
#'   cleaned_incidents <- clean_incidents_data(raw_incidents)
#'
#'   # Check distinct divisions after cleaning
#'   print(unique(cleaned_incidents$division))
#'
#'   # Check classes of date columns
#'   print(sapply(cleaned_incidents |> dplyr::select(dplyr::contains("date")), class))
#'
#'   # Clean only specific fields, skip date conversion
#'   partially_cleaned <- clean_incidents_data(
#'       raw_incidents,
#'       text_fields = c("premise", "division"),
#'       date_fields = NULL # Skip date parsing
#'   )
#'   print(head(partially_cleaned))
#' }
clean_incidents_data <- function(data,
                                 text_fields = c("division", "district", "sector", "beat",
                                                 "premise", "offincident", "signal",
                                                 "ucr_disp", "status", "type"),
                                 date_fields = c("date1", "date2_of_occurrence_2",
                                                 "reporteddate", "edate", "callorgdate",
                                                 "callreceived", "callcleared",
                                                 "calldispatched", "upzdate"),
                                 tz = "America/Chicago") {

  # --- Input validation ---
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame or tibble.", call. = FALSE)
  }
  if (nrow(data) == 0) {
    rlang::inform("Input data has 0 rows, returning unmodified.")
    return(data)
  }
  if (!is.null(text_fields) && !is.character(text_fields)) {
    stop("`text_fields` must be a character vector of column names or NULL.", call. = FALSE)
  }
  if (!is.null(date_fields) && !is.character(date_fields)) {
    stop("`date_fields` must be a character vector of column names or NULL.", call. = FALSE)
  }
  if (!is.character(tz) || length(tz) != 1 || !(tz %in% base::OlsonNames())) {
    stop("`tz` must be a valid timezone name (see OlsonNames()).", call. = FALSE)
  }

  cleaned_data <- data

  # --- Clean Text Fields ---
  if (!is.null(text_fields)) {
    fields_to_clean_present <- intersect(text_fields, names(cleaned_data))
    missing_fields <- setdiff(text_fields, fields_to_clean_present)
    if (length(missing_fields) > 0) {
      rlang::warn(paste("Specified `text_fields` not found and skipped:", paste(missing_fields, collapse = ", ")))
    }

    if (length(fields_to_clean_present) > 0) {
      rlang::check_installed("stringr", reason = "to clean text fields.")
      rlang::inform(paste("Applying text cleaning (lower, trim, squish) to columns:",
                          paste(fields_to_clean_present, collapse=", ")))
      cleaned_data <- cleaned_data |>
        dplyr::mutate(
          # Apply cleaning only to character columns among the specified fields
          dplyr::across(
            dplyr::all_of(fields_to_clean_present) & tidyselect::where(is.character),
            ~ .x |> stringr::str_to_lower() |> stringr::str_trim() |> stringr::str_squish()
          )
        )
    } else {
      rlang::inform("No specified text fields found or `text_fields` was NULL; skipping text cleaning.")
    }
  }


  # --- Convert Date/Time Fields ---
  if (!is.null(date_fields)) {
    fields_to_convert_present <- intersect(date_fields, names(cleaned_data))
    missing_fields_date <- setdiff(date_fields, fields_to_convert_present)
    if (length(missing_fields_date) > 0) {
      rlang::warn(paste("Specified `date_fields` not found and skipped:", paste(missing_fields_date, collapse = ", ")))
    }

    if (length(fields_to_convert_present) > 0) {
      rlang::check_installed("lubridate", reason = "to parse date/time strings.")
      rlang::inform(paste("Attempting to convert date columns to POSIXct (tz=", tz, "):",
                          paste(fields_to_convert_present, collapse=", ")))

      # Define likely orders for Socrata text/timestamp fields
      expected_orders <- c(
        "Ymd HMS",  # Common format with time, e.g., 2023-01-15T10:30:00
        "Ymd"       # Date only format
      )

      cleaned_data <- cleaned_data |>
        dplyr::mutate(
          dplyr::across(dplyr::all_of(fields_to_convert_present),
                        ~ lubridate::parse_date_time(.x, orders = expected_orders, tz = tz, quiet = TRUE))
        )
    } else {
      rlang::inform("No specified date fields found or `date_fields` was NULL; skipping date parsing.")
    }
  }

  return(cleaned_data)
}


#' Standardize Police Division Names
#'
#' Maps known variations of Dallas Police division names to a standard set and
#' converts the column to a factor. Designed to be used after basic text cleaning
#' (e.g., via `clean_incidents_data`).
#'
#' @param data A data frame or tibble containing a column named `division`.
#' @param division_col The name of the division column as a **string**.
#'   Defaults to `"division"`.
#'
#' @return A tibble with the specified division column standardized and converted
#'   to a factor with defined levels: "central", "northeast", "northwest",
#'   "southcentral", "southeast", "southwest", "northcentral". Values not matching
#'   known variations or standard names will become `NA`.
#' @export
#'
#' @importFrom dplyr mutate case_match select all_of rename_with across
#' @importFrom rlang .data sym warn inform check_installed :=
#' @importFrom stringr str_squish str_to_lower
#'
#' @examples
#' \dontrun{
#'   # Assume raw_incidents is output from get_incidents()
#'   cleaned_incidents <- clean_incidents_data(raw_incidents)
#'
#'   # Standardize the 'division' column
#'   standardized_incidents <- standardize_division(cleaned_incidents, division_col = "division")
#'
#'   # Check the levels and values
#'   print(levels(standardized_incidents$division))
#'   print(table(standardized_incidents$division, useNA = "ifany"))
#' }
# --- Function definition updated ---
standardize_division <- function(data, division_col = "division") {

  # Use the provided string column name directly
  col_name <- division_col

  # Check if column exists
  if (!col_name %in% names(data)) {
    rlang::warn(paste("Column", shQuote(col_name), "not found in data. Skipping standardization."))
    return(data)
  }
  # Ensure input is a string
  if (!is.character(col_name) || length(col_name) != 1) {
    stop("`division_col` must be a single string naming the column.", call.=FALSE)
  }

  # Ensure dependencies are available
  rlang::check_installed("dplyr", reason = "to standardize division names.")
  rlang::check_installed("stringr", reason = "to clean division names.")

  # Define standard names
  standard_division_names <- c("central", "northeast", "northwest",
                               "southcentral", "southeast", "southwest",
                               "northcentral")

  rlang::inform(paste("Standardizing column:", shQuote(col_name)))

  # Create temporary column names to avoid conflicts
  temp_clean_col <- paste0(".__", col_name, "_clean_temp")
  temp_std_col <- paste0(".__", col_name, "_std_temp")

  data_standardized <- data |>
    # Apply basic cleaning robustly (lowercase, squish whitespace)
    dplyr::mutate(
      "{temp_clean_col}" := stringr::str_squish(stringr::str_to_lower(as.character(.data[[col_name]])))
    ) |>
    dplyr::mutate(
      # Standardize using case_match on the temporary cleaned column
      "{temp_std_col}" := dplyr::case_match(
        .data[[temp_clean_col]],
        # --- Map known variations first ---
        # Add more variations here as discovered through data exploration
        "central patrol div" ~ "central",
        "south west" ~ "southwest",
        "north east" ~ "northeast",
        "north west" ~ "northwest",
        "south central" ~ "southcentral",
        "south east" ~ "southeast",
        "north central" ~ "northcentral",

        # --- Map standard names to themselves ---
        standard_division_names ~ .data[[temp_clean_col]],

        # --- Handle anything else ---
        .default = NA_character_
      )
    )

  # Check if any values became NA during standardization
  original_values <- data[[col_name]]
  standardized_values <- data_standardized[[temp_std_col]]
  num_na_introduced <- sum(is.na(standardized_values) & !is.na(original_values) & original_values != "")
  if (num_na_introduced > 0) {
    rlang::warn(paste0(num_na_introduced, " value(s) in column ", shQuote(col_name),
                       " did not match standard divisions and became NA."))
  }

  # Overwrite original column, convert to factor w/ standard levels
  data_standardized <- data_standardized |>
    dplyr::mutate(
      # Use !!sym() to use the string col_name on the LHS of :=
      !!rlang::sym(col_name) := factor(.data[[temp_std_col]],
                                       levels = standard_division_names)
    ) |>
    # Remove the temporary columns
    dplyr::select(-dplyr::all_of(c(temp_clean_col, temp_std_col)))


  return(data_standardized)
}


#' Standardize Dallas Council District Names
#'
#' Attempts to map variations of Dallas City Council District names/numbers
#' to a standard format ("1" through "14") and converts the column to a factor.
#' Assumes input column has already had basic text cleaning.
#'
#' @param data A data frame or tibble containing a council district column.
#' @param district_col The name of the district column as a **string**.
#'   Defaults to `"district"`.
#'
#' @return A tibble with the specified district column standardized to character
#'   values "1" through "14" and converted to a factor. Values that cannot be
#'   confidently mapped to 1-14 will become `NA`.
#' @export
#'
#' @importFrom dplyr mutate case_when select all_of if_else across
#' @importFrom rlang .data sym warn inform check_installed :=
#' @importFrom stringr str_squish str_to_lower str_extract str_detect
#'
#' @examples
#' \dontrun{
#'   # Assume raw_incidents is output from get_incidents()
#'   cleaned_incidents <- clean_incidents_data(raw_incidents) # Basic cleaning first
#'   standardized_incidents <- standardize_district(cleaned_incidents, district_col = "district")
#'
#'   # Check the levels and values
#'   print(levels(standardized_incidents$district))
#'   print(table(standardized_incidents$district, useNA = "ifany"))
#' }
# --- Function definition updated ---
standardize_district <- function(data, district_col = "district") {

  # Use the provided string column name directly
  col_name <- district_col

  # Check if column exists
  if (!col_name %in% names(data)) {
    rlang::warn(paste("Column", shQuote(col_name), "not found in data. Skipping standardization."))
    return(data)
  }
  # Ensure input is a string
  if (!is.character(col_name) || length(col_name) != 1) {
    stop("`district_col` must be a single string naming the column.", call.=FALSE)
  }

  # Ensure dependencies
  rlang::check_installed("dplyr", reason = "to standardize district names.")
  rlang::check_installed("stringr", reason = "to clean/extract district names.")

  # Define standard levels
  standard_district_levels <- as.character(1:14)

  rlang::inform(paste("Standardizing Council District column:", shQuote(col_name)))

  # Temporary column names
  temp_clean_col <- paste0(".__", col_name, "_clean_temp")
  temp_std_col <- paste0(".__", col_name, "_std_temp")

  data_standardized <- data |>
    # Basic cleaning within function for robustness
    dplyr::mutate(
      "{temp_clean_col}" := stringr::str_squish(stringr::str_to_lower(as.character(.data[[col_name]])))
    ) |>
    dplyr::mutate(
      # Extract number if present, handle specific text cases
      "{temp_std_col}" := dplyr::case_when(
        # Explicit matches for numbers "1" through "14"
        .data[[temp_clean_col]] %in% standard_district_levels ~ .data[[temp_clean_col]],
        # Extract number from strings like "district 1", "dist 14", "council district 5" etc.
        stringr::str_detect(.data[[temp_clean_col]], "(^|\\s|_)(\\d{1,2})$") ~
          stringr::str_extract(.data[[temp_clean_col]], "\\d{1,2}$"),
        # Add other specific known variations if needed
        .default = NA_character_ # Default to NA if no pattern matches
      ),
      # Ensure extracted numbers are within the valid 1-14 range
      "{temp_std_col}" := dplyr::if_else(
        !is.na(.data[[temp_std_col]]) & .data[[temp_std_col]] %in% standard_district_levels,
        .data[[temp_std_col]],
        NA_character_
      )
    )

  # Check for introduced NAs
  original_values <- data[[col_name]]
  standardized_values <- data_standardized[[temp_std_col]]
  num_na_introduced <- sum(is.na(standardized_values) & !is.na(original_values) & original_values != "")
  if (num_na_introduced > 0) {
    rlang::warn(paste0(num_na_introduced, " value(s) in column ", shQuote(col_name),
                       " could not be mapped to a standard district (1-14) and became NA."))
  }

  # Overwrite original column, convert to factor
  data_standardized <- data_standardized |>
    dplyr::mutate(
      # Use !!sym() to use the string col_name on the LHS of :=
      !!rlang::sym(col_name) := factor(.data[[temp_std_col]],
                                       levels = standard_district_levels)
    ) |>
    # Remove temporary columns
    dplyr::select(-dplyr::all_of(c(temp_clean_col, temp_std_col)))

  return(data_standardized)
}


#' Clean Dallas Police Arrests Data
#'
#' Performs basic cleaning on text fields and converts date/time columns
#' for data retrieved using `get_arrests()`.
#'
#' @description
#' This function standardizes common text columns from the Arrests dataset by
#' converting them to lowercase, trimming leading/trailing whitespace, and
#' squishing internal whitespace. It also converts known date/time columns
#' (both text and timestamp types from the source) to POSIXct objects using `lubridate`.
#'
#' @param data A data frame or tibble, typically the output from `get_arrests()`.
#' @param text_fields A character vector specifying the names of text columns to clean.
#'   Defaults to common categorical/text fields in the Arrests dataset.
#'   Provide `NULL` to skip text cleaning.
#' @param date_fields A character vector specifying the names of date/time columns
#'   to parse into POSIXct objects. Defaults to known date/time fields in the
#'   Arrests dataset. Provide `NULL` to skip date parsing.
#' @param tz The timezone to assign during date/time parsing. Defaults to
#'   `"America/Chicago"`. See `base::OlsonNames()` for other valid options.
#'
#' @return A tibble with the specified cleaning and parsing applied.
#' @export
#'
#' @importFrom dplyr mutate across all_of contains matches tibble select
#' @importFrom stringr str_to_lower str_trim str_squish
#' @importFrom rlang .data check_installed warn inform is_installed list2
#' @importFrom tidyselect everything where
#' @importFrom lubridate parse_date_time
#'
#' @examples
#' \dontrun{
#'   # Fetch some raw arrest data
#'   raw_arrests <- get_arrests(limit = 100, start_date = "2024-03-01")
#'
#'   # Apply default cleaning (common text fields + date fields)
#'   # Requires stringr & lubridate
#'   # install.packages(c("stringr", "lubridate"))
#'   cleaned_arrests <- clean_arrests_data(raw_arrests)
#'
#'   # Check class of arrest date
#'   print(class(cleaned_arrests$ararrestdate))
#'
#'   # Check distinct premises after cleaning
#'   print(unique(cleaned_arrests$arpremises))
#' }
clean_arrests_data <- function(data,
                               text_fields = c("arlzip", "arlcity", "arstate", "arldistrict",
                                               "aradow", "arpremises", "arweapon",
                                               "arcond", "race", "ethnic", "sex"),
                               date_fields = c("ararrestdate", "arbkdate", "warrantissueddate",
                                               "changedate", "ofcr_rpt_written_by_date",
                                               "ofcr_approved_by_date", "ofcr_received_by_date",
                                               "apprehended_date", "final_disp_date", "upzdate"),
                               tz = "America/Chicago") {

  # Input validation
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame or tibble.", call. = FALSE)
  }
  if (nrow(data) == 0) {
    rlang::inform("Input data has 0 rows, returning unmodified.")
    return(data)
  }
  if (!is.null(text_fields) && !is.character(text_fields)) {
    stop("`text_fields` must be a character vector of column names or NULL.", call. = FALSE)
  }
  if (!is.null(date_fields) && !is.character(date_fields)) {
    stop("`date_fields` must be a character vector of column names or NULL.", call. = FALSE)
  }
  if (!is.character(tz) || length(tz) != 1 || !(tz %in% base::OlsonNames())) {
    stop("`tz` must be a valid timezone name (see OlsonNames()).", call. = FALSE)
  }

  cleaned_data <- data

  # --- Clean Text Fields ---
  if (!is.null(text_fields)) {
    fields_to_clean_present <- intersect(text_fields, names(cleaned_data))
    missing_fields <- setdiff(text_fields, fields_to_clean_present)
    if (length(missing_fields) > 0) {
      rlang::warn(paste("Specified `text_fields` not found and skipped:", paste(missing_fields, collapse = ", ")))
    }

    if (length(fields_to_clean_present) > 0) {
      rlang::check_installed("stringr", reason = "to clean text fields.")
      rlang::inform(paste("Applying text cleaning (lower, trim, squish) to columns:",
                          paste(fields_to_clean_present, collapse=", ")))
      cleaned_data <- cleaned_data |>
        dplyr::mutate(
          dplyr::across(
            dplyr::all_of(fields_to_clean_present) & tidyselect::where(is.character),
            ~ .x |> stringr::str_to_lower() |> stringr::str_trim() |> stringr::str_squish()
          )
        )
    } else {
      rlang::inform("No specified text fields found or `text_fields` was NULL; skipping text cleaning.")
    }
  }


  # --- Convert Date/Time Fields ---
  if (!is.null(date_fields)) {
    fields_to_convert_present <- intersect(date_fields, names(cleaned_data))
    missing_fields_date <- setdiff(date_fields, fields_to_convert_present)
    if (length(missing_fields_date) > 0) {
      rlang::warn(paste("Specified `date_fields` not found and skipped:", paste(missing_fields_date, collapse = ", ")))
    }

    if (length(fields_to_convert_present) > 0) {
      rlang::check_installed("lubridate", reason = "to parse date/time strings.")
      rlang::inform(paste("Attempting to convert date columns to POSIXct (tz=", tz, "):",
                          paste(fields_to_convert_present, collapse=", ")))

      # Define likely orders for Socrata text/timestamp fields
      expected_orders <- c(
        "Ymd HMS",  # Common timestamp format
        "Ymd"       # Date only format
      )

      cleaned_data <- cleaned_data |>
        dplyr::mutate(
          # Apply to all specified date cols, lubridate handles various inputs
          dplyr::across(dplyr::all_of(fields_to_convert_present),
                        ~ lubridate::parse_date_time(.x, orders = expected_orders, tz = tz, quiet = TRUE))
        )

    } else {
      rlang::inform("No specified date fields found or `date_fields` was NULL; skipping date parsing.")
    }
  }

  return(cleaned_data)
}
