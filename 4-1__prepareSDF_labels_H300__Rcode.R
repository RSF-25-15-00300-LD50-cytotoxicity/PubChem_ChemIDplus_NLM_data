library(tidyverse)

# Prepare the SDF suitable for building the qualitative SAR models using the data obtained from PubChem and
# GHS Health codes FROM https://unece.org/sites/default/files/2023-07/GHS%20Rev10e.pdf and
# https://pubchem.ncbi.nlm.nih.gov/classification/#hid=72
# NB, this dataset is multilabel

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
data_raw <- read_tsv(".../data/h300_cid.tsv") |>
					mutate(cid = as.character(cid)) |>
					select(-hnid) |>
					separate_wider_delim(warning, delim = ": ", names = c("code", "label")) |>
					inner_join(mna_cids, by = c("cid" = "all_cid")) |>
					select(mna_cid, code, label)

# Summary
code_sum 	<- data_raw |> group_by(code) |> summarize(n = n())
label_sum 	<- data_raw |> group_by(label) |> summarize(n = n())

# Prepare the data
data <- data_raw |> group_by(mna_cid) |>
								mutate(code = str_c(code, collapse = "\r\n")) |>
								mutate(label = str_c(label, collapse = "\r\n")) |>
								slice_head(n = 1) |>
								ungroup()

# Add mols
sdf_proc <- sdf_raw |> inner_join(data)

# Prepare SDF
sdf <- sdf_proc |> mutate(id_rec = "\r\n>  <CID>\r\n", allid_rec = "\r\n\r\n>  <CID_all>\r\n",
							ghscode_rec = "\r\n\r\n>  <GHS code>\r\n", ghslabel_rec = "\r\n\r\n>  <GHS label>\r\n",
							end_rec = "\r\n\r\n$$$$") |>
					select(mol, id_rec, mna_cid, allid_rec, all_cid, ghscode_rec, code, ghslabel_rec, label,
							 end_rec) |>
							 unite("record", mol:end_rec, sep = "")

# Export SDFs
write_lines(str_c("", sdf[[1]]), ".../data/sdfs/labels_PC_CIDP_NLM__ghs.SDF")