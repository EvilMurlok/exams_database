from random import choice, randint

from insertion.database import CITIES, STREETS, HOUSES, HOUSINGS, FLATS


def address_insertion(connection, number=200):
    cursor = connection.cursor()
    for _ in range(number):
        city, street, house, housing, flat = choice(CITIES), choice(STREETS), HOUSES(), HOUSINGS(), FLATS()
        cursor.execute(
            f"INSERT INTO Address (City_name, Street, House, Housing, Flat) "
            f"VALUES (\'{city}\', \'{street}\', {house}, {housing}, {flat})"
        )
    connection.commit()
    print("Addresses added successfully!")


def address_school_insertion(connection, number=40):
    cursor = connection.cursor()
    for _ in range(number):
        if randint(0, 1):
            city, street, house, = choice(CITIES), choice(STREETS), HOUSES()
            cursor.execute(
                f"INSERT INTO Address (City_name, Street, House) "
                f"VALUES (\'{city}\', \'{street}\', {house})"
            )
        else:
            city, street, house, housing = choice(CITIES), choice(STREETS), HOUSES(), HOUSINGS()
            cursor.execute(
                f"INSERT INTO Address (City_name, Street, House, Housing) "
                f"VALUES (\'{city}\', \'{street}\', {house}, {housing})"
            )
    connection.commit()
    print("School addresses added successfully!")
