from random import choice, randint

from .database import FIRST_FEMALE_NAMES, SECOND_FEMALE_NAMES, FEMALE_PATRONYMICS
from .database import FIRST_MALE_NAMES, SECOND_MALE_NAMES, MALE_PATRONYMICS


def teacher_insertion(connection, teachers_per_school=3):
    cur = connection.cursor()
    cur.execute(
        f"SELECT id FROM school"
    )
    all_schools = list(map(lambda item: item[0], cur.fetchall()))
    cur.execute(
        f"SELECT id FROM subject"
    )
    all_subjects = list(map(lambda item: item[0], cur.fetchall()))
    for school_id in all_schools:
        already_used_subjects = set()
        for _ in range(teachers_per_school):
            sex = randint(0, 1)
            first_name = choice(FIRST_FEMALE_NAMES) if sex else choice(FIRST_MALE_NAMES)
            second_name = choice(SECOND_FEMALE_NAMES) if sex else choice(SECOND_MALE_NAMES)
            patronymic = choice(FEMALE_PATRONYMICS) if sex else choice(MALE_PATRONYMICS)
            subject_id = choice(all_subjects)
            already_used_subjects.add(subject_id)
            cur.execute(
                f"INSERT INTO teacher (first_name, surname, patronymic, school_id, subject_id) VALUES "
                f"(\'{first_name}\', \'{second_name}\', \'{patronymic}\', {school_id}, {subject_id})"
            )
    connection.commit()
    print("Teachers added successfully!")
