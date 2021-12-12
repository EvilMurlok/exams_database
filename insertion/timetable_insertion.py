from random import randint, choice
from collections import defaultdict

from insertion.database import DESK_NUMBERS


def last_element(lst, item):
    for i in reversed(range(len(lst))):
        if lst[i] == item:
            return i
    raise ValueError("{} is not in list".format(item))


def timetable_insertion(connection):
    cur = connection.cursor()
    # {'year1': {'school1' : [(), (), ... ], 'school2': [(), (), ... ], ...}, 'date2': {}, ... }
    used = {2019: defaultdict(list), 2020: defaultdict(list), 2021: defaultdict(list)}
    used_desks_in_classroom = {2019: defaultdict(list), 2020: defaultdict(list), 2021: defaultdict(list)}
    # берем студента и его город
    cur.execute(
        f"SELECT st.id, a.city_name FROM student AS st INNER JOIN address AS a ON st.address_id = a.id"
    )
    # [(student_id, city_name), (student_id, city_name), ...]
    all_students_data = list(cur.fetchall())
    for student_data in all_students_data:
        student_id = student_data[0]
        # берем все школы того же города
        cur.execute(
            f"SELECT sc.id FROM school AS sc INNER JOIN address a ON sc.address_id = a.id "
            f"WHERE a.city_name = \'{student_data[1]}\'"
        )
        all_available_schools_id = list(map(lambda sch: sch[0], cur.fetchall()))
        amount_of_subjects = randint(2, 4)
        year_of_exam = randint(2019, 2021)
        # берем все экзамены выпавшего года!
        cur.execute(
            f"SELECT id, exam_date FROM annualexamdata WHERE date_part('year', exam_date) = {year_of_exam}"
        )
        all_available_exams = list(cur.fetchall())
        used_date_exams = []
        for i in range(amount_of_subjects):
            annual_exam = choice(all_available_exams)
            while annual_exam[1] in used_date_exams:
                annual_exam = choice(all_available_exams)
            annual_exam_id, _ = annual_exam
            all_available_exams.remove(annual_exam)
            school_id = choice(all_available_schools_id)
            cur.execute(
                f"SELECT id FROM teacher WHERE school_id = {school_id}"
            )
            all_available_teachers_id = list(map(lambda teacher: teacher[0], cur.fetchall()))
            cur.execute(
                f"SELECT id FROM classroom WHERE school_id = {school_id}"
            )
            all_available_classrooms_id = list(map(lambda classroom: classroom[0], cur.fetchall()))
            if used[year_of_exam].get(school_id) is None:
                # школа пуста, можно ее спокойно использовать!
                desk_number = DESK_NUMBERS()
                classroom_id = choice(all_available_classrooms_id)
                teacher_id = choice(all_available_teachers_id)
                used_desks_in_classroom[year_of_exam][classroom_id] += [desk_number, ]
                cur.execute(
                    f"INSERT INTO timetable (desk_number, student_id, "
                    f"annual_exam_id, school_id, teacher_id, classroom_id) "
                    f"VALUES ({desk_number}, {student_id}, {annual_exam_id}, {school_id}, {teacher_id}, {classroom_id})"
                )
                used[year_of_exam][school_id] += [(annual_exam_id, teacher_id, classroom_id), ]
            else:
                school_data = used[year_of_exam][school_id]
                school_annual_exams = list(map(lambda ex_data: ex_data[0], school_data))
                school_teachers = list(map(lambda ex_data: ex_data[1], school_data))
                school_classrooms = list(map(lambda ex_data: ex_data[2], school_data))
                # тут возможны 2 варианта: либо по данному экзамену уже назначена аудитория с преподом, либо нет!
                # если экзамен уже есть, то здесь возможен вариант, когда аудитория уже переполнена
                # ( то есть все 18 парт заняты) и надо другого препода и другую аудиторию!
                # при этом важно искать имено с конца списка, потому что добавляем потом в конец!
                if (annual_exam_id in school_annual_exams
                    and
                    len(used_desks_in_classroom[year_of_exam][
                            school_classrooms[last_element(school_annual_exams, annual_exam_id)]]) == 18) \
                        or (annual_exam_id not in school_annual_exams):

                    new_teacher_id = choice(all_available_teachers_id)
                    while new_teacher_id in school_teachers:  # задействованные в этой школе препы
                        new_teacher_id = choice(all_available_teachers_id)
                    new_classroom_id = choice(all_available_classrooms_id)
                    while new_classroom_id in school_classrooms:
                        new_classroom_id = choice(all_available_classrooms_id)
                    desk_number = DESK_NUMBERS()
                    used_desks_in_classroom[year_of_exam][new_classroom_id] += [desk_number, ]
                    cur.execute(
                        f"INSERT INTO timetable (desk_number, student_id, "
                        f"annual_exam_id, school_id, teacher_id, classroom_id) "
                        f"VALUES ({desk_number}, {student_id}, {annual_exam_id}, {school_id}, "
                        f"{new_teacher_id}, {new_classroom_id})"
                    )
                    used[year_of_exam][school_id] += [(annual_exam_id, new_teacher_id, new_classroom_id), ]
                else:
                    # добавим просто в ту аудиторию за другую парту!
                    required_index = last_element(school_annual_exams, annual_exam_id)
                    desk_number = DESK_NUMBERS()
                    while desk_number in used_desks_in_classroom[year_of_exam][school_classrooms[required_index]]:
                        desk_number = DESK_NUMBERS()
                    used_desks_in_classroom[year_of_exam][school_classrooms[required_index]] += [desk_number, ]
                    cur.execute(
                        f"INSERT INTO timetable (desk_number, student_id, "
                        f"annual_exam_id, school_id, teacher_id, classroom_id) "
                        f"VALUES ({desk_number}, {student_id}, {annual_exam_id}, {school_id}, "
                        f"{school_teachers[required_index]}, {school_classrooms[required_index]})"
                    )

    connection.commit()
    print("Timetable created successfully!")