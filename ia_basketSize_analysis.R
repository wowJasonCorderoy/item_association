
setwd("C:\\Users\\njcy8\\Downloads")
library(tidyverse)

# 
# with dat as (
#   SELECT round(av_basket_size_pair/article_b_avg_basket_size,1) as rel_basketSize,
#   count(*) as n,
# 
#   avg(case when lift >= 2 then 1 else 0 end) as sig_assoc,
#   avg(case when basketSize_adjusted_lift > 2 then 1 else 0 end) as sig_basketSize_adjusted_assoc,
# 
#   avg(case when lift <= 0.5 then 1 else 0 end) as sig_disassoc,
#   avg(case when basketSize_adjusted_lift <= 0.5 then 1 else 0 end) as sig_basketSize_adjusted_disassoc,
# 
#   avg(case when lift > 0.5 and lift <2 then 1 else 0 end) as sig_noAssoc,
#   avg(case when basketSize_adjusted_lift > 0.5 and basketSize_adjusted_lift < 2 then 1 else 0 end) as sig_basketSize_adjusted_noAssoc
# 
#   FROM `gcp-wow-finance-de-lab-dev.inflation.itemAssociationSummary001`
#   where cnt_pair > 1000
#   group by round(av_basket_size_pair/article_b_avg_basket_size,1)
# )
# select *
#   from dat
# where rel_basketSize > 0 and
# n > 100
# order by rel_basketSize


dat <- read_csv("results-20210212-143900.csv")

## adjust numbers for all possible combinations:
# with dat as (
#   select distinct article_a as art
#   FROM `gcp-wow-finance-de-lab-dev.inflation.itemAssociationSummary001`
#   union all 
#   select distinct article_b as art
#   FROM `gcp-wow-finance-de-lab-dev.inflation.itemAssociationSummary001`
# )
# select distinct art
# from dat

# 77,855 unique articles = 77855*77854/2 combinations (order doesn't matter) = 12,122,646,340 combinations

allCombos <- 12122646340

# adjust percentages to account for all combinations.
dat2 <- dat %>% 
  dplyr::mutate(sig_assoc=sig_assoc*n/(allCombos),
                sig_basketSize_adjusted_assoc=sig_basketSize_adjusted_assoc*n/(allCombos),
                sig_disassoc=sig_disassoc*n/(allCombos),
                sig_basketSize_adjusted_disassoc=sig_basketSize_adjusted_disassoc*n/(allCombos),
                sig_noAssoc=1-sig_assoc-sig_disassoc,
                sig_basketSize_adjusted_noAssoc=1-sig_basketSize_adjusted_assoc-sig_basketSize_adjusted_disassoc,
                n=n+allCombos)

head(dat2)

colors <- c("pre" = "black", "post" = "red")

# plot dat if you only want to include pairs in data. use dat2 to use all possible combinations.
plotDat <- dat2 #dat

ggplot(plotDat, aes(x=rel_basketSize)) +
  geom_point(aes(y=sig_assoc , colour="pre")) +
  geom_point(aes(y=sig_basketSize_adjusted_assoc, colour="post")) +
  geom_vline(xintercept=1) +
  labs(title="% strong associations ~ relative pair basket size",
       x="Av. pairs basket size / av. article B basket size",
       y="% associations >= 2 lift") +
  scale_colour_manual(values = colors) +
  scale_y_continuous(labels=scales::percent)

ggplot(plotDat, aes(x=rel_basketSize)) +
  geom_point(aes(y=sig_disassoc , colour="pre")) +
  geom_point(aes(y=sig_basketSize_adjusted_disassoc, colour="post")) +
  geom_vline(xintercept=1) +
  labs(title="% weak associations ~ relative pair basket size",
       x="Av. pairs basket size / av. article B basket size",
       y="% associations <= 0.5 lift") +
  scale_colour_manual(values = colors) +
  scale_y_continuous(labels=scales::percent)

ggplot(plotDat, aes(x=rel_basketSize)) +
  geom_point(aes(y=sig_noAssoc , colour="pre")) +
  geom_point(aes(y=sig_basketSize_adjusted_noAssoc, colour="post")) +
  geom_vline(xintercept=1) +
  labs(title="% insignificant associations ~ relative pair basket size",
       x="Av. pairs basket size / av. article B basket size",
       y="% associations 0.5<lift<2 lift") +
  scale_colour_manual(values = colors) +
  scale_y_continuous(labels=scales::percent)

# significantly over or under pre
ggplot(plotDat, aes(x=rel_basketSize)) +
  geom_point(aes(y=sig_assoc+sig_disassoc)) +
  geom_vline(xintercept=1) +
  scale_y_continuous(labels=scales::percent)

ggplot(plotDat, aes(x=rel_basketSize)) +
  geom_point(aes(y=sig_basketSize_adjusted_assoc+sig_basketSize_adjusted_disassoc)) +
  geom_vline(xintercept=1) +
  scale_y_continuous(labels=scales::percent)
