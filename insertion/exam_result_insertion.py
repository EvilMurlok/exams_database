from insertion.database import DAYS_RESULT, RANDOM_RESULTS


def result_insertion(connection):
    # сначала получим id всех студентов
    cur = connection.cursor()
    cur.execute(
        f"SELECT id FROM student"
    )
    all_students_id = list(cur.fetchall())
    all_students_id = list(map(lambda exam: exam[0], all_students_id))
    # all_exams = list(map(lambda exam: exam[1], all_exams_timetable))
    # all_dates = list(map(lambda exam: exam[2], all_exams_timetable))
    for student_id in all_students_id:
        # для каждого студента берем экзамены, которые он пишет
        cur.execute(
            f"SELECT t.annual_exam_id, a.exam_date, a.subject_id FROM timetable AS t "
            f"INNER JOIN annualexamdata a on t.annual_exam_id = a.id "
            f"WHERE t.student_id = {student_id}"
        )
        all_student_exams = list(cur.fetchall())
        # достанем сразу все предметы
        cur.execute(
            f"SELECT subject_name FROM subject"
        )
        all_subjects = list(cur.fetchall())
        for student_exam_id, student_date, subject_id in all_student_exams:
            result_date = DAYS_RESULT(student_date)
            subject_name = all_subjects[subject_id - 1]
            json_result, sum_primary_score, sum_secondary_score = RANDOM_RESULTS(subject_name[0])
            # добавляем в таблицу, что сгенерили
            cur.execute(
                f"INSERT INTO examresult (date_of_result, tasks, "
                f"sum_primary_points, sum_secondary_points, student_id, annual_exam_id) "
                f"VALUES (\'{result_date}\', \'{json_result}\', {sum_primary_score}, "
                f"{sum_secondary_score}, {student_id}, {student_exam_id})"
            )
    connection.commit()
    print("Results added successfully!")
