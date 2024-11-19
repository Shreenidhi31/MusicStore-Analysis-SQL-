select * from album
select * from employee

select * from employee
order by levels desc
limit 1

select * from invoice

select billing_country, count(*) as c
from invoice 
group by billing_country
order by c desc

select * from invoice
order by total desc

select total from invoice
order by total desc
limit 3

select billing_city, SUM(total) as invoice_total 
from invoice
group by billing_city
order by invoice_total desc

select * from customer

select customer.customer_id,customer.first_name,customer.last_name,sum(invoice.total) as total 
from customer 
join customer invoice on customer.customer_id = invoice.customer_id
group by customer.customer_id
order by total desc
limit 1


select Distinct email,first_name,last_name
from customer
join invoice on customer.customer_id = invoice.customer_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
where track_id in(
select track_id from track
join genre on track.genre_id = genre.genre_id
where genre.name like 'Rock'
)
order by email;

select * from artist

select artist.artist_id,artist.name,count(artist.artist_id) as number_of_songs
from track
Join album on album.album_id = track.album_id
join artist on artist.artist_id = album.artist_id
join genre on genre.genre_id=track.genre_id
where genre.name like 'Rock'
group by artist.artist_id
order by number_of_songs DESC
limit 10;

select Avg(milliseconds) as avg_track_length from track

select name,milliseconds
from track
where milliseconds > (select Avg(milliseconds) as avg_track_length 
from track)
order by milliseconds desc

-- Create CTE
with best_selling_artist as(
	select artist.artist_id as artist_id,artist.name as artist_name,
	sum(invoice_line.unit_price*invoice_line.quantity)as total_sales
	from invoice_line
	join track on track.track_id=invoice_line.track_id
	join album on album.album_id=track.album_id
	join artist on artist.artist_id=album.artist_id
	group by 1
	order by 3 desc
	limit 1
)
select c.customer_id,c.first_name,c.last_name,bsa.artist_name,
sum(il.unit_price*il.quantity) as amount_spent
from invoice i
join customer c on c.customer_id = i.customer_id
join invoice_line il on il.invoice_id=i.invoice_id
join track t on t.track_id = il.track_id
join album alb on alb.album_id = t.album_id
join best_selling_artist bsa on bsa.artist_id =alb.artist_id
group by 1,2,3,4
order by 5 desc


--Method 1
with popular_genre as
(
	select count(invoice_line.quantity) as purchases,customer.country, genre.name, genre.genre_id,
	row_number() over(partition by customer.country order by count(invoice_line.quantity) desc) as RowNo
	from invoice_line
	join invoice on invoice.invoice_id = invoice_line.invoice_id
	join customer on customer.customer_id = invoice.customer_id
	join track on track.track_id = invoice_line.track_id
	join genre on genre.genre_id = track.genre_id
	group by 2,3,4
	order by 2 asc, 1 desc
)
select * from popular_genre where RowNo <= 1 

--Method 2
with recursive
	sales_per_country as(
		select count(*) as purchases_per_genre,customer.country,genre.name,genre.genre_id
    	from invoice_line
		join invoice on invoice.invoice_id = invoice_line.invoice_id
		join customer on customer.customer_id = invoice.customer_id
		join track on track.track_id = invoice_line.track_id
		join genre on genre.genre_id = track.genre_id
		group by 2,3,4
		order by 2
  ),
  max_genre_per_country as (select max (purchases_per_genre) as max_genre_number,country
  from sales_per_country
  group by 2
  order by 2)

select sales_per_country.*
from sales_per_country
join max_genre_per_country on sales_per_country.country = max_genre_per_country.country
where sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number
	

with recursive
	customer_with_country as(
		select customer.customer_id,first_name,last_name,billing_country,
		sum(total) as total_spending
		from invoice
		join customer on customer.customer_id = invoice.customer_id
		group by 1,2,3,4
		order by 2,3 desc),

	country_max_spending as(
		select billing_country,max(total_spending) as max_spending
		from customer_with_country
		group by billing_country)

select cc.billing_country, cc.total_spending,cc.first_name,cc.last_name,cc.customer_id
from customer_with_country cc
join country_max_spending ms
on cc.billing_country = ms.billing_country
where cc.total_spending = ms.max_spending
order by 1;
