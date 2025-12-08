library(tidyverse)

# Prepare the SDF suitable for building the qualitative SAR models using the data obtained from PubChem and
# Acute Toxicity Estimate Values FROM https://unece.org/sites/default/files/2023-07/GHS%20Rev10e.pdf

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
type_sum 	<- data_raw |> group_by(testtype) |> summarize(n = n())
unit_sum 	<- data_raw |> group_by(units) |> summarize(n = n())
org_sum  	<- data_raw  |> group_by(organism) |> summarize(n = n())
route_sum	<- data_raw  |> group_by(route) |> summarize(n = n())

# Prepare the data
data_preproc <- data_raw |> filter(units == "mg/kg") |>
					filter( organism %in% c('mouse', 'rat', 'rabbit', 'guinea pig', 'cat', 'dog', 'pig', 'monkey' )) |>
					filter(str_starts(dose, "[0-9]") & testtype == "LD50") |>
					mutate(dose = as.numeric(str_replace(dose, " .*", ""))) |>
					group_by(mna_cid, organism, route) |>
					mutate(dose = mean(dose)) |>
					mutate(reference = str_c(reference, collapse = " | ")) |>
					slice_head(n = 1) |>
					ungroup()

# Compute labels
data <- data_preproc |> filter(route == "oral") |>
						mutate(class = case_when(
							dose <= 5 ~ as.integer(1),
							dose <= 50 ~ as.integer(2),
							dose <= 300 ~ as.integer(3),
							dose <= 2000 ~ as.integer(4),
							dose <= 5000 ~ as.integer(5),
  							.default = NA_integer_
						)) |>
						filter(!is.na(class)) |>
						rowwise() |>
						mutate(class_organism = str_c(c(class, " using ", organism), collapse = "")) |>
						ungroup() |>
						group_by(mna_cid) |>
						mutate(overall_class = min(class),
								class_organism = str_c(class_organism, collapse = "\r\n"),
								reference = str_c(reference, collapse = "\r\n")) |>
						slice_head(n=1) |>
						ungroup() |>
						select(mna_cid, testtype, route, units, class_organism, overall_class, reference)


# Add mols
sdf_proc <- sdf_raw |> inner_join(data)

# Prepare SDF
sdf <- sdf_proc |> mutate(id_rec = "\r\n>  <CID>\r\n", allid_rec = "\r\n\r\n>  <CID_all>\r\n",
							overall_rec = "\r\n\r\n>  <GHS class, min>\r\n", organism_rec = "\r\n\r\n>  <GHS class by organism>\r\n",
							ref_rec = "\r\n\r\n>  <reference>\r\n",
							end_rec = "\r\n\r\n$$$$") |>
					select(mol, id_rec, mna_cid, allid_rec, all_cid, overall_rec, overall_class, organism_rec, class_organism,
							 ref_rec, reference, end_rec) |>
							 unite("record", mol:end_rec, sep = "")

# Export SDFs
write_lines(str_c("", sdf[[1]]), ".../data/sdfs/classes_PC_CIDP_NLM__oralRoute.SDF")