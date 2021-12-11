from .database import SUBJECTS


def subject_insertion(connection):
    cur = connection.cursor()
    for sbj in SUBJECTS:
        cur.execute(
            f"INSERT INTO subject (subject_name) VALUES (\'{sbj}\')"
        )
    connection.commit()
    print('Subjects created successfully!')
