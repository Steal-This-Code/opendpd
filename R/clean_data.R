# R/clean_data.R (Replace existing clean_incidents_data)

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
#' @importFrom rlang .data check_installed warn inform is_installed list2
#' @importFrom tidyselect everything where # Changed from defining where locally
#' @importFrom lubridate parse_date_time # Added lubridate import
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
            dplyr::all_of(fields_to_clean_present) & tidyselect::where(is.character), # Apply only to character cols
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
      # Socrata often uses ISO 8601 format like YYYY-MM-DDTHH:MM:SS
      # Sometimes date only might appear
      expected_orders <- c(
        "Ymd HMS",  # Common format with time
        "Ymd"       # Date only
        # Add others if specific formats are identified, e.g., "%m/%d/%Y %H:%M:%S"
      )

      cleaned_data <- cleaned_data |>
        dplyr::mutate(
          dplyr::across(dplyr::all_of(fields_to_convert_present),
                        ~ lubridate::parse_date_time(.x, orders = expected_orders, tz = tz, quiet = TRUE))
          # quiet = TRUE returns NA for parsing failures without excessive warnings
        )

      # Optional: Check for introduced NAs more thoroughly if needed
      # for (col in fields_to_convert_present) {
      #   num_failed <- sum(is.na(cleaned_data[[col]]) & !is.na(data[[col]]) & data[[col]] != "")
      #   if (num_failed > 0) {
      #      rlang::warn(paste(num_failed, "value(s) in column", shQuote(col), "failed to parse as dates/times."))
      #   }
      # }

    } else {
      rlang::inform("No specified date fields found or `date_fields` was NULL; skipping date parsing.")
    }
  }

  return(cleaned_data)
}

# Remove the locally defined 'where' function if it was added before,
# use tidyselect::where directly or ensure tidyselect is imported if needed.
# (Importing tidyselect itself might be easiest if using it more)
# Or alternatively, keep the helper:
# where <- function (fn) {
#   predicate <- rlang::as_function(fn)
#   function(x, ...) predicate(x, ...)
# }

#' Standardize Police Division Names
#'
#' Maps known variations of Dallas Police division names to a standard set and
#' converts the column to a factor. Designed to be used after basic text cleaning
#' (e.g., via `clean_incidents_data`).
#'
#' @param data A data frame or tibble containing a column named `division`,
#'   preferably already cleaned to lowercase and with squished whitespace.
#' @param division_col The name of the division column (unquoted or as string).
#'   Defaults to `division`.
#'
#' @return A tibble with the specified division column standardized and converted
#'   to a factor with defined levels: "central", "northeast", "northwest",
#'   "southcentral", "southeast", "southwest", "northcentral". Values not matching
#'   known variations or standard names will become `NA`.
#' @export
#'
#' @importFrom dplyr mutate case_match select all_of rename_with
#' @importFrom rlang .data enquo quo_name sym
#' @importFrom stringr str_squish str_to_lower # Apply basic cleaning again for robustness
#'
#' @examples
#' \dontrun{
#'   # Assume raw_incidents is output from get_incidents()
#'   # Basic cleaning first
#'   cleaned_incidents <- clean_incidents_data(raw_incidents)
#'
#'   # Standardize the 'division' column
#'   standardized_incidents <- standardize_division(cleaned_incidents)
#'
#'   # Check the levels and values
#'   print(levels(standardized_incidents$division))
#'   print(table(standardized_incidents$division, useNA = "ifany"))
#'
#'   # Example with a non-standard column name
#'   # df <- tibble::tibble(dpd_division = c("central", " South West ", "NORTHEAST"))
#'   # standardized_df <- standardize_division(df, division_col = dpd_division)
#'   # print(standardized_df)
#' }
standardize_division <- function(data, division_col = division) {

  # Capture the column name using non-standard evaluation
  col_quo <- rlang::enquo(division_col)
  col_name <- rlang::quo_name(col_quo)

  # Check if column exists
  if (!col_name %in% names(data)) {
    rlang::warn(paste("Column", shQuote(col_name), "not found in data. Skipping standardization."))
    return(data)
  }

  # Ensure dependencies are available if used directly
  rlang::check_installed("dplyr", reason = "to standardize division names.")
  rlang::check_installed("stringr", reason = "to clean division names.")

  # Define standard names (ensure this list is correct/complete for DPD)
  standard_division_names <- c("central", "northeast", "northwest",
                               "southcentral", "southeast", "southwest",
                               "northcentral")

  rlang::inform(paste("Standardizing column:", shQuote(col_name)))

  # Create a temporary cleaned name to work with
  temp_clean_col <- paste0(col_name, "_clean_temp")

  data_standardized <- data |>
    # Apply basic cleaning robustly (lowercase, squish whitespace)
    dplyr::mutate(
      # Use across with the captured column name
      dplyr::across(dplyr::all_of(col_name),
                    ~ stringr::str_squish(stringr::str_to_lower(as.character(.))),
                    .names = "{.col}_clean_temp") # Store in temp column
    ) |>
    dplyr::mutate(
      # Standardize using case_match on the temporary cleaned column
      "{col_name}_std_temp" := dplyr::case_match(
        .data[[temp_clean_col]], # Access temp column data
        # --- Map known variations first ---
        # Add variations as identified from exploring data
        "central patrol div" ~ "central",
        "south west" ~ "southwest",
        "north east" ~ "northeast",
        "north west" ~ "northwest",
        "south central" ~ "southcentral", # Map standard to self explicitly
        "south east" ~ "southeast",       # Map standard to self explicitly
        "north central" ~ "northcentral", # Map standard to self explicitly

        # --- Map standard names to themselves ---
        # This handles cases already correct and ensures they map correctly
        # It's somewhat redundant if the variations above cover these, but safe
        standard_division_names ~ .data[[temp_clean_col]],

        # --- Handle anything else ---
        # By default, case_match returns NA if no condition is met.
        # This flags unknown/unexpected values.
        .default = NA_character_
      )
    )

  # Check if any values became NA during standardization (optional but informative)
  original_values <- data[[col_name]]
  standardized_values <- data_standardized[[paste0(col_name,"_std_temp")]]
  num_na_introduced <- sum(is.na(standardized_values) & !is.na(original_values) & original_values != "")
  if (num_na_introduced > 0) {
    rlang::warn(paste0(num_na_introduced, " value(s) in column ", shQuote(col_name),
                       " did not match standard divisions and became NA."))
  }


  # Overwrite original column, convert to factor w/ standard levels
  # Use the !!sym() construct to use the string col_name on the LHS
  data_standardized <- data_standardized |>
    dplyr::mutate(
      !!rlang::sym(col_name) := factor(.data[[paste0(col_name,"_std_temp")]],
                                       levels = standard_division_names)
    ) |>
    # Remove the temporary columns
    dplyr::select(-dplyr::all_of(c(temp_clean_col, paste0(col_name,"_std_temp"))))


  return(data_standardized)
}


#' Standardize Dallas Council District Names
#'
#' Attempts to map variations of Dallas City Council District names/numbers
#' to a standard format ("1" through "14") and converts the column to a factor.
#' Assumes input column has already had basic text cleaning (lowercase, spacing).
#'
#' @param data A data frame or tibble containing a council district column,
#'   typically named `district`.
#' @param district_col The name of the district column (unquoted or as string).
#'   Defaults to `district`.
#'
#' @return A tibble with the specified district column standardized to character
#'   values "1" through "14" and converted to a factor. Values that cannot be
#'   confidently mapped to 1-14 will become `NA`.
#' @export
#'
#' @importFrom dplyr mutate case_match select all_of rename_with across lead lag na_if pull if_else
#' @importFrom rlang .data enquo quo_name sym :=
#' @importFrom stringr str_squish str_to_lower str_extract str_detect
#'
#' @examples
#' \dontrun{
#'   # Assume raw_incidents is output from get_incidents()
#'   cleaned_incidents <- clean_incidents_data(raw_incidents) # Basic cleaning first
#'   standardized_incidents <- standardize_district(cleaned_incidents)
#'
#'   # Check the levels and values
#'   print(levels(standardized_incidents$district))
#'   print(table(standardized_incidents$district, useNA = "ifany"))
#'
#'   # Example with different inputs
#'   # df <- tibble::tibble(council_dist = c("1", "District 2", "DISTRICT_03", "UNKNOWN"))
#'   # standardized_df <- standardize_district(df, district_col = council_dist)
#'   # print(standardized_df) # Expect "1", "2", "3", NA
#' }
standardize_district <- function(data, district_col = district) {

  # Capture the column name
  col_quo <- rlang::enquo(district_col)
  col_name <- rlang::quo_name(col_quo)

  # Check if column exists
  if (!col_name %in% names(data)) {
    rlang::warn(paste("Column", shQuote(col_name), "not found in data. Skipping standardization."))
    return(data)
  }

  # Ensure dependencies
  rlang::check_installed("dplyr", reason = "to standardize district names.")
  rlang::check_installed("stringr", reason = "to clean/extract district names.")

  # Define standard levels
  standard_district_levels <- as.character(1:14)

  rlang::inform(paste("Standardizing Council District column:", shQuote(col_name)))

  # Temporary column names
  temp_clean_col <- paste0(col_name, "_clean_temp")
  temp_std_col <- paste0(col_name, "_std_temp")

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
        # .data[[temp_clean_col]] == "some other text" ~ "desired_number",
        .default = NA_character_ # Default to NA if no pattern matches
      ),
      # Ensure extracted numbers are within the valid 1-14 range
      "{temp_std_col}" := dplyr::if_else(
        !is.na(.data[[temp_std_col]]) & .data[[temp_std_col]] %in% standard_district_levels,
        .data[[temp_std_col]],
        NA_character_
      )
    )

  # Check NAs (similar logic as standardize_division)
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
      !!rlang::sym(col_name) := factor(.data[[temp_std_col]],
                                       levels = standard_district_levels)
    ) |>
    # Remove temporary columns
    dplyr::select(-dplyr::all_of(c(temp_clean_col, temp_std_col)))

  return(data_standardized)
}

# R/clean_data.R (Add this function)

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
#'
#'   # Clean only date fields
#'   dates_only_cleaned <- clean_arrests_data(raw_arrests, text_fields = NULL)
#'   print(head(dates_only_cleaned))
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
            dplyr::all_of(fields_to_clean_present) & tidyselect::where(is.character), # Apply only to character cols
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
