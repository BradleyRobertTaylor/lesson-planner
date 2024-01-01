require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: "students_and_lessons")
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}, #{params}"
    @db.exec_params(statement, params)
  end

  def all_students_with_offset(offset)
    offset = (offset - 1) * 5
    sql = "SELECT * FROM students ORDER BY last_name, first_name LIMIT 5 OFFSET $1"
    result = query(sql, offset)

    result.map do |tuple|
      tuple_to_student_hash(tuple)
    end
  end

  def all_students
    sql = "SELECT * FROM students ORDER BY last_name, first_name"
    result = query(sql)

    result.map do |tuple|
      tuple_to_student_hash(tuple)
    end
  end

  def find_student(id)
    sql = "SELECT * FROM students WHERE id = $1"
    result = query(sql, id)

    result.map do |tuple|
      tuple_to_student_hash(tuple)
    end.first
  end

  def find_lesson(student_id, lesson_id)
    sql = <<~SQL
      SELECT * FROM lessons WHERE student_id = $1 AND lessons.id = $2
    SQL

    result = query(sql, student_id, lesson_id)
    result.map do |tuple|
      tuple_to_lesson_hash(tuple)
    end.first
  end

  def create_new_student(first, last, instrument)
    sql = <<~SQL
      INSERT INTO students (first_name, last_name, instrument)
      VALUES ($1, $2, $3)
    SQL
    query(sql, first, last, instrument)
  end

  # Returns an array of all lessons for one student ordered by date and time
  def student_lessons(student_id)
    sql = <<~SQL
      SELECT * FROM lessons WHERE student_id = $1
        ORDER BY lessons.date, lessons.start_time
    SQL
    result = query(sql, student_id)

    result.map do |tuple|
      tuple_to_lesson_hash(tuple)
    end
  end

  def student_lessons_with_offset(student_id, offset)
    offset = (offset - 1) * 5
    sql = <<~SQL
      SELECT * FROM lessons WHERE student_id = $1
        ORDER BY lessons.date, lessons.start_time
        LIMIT 5 OFFSET $2
    SQL
    result = query(sql, student_id, offset)

    result.map do |tuple|
      tuple_to_lesson_hash(tuple)
    end
  end

  def update_student(id, first, last, instrument)
    sql = <<~SQL
      UPDATE students
        SET first_name = $2,
            last_name = $3,
            instrument = $4
        WHERE id = $1
    SQL
    query(sql, id, first, last, instrument)
  end

  def delete_student(id)
    sql = "DELETE FROM students WHERE id = $1"
    query(sql, id)
  end

  def update_lesson(student_id, lesson_id, date, start_time, end_time)
    sql = <<~SQL
      UPDATE lessons
        SET "date" = $3,
            start_time = $4,
            end_time = $5
      WHERE student_id = $1 AND lessons.id = $2
    SQL
    query(sql, student_id, lesson_id, date, start_time, end_time)
  end

  def delete_all_students
    sql = "DELETE FROM students"
    query(sql)
  end

  def delete_lesson(student_id, lesson_id)
    sql = "DELETE FROM lessons WHERE student_id = $1 AND lessons.id = $2"
    query(sql, student_id, lesson_id)
  end

  def delete_students_lessons(student_id)
    sql = "DELETE FROM lessons WHERE student_id = $1"
    query(sql, student_id)
  end

  def delete_all_lessons
    sql = "DELETE FROM lessons"
    query(sql)
  end

  def new_lesson(id, date, start_time, end_time)
    sql = <<~SQL
      INSERT INTO lessons (student_id, date, start_time, end_time)
      VALUES ($1, $2, $3, $4)
    SQL
    query(sql, id, date, start_time, end_time)
  end

  # Returns an array of all students lessons ordered by date and time
  def all_students_lessons
    sql = <<~SQL
      SELECT CONCAT(students.first_name, ' ', students.last_name) AS name, lessons.*
        FROM students
          INNER JOIN lessons ON students.id = lessons.student_id
        ORDER BY lessons.date, lessons.start_time
    SQL
    result = query(sql)
    result.map do |tuple|
      { name: tuple["name"],
        date: tuple["date"],
        start_time: tuple["start_time"],
        end_time: tuple["end_time"] }
    end
  end

  def all_students_future_lessons
    sql = <<~SQL
      SELECT CONCAT(students.first_name, ' ', students.last_name) AS name, lessons.*
        FROM students
          INNER JOIN lessons ON students.id = lessons.student_id
        WHERE NOW() < lessons.date
        ORDER BY lessons.date, lessons.start_time
    SQL
    result = query(sql)
    result.map do |tuple|
      { name: tuple["name"],
        date: tuple["date"],
        start_time: tuple["start_time"],
        end_time: tuple["end_time"] }
    end
  end

  def all_students_future_lessons_with_offset(offset)
    offset = (offset - 1) * 5
    sql = <<~SQL
      SELECT CONCAT(students.first_name, ' ', students.last_name) AS name, lessons.*
        FROM students
          INNER JOIN lessons ON students.id = lessons.student_id
        WHERE NOW() < lessons.date
        ORDER BY lessons.date, lessons.start_time
        LIMIT 5 OFFSET $1
    SQL
    result = query(sql, offset)
    result.map do |tuple|
      { name: tuple["name"],
        date: tuple["date"],
        start_time: tuple["start_time"],
        end_time: tuple["end_time"] }
    end
  end

  private

  def tuple_to_lesson_hash(tuple)
    { lesson_id: tuple["id"].to_i,
      date: tuple["date"],
      start_time: tuple["start_time"],
      end_time: tuple["end_time"] }
  end

  def tuple_to_student_hash(tuple)
    { student_id: tuple["id"].to_i,
      first_name: tuple["first_name"],
      last_name: tuple["last_name"],
      instrument: tuple["instrument"] }
  end
end
