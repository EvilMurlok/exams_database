-- вывести количество аудиторий по каждому предмету в каждом городе
SELECT a.city_name,
       s.subject_name,
       COUNT(c.classroom_number) AS count_of_classrooms
FROM classroom AS c
         JOIN school sch ON c.school_id = sch.id
         JOIN address a ON sch.address_id = a.id
         JOIN subject s ON c.subject_id = s.id
GROUP BY city_name, subject_name
ORDER BY city_name, subject_name;


-- вывести по каждому предмету за каждый год количество раз, сколько этот предмет сдавали
SELECT date_part('year', aed.exam_date) AS year_of_exam,
       s.subject_name,
       COUNT(s.subject_name)            AS count_of_subjects
FROM timetable AS t
         JOIN annualexamdata aed on t.annual_exam_id = aed.id
         JOIN subject s on aed.subject_id = s.id
GROUP BY year_of_exam, subject_name
ORDER BY year_of_exam, subject_name;


-- вывести максимальные баллы в стобальной шкале по каждому экзамену в каждом городе
SELECT DATE_PART('year', aed.exam_date) AS year_of_exam,
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
SELECT st.first_name,
       st.surname,
       st.Patronymic,
       st.passport_series,
       st.passport_number,
       COUNT(*)                    AS count_of_subjects,
       SUM(e.sum_secondary_points) AS sum_of_points
FROM annualexamdata a
         JOIN examresult e ON a.id = e.annual_exam_id
         JOIN student st ON e.student_id = st.id
GROUP BY st.first_name, st.surname, st.Patronymic, st.passport_series, st.passport_number
ORDER BY count_of_subjects DESC, sum_of_points DESC;


-- вывести статистику по школам-нарушителям, которые неправильно проводят экзамены
-- нарушение, если:
-- ЛИБО сдаваемый предмет = предмет, который ведет налюдатель,
-- ЛИБО сдаваемый предмет = предмет, которому посвящена аудитория
SELECT a2.city_name, s2.school_name, count(*) AS count_of_violations
FROM timetable t
         JOIN annualexamdata a ON t.annual_exam_id = a.id
         JOIN teacher t2 ON t.teacher_id = t2.id
         JOIN classroom c ON t.classroom_id = c.id
         JOIN subject s ON t2.subject_id = s.id AND a.subject_id = s.id
    OR a.subject_id = s.id AND c.subject_id = s.id
         JOIN school s2 ON c.school_id = s2.id
         JOIN address a2 ON s2.address_id = a2.id
GROUP BY a2.city_name, s2.school_name
ORDER BY a2.city_name, count_of_violations DESC;


-- вывести средний балл по стобальной шкале по каждому экзамену в каждом городе
WITH ready_statistics AS (
    SELECT a2.city_name, s.subject_name, ROUND(AVG(e.sum_secondary_points), 2) AS average_secondary_points
    FROM examresult e
             JOIN student st ON e.student_id = st.id
             JOIN address a2 ON st.address_id = a2.id
             JOIN annualexamdata a ON e.annual_exam_id = a.id
             JOIN subject s ON a.subject_id = s.id
    GROUP BY a2.city_name, s.subject_name
)
SELECT city_name,
       subject_name,
       average_secondary_points,
       ROW_NUMBER() OVER (PARTITION BY subject_name ORDER BY average_secondary_points DESC) AS rating_of_cities
FROM ready_statistics;
