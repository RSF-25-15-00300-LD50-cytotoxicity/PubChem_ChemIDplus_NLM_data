library(tidyverse)

# Read the data
data <- read_file("C:/.../labels_PC_CIDP_NLM__ghs.SDF") |>
						str_trim() |>
						as_tibble() |>
						separate_longer_delim(value, delim = "$$$$") |>
						mutate(value = str_trim(value)) |>
						filter(value != "") |>
						mutate(cid = str_extract(value, regex(">  <CID>.*>  <CID_all>", dotall = TRUE)) |> str_replace(">  <CID>\r\n", "") |> str_replace("\r\n>  <CID_all>", "") |> str_trim()) |>
						mutate(ghs = str_extract(value, regex(">  <GHS code>.*>  <GHS label>", dotall = TRUE)) |> str_replace(">  <GHS code>\r\n", "") |> str_replace("\r\n>  <GHS label>", "")) |>
						select(cid, ghs) |>
						filter(str_detect(ghs, fixed("+"))) |>
						separate_longer_delim(ghs, delim = "\r\n") |>
						mutate(ghs = str_trim(ghs)) |>
						filter(ghs != "")

# Divide the data
data_distinct 	<- data |> filter(!str_detect(ghs, fixed("+"))) |>
							mutate(ghs = str_trim(ghs)) |>
							distinct() |>
							rename(ghs_d = ghs)
data_composite  <- data |> filter(str_detect(ghs, fixed("+"))) |>
							separate_longer_delim(ghs, delim = "+") |>
							mutate(ghs = str_trim(ghs)) |>
							distinct() |>
							rename(ghs_c = ghs)

# Join the data
by_1 <- join_by(cid, ghs_c == ghs_d)
data_intersection_1 <- data_composite |> left_join(data_distinct, by_1)
by_2 <- join_by(cid, ghs_d == ghs_c)
data_intersection_2 <- data_distinct |> left_join(data_composite, keep = TRUE, by_2) |> select(ghs_c) |> filter(!is.na(ghs_c))

# Identify the cases, where data_distinct does not contain labels from data_composite
problematic_records <-  data_distinct |> right_join(data_composite, keep = TRUE, by_2) |> filter(is.na(cid.x)) |> rename(cid = cid.y) |> select(cid) |> distinct() |> inner_join(data)
problematic_cids    <- problematic_records |> pull(cid) |> unique()
problematic_cids