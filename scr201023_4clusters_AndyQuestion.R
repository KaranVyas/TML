
library(RMariaDB)
library(tidyverse)

passwd_db = "xxxxx" #"xxxx"
user_db = "xxxx" #"xxxx"
db_name = "metaqsar_db" #"xxxx"

conn = dbConnect(RMariaDB::MariaDB(),
                 user = user_db,
                 password = passwd_db,
                 dbname = db_name,
                 host = "127.0.0.1")

#' To list all the tables in the database
dbListTables(conn)

targets <- tbl(conn, "Targets")
targets %>% head()
targets <- targets %>% filter(target_type_id == 'SINGLE PROTEIN', n_compounds >=30) %>%
  select(target_id, pref_name, organism, n_compounds) %>% collect()
#targets %>% write_csv('201020/targets.csv')

all_filenames <- list.files('/home/shared/1911TML/predictions/base/split_data/RF/test', full.names = T)
pred_filenames_base <- targets %>% 
  pull(target_id) %>% paste0('/home/shared/1911TML/predictions/base/split_data/RF/test/preds_did_',.,'.csv')

names(pred_filenames_base) <- targets %>% pull(target_id)

top_10 <- read_csv('/home/shared/1911TML/outputs/201020_top10_long.csv')
top_10 <- top_10 %>% filter(target_id %in% targets$target_id)

comp_names <- read_csv('/home/shared/1911TML/qsar_drugs_top10_euclidean_eom_2_full.csv')

cluster_of_interest1 <- c('Vesprin', 'Nivoman')
cluster_of_interest2 <- c('Parsidol', 'Zipan-25', 'Prophenamine HCl')
cluster_of_interest3 <- c('Tranquazine', 'Promazine', 'Mequitazine')
cluster_of_interest4 <- c('Chloractil', 'Elmarin')

clusters <- tibble(cluster_new = c(1,1,2,2,2,3,3,3,4,4),
                   label = c(cluster_of_interest1, cluster_of_interest2,
                             cluster_of_interest3, cluster_of_interest4))


comp_names <- comp_names %>% inner_join(clusters) %>%
  select(molecule_id = chembl_id, label, cluster, cluster_new)  


top_10 <- top_10 %>% inner_join(comp_names)
top_10 <- top_10 %>% inner_join(targets)
top_10 %>% head()
top_10 %>% arrange(molecule_id) %>% write_csv('/home/shared/1911TML/outputs/201023_4clusters.csv')

top_10 %>% group_by(target_id) %>% summarise(n_clust = n()) %>% 
  filter(n_clust == 1) %>% inner_join(top_10) %>% select(-n_clust) %>% 
  arrange(cluster) %>% write_csv('/home/shared/1911TML/outputs/201023_4clusters_unique_targets.csv')
