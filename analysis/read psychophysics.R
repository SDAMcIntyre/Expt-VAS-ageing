library(readr)
library(dplyr)
library(readxl)
library(stringr)

pleasant1 <- read_delim('BStim2_19-Dec-2019_124003_61.txt', delim = '\t', skip = 1, n_max = 20,
           col_names = c('Trial', 'Speed.cm.per.sec', 'VAS.0.to.10'),
           col_types = 'i--c---------c' ) %>% 
  mutate(PID = 'O_01',
         Speed.cm.per.sec = Speed.cm.per.sec %>% parse_double(),
         VAS.n10.to.p10 = VAS.0.to.10 %>% 
           parse_double() %>% 
           scales::rescale(., to = c(-10,10), from = c(0,10))
         ) %>% 
  filter(VAS.n10.to.p10 != 0.0) %>% 
  select(-VAS.0.to.10)


pleasant2 <- read_delim('BStim2_20-Dec-2019_094540_56.txt', delim = '\t', skip = 1, n_max = 20,
                        col_names = c('Trial', 'Speed.cm.per.sec', 'VAS.0.to.10'),
                        col_types = 'i--c---------c' ) %>% 
  mutate(PID = 'O_02',
         Speed.cm.per.sec = Speed.cm.per.sec %>% parse_double(),
         VAS.n10.to.p10 = VAS.0.to.10 %>% 
           parse_double() %>% 
           scales::rescale(., to = c(-10,10), from = c(0,10))
  ) %>% 
  filter(VAS.n10.to.p10 != 0.0) %>% 
  select(-VAS.0.to.10)

pleasant.older <- bind_rows(pleasant1, pleasant2) %>% 
  mutate(Age = 'Older')

pleasant.younger <- read_excel('Copy of whole_raw_data_ALL.xlsx', sheet = 2, range = 'A2:H3202') %>% 
  filter(location == 'leg' & brush_type == 'soft' & response_type == 'pleasant') %>% 
  select(-c(location, brush_type, response_type, block)) %>% 
  rename('Speed.cm.per.sec' = `speed (cm/s)`,
         'VAS.n10.to.p10' = `VAS (0 - 10)`,
         'PID' = SID,
         'Trial' = trial) %>% 
  filter(VAS.n10.to.p10 != 0.0) %>% 
  mutate(Age = 'Younger',
         PID = str_replace(PID, 'S', 'Y_'))

pleasant <- bind_rows(pleasant.older, pleasant.younger)

write_delim(pleasant, 'pleasant_all_raw_data.txt', delim = '\t')
