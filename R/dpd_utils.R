# R/dpd_utils.R

dpd_user_agent <- function() {
  httr::user_agent("opendpd/0.1.0 (https://github.com/Steal-This-Code/opendpd)")
}

get_dpd_dataset_spec <- function(dataset) {
  dataset <- match.arg(dataset, c("incidents", "arrests"))

  switch(
    dataset,
    incidents = list(
      dataset = "incidents",
      base_url = "https://www.dallasopendata.com/resource/qv6i-rri7.json",
      date_field = "date1"
    ),
    arrests = list(
      dataset = "arrests",
      base_url = "https://www.dallasopendata.com/resource/sdr7-6v3j.json",
      date_field = "ararrestdate"
    )
  )
}

validate_limit <- function(limit) {
  if (!is.numeric(limit) || length(limit) != 1 || is.na(limit) || limit <= 0) {
    stop("`limit` must be a positive number or Inf.", call. = FALSE)
  }
}

sql_in_clause <- function(field, values) {
  if (is.null(values) || length(values) == 0) {
    return(NULL)
  }

  quoted_values <- vapply(values, function(value) {
    if (is.character(value)) {
      escaped <- gsub("'", "''", value, fixed = TRUE)
      paste0("'", escaped, "'")
    } else if (is.numeric(value) || is.logical(value)) {
      as.character(value)
    } else {
      escaped <- gsub("'", "''", as.character(value), fixed = TRUE)
      paste0("'", escaped, "'")
    }
  }, FUN.VALUE = character(1))

  paste0(field, " IN (", paste(quoted_values, collapse = ", "), ")")
}

compose_where_clause <- function(clauses) {
  clauses <- clauses[!vapply(clauses, is.null, logical(1))]
  clauses <- unlist(clauses, use.names = FALSE)

  if (length(clauses) == 0) {
    return(NULL)
  }

  paste(clauses, collapse = " AND ")
}

build_date_range_clauses <- function(date_field, start_date = NULL, end_date = NULL) {
  clauses <- character()

  if (!is.null(start_date)) {
    tryCatch({
      start_date_fmt <- format(as.Date(start_date), "%Y-%m-%dT00:00:00")
      clauses <- c(clauses, paste0(date_field, " >= '", start_date_fmt, "'"))
    }, error = function(e) {
      stop("`start_date` invalid format.", call. = FALSE)
    })
  }

  if (!is.null(end_date)) {
    tryCatch({
      end_date_exclusive_fmt <- format(as.Date(end_date) + 1, "%Y-%m-%dT00:00:00")
      clauses <- c(clauses, paste0(date_field, " < '", end_date_exclusive_fmt, "'"))
    }, error = function(e) {
      stop("`end_date` invalid format.", call. = FALSE)
    })
  }

  clauses
}

ensure_selected_columns <- function(select, required_columns, context = "processing") {
  if (is.null(select)) {
    return(select)
  }

  missing_columns <- setdiff(required_columns, select)
  if (length(missing_columns) > 0) {
    rlang::inform(
      paste0(
        "Adding required columns for ", context, ": ",
        paste(missing_columns, collapse = ", ")
      )
    )
    select <- c(select, missing_columns)
  }

  unique(select)
}

fetch_socrata_dataset <- function(base_url, limit = Inf, select = NULL, where = NULL, ...) {
  rlang::check_installed("httr", reason = "to fetch data from the API.")
  rlang::check_installed("jsonlite", reason = "to parse JSON data.")
  rlang::check_installed("dplyr", reason = "for data manipulation.")

  validate_limit(limit)

  query_params <- rlang::list2(...)

  if (!is.null(select)) {
    if (!is.character(select)) {
      stop("`select` must be a character vector.", call. = FALSE)
    }
    query_params[["$select"]] <- paste(unique(select), collapse = ",")
  }

  if (!is.null(where)) {
    if (!is.character(where) || length(where) != 1) {
      stop("`where` must be a single string.", call. = FALSE)
    }
    query_params[["$where"]] <- where
  }

  all_data_chunks <- list()
  current_offset <- 0
  records_retrieved <- 0
  api_max_limit_per_req <- 1000
  fetch_limit_this_req <- if (is.infinite(limit)) {
    api_max_limit_per_req
  } else {
    min(limit - records_retrieved, api_max_limit_per_req)
  }

  if (fetch_limit_this_req > 0) {
    rlang::inform("Starting data retrieval...")
  } else {
    rlang::inform("Limit is zero; returning empty dataset.")
    return(dplyr::tibble())
  }

  repeat {
    if (fetch_limit_this_req <= 0) {
      break
    }

    query_params[["$limit"]] <- fetch_limit_this_req
    query_params[["$offset"]] <- current_offset
    request_url <- httr::modify_url(base_url, query = query_params)

    response <- httr::GET(request_url, dpd_user_agent())
    httr::stop_for_status(response, task = paste("fetch data. URL:", request_url))

    if (httr::http_type(response) != "application/json") {
      stop("API did not return JSON.", call. = FALSE)
    }

    content_text <- httr::content(response, "text", encoding = "UTF-8")

    if (nchar(trimws(content_text)) <= 2 || identical(content_text, "[]")) {
      data_chunk <- dplyr::tibble()
    } else {
      data_chunk <- tryCatch({
        jsonlite::fromJSON(content_text, flatten = TRUE) |>
          dplyr::as_tibble()
      }, error = function(e) {
        stop(
          paste("Failed to parse JSON response. Error:", e$message),
          call. = FALSE
        )
      })
    }

    chunk_rows <- nrow(data_chunk)
    if (chunk_rows == 0) {
      rlang::inform("No more data found.")
      break
    }

    all_data_chunks[[length(all_data_chunks) + 1]] <- data_chunk
    records_retrieved <- records_retrieved + chunk_rows
    current_offset <- current_offset + chunk_rows

    if (!is.infinite(limit) && records_retrieved >= limit) {
      rlang::inform(paste("Reached limit of", limit))
      break
    }

    if (chunk_rows < fetch_limit_this_req) {
      rlang::inform("Retrieved last page.")
      break
    }

    fetch_limit_this_req <- if (is.infinite(limit)) {
      api_max_limit_per_req
    } else {
      min(limit - records_retrieved, api_max_limit_per_req)
    }
  }

  rlang::inform(paste("Total records retrieved:", records_retrieved))

  if (length(all_data_chunks) == 0) {
    rlang::inform("Query returned no matching records.")
    return(dplyr::tibble())
  }

  final_data <- dplyr::bind_rows(all_data_chunks)

  if (!is.infinite(limit) && nrow(final_data) > limit) {
    final_data <- final_data[seq_len(limit), , drop = FALSE]
  }

  rlang::inform("Data retrieval complete.")
  final_data
}

#' Download Raw Dallas Police Data
#'
#' Downloads Dallas Police datasets from the Dallas Open Data portal without
#' applying any package-level cleaning or normalization.
#'
#' @param dataset Which dataset to download. Currently supports `"incidents"`
#'   and `"arrests"`.
#' @param start_date Optional. A character string in `'YYYY-MM-DD'` format or a
#'   `Date` object specifying the minimum record date (inclusive) for the
#'   dataset's primary date field.
#' @param end_date Optional. A character string in `'YYYY-MM-DD'` format or a
#'   `Date` object specifying the maximum record date (inclusive) for the
#'   dataset's primary date field.
#' @param limit The maximum number of raw records to return. Defaults to `Inf`.
#' @param select A character vector specifying which columns to retrieve.
#'   If `NULL` (default), all columns are retrieved.
#' @param where An optional character string containing a custom SoQL `WHERE`
#'   clause. If supplied, `start_date` and `end_date` are ignored.
#' @param ... Additional SODA query parameters passed directly to the API URL,
#'   such as `$order`.
#'
#' @return A tibble containing the raw API response for the selected dataset.
#' @export
download_dpd_raw <- function(dataset = c("incidents", "arrests"),
                             start_date = NULL,
                             end_date = NULL,
                             limit = Inf,
                             select = NULL,
                             where = NULL,
                             ...) {
  spec <- get_dpd_dataset_spec(dataset)

  if (!is.null(where) && (!is.null(start_date) || !is.null(end_date))) {
    rlang::warn("Using 'where'; ignoring start_date and end_date.")
  }

  effective_where <- if (is.null(where)) {
    compose_where_clause(
      build_date_range_clauses(
        date_field = spec$date_field,
        start_date = start_date,
        end_date = end_date
      )
    )
  } else {
    where
  }

  fetch_socrata_dataset(
    base_url = spec$base_url,
    limit = limit,
    select = select,
    where = effective_where,
    ...
  )
}

normalize_text_value <- function(x) {
  clean <- stringr::str_to_lower(as.character(x))
  clean <- stringr::str_trim(clean)
  clean <- stringr::str_squish(clean)
  clean[is.na(x) | clean == ""] <- NA_character_
  clean
}

normalize_code_value <- function(x) {
  clean <- stringr::str_to_upper(as.character(x))
  clean <- stringr::str_trim(clean)
  clean <- stringr::str_squish(clean)
  clean[is.na(x) | clean == ""] <- NA_character_
  clean
}

normalize_id_value <- function(x) {
  clean <- stringr::str_trim(as.character(x))
  clean <- stringr::str_squish(clean)
  clean[is.na(x) | clean == ""] <- NA_character_
  clean
}

coerce_numeric_filter <- function(x) {
  numeric_values <- suppressWarnings(as.numeric(x))

  if (all(is.na(numeric_values)) && any(!is.na(x))) {
    return(as.character(x))
  }

  numeric_values
}

standardize_division_values <- function(x) {
  clean <- normalize_text_value(x)

  division_map <- c(
    "central patrol div" = "central",
    "south west" = "southwest",
    "north east" = "northeast",
    "north west" = "northwest",
    "south central" = "southcentral",
    "south east" = "southeast",
    "north central" = "northcentral",
    "central" = "central",
    "northeast" = "northeast",
    "northwest" = "northwest",
    "southcentral" = "southcentral",
    "southeast" = "southeast",
    "southwest" = "southwest",
    "northcentral" = "northcentral"
  )

  standardized <- unname(division_map[clean])
  standardized[is.na(clean)] <- NA_character_
  standardized
}

standardize_council_district_values <- function(x) {
  clean <- normalize_text_value(x)
  standard_levels <- as.character(1:14)

  standardized <- ifelse(
    clean %in% standard_levels,
    clean,
    stringr::str_extract(clean, "\\d{1,2}$")
  )

  standardized[!standardized %in% standard_levels] <- NA_character_
  standardized[is.na(clean)] <- NA_character_
  standardized
}

append_clean_columns <- function(data, fields, transform, suffix = "_clean", overwrite = FALSE) {
  present_fields <- intersect(fields, names(data))

  for (field in present_fields) {
    target_field <- if (overwrite) field else paste0(field, suffix)
    data[[target_field]] <- transform(data[[field]])
  }

  data
}

append_parsed_date_columns <- function(data,
                                       fields,
                                       tz,
                                       suffix = "_parsed",
                                       overwrite = FALSE) {
  present_fields <- intersect(fields, names(data))
  expected_orders <- c("Ymd HMS", "Ymd")

  for (field in present_fields) {
    target_field <- if (overwrite) field else paste0(field, suffix)
    data[[target_field]] <- lubridate::parse_date_time(
      data[[field]],
      orders = expected_orders,
      tz = tz,
      quiet = TRUE
    )
  }

  data
}

filter_vector_in <- function(data, column, values, transform = identity) {
  if (is.null(values) || !column %in% names(data)) {
    return(data)
  }

  target_values <- unique(transform(values))
  target_values <- target_values[!is.na(target_values)]

  if (length(target_values) == 0) {
    return(data[0, , drop = FALSE])
  }

  source_values <- transform(data[[column]])
  keep <- !is.na(source_values) & source_values %in% target_values
  data[keep, , drop = FALSE]
}

truncate_to_limit <- function(data, limit) {
  if (is.infinite(limit) || nrow(data) <= limit) {
    return(data)
  }

  data[seq_len(limit), , drop = FALSE]
}

filter_incidents_locally <- function(data,
                                     nibrs_group = NULL,
                                     nibrs_code = NULL,
                                     nibrs_crime_against = NULL,
                                     zip_code = NULL,
                                     beat = NULL,
                                     division = NULL,
                                     sector = NULL,
                                     district = NULL) {
  filtered <- data

  filtered <- filter_vector_in(
    filtered,
    column = if ("nibrs_group_clean" %in% names(filtered)) "nibrs_group_clean" else "nibrs_group",
    values = nibrs_group,
    transform = normalize_code_value
  )
  filtered <- filter_vector_in(
    filtered,
    column = if ("nibrs_code_clean" %in% names(filtered)) "nibrs_code_clean" else "nibrs_code",
    values = nibrs_code,
    transform = normalize_code_value
  )
  filtered <- filter_vector_in(
    filtered,
    column = if ("nibrs_crimeagainst_clean" %in% names(filtered)) "nibrs_crimeagainst_clean" else "nibrs_crimeagainst",
    values = nibrs_crime_against,
    transform = normalize_code_value
  )
  filtered <- filter_vector_in(
    filtered,
    column = if ("zip_code_clean" %in% names(filtered)) "zip_code_clean" else "zip_code",
    values = zip_code,
    transform = normalize_id_value
  )
  filtered <- filter_vector_in(
    filtered,
    column = if ("beat_clean" %in% names(filtered)) "beat_clean" else "beat",
    values = beat,
    transform = normalize_id_value
  )
  filtered <- filter_vector_in(
    filtered,
    column = if ("division_standardized" %in% names(filtered)) "division_standardized" else "division",
    values = division,
    transform = standardize_division_values
  )
  filtered <- filter_vector_in(
    filtered,
    column = if ("sector_clean" %in% names(filtered)) "sector_clean" else "sector",
    values = sector,
    transform = normalize_id_value
  )
  filtered <- filter_vector_in(
    filtered,
    column = if ("district_standardized" %in% names(filtered)) "district_standardized" else "district",
    values = district,
    transform = standardize_council_district_values
  )

  filtered
}

filter_arrests_locally <- function(data,
                                   zip_code = NULL,
                                   beat = NULL,
                                   sector = NULL,
                                   district = NULL) {
  filtered <- data

  filtered <- filter_vector_in(
    filtered,
    column = if ("arlzip_clean" %in% names(filtered)) "arlzip_clean" else "arlzip",
    values = zip_code,
    transform = normalize_id_value
  )
  filtered <- filter_vector_in(
    filtered,
    column = if ("arlbeat_clean" %in% names(filtered)) "arlbeat_clean" else "arlbeat",
    values = beat,
    transform = normalize_id_value
  )
  filtered <- filter_vector_in(
    filtered,
    column = if ("arlsector_clean" %in% names(filtered)) "arlsector_clean" else "arlsector",
    values = sector,
    transform = normalize_id_value
  )
  filtered <- filter_vector_in(
    filtered,
    column = if ("arldistrict_clean" %in% names(filtered)) "arldistrict_clean" else "arldistrict",
    values = district,
    transform = normalize_text_value
  )

  filtered
}
