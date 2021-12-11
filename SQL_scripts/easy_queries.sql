-- вывести количество учеников по городам, упорядочить по убыванию количества
SELECT a.city_name,
       COUNT(s.first_name) AS count_students
FROM student AS s
         JOIN address AS a ON s.address_id = a.id
GROUP BY a.city_name
ORDER BY count_students DESC;


-- вывести вывести первые 5 городов, где работает наибольшее количество учителей
SELECT a.city_name, COUNT(t.first_name) AS count_of_teachers
FROM teacher AS t
         JOIN school s ON t.school_id = s.id
         JOIN address a on s.address_id = a.id
GROUP BY a.city_name
ORDER BY count_of_teachers DESC
LIMIT 5;
