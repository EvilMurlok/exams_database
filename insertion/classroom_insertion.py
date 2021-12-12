from random import choice

from insertion.database import CLASSROOMS


def classroom_insertion(connection, classrooms_per_school=15):
    cur = connection.cursor()
    cur.execute(
        f"SELECT id FROM subject"
    )
    all_subject_id = list(cur.fetchall())
    cur.execute(
        f"SELECT id FROM school"
    )
    all_school_id = list(cur.fetchall())

    # There are number_classrooms_at_school classrooms for each school!
    for school_id in map(lambda item: item[0], all_school_id):
        already_used_numbers = set()
        for _ in range(classrooms_per_school):
            classroom = CLASSROOMS()
            # no equal numbers at the same school!
            while classroom in already_used_numbers:
                classroom = CLASSROOMS()
            already_used_numbers.add(classroom)
            subject_id = choice(all_subject_id)[0]
            cur.execute(
                f"INSERT INTO classroom (classroom_number, subject_id, school_id) "
                f"VALUES ({classroom}, {subject_id}, {school_id})"
            )
    connection.commit()
    print("Classrooms added successfully!")
