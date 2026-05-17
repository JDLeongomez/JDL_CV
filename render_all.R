scholar_id <- "8Q0jKHsAAAAJ"
cache_file  <- "scholar_cache.rds"

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
  saveRDS(data, cache_file)
  message("Scholar data saved to cache.")
  data
}, error = function(e) {
  message("Scholar fetch failed: ", conditionMessage(e))
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
