library(tidyverse)

# Select random subset of 1000 cmpnds to assess chemical diversity

# Input CS with GHS labels
sdf__ghs_labels <- read_file(".../data/sdfs/labels_PC_CIDP_NLM__ghs.SDF") |>
								str_trim() |>
								as_tibble() |>
								separate_longer_delim(value, delim = "$$$$") |>
								mutate(value = str_trim(value)) |>
								filter(value != "") |>
								slice_sample(n = 1000) |>
								mutate(end_rec = "\r\n\r\n$$$$") |>
								unite("record", value:end_rec, sep = "")
# Input CS with GHS classes
sdf__ghs_classes <- read_file(".../data/sdfs/classes_PC_CIDP_NLM__oralRoute.SDF") |>
								str_trim() |>
								as_tibble() |>
								separate_longer_delim(value, delim = "$$$$") |>
								mutate(value = str_trim(value)) |>
								filter(value != "") |>
								slice_sample(n = 1000) |>
								mutate(end_rec = "\r\n\r\n$$$$") |>
								unite("record", value:end_rec, sep = "")
# Input CS with rat oral values
sdf__ghs_values <- read_file(".../data/sdfs/classes_PC_CIDP_NLM__oralRoute.SDF") |>
								str_trim() |>
								as_tibble() |>
								separate_longer_delim(value, delim = "$$$$") |>
								mutate(value = str_trim(value)) |>
								filter(value != "") |>
								slice_sample(n = 1000) |>
								mutate(end_rec = "\r\n\r\n$$$$") |>
								unite("record", value:end_rec, sep = "")


# Export SDFs
write_lines(str_c("", sdf__ghs_labels[[1]]), ".../data/sdfs_rand/ghs_labels__rand1000.SDF")
write_lines(str_c("", sdf__ghs_classes[[1]]), ".../data/sdfs_rand/ghs_classes__rand1000.SDF")
write_lines(str_c("", sdf__ghs_values[[1]]), ".../data/sdfs_rand/ghs_values__rand1000.SDF")