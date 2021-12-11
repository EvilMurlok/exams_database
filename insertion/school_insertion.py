from random import choice

from .database import MOSCOW_SCHOOLS, NOT_MOSCOW_SCHOOLS


def school_insertion(connection, id_start=201, id_stop=241):
    cur = connection.cursor()
    not_used_moscow, not_used_not_moscow = list(range(len(MOSCOW_SCHOOLS))), list(range(len(NOT_MOSCOW_SCHOOLS)))
    for cur_address_id in range(id_start, id_stop):
        cur.execute(
            f"SELECT city_name from address where id = {cur_address_id}"
        )
        cur_city = cur.fetchone()
        if cur_city[0] != 'Москва':
            index = choice(not_used_not_moscow)
            not_used_not_moscow.remove(index)
            school = NOT_MOSCOW_SCHOOLS[index]
        else:
            index = choice(not_used_moscow)
            not_used_moscow.remove(index)
            school = MOSCOW_SCHOOLS[index]
        cur.execute(
            f"INSERT INTO school (school_name, address_id) "
            f"VALUES (\'{school}\', {cur_address_id})"
        )
    connection.commit()
    print('Schools were added successfully!')
