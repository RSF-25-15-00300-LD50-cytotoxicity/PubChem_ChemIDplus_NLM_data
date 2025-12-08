library(tidyverse)
library(jsonlite)

# Simply parse the data obtained on step 2 and make flat table with the results needed

# List files in the folder
files <- list.files(path = ".../data/json", full.names = TRUE)
# Prepare the tibble
result <- tibble(effect = rep(NA, 108000*4), gid = rep(NA, 108000*4), srcid = rep(NA, 108000*4), cid = rep(NA, 108000*4),
					sid = rep(NA, 108000*4), sourceid = rep(NA, 108000*4), organism = rep(NA, 108000*4),
					testtype = rep(NA, 108000*4), route = rep(NA, 108000*4), dose = rep(NA, 108000*4), reference = rep(NA, 108000*4) ) 
# Process files
row_counter <- 0
for (i in seq(1:length(files))) {
	json <- read_json(files[i])[[1]][[1]][["rows"]]
	if (length(json) > 0) {
		for (k in seq(1:length(json))) {
			row_counter <- row_counter + 1
			result[row_counter, 1] <- json[[k]]$effect |> unlist() |> str_c(collapse = " | ")
			result[row_counter, 2] <- json[[k]]$gid |> unlist() |> str_c(collapse = " | ")
			result[row_counter, 3] <- json[[k]]$srcid |> unlist() |> str_c(collapse = " | ")
			result[row_counter, 4] <- json[[k]]$cid |> unlist() |> str_c(collapse = " | ")
			result[row_counter, 5] <- json[[k]]$sid |> unlist() |> str_c(collapse = " | ")
			result[row_counter, 6] <- json[[k]]$sourceid |> unlist() |> str_c(collapse = " | ")
			result[row_counter, 7] <- json[[k]]$organism |> unlist() |> str_c(collapse = " | ")
			result[row_counter, 8] <- json[[k]]$testtype |> unlist() |> str_c(collapse = " | ")
			result[row_counter, 9] <- json[[k]]$route |> unlist() |> str_c(collapse = " | ")
			result[row_counter, 10] <- json[[k]]$dose |> unlist() |> str_c(collapse = " | ")
			result[row_counter, 11] <- json[[k]]$reference |> unlist() |> str_c(collapse = " | ")
		}
	}
}

# Delete empty
result <- result |> filter(!is.na(effect)) |> distinct() |>
						mutate(effect = as.character(effect), gid = as.character(gid), srcid = as.character(srcid), cid = as.character(cid),
								sid = as.character(sid), sourceid = as.character(sourceid), organism = as.character(organism),
								testtype = as.character(testtype), route = as.character(route), dose = as.character(dose),
								reference = as.character(reference))

write_tsv(result, ".../data/result_acutetox.tsv")