library(readr)
library(dplyr)
library(ggplot2)
library(svglite)
library(afex)
library(emmeans)
library(patchwork)
library(parallel)

pleasant <- read_delim('pleasant_all_raw_data.txt', delim = '\t')

pleasant.summary <- pleasant %>% 
  group_by(Age, PID, Speed.cm.per.sec) %>% 
  summarise(meanVAS = mean(VAS.n10.to.p10))

theme_set(theme_bw())

windows(8.3,8.8)


legend_border <- theme(legend.background = element_rect(colour = 'black'), legend.margin = margin(-1,5.5,1,5.5))

pleasant.summary %>%
  ggplot(aes(x = Speed.cm.per.sec, y = meanVAS)) +
  scale_color_brewer(palette = 'Set1') +
  geom_jitter(aes(colour = Age), width = 0.05, shape = 20, size = 5, alpha = 0.4) +
  stat_summary(data = filter(pleasant.summary, Age == 'Younger'),
               fun.y = 'mean', geom = 'point', shape = '_', size = 6) +
  stat_summary(data = filter(pleasant.summary, Age == 'Younger'),
               fun.y = 'mean', geom = 'line',  size = 0.8) +
  stat_summary(data = filter(pleasant.summary, Age == 'Younger'),
               fun.data = 'mean_cl_boot', geom = 'errorbar', 
               size = 0.8, width = 0.1) +
  scale_y_continuous(breaks = c(-10,0,10), labels = c('u','','p')) +
  coord_cartesian(ylim = c(-13,13)) +
  scale_x_log10() +
  theme(legend.position = c(0.85,0.16)) + legend_border +
  labs(x = 'Brush speed (cm/sec)',
       y = 'Mean pleasantness rating (VAS)',
       colour = NULL) -> plot.pleasant

# stats

pleasant.contrasts <- pleasant %>% 
  mutate(older2.vs.younger = case_when(PID == 'O_01' ~ 'exclude',
                                       PID == 'O_02' ~ 'Older P02',
                                       TRUE ~ 'Younger'),
         older1.vs.younger = case_when(PID == 'O_02' ~ 'exclude',
                                       PID == 'O_01' ~ 'Older P01',
                                       TRUE ~ 'Younger')) 
(nc <- detectCores()) # number of cores
cl <- makeCluster(rep("localhost", nc)) # make cluster

m1 <- pleasant.contrasts %>% 
  filter(older1.vs.younger != 'exclude') %>% 
  mixed(data = ., VAS.n10.to.p10 ~ older1.vs.younger * factor(Speed.cm.per.sec) + (1|PID), 
        cl = cl, method = 'PB', args_test = list(nsim = 1000, cl = cl))
anova(m1)

( emm1 <- emmeans(m1, ~ older1.vs.younger | factor(Speed.cm.per.sec)) )
pairs(emm1)
emmip(m1, older1.vs.younger ~ factor(Speed.cm.per.sec), CIs = TRUE, cov.reduce = range) +
  scale_color_brewer(palette = 'Set1') +
  scale_y_continuous(breaks = c(-10,0,10), labels = c('u','','p')) +
  coord_cartesian(ylim = c(-13,13)) +
  theme(legend.position = c(0.85,0.16)) + legend_border +
  labs(title = 'Older participant 1 vs all younger participants',
       x = 'Brush speed (cm/sec)',
       y = 'Mean pleasantness rating (VAS)',
       colour = NULL) -> plot.o1


m2 <- pleasant.contrasts %>% 
  filter(older2.vs.younger != 'exclude') %>% 
  mixed(data = ., VAS.n10.to.p10 ~ older2.vs.younger * factor(Speed.cm.per.sec) + (1|PID), 
        cl = cl, method = 'PB', args_test = list(nsim = 1000, cl = cl))
anova(m2)

(emm2 <- emmeans(m2, ~ older2.vs.younger | factor(Speed.cm.per.sec)))
pairs(emm2)
emmip(m2, older2.vs.younger ~ factor(Speed.cm.per.sec), CIs = TRUE, cov.reduce = range) +
  scale_color_brewer(palette = 'Set1') +
  scale_y_continuous(breaks = c(-10,0,10), labels = c('u','','p')) +
  coord_cartesian(ylim = c(-13,13)) +
  theme(legend.position = c(0.85,0.16)) + legend_border +
  annotate(geom = 'text', x = c(1,3:5), y = c(1.5,rep(-1.2,3)), label = '*', size = 10) +
  labs(title = 'Older participant 2 vs all younger participants',
       x = 'Brush speed (cm/sec)',
       y = 'Mean pleasantness rating (VAS)',
       colour = NULL) -> plot.o2

windows(8.3,4.0)

(plot.pleasant /plot.pleasant) | (plot.o1 / plot.o2)

ggsave('AT_pleasantness.svg')
