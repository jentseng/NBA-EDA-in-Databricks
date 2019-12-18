-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Light Modeling for Star Player Importance
-- MAGIC Following the exploratory analysis, we decided to build a logistic regression model to test whether a winning team generally have a balanced team (i.e., all players contribute equally) or a star player. Our hypothesis is that balanced teams would win more.
-- MAGIC **Note 1:** Given that the API only worked for one season's player data, this hypothesis is only tested with one season's data (18-19).
-- MAGIC 
-- MAGIC **Note 2:** To conduct the analyses in this file, we continued to use the tables we created for the exploratory analysis. As a reminder, the csv's used and the corresponding table names are below.
-- MAGIC - TeamGamesLogsDF16.csv --> gamelog16 
-- MAGIC - TeamGamesLogsDF17.csv --> gamelog17
-- MAGIC - TeamGamesLogsDF18.csv --> gamelog18
-- MAGIC - PlayerGameLog18.csv --> playergamelog18
-- MAGIC 
-- MAGIC ## Step 1: Prepare table for modeling

-- COMMAND ----------

-- Find the top 7 players' score % (as proportion of total team points during that game) -- For classification models in Python
Create or replace View allGamesPlayers as (
select a.game_date, a.matchup, a.team_name, (a.game_ID || a.team_abbreviation || a.game_date) as gameTeamDate, a.WL, a.pts as TeamPts, b.player_id, b.pts
from gamelog18 a inner join 
    (
    SELECT *, left(matchup, 3) as team_abbreviation -- playergamelog does not have the teams listed in a column
    FROM playergamelog18 
    ) b 
  on a.game_id = b.game_id and a.team_abbreviation = b.team_abbreviation);

-- COMMAND ----------

select count(*) from allgamesplayers
-- matches the count of the playergamelog

-- COMMAND ----------

-- test to see average points by players
select player_id, avg(pts) as avgpts
from allgamesplayers
group by player_id
order by avgpts desc
limit 10

-- COMMAND ----------

-- test to see average points by team
select team_name, avg(teampts) as avgteampts
from allgamesplayers
group by team_name
order by avgteampts desc

-- COMMAND ----------

-- rank players by scores by game, team, and date (i.e., who score the most to least on each team in each game)
Create or replace View Ordered as (
select game_date, matchup, team_name, gameTeamDate, WL, teamPts, player_id, pts, row_number() over (partition by gameTeamDate order by pts desc) as rn
from allGamesPlayers );

-- COMMAND ----------

-- sanity check to ensure player points add up to team points
select * from Ordered limit 20

-- COMMAND ----------

-- find the top 7 scorers for each team for each game and calculate each's contribution to total team points as a %
Create or replace View Top7 as
(
select game_date, matchup, gameTeamDate, WL, teamPts, player_id, rn, pts, round((pts / teampts)*100,2) as playerpercent 
from Ordered
where rn<= 7
) 

-- COMMAND ----------

select * from top7 limit 10
-- some players have ties in points, but given that we hypothesized balanced teams are better, this should help us conclude one way or another

-- COMMAND ----------

-- Pivot the playerpercent column into 7 columns (7 predictors) --> View for Python's use 
Create or replace View PivotTop7 as ( 
select *
from (select gameteamdate, WL, teampts, playerpercent, RN from Top7)
pivot (sum(playerpercent) as PlayerPercent for (RN) in (1 as First, 2 as Second, 3 as Third, 4 as Fourth, 5 as Fifth, 6 as Sixth, 7 as Seventh)) );

-- COMMAND ----------

-- sanity check to ensure the percentages add up to <= 100
select * from PivotTop7

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Step 2: Build logistic regression model in Python

-- COMMAND ----------

-- MAGIC %python
-- MAGIC # Prepare data for Python
-- MAGIC from pandas import Series, DataFrame
-- MAGIC import pandas as pd
-- MAGIC from patsy import dmatrices
-- MAGIC import matplotlib as plt
-- MAGIC 
-- MAGIC df = sqlContext.sql('select * from PivotTop7').toPandas()
-- MAGIC 
-- MAGIC df.head()

-- COMMAND ----------

-- MAGIC %python
-- MAGIC # Set up target column
-- MAGIC df['target'] = 0.0
-- MAGIC df['target'][df['WL'] =='W'] = 1.0
-- MAGIC df['target'].value_counts() # winning counts = losing counts

-- COMMAND ----------

-- MAGIC %python
-- MAGIC # prepare design matrix
-- MAGIC formula = 'target ~ + First + Second + Third + Fourth + Fifth + Sixth + Seventh'
-- MAGIC print(formula)
-- MAGIC 
-- MAGIC Y, X = dmatrices(formula, df, return_type='dataframe')
-- MAGIC y = Y['target'].values
-- MAGIC 
-- MAGIC # Split data into train and test sets
-- MAGIC from sklearn.model_selection import train_test_split
-- MAGIC X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=1)

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Train model to get p-values of coefficients and model accuracy

-- COMMAND ----------

-- MAGIC %python
-- MAGIC # model
-- MAGIC import statsmodels.api as sm
-- MAGIC model = sm.Logit(y_train, X_train)
-- MAGIC result = model.fit()
-- MAGIC result.summary()

-- COMMAND ----------

-- MAGIC %python
-- MAGIC pred = result.predict(X_test)
-- MAGIC pred_bi = [ 0 if x < 0.5 else 1 for x in pred]
-- MAGIC 
-- MAGIC from sklearn import metrics 
-- MAGIC print("The model accuracy is", metrics.accuracy_score(y_test,pred_bi))

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Conclusion**: The accuracy aligns with a random guess. The presence of a star player or a balanced team does not increase winning probability.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Step 3: Verification with SQL

-- COMMAND ----------

-- 1. overall average
Select ROUND(avg(FIRST),2) First_AVG, ROUND(avg(SECOND),2) Sec_AVG, ROUND(avg(THIRD),2) Third_AVG, 
    ROUND(avg(FOURTH),2) Fourth_AVG, ROUND(avg(FIFTH),2) Fifth_AVG, ROUND(avg(SIXTH),2) Sixth_AVG, ROUND(avg(SEVENTH),2) Seventh_AVG
from pivottop7;

-- COMMAND ----------

-- 2. Avg % from winning team's top 7
Select ROUND(avg(FIRST),2) First_AVG, ROUND(avg(SECOND),2) Sec_AVG, ROUND(avg(THIRD),2) Third_AVG, 
    ROUND(avg(FOURTH),2) Fourth_AVG, ROUND(avg(FIFTH),2) Fifth_AVG, ROUND(avg(SIXTH),2) Sixth_AVG, ROUND(avg(SEVENTH),2) Seventh_AVG
from pivottop7
where WL = 'W';


-- COMMAND ----------

-- 3. Avg % from losing team's top 7
Select ROUND(avg(FIRST),2) First_AVG, ROUND(avg(SECOND),2) Sec_AVG, ROUND(avg(THIRD),2) Third_AVG, 
    ROUND(avg(FOURTH),2) Fourth_AVG, ROUND(avg(FIFTH),2) Fifth_AVG, ROUND(avg(SIXTH),2) Sixth_AVG, ROUND(avg(SEVENTH),2) Seventh_AVG
from pivottop7
where WL = 'L';


-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Final Note:** The averages of the percentages seem to be consistent across winning and losing teams, proving that the results of the logistic regression are logical.

-- COMMAND ----------


