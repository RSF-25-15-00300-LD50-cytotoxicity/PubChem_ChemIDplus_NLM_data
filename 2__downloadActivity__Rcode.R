library(tidyverse)
library(jsonlite)

# The way to efficiently download the toxicity values was not found in https://pubchem.ncbi.nlm.nih.gov/docs/
# The problem is that the values are situated in the "external table", which could be accessed via the external link,
# but the additional time is needed for the data to render.
# However, while accessing this table via PubChem's graphical interface the link is generated, which mentions some "sdq.agent" 
# Browser's AI said:
# "sdqagent" is an internal agent for the PubChem search interface that is used to retrieve chemical information. An error message showing "SDQ FETCH ERROR" indicates a problem with this agent's process, often due to a network issue or a request that could not be processed, as seen in an error when searching for "DIDECYL DIMETHYL AMMONIUM CHLORIDE". 
# PubChem: This is a free, open database of chemical molecules and their biological activities, maintained by the U.S. National Institutes of Health (NIH).
# sdqagent: This is a backend agent that handles requests from the PubChem website to search for and retrieve data, as detailed in a PubChem search error log.
# I was not able to find the description of this tool in the official docs, but
# There is a paper, which probably mentions it: https://journals.flvc.org/cee/article/view/115508
# There is a related discussion: https://stackoverflow.com/questions/75110830/programmatic-access-to-pubchem-bioassay-data-in-r
# Thus, I decided to use this SDQ agent thing:
# It is fast and convinient

# Please, comply with the PubChem's Programmatic Access Usage Policy:
# USAGE POLICY: Please note that PubChem web services run on a limited pool of servers shared by all PubChem users.
# We ask that any user, application, or organization not make more than 5 requests per second, in order to avoid overloading these servers.
# For more detail on request volume limitations, including automated rate limiting (throttling), please read this document.
# We cannot offer API keys or whitelists to exceed these limits. If you have a large data set that you need to compute with,
# please contact us for help on optimizing your task, as there are likely more efficient ways to approach bulk access.
# See also the help page for bulk data downloads.

# Read the dataset containing the CIDs of chemicals of interest
cid <- read_tsv(".../data/acutetox_cmpnds.tsv")

# Get the vector of cidd and divide it into chunks
cid_v <- cid |> pull(cid) |> unique()
chunks <- split(cid_v, ceiling(seq_along(cid_v)/30)) |> lapply( \(x) str_c(x, collapse = ","))

# 

# Download the data on acute toxicity
issues <- rep(NA, chunks |> length())
safe_counter <- 0
for (i in seq(1:length(chunks))) {
	safe_counter <- safe_counter + 1
	link_start <- 'https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=json&query={"select":"*","collection":"chemidplus","order":["relevancescore,desc"],"start":1,"limit":999,"where":{"ands":[{"cid":"'
	link_middle <- chunks[[i]]
	link_end <- '"}]},"width":1000000,"listids":0}'
	link <- str_c(c(link_start, link_middle, link_end), collapse = "")
	if (safe_counter < 5) {
		Sys.sleep(1)
		rslt <- tryCatch({ read_json(link) },
					warning = function(w) { "warn" },
					error = function(e) { "err" })
		if ( rslt == "warn" | rslt == "err") {
				issues[i] <- rslt
				print("Problem")
			} else {
				write_json(rslt, str_glue(".../data/json/acutetox_data_{i}.JSON"))
				print("OK")
			}
	} else {
		safe_counter <- 0
		Sys.sleep(3)
		rslt <- tryCatch({ read_json(link) },
					warning = function(w) { "warn" },
					error = function(e) { "err" })
		if ( rslt == "warn" | rslt == "err") {
				issues[i] <- rslt
				print("Problem")
			} else {
				write_json(rslt, str_glue(".../data/json/acutetox_data_{i}.JSON"))
				print("OK")
		}
	}
}

Sys.sleep(30)

# Check the problems

# Get the problematic indices
problem_t <- tibble(value = issues) |> rowid_to_column(var = "pos") |> filter(!is.na(value)) # nothing basically
files <- tibble(exist = list.files(path = ".../data/json", full.names = FALSE) |>
						str_replace("acutetox_data_", "") |>
						str_replace(".JSON", "") |> as.integer())
shouldbe <- tibble(shouldbe = seq(1:length(chunks))) |> anti_join(files, by = c("shouldbe"="exist"))

# Download the remaining data on acute toxicity
issues <- rep( NA, nrow(shouldbe) )
safe_counter <- 0
safe_counter <- 0
for (i in seq(1:nrow(shouldbe))) {
	safe_counter <- safe_counter + 1
	link_start <- 'https://pubchem.ncbi.nlm.nih.gov/sdq/sdqagent.cgi?infmt=json&outfmt=json&query={"select":"*","collection":"chemidplus","order":["relevancescore,desc"],"start":1,"limit":999,"where":{"ands":[{"cid":"'
	link_middle <- chunks[[shouldbe[i,1] |> pull()]]
	link_end <- '"}]},"width":1000000,"listids":0}'
	link <- str_c(c(link_start, link_middle, link_end), collapse = "")
	if (safe_counter < 5) {
		Sys.sleep(3)
		rslt <- tryCatch({ read_json(link) },
					warning = function(w) { "warn" },
					error = function(e) { "err" })
		if ( rslt == "warn" | rslt == "err") {
				issues[i] <- rslt
				print("Problem")
			} else {
				write_json(rslt, str_glue(".../data/json/acutetox_data_{shouldbe[i,1] |> pull()}.JSON"))
				print("OK")
			}
	} else {
		safe_counter <- 0
		Sys.sleep(3)
		rslt <- tryCatch({ read_json(link) },
					warning = function(w) { "warn" },
					error = function(e) { "err" })
		if ( rslt == "warn" | rslt == "err") {
				issues[i] <- rslt
				print("Problem")
			} else {
				write_json(rslt, str_glue(".../data/json/acutetox_data_{shouldbe[i,1] |> pull()}.JSON"))
				print("OK")
		}
	}
}
