
setwd("C:\\Users\\njcy8\\Downloads")

library(tidyverse)

df_lifts <- read_csv("artSigLift.csv") %>%
  rename("Article"="article_a")
df_basketSize <- read_csv("artBasketSize.csv")

df <- df_basketSize %>% 
  inner_join(df_lifts)

# plot(df$articleAvBasketSize_v_avBasketSize, df$mean_sig_lift,
#      main="article: significant item association lift ~ relative av Basket Size"
#      , ylab= "% significant lift (>2 or <0.5)"
#      , xlab = "mean basket size (given article) / mean basket size (all articles)")
# grid()


## Before basket sizes are controlled for.
gg01 <- ggplot(df, aes(x=articleAvBasketSize_v_avBasketSize, y=mean_sig_lift)) +
  geom_point(alpha=0.03) +
  labs(title="article: significant item association lift ~ relative av Basket Size",
       subtitle="Before average basket sizes are controlled for."
       , y= "% significant lift (>2 or <0.5)"
       , x = "mean basket size (given article) / mean basket size (all articles)")
gg01
ggsave("gg01.png")

##### Basket size SQL
# create temp table allDat as (
#   SELECT distinct a.article, a.BasketKey
#   
#   FROM
#   
#   `gcp-wow-ent-im-tbl-prod.adp_dm_basket_sales_view.pos_item_line_detail` a,
#   `gcp-wow-ent-im-tbl-prod.adp_dm_masterdata_view.dim_article_hierarchy_v` b
#   
#   WHERE
#   a.BasketKey in (
#     select distinct BasketKey
#     from `gcp-wow-ent-im-tbl-prod.adp_dm_basket_sales_view.pos_item_line_detail`
#     where --rand() < 0.000000001 and
#     salesorg = '1005'  
#     and businessdate >= '2019-01-01'
#     and businessdate <= '2019-12-30'  
#     and itemvoidflag is null
#     and ItemTXNType in  ('S201') #,'S202') --S201 sales, S202 returns.
#     order by rand()
#     --limit 10000000
#   ) and
#   a.salesorg = '1005'  
#   and ltrim(a.article,'0') = ltrim(b.article,'0')
#   and b.salesorg = '1005'
#   and b. Department not in ('W100','W120')
#   and businessdate >= '2019-01-01'
#   and businessdate <= '2019-12-30'  
#   and itemvoidflag is null
#   and ItemTXNType in  ('S201') #,'S202') --S201 sales, S202 returns.
#   
#   ORDER BY a.BasketKey, a.article
# );
# 
# create temp table temp_basketSize as (
#   select BasketKey, count(*) as basketSize
#   from allDat
#   group by BasketKey
# );
# 
# create temp table overall_avBasketSize as (
#   select avg(basketSize) as av_basketSizeAllBaskets
#   from temp_basketSize
# );
# 
# create temp table countbasketsWithArticle as (
#   select Article, count(distinct BasketKey) as cnt_baskets_with_article
#   from allDat
#   group by Article
# );
# 
# create temp table artAvBasketSize as (
#   with abc as (
#     select a.Article, b.basketSize
#     from allDat a
#     left join temp_basketSize b on (a.BasketKey=b.BasketKey)
#   )
#   select Article, avg(basketSize) as av_basketSize
#   , STDDEV(basketSize) as stddev_basketSize
#   from abc
#   group by Article
# );
# 
# create temp table artBasketSize_fnlSummary as (
#   select a.*, b.av_basketSize, d.av_basketSizeAllBaskets, b.stddev_basketSize,
#   b.av_basketSize/d.av_basketSizeAllBaskets as articleAvBasketSize_v_avBasketSize
#   from countbasketsWithArticle a 
#   left join
#   artAvBasketSize b on (a.Article = b.Article),
#   overall_avBasketSize d
#   where cnt_baskets_with_article > 10000
#   order by av_basketSize desc
# );
# 
# 


####### Item association SQL
##
# create temp table allDat as (
#   with dat as (
#     SELECT a.BasketKey,
#     a.article
#     
#     FROM
#     
#     `gcp-wow-ent-im-tbl-prod.adp_dm_basket_sales_view.pos_item_line_detail` a,
#     `gcp-wow-ent-im-tbl-prod.adp_dm_masterdata_view.dim_article_hierarchy_v` b
#     
#     WHERE
#     a.BasketKey in (
#       select distinct BasketKey
#       from `gcp-wow-ent-im-tbl-prod.adp_dm_basket_sales_view.pos_item_line_detail`
#       where --rand() < 0.000000001 and
#       salesorg = '1005'  
#       and businessdate >= '2019-01-01'
#       and businessdate <= '2019-12-30'  
#       and itemvoidflag is null
#       and ItemTXNType in  ('S201') #,'S202') --S201 sales, S202 returns.
#       order by rand()
#       --limit 10000000
#     ) and
#     a.salesorg = '1005'  
#     and ltrim(a.article,'0') = ltrim(b.article,'0')
#     and b.salesorg = '1005'
#     and b. Department not in ('W100','W120')
#     and businessdate >= '2019-01-01'
#     and businessdate <= '2019-12-30'  
#     and itemvoidflag is null
#     and ItemTXNType in  ('S201') #,'S202') --S201 sales, S202 returns.
#     ORDER BY a.BasketKey,
#     a.article
#   )
#   select d.*,
#   b.cnt_baskets as cnt_baskets,
#   1/b.cnt_baskets as perc_weighting
#   
#   from dat d,
#   (
#     select
#     count(distinct BasketKey) as cnt_baskets
#     from dat
#   ) b
# );
# 
# create temp table articlePriorProb as (
#   select article,
#   sum(perc_weighting) as prob_article_in_basket
#   from allDat
#   group by article
# );
# 
# create temp table cntAllBaskets as (
#   select count(distinct BasketKey) as cnt_distinct_baskets
#   from allDat
# );
# 
# create temp table cnt_articlePair as (
#   select a.article as article_a,
#   b.article as article_b,
#   count(distinct a.BasketKey) as cnt_pair
#   from allDat a,
#   allDat b
#   where a.BasketKey = b.BasketKey
#   and a.article != b.article
#   group by a.article, b.article
# );
# 
# create temp table cnt_articleBaskets as (
#   select a.article as article,
#   count(*) as cnt_basketsWithItemInIt
#   from allDat a
#   group by a.article
# );
# 
# create temp table itemAssociationSummary000 as (
#   select a.*,
#   b.cnt_basketsWithItemInIt as cnt_basketsWithArticleAInIt,
#   c.cnt_basketsWithItemInIt as cnt_basketsWithArticleBInIt,
#   zz.cnt_distinct_baskets as cnt_allBasketsInData
#   
#   from cnt_articlePair a,
#   cntAllBaskets zz left join
#   cnt_articleBaskets b on (a.article_a=b.article) left join
#   cnt_articleBaskets c on (a.article_b=c.article)
# );
# 
# 
# CREATE OR REPLACE TABLE `gcp-wow-finance-de-lab-dev.inflation.itemAssociationSummary001` as (
#   with dat as (
#     select b.ArticleDescription as Article_a_description, c.ArticleDescription as Article_b_description, a.*,
#     a.cnt_basketsWithArticleAInIt/a.cnt_allBasketsInData as support_a,
#     a.cnt_basketsWithArticleBInIt/a.cnt_allBasketsInData as support_b,
#     a.cnt_pair/a.cnt_allBasketsInData as support_ab
#     from itemAssociationSummary000 a left join
#     `gcp-wow-ent-im-tbl-prod.adp_dm_masterdata_view.dim_article_v` b on (a.Article_a=b.Article) left join
#     `gcp-wow-ent-im-tbl-prod.adp_dm_masterdata_view.dim_article_v` c on (a.Article_b=c.Article)
#     where a.Article_a < a.Article_b -- we don't need article a,b and also article b,a in the data
# )
# select *,
# --support_ab/support_a as confidence,
# support_ab/(support_a*support_b) as lift
# from dat
# );


#### SQL to generate csv's used in this script:
# artSigLift.csv:
# SELECT article_a, avg(case when lift > 2 or lift < 0.5 then 1 else 0 end) as mean_sig_lift,
# avg(case when lift > 2 then 1 else 0 end) as mean_sig_liftgt2,
# avg(case when lift < 0.5 then 1 else 0 end) as mean_sig_liftltHalf
# FROM `gcp-wow-finance-de-lab-dev.inflation.itemAssociationSummary001`
# group by article_a
# 
# artBasketSize.csv (within the temp table generation sql above):
# select * from artBasketSize_fnlSummary
