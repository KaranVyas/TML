rm(list = ls())

library(tidyverse)

fnames = list.files("/home/shared/1911TML/datasets/transformed/RF/")
names(fnames) = str_remove_all(fnames, "data_|.csv")

full_data = map_dfr(fnames, ~ read_csv(paste0("/home/shared/1911TML/datasets/transformed/RF/", .x), col_types = cols(
  .default = col_double(),
  target_id = col_character(),
  molecule_id = col_character()
)) %>% select(target_id, molecule_id, pXC50))
write_csv(full_data, "/home/shared/1911TML/outputs/2007_molecule_true_activities.csv")

library(readxl)
sel_mol = read_excel("for_ivan.xlsx", col_names = FALSE)
sel_mol = sel_mol %>% select(c(3,4))
names(sel_mol) = c("molecule_id", "name")

compounds = c("Solifenacin", "oxybutynin chloride")
names(compounds) = c("CHEMBL1734","CHEMBL1133")
sel_mol = sel_mol %>% bind_rows(tibble(molecule_id = names(compounds),
                 name = compounds))

targ_info = read_csv("/home/shared/1911TML/datasets_info.csv")

full_data = full_data %>% 
  inner_join(sel_mol) %>%
  inner_join(targ_info) %>%
  select(molecule_id, molecule_name = name, true_activity_pXC50 = pXC50, target_id, target_name = pref_name, organism )
full_data %>% arrange(molecule_id) %>%
  write_csv("/home/shared/1911TML/outputs/200709_true_activities.csv")
