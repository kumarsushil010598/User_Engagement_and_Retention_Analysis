select * from users;
select * from logins

--1. Managment wants to see all the users that did not login in past 5 months
select max(LOGIN_TIMESTAMP) from logins --2024-06-28 --2024-01-28
 
--WAY 1
select USER_ID, MAX(LOGIN_TIMESTAMP) as MAX_DATE
from logins
group by USER_ID
having max(LOGIN_TIMESTAMP)<'2024-01-28'

--WAY 2
select distinct USER_ID 
from logins
where USER_ID not in(select  USER_ID
					 from logins
					 where LOGIN_TIMESTAMP>'2024-01-28')

--2.For the business units quaterly analysis, calculate how many users and how many sessions were at each quarter
--order by quater from newest to oldest.
--return first day of the quarter, user count, session count
--assumption: considered quater only irrespective of year
select * from logins

select DATEPART(QUARTER,LOGIN_TIMESTAMP) as QUATER_NO
	,min(LOGIN_TIMESTAMP) as QTR_FIRST_LOGIN
	,count(distinct USER_ID) as USER_COUNT
	,sum(SESSION_SCORE) as SESSION_COUNT
	--,DATETRUNC(QUARTER,min(LOGIN_TIMESTAMP)) as FIRST_QUATER_DATE
from logins
group by DATEPART(QUARTER,LOGIN_TIMESTAMP)

--3. Display user id that log-in in january 2024 and did not login in on novemeber 2023
select * from users;
select * from logins
--january 2024 1 2 3 5
--novemeber 2023 2 4 6 7
select USER_ID
from logins
where MONTH(LOGIN_TIMESTAMP)=1 and YEAR(LOGIN_TIMESTAMP)=2024
and user_id not in (select USER_ID
					from logins
					where MONTH(LOGIN_TIMESTAMP)=11 and YEAR(LOGIN_TIMESTAMP)=2023
					group by USER_ID)
group by USER_ID

select USER_ID
from logins
where MONTH(LOGIN_TIMESTAMP)=1 and YEAR(LOGIN_TIMESTAMP)=2024
group by USER_ID

--4. Add to the query from question 2 the percentage change in the session form the last quater
--return- first day of the quater, session cnt, 
--session cnt previous, session percentage change


select *,(SESSION_COUNT-CHANGE_LST_QTR)*100/CHANGE_LST_QTR as PERCENTAGE_CHANGE  from(
	select *
	,LAG(SESSION_COUNT,1,SESSION_COUNT) over(order by QUATER_NO) as CHANGE_LST_QTR
	from(
		select DATEPART(QUARTER,LOGIN_TIMESTAMP) as QUATER_NO
			,min(LOGIN_TIMESTAMP) as QTR_FIRST_LOGIN
			,count(distinct USER_ID) as USER_COUNT
			,COUNT(*) as SESSION_COUNT
			--,DATETRUNC(QUARTER,min(LOGIN_TIMESTAMP)) as FIRST_QUATER_DATE
		from logins
		group by DATEPART(QUARTER,LOGIN_TIMESTAMP)) A) B


--5. Display the user that had highest session score(max) for each day
--return: date, username, score

select LOGIN_DATE
,MAX(SUM_SCORE) as MAXIMUM_SESSION_SCORE
from(
	select USER_ID
	,cast(LOGIN_TIMESTAMP as date) as LOGIN_DATE
	,SUM(SESSION_SCORE) as SUM_SCORE
	from logins
	group by USER_ID,cast(LOGIN_TIMESTAMP as date)) A
group by LOGIN_DATE
order by LOGIN_DATE

select *
from(
	select *
	,ROW_NUMBER() over(partition by DATEE order by SUMSCORE desc) as rn
	from(
		select USER_ID
		,cast(LOGIN_TIMESTAMP as date) as DATEE
		,sum(SESSION_SCORE) as SUMSCORE
		from logins
		group by USER_ID, cast(LOGIN_TIMESTAMP as date)) A) B
where rn=1

--6. To identify our best users - return the user that had a session on every single day since their first login
--(make assumption if needed)
--return- userid
select *
from(
	select *
	,DATEDIFF(DAY,MIN_LOGIN_DATE,MAXIMUM_LOGIN_DATE)+1 as DAYS_BETWEEN
	from(
		select USER_ID
		,MIN(LOGIN_TIMESTAMP) as MIN_LOGIN_DATE
		,MAX(LOGIN_TIMESTAMP) as MAXIMUM_LOGIN_DATE
		,COUNT(*) as TOTAL_NO_OF_LOGINS
		from logins
		group by USER_ID) A)B
where DAYS_BETWEEN=TOTAL_NO_OF_LOGINS

select USER_ID
,MIN(cast(LOGIN_TIMESTAMP as date)) as FIRST_LOGIN
,max(cast(LOGIN_TIMESTAMP as date)) as LAST_LOGIN
,DATEDIFF(DAY,MIN(cast(LOGIN_TIMESTAMP as date))
,max(cast(LOGIN_TIMESTAMP as date)))+1 as DATE_DIFF
,COUNT(USER_ID) as TOTAL_LOGIN
from logins
group by USER_ID
having COUNT(USER_ID)=DATEDIFF(DAY,MIN(cast(LOGIN_TIMESTAMP as date)),max(cast(LOGIN_TIMESTAMP as date)))+1

--7. On what date there were no login at all
--return- login date
select * from logins

select min(LOGIN_TIMESTAMP)as MIN_DATE,max(LOGIN_TIMESTAMP)as MAX_DATE
from logins
--2023-07-15 
--2024-06-28 

--recursive cte for creating date table from the min date to max date
with cte as (
	select cast('2023-07-15' as date) as CAL_DATE
	union all
	select DATEADD(day,1,CAL_DATE) as CAL_DATE
	from cte
	where CAL_DATE<cast('2024-06-28' as date)
)
select * into CAL_TABLE
from cte
option(maxrecursion 500)

select * from CAL_TABLE

select *
from CAL_TABLE c
left join
	(select cast(LOGIN_TIMESTAMP as date)as REQ_DATE
	from logins) a 
	on c.CAL_DATE=a.REQ_DATE
where REQ_DATE is null