import json

from .database import ANNUAL_EXAM_DATA
from .database import EXAM_DATES


def annual_exam_insertion(connection):
    cur = connection.cursor()
    cur.execute(
        f"SELECT id, subject_name FROM subject"
    )
    used_days = {'2019': [], '2020': [], '2021': []}
    # [(id, subject_name), (id, subject_name), ...]
    all_subjects = list(cur.fetchall())
    for subject_id, subject_name in all_subjects:
        annual_exam_data = ANNUAL_EXAM_DATA[subject_name]
        for exam_date, scale_points, tasks, primary_score, secondary_score in annual_exam_data:
            day = exam_date[8: 10]
            while day in used_days[exam_date[:4]]:
                exam_date = exam_date[:4] + EXAM_DATES()
                day = exam_date[8:10]
            used_days[exam_date[:4]].append(day)
            cur.execute(
                f"INSERT INTO annualexamdata (exam_date, scale_conversation_points, "
                f"amount_tasks, passing_primary_score, passing_secondary_score, subject_id) "
                f"VALUES (\'{exam_date}\', \'{json.dumps(scale_points)}\', {tasks}, "
                f"{primary_score}, {secondary_score}, {subject_id})"
            )
    connection.commit()
    print('All exam data added successfully!')
