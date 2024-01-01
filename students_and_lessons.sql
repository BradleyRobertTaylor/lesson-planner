CREATE TABLE students (
  id serial PRIMARY KEY,
  first_name text NOT NULL,
  last_name text NOT NULL,
  instrument text NOT NULL
);

CREATE TABLE lessons (
  id serial PRIMARY KEY,
  "date" date NOT NULL,
  start_time time NOT NULL,
  end_time time NOT NULL,
  student_id int REFERENCES students (id)
    ON DELETE CASCADE
);

INSERT INTO students (first_name, last_name, instrument)
VALUES ('Bradley', 'Taylor', 'Cello'),
       ('Elisha', 'Taylor', 'Voice'),
       ('Patches', 'Taylor', 'Piano'),
       ('London', 'Taylor', 'Piano'),
       ('Maliyah', 'Taylor', 'Violin'),
       ('Patsy', 'Price', 'Flute'),
       ('Alexandra', 'Dickens', 'Clarinet'),
       ('Jeremy', 'Russo', 'Cello'),
       ('John', 'Smith', 'Viola'),
       ('Curtis', 'Jackson', 'Voice'),
       ('Aubrey', 'Graham', 'Voice')
;

INSERT INTO lessons ("date", start_time, end_time, student_id)
VALUES ('2022-12-7', '12:00', '13:00', 1),
       ('2022-12-8', '12:00', '13:00', 1),
       ('2022-12-14', '12:00', '13:00', 1),
       ('2022-12-20', '12:00', '13:00', 1),
       ('2022-12-23', '12:00', '13:00', 1),
       ('2022-12-11', '12:00', '13:00', 1),
       ('2022-12-30', '13:00', '14:00', 2),
       ('2022-12-28', '16:00', '17:00', 2),
       ('2022-12-23', '18:00', '19:00', 2),
       ('2022-11-18', '8:00', '9:00', 2),
       ('2022-11-16', '12:00', '13:00', 2),
       ('2022-11-30', '13:30', '14:00', 2),
       ('2022-12-22', '16:00', '17:00', 2),
       ('2022-11-23', '8:00', '9:00', 3),
       ('2022-11-28', '14:00', '15:00', 3),
       ('2022-11-30', '14:00', '15:00', 3),
       ('2022-11-14', '14:00', '15:00', 3),
       ('2022-11-20', '14:00', '15:00', 6),
       ('2022-10-29', '14:00', '15:00', 6),
       ('2022-10-23', '14:00', '15:00', 6),
       ('2022-10-24', '12:00', '13:00', 9),
       ('2022-10-22', '12:00', '13:00', 10),
       ('2022-12-14', '12:00', '13:00', 11),
       ('2022-12-16', '12:00', '13:00', 11),
       ('2022-12-20', '12:00', '13:00', 8),
       ('2022-12-23', '12:00', '13:00', 8),
       ('2022-12-10', '12:00', '13:00', 8)
;
