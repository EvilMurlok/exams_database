from random import randint, choice
from copy import copy

from insertion.database import FIRST_FEMALE_NAMES, SECOND_FEMALE_NAMES, FEMALE_PATRONYMICS
from insertion.database import FIRST_MALE_NAMES, SECOND_MALE_NAMES, MALE_PATRONYMICS
from insertion.database import CITIES, BIRTHDAYS, PASSPORT_NUMBERS, PASSPORT_SERIES


def student_insertion(connection, number=200):
    """Город школы такой же, как и город проживания ученика, иначе бред!"""
    cur = connection.cursor()
    cities = copy(CITIES)
    # [(id, city_name), (id, city_name), ]
    cur.execute(
        f"SELECT id, city_name FROM address WHERE flat IS NOT NULL"
    )
    available_student_addresses = list(cur.fetchall())
    for _ in range(number):
        sex = randint(0, 1)  # пол ученика
        first_name = choice(FIRST_FEMALE_NAMES) if sex else choice(FIRST_MALE_NAMES)
        second_name = choice(SECOND_FEMALE_NAMES) if sex else choice(SECOND_MALE_NAMES)
        patronymic = choice(FEMALE_PATRONYMICS) if sex else choice(MALE_PATRONYMICS)
        birthday = BIRTHDAYS()
        passport_series = PASSPORT_SERIES()
        passport_numbers = PASSPORT_NUMBERS()
        student_city = choice(cities)

        student_address_id = choice(list(filter(lambda address: address[1] == student_city,
                                                available_student_addresses)))[0]
        # [(sc.id,), (sc.id, )]
        cur.execute(
            f"SELECT sc.id from address AS a inner join school AS sc"
            f" on a.id = sc.address_id and a.city_name = \'{student_city}\'"
        )
        available_schools = list(cur.fetchall())
        student_school_id = choice(available_schools)[0]
        cur.execute(
            f"INSERT INTO student (first_name, surname, patronymic, birthday,"
            f" passport_series, passport_number, address_id, school_id) "
            f"VALUES (\'{first_name}\', \'{second_name}\', \'{patronymic}\', \'{birthday}\', {passport_series}, "
            f"{passport_numbers}, {student_address_id}, {student_school_id})"
        )
        available_student_addresses.remove((student_address_id, student_city))
        if len(list(filter(lambda address: address[1] == student_city, available_student_addresses))) == 0:
            cities.remove(student_city)

    connection.commit()
    print("Students added successfully!")
