-- вывести количество аудиторий по каждому предмету в каждом городе
SELECT a.city_name,
       s.subject_name,
       count(c.classroom_number) AS count_of_classrooms
FROM classroom AS c
         JOIN school sch ON c.school_id = sch.id
         JOIN address a ON sch.address_id = a.id
         JOIN subject s ON c.subject_id = s.id
GROUP BY city_name, subject_name
ORDER BY city_name, subject_name;


-- вывести максимальные баллы в стобальной шкале по каждому экзамену в каждом городе
SELECT date_part('year', aed.exam_date) AS year_of_exam,
       a.city_name,
       s.subject_name,
       MAX(e.sum_secondary_points)      AS max_secondary_points
FROM examresult AS e
         JOIN annualexamdata AS aed ON e.annual_exam_id = aed.id
         JOIN student st ON e.student_id = st.id
         JOIN address a ON st.address_id = a.id
         JOIN subject AS s ON aed.subject_id = s.id
GROUP BY year_of_exam, city_name, subject_name
ORDER BY year_of_exam, city_name, subject_name;


-- вывести суммарное количество баллов каждого ученика по всем его предметам
-- и количество предметов, которые он сдавал, упорядочить по количеству предметов, а потом по количеству баллов
SELECT st.first_name, st.surname, st.Patronymic,
       st.passport_series, st.passport_number,
       count(*) as count_of_subjects, sum(e.sum_secondary_points) as sum_of_points
FROM annualexamdata a
JOIN examresult e ON a.id = e.annual_exam_id
JOIN student st ON e.student_id = st.id
JOIN subject s2 on a.subject_id = s2.id
GROUP BY st.first_name, st.surname, st.Patronymic, st.passport_series, st.passport_number
ORDER BY count_of_subjects DESC, sum_of_points DESC;


