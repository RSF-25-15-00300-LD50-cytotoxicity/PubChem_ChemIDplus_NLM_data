library(tidyverse)
library(jsonlite)

# The JSON file was obtained via PubChem's graphical interface: https://pubchem.ncbi.nlm.nih.gov/
# The JSON file was generated using the following steps:
# https://pubchem.ncbi.nlm.nih.gov/		->
# Browse data 							->
# Browse PubChem Compound TOC 			->
# Acute Effects 						->
# Download

# Import JSON

# NB, SOME ERRORS in downloaded file, such things could happen
# > toxdata_json <- read_json(".../raw_data/PubChem_compound_cache_TQroaGNiBt4x8I7pDJHHzseWi_bGhiVTX3Y-H0RnLB5EfhA.json")
# Error in parse_con(txt, bigint_as_char) : 
#   parse error: after array element, I expect ',' or ']'
#           "Subscription Services"] 	} 	{ 		"cid": "6", 		"cmpdname": "
#                      (right here) ------^

# -> replace "}\n" with "},\n"

# Error in parse_con(txt, bigint_as_char) : 
#   parse error: unallowed token at this point in JSON text
#           search and Development"] 	}, ] 
#                      (right here) ------^

# -> replace "}, ]" with "} ]"
toxdata_json <- read_json(".../raw_data/PubChem_compound_cache_TQroaGNiBt4x8I7pDJHHzseWi_bGhiVTX3Y-H0RnLB5EfhA.json")

# Prepare the tibble to store the results
toxdata <- tibble(cid = rep(NA, length(toxdata_json)), name = rep(NA, length(toxdata_json)), smiles = rep(NA, length(toxdata_json)))
# Fill the tibble
for (i in seq(1:length(toxdata_json))) {
	toxdata[i, 1] <- toxdata_json[[i]]['cid']
	toxdata[i, 2] <- toxdata_json[[i]]['cmpdname']
	toxdata[i, 3] <- toxdata_json[[i]]['smiles']
}

# Export the results
write_tsv(toxdata, ".../data/acutetox_cmpnds.tsv")

# Basically, the results are the list of CIDs (compounds' IDs) for which there are the data on acute toxicity.