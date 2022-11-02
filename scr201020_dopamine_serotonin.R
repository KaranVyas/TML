
library(RMariaDB)
library(tidyverse)

passwd_db = "xxxx" #"xxxx"
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
targets <- targets %>% filter(str_detect(pref_name, 'dopamine|serotonin'), target_type_id == 'SINGLE PROTEIN', n_compounds >30) %>%
  select(target_id, pref_name, organism, n_compounds) %>% collect()
targets %>% write_csv('201020/targets.csv')

all_filenames <- list.files('/home/shared/1911TML/predictions/base/split_data/RF/test', full.names = T)
pred_filenames_base <- targets %>% 
  pull(target_id) %>% paste0('/home/shared/1911TML/predictions/base/split_data/RF/test/preds_did_',.,'.csv')

names(pred_filenames_base) <- targets %>% pull(target_id)

top_10 <- read_csv('/home/shared/1911TML/outputs/201020_top10_long.csv')
top_10 <- top_10 %>% filter(target_id %in% targets$target_id)

comp_names <- read_csv('/home/shared/1911TML/qsar_drugs_top10_euclidean_eom_2_full.csv')

cluster_of_interest <- c('Relpax',
                         'Amerge',
                         'Imitrex',
                         'Zomig',
                         'Vespro',
                         'Cabaser',
                         'Parlodel',
                         'Lysuride',
                         'Vilazodone',
                         'Zelmac',
                         'MK-462',
                         'Vargatef',
                         'Tropisetron',
                         'AF-802')
                         
  
comp_names <- comp_names %>% filter(str_detect(label, paste0(cluster_of_interest, collapse = '|')))
comp_names <- comp_names %>% select(molecule_id = chembl_id, label)  
  
alt_names <- tibble(label = cluster_of_interest, 
                    altlabel = c('Eletriptan', 'Naratriptan', 'Sumatriptan', 'Zolmitriptan',
                                 'Melatonin', 'Cabergoline', 'Bromocriptine', 'Lisuride', 'Vilazodone',
                                 'Tegaserod', 'Rizatriptan', 'Nintedanib', 'Tropisetron', 'Alectinib')
                    )  
comp_names <- comp_names %>% inner_join(alt_names)

top_10 <- top_10 %>% inner_join(comp_names)
top_10 <- top_10 %>% inner_join(targets)
top_10 %>% head()
top_10 %>% arrange(molecule_id) %>% write_csv('/home/shared/1911TML/outputs/201020_cluster_top_right.csv')
