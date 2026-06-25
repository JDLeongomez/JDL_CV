scholar_id <- "8Q0jKHsAAAAJ"
cache_file  <- "scholar_cache.rds"

# Dialog helpers: popup in RStudio, readline fallback in plain R
ask_yn <- function(title, message) {
  if (rstudioapi::isAvailable()) {
    isTRUE(rstudioapi::showQuestion(title, message, ok = "Yes", cancel = "No"))
  } else {
    tolower(trimws(readline(paste0(message, " [y/N]: ")))) == "y"
  }
}

ask_value <- function(label) {
  if (rstudioapi::isAvailable()) {
    val <- rstudioapi::showPrompt(title = label, message = label, default = "")
    if (is.null(val)) stop("Cancelled by user.")
    val
  } else {
    readline(paste0("  ", label, ": "))
  }
}

prompt_manual_metrics <- function() {
  message("\nOpen your Scholar profile in a browser:")
  message("  https://scholar.google.com/citations?user=8Q0jKHsAAAAJ\n")

  list(
    profile = list(
      h_index     = as.integer(ask_value("h-index")),
      i10_index   = as.integer(ask_value("i10-index")),
      total_cites = as.integer(ask_value("Total citations")),
      pubs_num    = as.integer(ask_value("Number of publications")),
      g_index     = as.integer(ask_value("g-index")),
      meancit     = as.numeric(ask_value("Mean citations")),
      mediancit   = as.numeric(ask_value("Median citations"))
    ),
    pubs = data.frame(
      title = character(), journal = character(),
      year = integer(), cites = integer(),
      stringsAsFactors = FALSE
    )
  )
}

message("Fetching Google Scholar data...")
scholar_data <- tryCatch({
  data <- list(
    profile = scholar::get_profile(scholar_id),
    pubs    = scholar::get_publications(scholar_id) |>
      dplyr::filter(
        journal != "",
        !grepl("The Conversation|University of Stirling", journal)
      )
  )
  if (!is.list(data$profile) || is.null(data$profile$h_index) ||
      is.null(data$pubs) || nrow(data$pubs) == 0) {
    stop("Scholar returned invalid data (possibly rate-limited).")
  }
  saveRDS(data, cache_file)
  message("Scholar data saved to cache.")
  data
}, error = function(e) {
  message("Scholar fetch failed: ", conditionMessage(e))
  NULL
})

# Scholar failed — always offer manual entry (cache may be outdated)
if (is.null(scholar_data)) {
  if (ask_yn(
    title   = "Scholar unavailable",
    message = "Could not fetch Google Scholar data.\nEnter metrics manually?"
  )) {
    scholar_data <- prompt_manual_metrics()
    saveRDS(scholar_data, cache_file)
    message("Cache saved with manual values.")
  } else if (file.exists(cache_file)) {
    message("Loading existing cache.")
    scholar_data <- readRDS(cache_file)
  } else {
    message("Proceeding without Scholar data — metrics will show NA.")
  }
}

# Signal to each Rmd that Scholar data is already resolved for this session
options(jdl_scholar_cache_only = TRUE)

cv_dirs <- list.files(".", pattern = "^CV_", include.dirs = TRUE)

for (dir in cv_dirs) {
  for (file in list.files(dir, pattern = "\\.Rmd$")) {
    message("\nRendering: ", dir, "/", file)
    withr::with_dir(dir, rmarkdown::render(file))
  }
}

options(jdl_scholar_cache_only = FALSE)
message("\nDone.")
