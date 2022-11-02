
library(tidyverse)

fnames = list.files("/home/shared/1911TML/datasets/transformed/RF/")
names(fnames) = str_remove_all(fnames, "data_|.csv")

full_data = map_dfr(fnames, ~ read_csv(paste0("/home/shared/1911TML/datasets/transformed/RF/", .x), col_types = cols(
  .default = col_double(),
  target_id = col_character(),
  molecule_id = col_character()
)), .id = "dataset")

names(full_data)[c(1:5,2092:2098)]

full_data %>% select(1:8) %>% head()
full_data = full_data %>% arrange(molecule_id)

full_data = full_data %>% distinct(molecule_id, .keep_all = T)
write_csv(full_data, "/home/shared/1911TML/outputs/2007_molecule_prediction_profiles.csv")

library(readxl)
sel_mol = read_excel("for_ivan.xlsx", col_names = FALSE)
sel_mol = sel_mol %>% select(c(3,4))
names(sel_mol) = c("molecule_id", "name")

pred_profiles = sel_mol %>% inner_join(full_data)
write_csv(pred_profiles, "/home/shared/1911TML/outputs/200708_pred_profiles.csv")

top_data = full_data %>% select(-c(dataset, pXC50, target_id)) %>%
  pivot_longer(-molecule_id, names_to = "target_id", values_to = "pred_act")

top_data = top_data %>% group_by(target_id) %>%
  arrange(desc(pred_act), .by_group = T)

write_rds(top_data, "/home/shared/1911TML/outputs/2007_molecules_top.rds")
rm(full_data)

# 10% 384123 = 38412
top_10 = top_data %>% slice(1:38412)
top_10 = top_10 %>% filter(molecule_id %in% sel_mol$molecule_id)

# 1% 384123 = 3841
top_1 = top_data %>% slice(1:3841)
top_1 = top_1 %>% filter(molecule_id %in% sel_mol$molecule_id)

# 0.1% 384123 = 384
top_01 = top_data %>% slice(1:384)
top_01 = top_01 %>% filter(molecule_id %in% sel_mol$molecule_id)

targ_info = read_csv("/home/shared/1911TML/datasets_info.csv")

targ_info %>% select(target_id, pref_name, organism) %>%
  inner_join(top_10) %>% 
  arrange(molecule_id, desc(pred_act)) %>% write_csv("/home/shared/1911TML/outputs/200708_top10.csv")

targ_info %>% select(target_id, pref_name, organism) %>%
  inner_join(top_1) %>% 
  arrange(molecule_id, desc(pred_act)) %>% write_csv("/home/shared/1911TML/outputs/200708_top1.csv")

targ_info %>% select(target_id, pref_name, organism) %>%
  inner_join(top_01) %>% 
  arrange(molecule_id, desc(pred_act)) %>% write_csv("/home/shared/1911TML/outputs/200708_top01.csv")


#### Other compounds
full_data = read_csv("/home/shared/1911TML/outputs/2007_molecule_prediction_profiles.csv")

compounds = c("Solifenacin", "oxybutynin chloride")
names(compounds) = c("CHEMBL1734","CHEMBL1133")
sel_mol = tibble(molecule_id = names(compounds),
                 name = compounds)

# Now go to line 26: pred_profiles = sel_mol %>% inner_join(full_data) and run from them.
pred_profiles = sel_mol %>% inner_join(full_data)
write_csv(pred_profiles, "/home/shared/1911TML/outputs/200709_pred_profiles.csv")

top_data = read_rds("/home/shared/1911TML/outputs/2007_molecules_top.rds")

# 10% 384123 = 38412
top_10 = top_data %>% slice(1:38412)
top_10 = top_10 %>% filter(molecule_id %in% sel_mol$molecule_id)

# 1% 384123 = 3841
top_1 = top_data %>% slice(1:3841)
top_1 = top_1 %>% filter(molecule_id %in% sel_mol$molecule_id)

# 0.1% 384123 = 384
top_01 = top_data %>% slice(1:384)
top_01 = top_01 %>% filter(molecule_id %in% sel_mol$molecule_id)

targ_info = read_csv("/home/shared/1911TML/datasets_info.csv")

targ_info %>% select(target_id, pref_name, organism) %>%
  inner_join(top_10) %>% 
  arrange(molecule_id, desc(pred_act)) %>% write_csv("/home/shared/1911TML/outputs/200709_top10.csv")

targ_info %>% select(target_id, pref_name, organism) %>%
  inner_join(top_1) %>% 
  arrange(molecule_id, desc(pred_act)) %>% write_csv("/home/shared/1911TML/outputs/200709_top1.csv")

targ_info %>% select(target_id, pref_name, organism) %>%
  inner_join(top_01) %>% 
  arrange(molecule_id, desc(pred_act)) %>% write_csv("/home/shared/1911TML/outputs/200709_top01.csv")

