-- 1. Вывести количество фильмов в каждой категории, отсортировать по убыванию.
SELECT category.name, COUNT(film_category.film_id) AS films_amount
FROM category
LEFT JOIN film_category ON category.category_id = film_category.category_id
GROUP BY category.name
ORDER BY films_amount DESC;

-- 2. Вывести 10 актеров, чьи фильмы большего всего арендовали, отсортировать по убыванию.
SELECT actor.first_name, actor.last_name, COUNT(film.film_id) AS rental_amount
FROM actor
INNER JOIN film_actor ON actor.actor_id = film_actor.actor_id
INNER JOIN film ON film_actor.film_id = film.film_id
GROUP BY actor.actor_id
ORDER BY rental_amount DESC
LIMIT 10;

-- 3. Вывести категорию фильмов, на которую потратили больше всего денег.
SELECT category.name, SUM(film.replacement_cost) AS category_replacement_cost
FROM category
INNER JOIN film_category ON category.category_id = film_category.category_id
INNER JOIN film ON film_category.film_id = film.film_id
GROUP BY category.name
ORDER BY category_replacement_cost DESC
LIMIT 1;

-- 4. Вывести названия фильмов, которых нет в inventory. Написать запрос без использования оператора IN.
SELECT film.title FROM film
WHERE NOT EXISTS(SELECT 1 FROM inventory 
				 WHERE inventory.film_id = film.film_id);

-- 5. Вывести топ 3 актеров, которые больше всего появлялись в фильмах в категории “Children”. 
-- Если у нескольких актеров одинаковое кол-во фильмов, вывести всех.
WITH actors_ranked AS
	(SELECT actor.first_name, actor.last_name, COUNT(film.film_id) AS films_count, DENSE_RANK() OVER (ORDER BY COUNT(actor.actor_id) DESC) AS RANK
	 FROM actor
	 INNER JOIN film_actor USING (actor_id)
	 INNER JOIN film USING (film_id)
	 INNER JOIN film_category USING (film_id)
	 INNER JOIN category USING (category_id)
	 WHERE category.name = 'Children'
	 GROUP BY actor.actor_id)
	
SELECT actors_ranked.first_name, actors_ranked.last_name, films_count
FROM actors_ranked
WHERE RANK <= 3

-- 6. Вывести города с количеством активных и неактивных клиентов (активный — customer.active = 1). 
-- Отсортировать по количеству неактивных клиентов по убыванию.
SELECT city.city,
COUNT(customer) FILTER (WHERE customer.active = 1)  AS active_customers,
COUNT(customer) FILTER (WHERE customer.active = 0) AS inactive_customers
FROM city
INNER JOIN address ON city.city_id = address.city_id
INNER JOIN customer ON address.address_id = customer.address_id
GROUP BY city.city
ORDER BY inactive_customers DESC, active_customers DESC;

-- 7. Вывести категорию фильмов, у которой самое большое кол-во часов суммарной аренды в городах (customer.address_id в этом city), 
-- и которые начинаются на букву “a”. То же самое сделать для городов в которых есть символ “-”. Написать все в одном запросе.
WITH categories_city_rental AS (SELECT category.name, city.city, 
								SUM(rental.return_date - rental.rental_date) AS rental_duration
								FROM category
								INNER JOIN film_category ON category.category_id = film_category.category_id
								INNER JOIN film ON film_category.film_id = film.film_id
								INNER JOIN inventory ON film_category.film_id = inventory.film_id
								INNER JOIN rental ON inventory.inventory_id = rental.inventory_id
								INNER JOIN customer ON rental.customer_id = customer.customer_id
								INNER JOIN address ON customer.address_id = address.address_id
								INNER JOIN city ON address.city_id = city.city_id
								GROUP BY category.category_id, city.city_id)
								
(SELECT * FROM categories_city_rental
 WHERE categories_city_rental.city LIKE '%a%'
 LIMIT 1)
 
UNION ALL

(SELECT * FROM categories_city_rental
 WHERE categories_city_rental.city LIKE '%-%'
 LIMIT 1);
