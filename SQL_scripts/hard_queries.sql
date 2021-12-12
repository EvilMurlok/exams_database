-- по каждому году отобрать топ 3 самых популярных у учеников экзаменов
-- и вывести динамику количеств выборов предметов
WITH subjects_annually AS (
    SELECT DATE_PART('year', a.exam_date) AS year_of_exam,
           s.subject_name,
           COUNT(*)                       AS count_of_choices
    FROM timetable t
             JOIN annualexamdata a ON t.annual_exam_id = a.id
             JOIN subject s ON a.subject_id = s.id
    GROUP BY year_of_exam, s.subject_name
    ORDER BY year_of_exam, count_of_choices DESC
),
     ranked_subjects AS (
         SELECT subjects_annually.*,
                ROW_NUMBER() OVER count_window                             AS top_subjects,
                LAG(count_of_choices) OVER count_window - count_of_choices AS differences
         FROM subjects_annually
             WINDOW count_window AS (PARTITION BY
                 year_of_exam ORDER BY count_of_choices DESC)
     )
SELECT year_of_exam, subject_name, count_of_choices, differences
FROM ranked_subjects
WHERE top_subjects <= 3;


-- по каждой школе вывести разницу между количеством учителей в
-- школе и сколько раз учителя были востребованы,
-- отобрать подробную инфу про школы,
-- где востребованность выше или равна половине числа чителей в школе
-- ( допустим, введено ограничение, что только половина учителей
-- может быть задействована на экзаменах и при том только один раз каждый)
WITH count_of_teachers_per_school AS (
    SELECT s.id,
           s.school_name,
           COUNT(*) AS count_of_teachers_per_school
    FROM school s
             JOIN teacher t ON s.id = t.school_id
    GROUP BY s.id, s.school_name
),
     count_of_exams_per_school AS (
         SELECT DATE_PART('year', a.exam_date) as year_of_exam,
                s.id,
                s.school_name,
                COUNT(*)                       AS count_of_exams_per_school
         FROM timetable t
                  JOIN annualexamdata a ON t.annual_exam_id = a.id
                  JOIN teacher t2 ON t.teacher_id = t2.id
                  JOIN school s ON t.school_id = s.id
         GROUP BY year_of_exam, s.id, s.school_name
     ),
     differences AS (
         SELECT ceps.year_of_exam,
                ctps.id,
                count_of_exams_per_school - ROUND(count_of_teachers_per_school / 2) AS difference
         FROM count_of_teachers_per_school ctps
                  JOIN count_of_exams_per_school ceps ON ctps.id = ceps.id
     )
SELECT d.year_of_exam,
       s.school_name,
       a.city_name,
       a.street,
       a.house,
       d.difference
FROM differences d
         JOIN school s ON s.id = d.id
         JOIN address a ON s.address_id = a.id
WHERE d.difference >= 0
ORDER BY d.difference DESC;


-- посмотреть ежегодную динамику результатов по предметам,
-- вывести года и предметы, когда средний бал уменьшился
WITH annual_avg_points_info AS (
    SELECT DATE_PART('year', a.exam_date)        AS year_of_exam,
           s.subject_name,
           ROUND(AVG(e.sum_secondary_points), 2) AS avg_annual_points
    FROM examresult e
             JOIN annualexamdata a ON e.annual_exam_id = a.id
             JOIN subject s ON a.subject_id = s.id
    GROUP BY year_of_exam, subject_name
    ORDER BY subject_name, year_of_exam
),
     differences_annual_avg_points AS (
         SELECT annual_avg_points_info.*,
                LEAD(avg_annual_points) OVER subject_window - avg_annual_points AS annual_differences
         FROM annual_avg_points_info
             WINDOW subject_window AS (PARTITION BY subject_name ORDER BY year_of_exam)
     )
SELECT year_of_exam + 1 as year_of_exam, subject_name
from differences_annual_avg_points
WHERE annual_differences < 0
ORDER BY year_of_exam, subject_name;
-- select * from differences_annual_avg_points;


-- взять информацию по стобальникам,
-- где было нарушено правило проведения экзамена
WITH exam_result_info AS (
    SELECT t.id,
           a.exam_date,
           sb.subject_name,
           e.sum_secondary_points,
           s.first_name,
           s.surname,
           a2.city_name
    FROM examresult e
             JOIN annualexamdata a ON e.annual_exam_id = a.id
             JOIN subject sb ON a.subject_id = sb.id
             JOIN student s ON e.student_id = s.id
             JOIN address a2 ON s.address_id = a2.id
             JOIN timetable t ON s.id = t.student_id AND t.annual_exam_id = a.id
    WHERE sum_secondary_points = 100
    ORDER BY a.exam_date
),
     violations AS (
         SELECT t.id,
                a.exam_date,
                s.subject_name,
                e.sum_secondary_points,
                s2.first_name,
                s2.surname,
                a2.city_name
         FROM timetable t
                  JOIN annualexamdata a ON t.annual_exam_id = a.id
                  JOIN teacher t2 ON t.teacher_id = t2.id
                  JOIN classroom c ON t.classroom_id = c.id
                  JOIN subject s ON t2.subject_id = s.id AND a.subject_id = s.id
             OR a.subject_id = s.id AND c.subject_id = s.id
                  JOIN student s2 ON t.student_id = s2.id
                  JOIN address a2 ON s2.address_id = a2.id
                  JOIN examresult e ON a.id = e.annual_exam_id AND e.student_id = t.student_id
         ORDER BY a.exam_date
     )
SELECT *
FROM exam_result_info
INTERSECT
SELECT *
FROM violations;

-- вывести всех стобальников, которые писали в одной аудитории с учителями,
-- которые работали больше, чем на одном экзамене в один год
WITH all_successful_student AS (
    SELECT s.first_name,
           s.surname,
           s.patronymic,
           s2.subject_name,
           e.sum_secondary_points,
           a2.city_name,
           DATE_PART('year', a.exam_date) AS year_of_exam,
           t.teacher_id
    FROM examresult e
             INNER JOIN student s on e.student_id = s.id
             INNER JOIN annualexamdata a ON e.annual_exam_id = a.id
             INNER JOIN subject s2 ON s2.id = a.subject_id
             INNER JOIN timetable t on a.id = t.annual_exam_id AND t.student_id = s.id
             INNER JOIN address a2 on s.address_id = a2.id
    WHERE e.sum_secondary_points = 100
),
     all_teachers_required AS (
         select DATE_PART('year', a.exam_date) AS year_of_exam,
                t.id,
                t.first_name,
                t.surname,
                t.patronymic,
                count(*)                       as count_of_annual_observations
         FROM timetable t2
                  INNER JOIN teacher t ON t2.teacher_id = t.id
                  INNER JOIN annualexamdata a ON t2.annual_exam_id = a.id
         GROUP BY t.id, DATE_PART('year', a.exam_date), t.first_name, t.surname, t.patronymic
         HAVING count(*) > 2
     )
SELECT ass.first_name               as student_name,
       ass.surname                  as student_surname,
       ass.patronymic               as student_patronymic,
       subject_name,
       sum_secondary_points,
       city_name,
       ass.year_of_exam,
       atr.first_name,
       atr.surname,
       atr.patronymic,
       count_of_annual_observations as annual_observations
FROM all_successful_student ass
         INNER JOIN all_teachers_required atr
                    ON ass.teacher_id = atr.id AND atr.year_of_exam = ass.year_of_exam;


-- вывести количество школ по годам, где есть хотя бы один
-- плохо написавший егэ человек. Плохо:
-- (2 предмета (сумма баллов < 130),
-- 3 предмета (сумма баллов < 220),
-- 4 предмета (сумма баллов < 280))
WITH all_required_students AS (
    SELECT st.id,
           st.school_id,
           DATE_PART('year', a.exam_date) AS year_of_exam,
           COUNT(*)                       AS count_of_subjects,
           SUM(e.sum_secondary_points)    AS sum_of_points
    FROM annualexamdata a
             JOIN examresult e ON a.id = e.annual_exam_id
             JOIN student st ON e.student_id = st.id
    GROUP BY st.id, st.school_id, year_of_exam
    HAVING COUNT(*) = 2 and SUM(e.sum_secondary_points) < 140
        or COUNT(*) = 3 and SUM(e.sum_secondary_points) < 220
        or COUNT(*) = 4 and SUM(e.sum_secondary_points) < 320
),
     annual_schools_data AS (
         SELECT distinct on (year_of_exam, school_id) year_of_exam
         FROM all_required_students
     )
SELECT year_of_exam, count(*) as count_of_schools
FROM annual_schools_data
GROUP BY year_of_exam;


-- вывести статистику по возрасту пишущих экзамен учеников: разницу между средним
-- баллом, набранным за определенный год по определенному предмету
WITH age_of_student AS (
    SELECT distinct on (st.passport_series, st.passport_number) st.id,
    (CASE
        WHEN DATE_PART('year', AGE(a.exam_date, st.birthday)) > 17
        THEN 'adult'
        ELSE 'child'
    END) AS adult_child
    FROM timetable t
             INNER JOIN annualexamdata a on t.annual_exam_id = a.id
             INNER JOIN student st on t.student_id = st.id
),
     required_annual_data AS (
         SELECT DATE_PART('year', a.exam_date)        AS year_of_exam,
                s.subject_name,
                aos.adult_child,
                ROUND(AVG(e.sum_secondary_points), 2) AS average_points
         FROM examresult e
                  INNER JOIN annualexamdata a on e.annual_exam_id = a.id
                  INNER JOIN subject s on a.subject_id = s.id
                  INNER JOIN age_of_student aos ON aos.id = e.student_id
         GROUP BY year_of_exam, s.subject_name, aos.adult_child
         ORDER BY year_of_exam, subject_name, adult_child
     )
SELECT required_annual_data.*,
       LEAD(average_points) OVER average_window - average_points AS differences_between_childs_adults
FROM required_annual_data
WINDOW average_window AS (PARTITION BY year_of_exam, subject_name);


