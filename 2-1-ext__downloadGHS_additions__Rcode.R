library(tidyverse)
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

# Input
hnids <- read_tsv("C:/.../hid83/env_hazard-and-precautions.tsv") |>
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
write_tsv(hnids_exp, "C:/.../env_precautions_cid.tsv")