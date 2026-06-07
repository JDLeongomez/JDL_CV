scholar_id <- "8Q0jKHsAAAAJ"
cache_file  <- "scholar_cache.rds"

prompt_manual_metrics <- function(cache_file) {
  message("\nOpen your Scholar profile in a browser:")
  message("  https://scholar.google.com/citations?user=8Q0jKHsAAAAJ")
  message("\nEnter the values shown there:\n")

  h_index     <- as.integer(readline("  h-index: "))
  i10_index   <- as.integer(readline("  i10-index: "))
  total_cites <- as.integer(readline("  Total citations: "))

  pubs <- if (file.exists(cache_file)) {
    readRDS(cache_file)$pubs
  } else {
    data.frame(
      title = character(), journal = character(),
      year = integer(), cites = integer(),
      stringsAsFactors = FALSE
    )
  }

  list(
    profile = list(h_index = h_index, i10_index = i10_index, total_cites = total_cites),
    pubs    = pubs
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
  if (!is.list(data$profile) || nrow(data$pubs) == 0) {
    stop("Scholar returned invalid data (possibly rate-limited).")
  }
  saveRDS(data, cache_file)
  message("Scholar data saved to cache.")
  data
}, error = function(e) {
  message("Scholar fetch failed: ", conditionMessage(e))
  if (interactive()) {
    use_manual <- readline("Fetch failed. Enter metrics manually? [y/N]: ")
    if (tolower(trimws(use_manual)) == "y") {
      data <- prompt_manual_metrics(cache_file)
      saveRDS(data, cache_file)
      message("Cache updated with manual values.")
      return(data)
    }
  }
  if (file.exists(cache_file)) {
    message("Loading cached Scholar data.")
    readRDS(cache_file)
  } else {
    message("No cache available. Citation metrics will show NA.")
    NULL
  }
})

# Signal to each Rmd that Scholar data is already cached for this session
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
