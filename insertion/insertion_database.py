import psycopg2

from local_settings import DATABASE, USER, PASSWORD, HOST, PORT
from insertion.address_insertion import address_insertion
from insertion.address_insertion import address_school_insertion
from insertion.school_insertion import school_insertion
from insertion.student_insertion import student_insertion
from insertion.subject_insertion import subject_insertion
from insertion.classroom_insertion import classroom_insertion
from insertion.teacher_insertion import teacher_insertion
from insertion.annual_exam_insertion import annual_exam_insertion
from insertion.timetable_insertion import timetable_insertion
from insertion.exam_result_insertion import result_insertion

con = psycopg2.connect(
    database=DATABASE,
    user=USER,
    password=PASSWORD,
    host=HOST,
    port=PORT
)

print("Connection created successfully!")

address_insertion(connection=con, number=200) # номер отсюда должен совпадать с номером
address_school_insertion(connection=con, number=40)
school_insertion(connection=con)
student_insertion(connection=con, number=200) # отсюда!
subject_insertion(connection=con)
classroom_insertion(connection=con, classrooms_per_school=20)
teacher_insertion(connection=con, teachers_per_school=25)
annual_exam_insertion(connection=con)
timetable_insertion(connection=con)
result_insertion(connection=con)

print('Everything is all right!')
con.close()
