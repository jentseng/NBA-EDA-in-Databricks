-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Exploratory Analysis
-- MAGIC We tested three hypotheses in our initial exploratory analysis.
-- MAGIC 
-- MAGIC **Note:** To conduct the analyses in this file, we uploaded the following csv's and used Databricks' UI to create tables from the csv's; the corresponding table names are also listed below. When creating the table, we checked **first row is header** and **infer schema**.
-- MAGIC - TeamGamesLogsDF16.csv --> gamelog16 
-- MAGIC - TeamGamesLogsDF17.csv --> gamelog17
-- MAGIC - TeamGamesLogsDF18.csv --> gamelog18
-- MAGIC - PlayerGameLog18.csv --> playergamelog18
-- MAGIC 
-- MAGIC ## 1. Hypothesis: Home teams win more games than Away teams

-- COMMAND ----------

-- Season 16-17 
SELECT A.TEAM_NAME,HOME_WINS,AWAY_WINS, (HOME_WINS- AWAY_WINS) as AddllHomeWins
FROM
   (SELECT TEAM_NAME, COUNT(WL) AS HOME_WINS
    FROM GAMELOG16
    WHERE WL = 'W' AND HOME_AWAY = 1
    GROUP BY TEAM_NAME)A,
   (SELECT TEAM_NAME, COUNT(WL) AS AWAY_WINS
    FROM GAMELOG16
    WHERE WL = 'W' AND HOME_AWAY = 0
    GROUP BY TEAM_NAME)B
WHERE A.TEAM_NAME = B.TEAM_NAME;

-- COMMAND ----------

-- Season 17-18 
SELECT A.TEAM_NAME,HOME_WINS,AWAY_WINS, (HOME_WINS- AWAY_WINS) as AddllHomeWins
FROM
   (SELECT TEAM_NAME, COUNT(WL) AS HOME_WINS
    FROM GAMELOG17
    WHERE WL = 'W' AND HOME_AWAY = 1
    GROUP BY TEAM_NAME)A,
   (SELECT TEAM_NAME, COUNT(WL) AS AWAY_WINS
    FROM GAMELOG17
    WHERE WL = 'W' AND HOME_AWAY = 0
    GROUP BY TEAM_NAME)B
WHERE A.TEAM_NAME = B.TEAM_NAME;

-- COMMAND ----------

-- Season 18-19
SELECT A.TEAM_NAME,HOME_WINS,AWAY_WINS, (HOME_WINS- AWAY_WINS) as AddllHomeWins
FROM
   (SELECT TEAM_NAME, COUNT(WL) AS HOME_WINS
    FROM GAMELOG18
    WHERE WL = 'W' AND HOME_AWAY = 1
    GROUP BY TEAM_NAME)A,
   (SELECT TEAM_NAME, COUNT(WL) AS AWAY_WINS
    FROM GAMELOG18
    WHERE WL = 'W' AND HOME_AWAY = 0
    GROUP BY TEAM_NAME)B
WHERE A.TEAM_NAME = B.TEAM_NAME;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Only two teams** won more away games vs. home games in each of the 2017-2018 and 2018-2019 seasons. No team did so in 2016-2017.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 2. Hypothesis: Teams that shoot better from the 3-point line win more games
-- MAGIC **Looking at all three seasons together**

-- COMMAND ----------

create or replace view allgamelogs as
  Select * from gamelog16
  union
  select * from gamelog17
  union
  select * from gamelog18


-- COMMAND ----------

Create or replace View NBAFieldGoalAnalysis as 
Select game_id_W, team_name_W, WL_W, FG2M_W,FG2A_W, FG_PCT_W, FG3M_W, FG3A_W, FG3_PCT_W, team_name_L, WL_L, FG2M_L, FG2A_L, FG_PCT_L,FG3M_L,FG3A_L, FG3_PCT_L from 
(Select game_id as game_id_W,team_name as team_name_W, WL as WL_W, (fgm-fg3m) as fg2m_W, (fga-fg3a) as fg2a_W, round(fg_pct,3) as fg_pct_W, fg3m as fg3m_W, fg3a as fg3a_W, round(fg3_pct,3) as fg3_pct_W
from allgamelogs
where WL = 'W') t1

LEFT JOIN

(Select game_id as game_id_L,team_name as team_name_L, WL as WL_L, (fgm-fg3m) as fg2m_L, (fga-fg3a) as fg2a_L, round(fg_pct,3) as fg_pct_L, fg3m as fg3m_L, fg3a as fg3a_L, round(fg3_pct,3) as fg3_pct_L
from allgamelogs
where WL = 'L') t2

on t1.game_id_W = t2.game_id_L;

-- COMMAND ----------

--# of Wins per team when they shoot 2-pointers better--
Create or replace View wins_better2 as 

Select team_Name_W as team_name, count(WL_W) as wins_better2 from nbafieldgoalanalysis
where FG_PCT_W > FG_PCT_L
and WL_W = 'W'
group by Team_Name_W
order by count(WL_W) desc;


-- COMMAND ----------

--# of Wins per team when they shoot 2-pointers worse--
Create or replace View wins_worse2 as 

Select team_Name_W as team_name_1, count(WL_W) as wins_worse2 from nbafieldgoalanalysis
where FG_PCT_W < FG_PCT_L
and WL_W = 'W'
group by Team_Name_W
order by count(WL_W) desc;

-- COMMAND ----------

--# of Wins per team when they shoot 3-pointers better--
Create or replace View wins_better3 as 

Select team_Name_W as team_name_2, count(WL_W) as wins_better3 from nbafieldgoalanalysis
where fg3_pct_w > fg3_pct_l
and WL_W = 'W'
group by Team_Name_W
order by count(WL_W) desc;

--# of Wins per team when they shoot 3-pointers worse--
Create or replace View wins_worse3 as 

Select team_Name_W as team_name_3, count(WL_W) as wins_worse3 from nbafieldgoalanalysis
where fg3_pct_w < fg3_pct_l
and WL_W = 'W'
group by Team_Name_W
order by count(WL_W) desc;

-- COMMAND ----------

--# of Losses per Team when they shoot 2 pointers better--
Create or replace View losses_better2 as 

Select team_Name_L as team_name_4, count(WL_L) as losses_better2 from nbafieldgoalanalysis
where fg_pct_w > fg_pct_l
and WL_L = 'L'
group by Team_Name_L
order by count(WL_L) desc;

-- COMMAND ----------

--# of Losses per Team when they shoot 2 pointers worse--
Create or replace View losses_worse2 as 

Select team_Name_L as team_name_5, count(WL_L) as losses_worse2 from nbafieldgoalanalysis
where fg_pct_w < fg_pct_l
and WL_L = 'L'
group by Team_Name_L
order by count(WL_L) desc;


-- COMMAND ----------

--# of Losses per Team when they shoot 3-pointers better--
Create or replace View losses_better3 as 

Select team_Name_L as team_name_6, count(WL_L) as losses_better3 from nbafieldgoalanalysis
where fg3_pct_w > fg3_pct_l
and WL_L = 'L'
group by Team_Name_L
order by count(WL_L) desc;

--# of Losses per Team when they shoot 3-pointers worse--
Create or replace View losses_worse3 as 

Select team_Name_L as team_name_7, count(WL_L) as losses_worse3 from nbafieldgoalanalysis
where fg3_pct_w < fg3_pct_l
and WL_L = 'L'
group by Team_Name_L
order by count(WL_L) desc;


-- COMMAND ----------

-- After creating all views, run the query:

Select team_name, wins_better2, wins_worse2, wins_better3, wins_worse3,losses_better2, losses_worse2, losses_better3, losses_worse3
from wins_better2 wb2 inner join wins_worse2 ww2 on wb2.team_name = ww2.team_name_1
full outer join wins_better3 wb3 on ww2.team_name_1 = wb3.team_name_2
left outer join wins_worse3 ww3 on wb3.team_name_2 = ww3.team_name_3
left outer join losses_better2 lb2 on ww3.team_name_3 = lb2.team_name_4
left outer join losses_worse2 lw2 on lb2.team_name_4 = lw2.team_name_5
left outer join losses_better3 lb3 on lw2.team_name_5 = lb3.team_name_6
left outer join losses_worse3 lw3 on lb3.team_name_6 = lw3.team_name_7;

-- COMMAND ----------

Create or Replace View FieldGoalAnalysis as

Select team_name, wins_better2, wins_worse2, wins_better3, wins_worse3,losses_better2, losses_worse2, losses_better3, losses_worse3
from wins_better2 wb2 inner join wins_worse2 ww2 on wb2.team_name = ww2.team_name_1
full outer join wins_better3 wb3 on ww2.team_name_1 = wb3.team_name_2
left outer join wins_worse3 ww3 on wb3.team_name_2 = ww3.team_name_3
left outer join losses_better2 lb2 on ww3.team_name_3 = lb2.team_name_4
left outer join losses_worse2 lw2 on lb2.team_name_4 = lw2.team_name_5
left outer join losses_better3 lb3 on lw2.team_name_5 = lb3.team_name_6
left outer join losses_worse3 lw3 on lb3.team_name_6 = lw3.team_name_7;

-- COMMAND ----------

-- visualize with Python
%python
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
df = sqlContext.sql('select * from fieldgoalanalysis').toPandas()

-- COMMAND ----------

-- MAGIC %python
-- MAGIC df.head()

-- COMMAND ----------

-- MAGIC %python
-- MAGIC df.set_index('team_name',inplace=True)
-- MAGIC 
-- MAGIC wb2 = sum(df['WINS_BETTER2'.lower()])
-- MAGIC ww2 = sum(df['WINS_WORSE2'.lower()])
-- MAGIC wb3 = sum(df['WINS_BETTER3'.lower()])
-- MAGIC ww3 = sum(df['WINS_WORSE3'.lower()])
-- MAGIC lb2 = sum(df['LOSSES_BETTER2'.lower()])
-- MAGIC lw2 = sum(df['LOSSES_WORSE2'.lower()])
-- MAGIC lb3 = sum(df['LOSSES_BETTER3'.lower()])
-- MAGIC lw3 = sum(df['LOSSES_WORSE3'.lower()])
-- MAGIC wins_list = [wb2,ww2,wb3,ww3]
-- MAGIC 
-- MAGIC names_wins = ['Better 2p %','Worse 2p %','Better 3p %','Worse 3p %']

-- COMMAND ----------

-- MAGIC %python
-- MAGIC wins_list

-- COMMAND ----------

-- MAGIC %python
-- MAGIC plt.figure(figsize = (8,6))
-- MAGIC plt.bar(names_wins,wins_list, color='rbrb')
-- MAGIC plt.ylabel('# of Wins')
-- MAGIC plt.xlabel('Win By Categories')
-- MAGIC plt.title('Total Wins by Field Goal Criteria')
-- MAGIC # plt.savefig('foo1.png', bbox_inches='tight')
-- MAGIC 
-- MAGIC display()

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 3. Hypothesis: Teams with more offensive rebounds win more games
-- MAGIC ## Do one for each season

-- COMMAND ----------

-- Season 16-17 - offensive
select w.game_ID, (w.oreb - l.oreb) as winning_offensive --, (w.dreb - l.dreb) as winning_defensive
from 
(select game_ID, team_name, WL, oreb, dreb
from gamelog16
where wl = 'W') W, 
(select game_ID, team_name, WL, oreb, dreb
from gamelog16
where wl = 'L') L
where W.game_ID = L.game_ID
-- seems to somewhat center around 0

-- COMMAND ----------

-- Season 16-17 - defensive
select w.game_ID, (w.dreb - l.dreb) as winning_defensive
from 
(select game_ID, team_name, WL, oreb, dreb
from gamelog16
where wl = 'W') W, 
(select game_ID, team_name, WL, oreb, dreb
from gamelog16
where wl = 'L') L
where W.game_ID = L.game_ID

-- this distribution definitely seems to have an an above 0 mean

-- COMMAND ----------

-- Season 17-18 - offensive
select w.game_ID, (w.oreb - l.oreb) as winning_offensive
from 
(select game_ID, team_name, WL, oreb, dreb
from gamelog17
where wl = 'W') W, 
(select game_ID, team_name, WL, oreb, dreb
from gamelog17
where wl = 'L') L
where W.game_ID = L.game_ID
-- seems to somewhat center around 0

-- COMMAND ----------

-- Season 17-18 - defensive
select w.game_ID, (w.dreb - l.dreb) as winning_defensive
from 
(select game_ID, team_name, WL, oreb, dreb
from gamelog17
where wl = 'W') W, 
(select game_ID, team_name, WL, oreb, dreb
from gamelog17
where wl = 'L') L
where W.game_ID = L.game_ID

-- clearly above 0

-- COMMAND ----------

-- Season 18-19
select w.game_ID, (w.oreb - l.oreb) as winning_offensive
from 
(select game_ID, team_name, WL, oreb, dreb
from gamelog18
where wl = 'W') W, 
(select game_ID, team_name, WL, oreb, dreb
from gamelog18
where wl = 'L') L
where W.game_ID = L.game_ID
-- seems to somewhat center around 0; even has a long left tail

-- COMMAND ----------

-- Season 18-19 - defensive
select w.game_ID, (w.dreb - l.dreb) as winning_defensive
from 
(select game_ID, team_name, WL, oreb, dreb
from gamelog18
where wl = 'W') W, 
(select game_ID, team_name, WL, oreb, dreb
from gamelog18
where wl = 'L') L
where W.game_ID = L.game_ID

-- clearly above 0, but not as to the right compared to 17-18

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Hypothesis proven untrue.** A winning team does not necessarily have more offensive rebounds.

-- COMMAND ----------


