use ev;

select * from sales_by_maker sbm;

#Q1. List the top 3 and bottom 3 makers for the fiscal years 2023 and 2024 in terms of the number of 2-wheelers sold.

# Top 3 makers:
select 
	maker,
	fiscal_year,
	no_of_ev_sold
from
	(select 
		sbm.maker,
		dd.fiscal_year,
		sum(sbm.electric_vehicles_sold) no_of_ev_sold,
		rank() 
		over(partition by dd.fiscal_year 
			order by sum(sbm.electric_vehicles_sold) desc) as rnk
	from
		dim_date dd 
	join
		sales_by_maker sbm 
	on
		dd.`date` = sbm.`date`
	where 
		sbm.vehicle_category = "2-Wheelers"
	group by 
		sbm.maker, dd.fiscal_year
	having 
		dd.fiscal_year in (2023,2024)
	) as sbmr
where 
	rnk in (1,2,3)
order by
	fiscal_year, no_of_ev_sold desc;

# Bottom 3 makers:
select 
	maker,
	fiscal_year,
	no_of_ev_sold
from
	(select 
		sbm.maker,
		dd.fiscal_year,
		sum(sbm.electric_vehicles_sold) no_of_ev_sold,
		rank() 
		over(partition by dd.fiscal_year 
			order by sum(sbm.electric_vehicles_sold) ) as rnk
	from
		dim_date dd 
	join
		sales_by_maker sbm 
	on
		dd.`date` = sbm.`date`
	where 
		sbm.vehicle_category = "2-Wheelers"
	group by 
		sbm.maker, dd.fiscal_year
	having 
		dd.fiscal_year in (2023,2024)
	) as sbmr
where 
	rnk in (1,2,3)
order by
	fiscal_year, no_of_ev_sold;

#Q2. Identify the top 5 states with the highest penetration rate in 2-wheeler and 4-wheeler EV sales in FY 2024. 

# 2 Wheelers sales:
select 	 
	sbs.state,
	round(sum(sbs.electric_vehicles_sold)*100
		/sum(sbs.total_vehicles_sold),2) as penetration_rate
from
	sales_by_state sbs
join
	dim_date dd 
on 
	sbs.`date` = dd.`date`
where 
	sbs.vehicle_category = '2-Wheelers' and 
	dd.fiscal_year = 2024
group by
	sbs.state
order by 
	penetration_rate desc
limit 5;


# 4 Wheelers sales:
select 	
	sbs.state,
	round(sum(sbs.electric_vehicles_sold)*100
		/sum(sbs.total_vehicles_sold),2) as penetration_rate
from
	sales_by_state sbs
join
	dim_date dd 
on 
	sbs.`date` = dd.`date`
where 
	sbs.vehicle_category = '4-Wheelers' and 
	dd.fiscal_year = 2024
group by
	sbs.state
order by 
	penetration_rate desc
limit 5;

#Q3. List the states with negative penetration (decline) in EV sales from 2022 to 2024?


# 2 Wheleers:
select 
	penet_1.state,
	penet_1.penetration_rate as penet_rate_2022,
	penet_2.penetration_rate penet_rate_2023,
	penet_2.penetration_rate - penet_1.penetration_rate as difference_of_22_23
from
	(select
		sbs.state,
		round(sum(sbs.electric_vehicles_sold)*100
		/sum(sbs.total_vehicles_sold),2) as penetration_rate
	from
		sales_by_state sbs
	join
		dim_date dd 
	on 
		sbs.`date` = dd.`date`
	where 
		dd.fiscal_year in (2022) and sbs.vehicle_category = "2-Wheelers"
	group by
		sbs.state
	) as penet_1
join
	(select
		sbs.state,
		round(sum(sbs.electric_vehicles_sold)*100
		/sum(sbs.total_vehicles_sold),2) as penetration_rate
	from
		sales_by_state sbs
	join
		dim_date dd 
	on 
		sbs.`date` = dd.`date`
	where 
		dd.fiscal_year in (2024) and sbs.vehicle_category = "2-Wheelers"
	group by
		sbs.state
	) as penet_2
on
	penet_1.state = penet_2.state
group by
	penet_1.state
having 	
	difference_of_22_23 < 0
order by
	penet_1.state;

# 4 Wheleers:
select 
	penet_1.state,
	penet_1.penetration_rate as penet_rate_2022,
	penet_2.penetration_rate penet_rate_2024,
	penet_2.penetration_rate - penet_1.penetration_rate as difference_of_22_24
from
	(select
		sbs.state as state,
		round(sum(sbs.electric_vehicles_sold)*100
			/sum(sbs.total_vehicles_sold),2) as penetration_rate
	from
		sales_by_state sbs
	join
		dim_date dd 
	on 
		sbs.`date` = dd.`date`
	where 
		dd.fiscal_year in (2022) and sbs.vehicle_category = "4-Wheelers"
	group by
		sbs.state
	) as penet_1
join
	(select
		sbs.state as state,
		round(sum(sbs.electric_vehicles_sold)*100
			/sum(sbs.total_vehicles_sold),2) as penetration_rate
	from
		sales_by_state sbs
	join
		dim_date dd 
	on 
		sbs.`date` = dd.`date`
	where 
		dd.fiscal_year in (2024) and sbs.vehicle_category = "4-Wheelers"
	group by
		sbs.state
	) as penet_2
on
	penet_1.state = penet_2.state
group by
	penet_1.state
having 	
	difference_of_22_24 < 0
order by
	penet_1.state;
	


#Q4. What are the quarterly trends based on sales volume for the top 5 EV makers (4-wheelers) from 2022 to 2024?

# Top 5 EV makers 4-whellers:

select 
	sbm.maker, 
	sum(sbm.electric_vehicles_sold)
from
	sales_by_maker sbm 
join
	dim_date dd 
on
	sbm.`date` = dd.`date` 
where 	
	sbm.vehicle_category = "4-Wheelers"
group by 	
	sbm.maker
order by 	
	sum(sbm.electric_vehicles_sold) desc
limit 5;	
	
# Quarterly trends based on sales volume:

select 
	top_5.makers,
	dd2.quarter,
	sum(sbm2.electric_vehicles_sold)
from
	(select 
		sbm.maker as makers, 
		sum(sbm.electric_vehicles_sold)
	from
		sales_by_maker sbm 
	join
		dim_date dd 
	on
		sbm.`date` = dd.`date` 
	where 	
		sbm.vehicle_category = "4-Wheelers"
	group by 	
		sbm.maker
	order by 	
		sum(sbm.electric_vehicles_sold) desc
	limit 5
	) as top_5
join
	sales_by_maker sbm2 
on 
	top_5.makers = sbm2.maker 
join
	dim_date dd2
on
	sbm2.`date` = dd2.`date`
group by
	top_5.makers, dd2.quarter
order by 	
	top_5.makers;


#Q5. How do the EV sales and penetration rates in Delhi compare to Karnataka for 2024? 

select
		sbs.state as state,
		sum(sbs.electric_vehicles_sold),
		round(sum(sbs.electric_vehicles_sold)*100
			/sum(sbs.total_vehicles_sold),2) as penetration_rate
	from
		sales_by_state sbs
	join
		dim_date dd 
	on 
		sbs.`date` = dd.`date`
	where 
		dd.fiscal_year in (2024) and sbs.state in ('Delhi','Karnataka')
	group by
		sbs.state;
	
#Q6. List down the compounded annual growth rate (CAGR) in 4-wheeler units for the top 5 makers from 2022 to 2024.

select 
	ending_ev_sales.maker,
	round((power(sum(ending_ev_sales.ev_sales_2024)
		/sum(beginning_ev_sales.ev_sales_2022),1/2)-1)*100,2) as cagr_per
from
	(select
		sbm.maker,
		sum(sbm.electric_vehicles_sold) ev_sales_2024
	from
		sales_by_maker sbm
	join
		dim_date dd 
	on 
		sbm.`date` = dd.`date`
	where 
		sbm.maker in 
		('Tata Motors','Mahindra & Mahindra',
		'MG Motor','BYD India','Hyundai Motor')
		and
		dd.fiscal_year = 2024
	group by
		sbm.maker
	) as ending_ev_sales
join 	
	 (select
		sbm.maker,
		sum(sbm.electric_vehicles_sold) ev_sales_2022
	from
		sales_by_maker sbm
	join
		dim_date dd 
	on 
		sbm.`date` = dd.`date`
	where 
		sbm.maker in 
		('Tata Motors','Mahindra & Mahindra',
		'MG Motor','BYD India','Hyundai Motor')
		and
		dd.fiscal_year = 2022
	group by
		sbm.maker
	) as beginning_ev_sales
on
	ending_ev_sales.maker = beginning_ev_sales.maker
group by
	ending_ev_sales.maker;


#Q7. List down the top 10 states that had the highest compounded annual growth rate (CAGR) from 2022 to 2024 in total vehicles sold.


with beggining_sales as 
(select
	sbs.state,
	sum(sbs.total_vehicles_sold) as vehicle_sold
from
	sales_by_state sbs
join
	dim_date dd 
on
	sbs.`date` = dd.`date` 
where 
	dd.fiscal_year = 2022
group by
	sbs.state
),
ending_sales as 
(select
	sbs.state,
	sum(sbs.total_vehicles_sold) as vehicle_sold
from
	sales_by_state sbs
join
	dim_date dd 
on
	sbs.`date` = dd.`date` 
where 
	dd.fiscal_year = 2024
group by
	sbs.state
)
select 
	bs.state,
	round((power(sum(es.vehicle_sold)
		/sum(bs.vehicle_sold),1/2)-1)*100,2) as cagr_per
from
	beggining_sales bs
join
	ending_sales es
on 
	bs.state = es.state
group by
	bs.state
order by
	cagr_per desc 
limit
	10;


#8. What are the peak and low season months for EV sales based on the data from 2022 to 2024?

# To extract monthname from date column I have to change its date type
# As date column in dim_date table can't be change as it is useful to join it with other tables
# So I will add one same column date_updated in dim_date table as date column we have and then I will change its datatype to date 

alter table dim_date 
add date_updated varchar(20);

update dim_date 
set date_updated = str_to_date(`date`,'%d-%b-%y')

# All over peak and low season months:
select 
	monthname(dd.date_updated) as month_name,
	sum(sbs.electric_vehicles_sold) as ev_sold
from
	sales_by_state sbs 
join
	dim_date dd 
on
	sbs.`date` = dd.`date` 
group by 	
	month_name
order by 	
	ev_sold desc;

# Fiscal year wise peak and low season months:
select 
	dd.fiscal_year as year_no,
	monthname(dd.date_updated) as month_name,
	sum(sbs.electric_vehicles_sold) as ev_sold
from
	sales_by_state sbs 
join
	dim_date dd 
on
	sbs.`date` = dd.`date` 
group by 	
	year_no, month_name
order by 	
	year_no, ev_sold desc;


#9. What is the projected number of EV sales (including 2-wheelers and 4-wheelers) 
#   for the top 10 states by penetration rate in 2030, based on the compounded annual growth rate (CAGR) 
#   from previous years?

# to find projected number of ev sales in 2030 we can use cagr formula as follows:
# Future value = previous value * (1+cagr/100)^n
# where n denotes number of years

with top10_states_by_PR as 
(select
	sbs.state as state,
	round(sum(sbs.electric_vehicles_sold)/sum(sbs.total_vehicles_sold)*100,2) as pen_rate,
	sum(case when dd.fiscal_year = 2022 then electric_vehicles_sold end) as ev_sales_2022,
	sum(case when dd.fiscal_year = 2024 then electric_vehicles_sold end) as ev_sales_2024
from
	sales_by_state sbs 
join
	dim_date dd 
on
	sbs.`date` = dd.`date`
group by
	state
order by
	pen_rate desc
limit 
	10
),
growth_rate as 
(select
	state,
	ev_sales_2022,
	ev_sales_2024,
	case
		when ev_sales_2022 > 0 then 
		round((power(ev_sales_2024/ev_sales_2022,0.5)-1)*100,2)
	end as cagr
from
	top10_states_by_PR
)
select
	state,
	round(ev_sales_2024*power((1+cagr/100),(2030-2024)),0) as ev_sales_2030
from
	growth_rate
order by
	ev_sales_2030 desc;


#10. Estimate the revenue growth rate of 4-wheeler and 2-wheelers EVs in India 
#for 2022 vs 2024 and 2023 vs 2024, assuming an average unit price. 

# First I will add one column of unit price in sales_by_maker table

alter table sales_by_maker 
add unit_price varchar(10);

update sales_by_maker
set unit_price = (case
						when vehicle_category = '4-Wheelers' then 1500000
						when vehicle_category = '2-Wheelers' then 85000
				  end
				 )

with revenue as
(select
	sbm.vehicle_category,
	dd.fiscal_year,
	sum(sbm.electric_vehicles_sold*sbm.unit_price) as revenue
from
	sales_by_maker sbm 
join
	dim_date dd 
on
	sbm.`date` = dd.`date`
group by
	sbm.vehicle_category, dd.fiscal_year
),
growth as
(select 	
	r1.vehicle_category,
	round((r2.revenue-r1.revenue)/r1.revenue*100,2) as 2022_vs_2024_growth,
	round((r2.revenue-r3.revenue)/r3.revenue*100,2) as 2023_vs_2024_growth
from
	revenue r1 
	join revenue r2 
	on r1.vehicle_category = r2.vehicle_category and r2.fiscal_year = 2024
	join revenue r3 
	on r1.vehicle_category = r3.vehicle_category and r3.fiscal_year = 2023
where 
	r1.fiscal_year = 2022
)
select 	
	vehicle_category,
	2022_vs_2024_growth,
	2023_vs_2024_growth
from
	growth
order by
	1;




















