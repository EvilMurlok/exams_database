drop table Timetable;
drop table ExamResult;
drop table AnnualExamData;
drop table Teacher;
drop table Classroom;
drop table Subject;
drop table Student;
drop table School;
drop table Address;


create table if not exists Address(
	Id bigserial not null primary key,
	City_name varchar(30) not null,
	Street varchar(50) not null,
	House integer check (House > 0) not null,
	Housing integer check (Housing > 0),
	Flat integer check (Flat > 0)
);

create table if not exists School(
	Id serial not null primary key,
	School_name varchar(255) not null,
	Address_id bigint not null references Address (Id) on delete cascade on update cascade -- у школы обязательно есть адрес
);


create table if not exists Student
(
	Id bigserial not null primary key,
	First_name varchar(25) not null,
	Surname varchar(25) not null,
	Patronymic varchar(25), --отчества запросто может не быть
	Birthday date not null, -- тут обычная дата , так как время рождения, как правило, никто не помнит
	Passport_series int not null check (Passport_series > 999 and Passport_series < 10000), -- 4-х начное число
	Passport_number bigint not null check (Passport_number > 99999 and Passport_number < 1000000), -- 6-ти значное число
	Address_id bigint not null references Address (Id) on delete cascade on update cascade, -- адрес проживания
	School_id int references School(Id) on delete set null on update cascade, -- может не оказаться школы, если ученик пересдает егэ через год
	unique (Passport_series, Passport_number) -- паспорта у всех уникальны
);

create table if not exists Subject(
	Id serial not null primary key,
	Subject_name varchar(30) not null unique -- предмет в отдельной таблице, как того требует 3 НФ
);


create table if not exists Classroom(
	Id bigserial not null primary key,
	Classroom_number int not null check (Classroom_number > 0),
	Subject_id int not null references Subject(Id) on delete set null on update cascade, -- класс обязаельно соответствует какому-то предету
	School_id int not null references School(Id) on delete cascade on update cascade -- класс обязательно находится в какой-то школе
);

create table if not exists Teacher(
	Id bigserial not null primary key,
	First_name varchar(25) not null,
	Surname varchar(25) not null,
	Patronymic varchar(25), -- отчества может не быть
	School_id int references School(Id) on delete set null on update cascade, -- может не работать ни в какой школе
	Subject_id int not null references Subject(Id) on delete cascade on update cascade -- каждый учитель ведет уроки по конкретному предмету
);

create table if not exists AnnualExamData(
	Id serial not null primary key,
	Exam_date timestamp not null check (date_part('year', Exam_date) > 2000), -- дата экзамена в конкретном году с точностью до времени, ЕГЭ ввели в 2000 году
	Scale_conversation_points json, -- шкала перевода баллов, храниться будет в json-формате, может догуружаться в процессе, Вы говорили создать именно json
	Amount_tasks int not null check (Amount_tasks > 0), -- количество заданий всегда известно заранее и должно быть задано
	Passing_primary_score int not null check (Passing_primary_score > 0 and Passing_primary_score <= 100), -- аналогично и проходные баллы (перв.
	Passing_secondary_score int not null check (Passing_secondary_score > 0 and Passing_secondary_score <= 100), --  и вторич.) устанавливаются сразу
	Subject_id int not null references Subject(Id) on delete cascade on update cascade  -- у экзамена не может отсутсвовать предмета,
																						-- по которому он сдается
);

create table if not exists ExamResult(
	Id bigserial not null primary key,
	Date_of_result timestamp,
	Tasks json, -- разбалловка по заданиям, сколько баллов набрано по каждому заданию, Вы говорили создать именно json
	Sum_primary_points int  default 0 check (Sum_primary_points >= 0), -- сумма перыичных баллов
	Sum_secondary_points int default 0 check (Sum_secondary_points >= 0), -- сумма по 100-бальной шкале
	Student_id bigint references Student(Id) on delete set null on update cascade,
	Annual_exam_id int references AnnualExamData(Id) on delete set null on update cascade,
	unique (Student_id, Annual_exam_id) -- не может быть у одного ученика по одинаковому предмету двух результатов
);

create table if not exists Timetable(
	Id bigserial not null primary key,
	Desk_number smallint check (Desk_number > 0 and Desk_number < 19), -- когда станет известна школа, можно подумать и о размещении (поле не обязательное)
	Student_id bigint references Student(Id) on delete cascade on update cascade, -- ученик сразу известен, иначе какой-то абсурд
	Annual_exam_id int references AnnualExamData(Id) on delete cascade on update cascade, --предметы ученики выбирают до 1 декабря(поле обязательное)
	School_id int references School(Id) on delete set null on update cascade, -- школа,
	Teacher_id bigint references Teacher(Id) on delete set null on update cascade, -- наблюдатель,
	Classroom_id bigint references Classroom(Id) on delete set null on update cascade, -- аудитория, где пишется экзамен,
																					-- определяются в последние моменты (они не обязательные)
	unique (Student_id, Annual_exam_id) -- один ученик может писать только ОДИН экзамен по конкретному предмету
);


