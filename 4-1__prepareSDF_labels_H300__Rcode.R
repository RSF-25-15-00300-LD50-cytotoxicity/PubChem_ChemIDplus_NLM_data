library(tidyverse)

# Input
# Compounds
sdf_raw <- read_file("C:/.../data/PubChem_compound_cache_rukLgqoMz7D4nkeHxf8OoA5QnDBosCu-UZsw8kqKIvNKkx4_records_SD.SDF") |>
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
data_raw <- read_tsv("C:/.../data/h300_cid.tsv") |>
					mutate(cid = as.character(cid)) |>
					select(-hnid) |>
					separate_wider_delim(warning, delim = ": ", names = c("code", "label")) |>
					inner_join(mna_cids, by = c("cid" = "all_cid")) |>
					select(mna_cid, code, label)
# Read the list of codes having pictograms downloaded from: https://pubchem.ncbi.nlm.nih.gov/ghs/
# Only records having pictograms are considered
# Only GHS05, GHS06, GHS07, GHS08 are considered
pictogram <- read_tsv("C:/.../raw_data/GHS_picts.tsv") |>
					mutate(hazard_label_pict = case_when(
							Pictogram == "GHS05" ~ "corrosives",
							Pictogram == "GHS06" ~ "acute toxicity",
							Pictogram == "GHS07" ~ "irritant",
							Pictogram == "GHS08" ~ "health hazard"
						))

# Summary
code_sum 	<- data_raw |> group_by(code) |> summarize(n = n())
label_sum 	<- data_raw |> group_by(label) |> summarize(n = n())

## 11.02.26: Make sure that each code in combined label (like H303+H313+H333) is also included as a distinct label (like H303, H313, H333)
# Get labels' descriptions
label_descr <- data_raw |> select(code, label) |> distinct()
# Separate combined labels
data_separated <- data_raw |> select(-label) |> separate_longer_delim(code, delim = "+")
# Re-introduce combined labels
data_main <- bind_rows(data_separated, data_raw |> select(-label)) |> distinct() |> inner_join(label_descr)

## 11.02.26: Select only records having associated pictograms, list of pictograms is available at: https://pubchem.ncbi.nlm.nih.gov/ghs/
data_pict <- data_main |> inner_join(pictogram, by = c("code" = "H-Code")) |>
							select(mna_cid, hazard_label_pict) |>
							distinct()

# Prepare the data
# Codes and all
data <- data_main |> group_by(mna_cid) |>
						mutate(code = str_c(code, collapse = "\r\n")) |>
						mutate(label = str_c(label, collapse = "\r\n")) |>
						slice_head(n = 1) |>
						ungroup()
# Hazard labels according to pictograms
data_hlp <- data_pict |> group_by(mna_cid) |>
						mutate(hazard_label_pict = str_c(hazard_label_pict, collapse = "\r\n")) |>
						slice_head(n = 1) |>
						ungroup()

# Add mols
sdf_proc     <- sdf_raw |> inner_join(data)
sdf_proc_hlp <- sdf_raw |> inner_join(data_hlp)

## Prepare SDFs
# Codes and labels
sdf <- sdf_proc |> mutate(id_rec = "\r\n>  <CID>\r\n", allid_rec = "\r\n\r\n>  <CID_all>\r\n",
							ghscode_rec = "\r\n\r\n>  <GHS code>\r\n", ghslabel_rec = "\r\n\r\n>  <GHS label>\r\n",
							end_rec = "\r\n\r\n$$$$") |>
					select(mol, id_rec, mna_cid, allid_rec, all_cid, ghscode_rec, code, ghslabel_rec, label,
							 end_rec) |>
							 unite("record", mol:end_rec, sep = "")
# Hazard labels according to pictogram
sdf_hlp <- sdf_proc_hlp |> mutate(id_rec = "\r\n>  <CID>\r\n", allid_rec = "\r\n\r\n>  <CID_all>\r\n",
							hlp_rec = "\r\n\r\n>  <hazard label>\r\n", end_rec = "\r\n\r\n$$$$") |>
					select(mol, id_rec, mna_cid, allid_rec, all_cid, hlp_rec, hazard_label_pict, end_rec) |>
							 unite("record", mol:end_rec, sep = "")

## Export SDFs
write_lines(str_c("", sdf_hlp[[1]]), "C:/.../data/sdfs/hazard_labels_PC_CIDP_NLM__ghs.SDF")


