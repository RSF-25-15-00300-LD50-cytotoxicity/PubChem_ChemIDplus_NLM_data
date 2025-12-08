library(tidyverse)

# Prepare the SDF containing the data needed to build a QSAR models
# Chemical structures in the MOL format were obtained using the actions describe in step 1.

# Input
# Compounds
sdf_raw <- read_file(".../data/PubChem_compound_cache_rukLgqoMz7D4nkeHxf8OoA5QnDBosCu-UZsw8kqKIvNKkx4_records_SD.SDF") |>
				#str_replace_all("\n", "\r\n") |>
				str_trim() |>
				as_tibble() |>
				separate_longer_delim(value, delim = "$$$$") |>
				mutate(value = str_trim(value)) |>
				filter(value != "") |>
				separate_wider_delim(value, delim = "\r\n> <PUBCHEM_COMPOUND_CID>", names=c("mol", "data"), too_few = "align_start") |>
				separate_wider_delim(data, delim = "\r\n> <PUBCHEM_COMPOUND_CANONICALIZED>", names=c("id", "data"), too_few = "align_start") |>
				separate_wider_delim(data, delim = "\r\n>  <MNA_DESCRIPTORS>", names=c("data", "mna"), too_few = "align_start") |>
				mutate(mna_cid = str_trim(id), mna = str_trim(mna), mol = str_trim(mol)) |>
				select(-data) |>
				group_by(mna) |>
				mutate(all_cid = str_c(mna_cid, collapse = ", ")) |>
				slice_head(n = 1) |>
				ungroup()
# Prepare IDs
mna_cids <- sdf_raw |> select(mna_cid, all_cid) |>
					   separate_longer_delim(all_cid, ", ") |>
					   mutate(all_cid = str_trim(all_cid)) |>
					   distinct()
# Read the data
data_raw <- read_tsv(".../data/result_acutetox.tsv") |>
					mutate(cid = as.character(cid)) |>
					inner_join(mna_cids, by = c("cid" = "all_cid")) |>
					select(mna_cid, organism, testtype, route, dose, reference) |>
					rowwise() |>
					mutate(units = str_split(dose, " ")[[1]][2]) |>
					ungroup()

# Summary
type_sum <- data_raw |> group_by(testtype) |> summarize(n = n())
unit_sum <- data_raw |> group_by(units) |> summarize(n = n())
org_sum  <- data_raw  |> group_by(organism) |> summarize(n = n())

# Prepare the data
data <- data_raw |> filter(units == "mg/kg") |>
					filter( organism %in% c('mouse', 'rat', 'rabbit', 'guinea pig', 'cat', 'dog', 'pig', 'monkey' )) |>
					filter(str_starts(dose, "[0-9]") & testtype == "LD50") |>
					mutate(dose = as.numeric(str_replace(dose, " .*", ""))) |>
					group_by(mna_cid, organism, route) |>
					mutate(dose = mean(dose)) |>
					mutate(reference = str_c(reference, collapse = " | ")) |>
					slice_head(n = 1) |>
					ungroup()

# Add mols
sdf_proc <- sdf_raw |> inner_join(data)

# Prepare SDFs
sdfs <- sdf_proc |> mutate(id_rec = "\r\n>  <CID>\r\n", allid_rec = "\r\n\r\n>  <CID_all>\r\n",
							org_rec = "\r\n\r\n>  <organism>\r\n", route_rec = "\r\n\r\n>  <route>\r\n",
							dose_rec = "\r\n\r\n>  <dose, mg/kg>\r\n", ref_rec = "\r\n\r\n>  <reference>\r\n",
							end_rec = "\r\n\r\n$$$$") |>
					select(mol, id_rec, mna_cid, allid_rec, all_cid, org_rec, organism, route_rec, route,
						dose_rec, dose, ref_rec, reference, end_rec) |>
					group_by(organism, route) |>
					group_split()

for (i in seq(1:length(sdfs))) {
	org <- sdfs[[i]][1,7]
	route <- sdfs[[i]][1,9]
	sdf <- sdfs[[i]] |> unite("record", mol:end_rec, sep = "")
	# Export SDFs
	write_lines(str_c("", sdf[[1]]), str_glue(".../data/sdfs/PC_CIDP_NLM__{org}_{route}.SDF"))
}