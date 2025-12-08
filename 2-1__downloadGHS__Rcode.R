library(tidyverse)

# The "hnids" are used in this script to retrieve the list of compounds' IDs associated with the particular health code.
# These hnids are mentioned in: https://pubchem.ncbi.nlm.nih.gov/docs/pug-rest#section=Source-Table.
# The hnids for the GHS health codes are contained in https://pubchem.ncbi.nlm.nih.gov/classification/#hid=72 in the href corresponding to the each code.
# Initially, the were obtained semi-automatically, thus, instead of the code the file with hnids is provided, please, SEE: 

# INFO
# GHS Classification (Rev.11, 2025) Summary
# GHS, the Globally Harmonized System of Classification and Labeling of Chemicals, was developed by the United Nations as a way to bring into agreement the chemical regulations and standards of different countries. GHS includes criteria for the classification of health, physical and environmental hazards, as well as specifying what information should be included on labels of hazardous chemicals as well as safety data sheets. This page summarizes the relationship of GHS hazard statements, pictograms, signal words, hazard classes, categories, and precautionary statements.
# References:
# UNECE GHS (Rev.11, 2025)
# UNECE GHS (Rev.10, 2023)
# UNECE GHS (Rev.9, 2021)
# UNECE GHS (Rev.8, 2019)
# UNECE GHS (Rev.7, 2017)
# UNECE GHS (Rev.6, 2015)
# UNECE GHS (Rev.5, 2013)

# Please, comply with the PubChem's Programmatic Access Usage Policy:
# USAGE POLICY: Please note that PubChem web services run on a limited pool of servers shared by all PubChem users.
# We ask that any user, application, or organization not make more than 5 requests per second, in order to avoid overloading these servers.
# For more detail on request volume limitations, including automated rate limiting (throttling), please read this document.
# We cannot offer API keys or whitelists to exceed these limits. If you have a large data set that you need to compute with,
# please contact us for help on optimizing your task, as there are likely more efficient ways to approach bulk access.
# See also the help page for bulk data downloads.

# Input
hnids <- read_tsv(".../raw_data/hazardStatementCodes_health_H300.tab") |>
					mutate(cid = NA_character_)

# Retrive associated CIDS
issues <- rep(NA, hnids |> nrow())
safe_counter <- 0
for (i in seq(1:nrow(hnids))) {
	safe_counter <- safe_counter + 1
	if (safe_counter > 5) {
		Sys.sleep(1)
		safe_counter <- 0
	}
	# Prepare the link
	link <- str_glue("https://pubchem.ncbi.nlm.nih.gov/rest/pug/classification/hnid/{hnids[i, 1] |> pull()}/cids/TXT")
	rslt <- tryCatch({ read_file(link) },
				warning = function(w) { "warn" },
				error = function(e) { "err" })
	if ( rslt == "warn" | rslt == "err" | is.na(rslt)) {
		issues[i] <- "problem"
		print("Problem")
	} else {
		hnids[i,3] <- rslt
		print("OK")
	}
}

# Export the results
hnids_exp <- hnids |> mutate(cid = str_trim(cid)) |>
				separate_longer_delim(cid, delim = "\n")
write_tsv(hnids_exp, ".../data/h300_cid.tsv")