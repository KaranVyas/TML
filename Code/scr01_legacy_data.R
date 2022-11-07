
# RDKit fingerprints into legacy directory

# make directory structure

proj_name = "1911TML"
path_proj = paste0("/home/shared/", proj_name, "/")

path_legacy_data = paste0(path_proj, "legacy/")
dir.create(path_legacy_data, recursive = T)

# put data id file in the legacy directory
file.copy(from = "~/work/rQSAR/tmpdata/full_data_ids.rds",
          to = paste0(path_legacy_data))

# ... and the RDKit fingerprint table...
file.copy(from = "~/work/rQSAR/tmpdata/fingp_tbl_170510.rda",
          to = paste0(path_legacy_data))


# dataset info
file.copy(from = "/home/shared/1909TML/datasets_info.csv",
          to = path_proj)

dset_info = read_csv(paste0(path_proj, "datasets_info.csv"))
targ_ids = read_rds(paste0(path_legacy_data, "full_data_ids.rds")) %>%
  distinct(target_id, .keep_all = T) %>%
  select(target_id, dataset_id) %>%
  rename(dataset_id_rdkit = dataset_id)

dset_info = targ_ids %>% inner_join(dset_info)
head(dset_info)

write_csv(dset_info, paste0(path_proj, "datasets_info.csv"))
