declare from_date DATE DEFAULT DATE("2019-01-01");
declare to_date DATE DEFAULT DATE('2019-12-31');

##
create temp table allDat as (
with dat as (
SELECT distinct a.BasketKey,
a.article

FROM

`gcp-wow-ent-im-tbl-prod.adp_dm_basket_sales_view.pos_item_line_detail` a,
`gcp-wow-ent-im-tbl-prod.adp_dm_masterdata_view.dim_article_hierarchy_v` b

WHERE
a.BasketKey in (
select distinct BasketKey
from `gcp-wow-ent-im-tbl-prod.adp_dm_basket_sales_view.pos_item_line_detail`
where --rand() < 0.000000001 and
salesorg = '1005'  
and businessdate >= from_date
and businessdate <= to_date 
and itemvoidflag is null
and ItemTXNType in  ('S201') #,'S202') --S201 sales, S202 returns.
order by rand()
--limit 10000000
) and
a.salesorg = '1005'  
and ltrim(a.article,'0') = ltrim(b.article,'0')
and b.salesorg = '1005'
and b. Department not in ('W100','W120')
and businessdate >= from_date
and businessdate <= to_date  
and itemvoidflag is null
and ItemTXNType in  ('S201') #,'S202') --S201 sales, S202 returns.
ORDER BY a.BasketKey,
a.article
)
select d.*,
b.cnt_baskets as cnt_baskets,
1/b.cnt_baskets as perc_weighting

from dat d,
(
select
count(distinct BasketKey) as cnt_baskets
from dat
) b
);

create temp table BasketKey_basketSize as (
select BasketKey,
count(distinct article) as basket_size
from allDat
group by BasketKey
);

-- create temp table article_avgSize as (
-- select article,
-- count(*)/count(distinct BasketKey) as article_avg_basket_size
-- from allDat
-- group by article
-- );

create temp table article_avgSize as (
with abc as (
select a.Article, b.basket_size
from allDat a
left join BasketKey_basketSize b on (a.BasketKey=b.BasketKey)
)
select Article, avg(basket_size) as article_avg_basket_size
--, STDDEV(basketSize) as stddev_basketSize
from abc
group by Article
);

create temp table articlePriorProb as (
select article,
sum(perc_weighting) as prob_article_in_basket
from allDat
group by article
);

create temp table cntAllBaskets as (
select count(distinct BasketKey) as cnt_distinct_baskets
from allDat
);

create temp table cnt_articlePair as (
select a.article as article_a,
b.article as article_b,
count(distinct a.BasketKey) as cnt_pair,
avg(c.basket_size) as av_basket_size_pair,
avg(d.article_avg_basket_size) as article_a_avg_basket_size,
avg(e.article_avg_basket_size) as article_b_avg_basket_size
from allDat a,
allDat b,
BasketKey_basketSize c,
article_avgSize d,
article_avgSize e
where a.BasketKey = b.BasketKey
and a.article != b.article
and a.BasketKey = c.BasketKey
and b.BasketKey = c.BasketKey
and a.article = d.article
and b.article = e.article
group by a.article, b.article
);

create temp table cnt_articleBaskets as (
select a.article as article,
count(*) as cnt_basketsWithItemInIt
from allDat a
group by a.article
);

create temp table itemAssociationSummary000 as (
select a.*,
b.cnt_basketsWithItemInIt as cnt_basketsWithArticleAInIt,
c.cnt_basketsWithItemInIt as cnt_basketsWithArticleBInIt,
zz.cnt_distinct_baskets as cnt_allBasketsInData

from cnt_articlePair a,
cntAllBaskets zz left join
cnt_articleBaskets b on (a.article_a=b.article) left join
cnt_articleBaskets c on (a.article_b=c.article)
);


--CREATE OR REPLACE TABLE `gcp-wow-finance-de-lab-dev.inflation.itemAssociationSummary001_test` as (
create temp table ia_ingredients as (
with dat as (
select b.ArticleDescription as Article_a_description, c.ArticleDescription as Article_b_description, a.*,
a.cnt_basketsWithArticleAInIt/a.cnt_allBasketsInData as support_a,
a.cnt_basketsWithArticleBInIt/a.cnt_allBasketsInData as support_b,
a.cnt_pair/a.cnt_allBasketsInData as support_ab
from itemAssociationSummary000 a left join
`gcp-wow-ent-im-tbl-prod.adp_dm_masterdata_view.dim_article_v` b on (a.Article_a=b.Article) left join
`gcp-wow-ent-im-tbl-prod.adp_dm_masterdata_view.dim_article_v` c on (a.Article_b=c.Article)
where a.Article_a < a.Article_b -- we don't need article a,b and also article b,a in the data
)
select *,
--support_ab/support_a as confidence,
support_ab/(support_a*support_b) as lift
from dat
);


CREATE OR REPLACE TABLE `gcp-wow-finance-de-lab-dev.inflation.itemAssociationSummary001` as (
with dat as (select *, 
av_basket_size_pair/article_b_avg_basket_size*support_b as basketSize_adjusted_support_b,
from ia_ingredients
)
select *,
support_ab/(support_a*basketSize_adjusted_support_b) as basketSize_adjusted_lift
from dat
);

