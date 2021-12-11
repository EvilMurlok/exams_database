-- вывести количество учеников по городам, упорядочить по убыванию количества
SELECT a.city_name,
       COUNT(s.first_name) AS count_students
FROM student AS s
         JOIN address AS a ON s.address_id = a.id
GROUP BY a.city_name
ORDER BY count_students DESC;

-- вывести по каждому предмету за каждый год количество раз, сколько этот предмет сдавали
SELECT date_part('year', aed.exam_date) AS year_of_exam,
       s.subject_name,
       COUNT(s.subject_name)            AS count_of_subjects
FROM timetable AS t
         JOIN annualexamdata aed on t.annual_exam_id = aed.id
         JOIN subject s on aed.subject_id = s.id
GROUP BY year_of_exam, subject_name
ORDER BY year_of_exam, subject_name;