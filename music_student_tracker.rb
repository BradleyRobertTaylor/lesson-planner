require "sinatra"
require "sinatra/content_for"
require "tilt/erubis"

require_relative "database_persistence"

configure do
  enable :sessions
  set :session_secret, "secret"
  set :erb, escape_html: true
end

configure(:development) do
  require "sinatra/reloader"
  also_reload "database_persistence.rb"
end

helpers do
  def error_for_new_student(first, last, instrument)
    [first, last, instrument].each do |text|
      if !(1..100).cover?(text.size)
        return "All inputs must be between 1 to 100 characters."
      end
    end
    nil
  end

  def error_for_new_lesson(date, start_time, end_time)
    "Each field must be entered." if error_for_new_student(date, start_time, end_time)
  end

  def load_student(student_id)
    student = @storage.find_student(student_id)
    return student if student

    session[:error] = "The specified student was not found."
    redirect "/students"
  end

  def load_lesson(student_id, lesson_id)
    lesson = @storage.find_lesson(student_id, lesson_id)
    return lesson if lesson

    session[:error] = "The specified lesson was not found."
    redirect "/students/#{student_id}"
  end

  def display_name(student)
    "#{student[:first_name]} #{student[:last_name]}"
  end

  def display_time(time)
    hours, minutes = split_time(time)
    result = Time.new(2022, 1, 1, hours, minutes).strftime("%I:%M %P")
    result.slice!(0) if result[0, 2].to_i < 10
    result
  end

  def display_date(date)
    year, month, day = split_date(date)
    result = Time.new(year, month, day)
    result = result.strftime("%m/%d/%y")
  end

  def split_date(date)
    date.split("-")
  end

  def split_time(time)
    time.split(":")
  end

  def valid_page(page, elements, student_id=nil)
    if page < 1 || page > max_page(elements)
      case elements.first.keys[0]
      when :lesson_id
        session[:error] = "That is not a valid page."
        redirect "/students/#{student_id}"
      when :student_id
        session[:error] = "That is not a valid page."
        redirect "/students"
      when :name
        session[:error] = "That is not a valid page."
        redirect "/schedule"
      end
    end
  end

  def max_page(elements)
    elements = elements.size
    loop do
      break if elements % 5 == 0
      elements += 1
    end
    elements / 5
  end

  def check_login
    session[:last_page] = request.path_info
    unless session[:user_name]
      session[:error] = "You have to be logged in to do that."
      halt erb :login
    end
  end

  def validate_params
    # Validate if student_id or lesson_id contains non-digit characters
    if /\D+/ =~ params[:student_id]
      session[:error] = "That student page is invalid."
      redirect "/students"
    elsif /\D+/ =~ params[:lesson_id]
      session[:error] = "That lesson page is invalid."
      redirect "/students/#{params[:student_id]}"
    end
  end
end

before do
  @storage = DatabasePersistence.new(logger)
end

# Login form
get "/login" do
  erb :login
end

# Submit login information
post "/login" do
  if params[:name] == "admin" && params[:password] == "admin"
    session[:user_name] = params[:name]
    redirect session.delete(:last_page) if session[:last_page]
    redirect "/students"
  else
    session[:error] = "Wrong username or password"
    erb :login
  end
end

# Submit logout form
post "/logout" do
  session.delete(:user_name)
  redirect "/login"
end

get "/" do
  redirect "/students"
end

# Display all the students
get "/students" do
  redirect "/login" unless session[:user_name]

  @all_students = @storage.all_students
  @page = params["page"].to_i
  @page = 1 unless params["page"]
  if @page == 1
    @students = @all_students[0, 5]
  elsif params["page"]
    valid_page(@page, @all_students)
    @students = @storage.all_students_with_offset(@page)
  end
  erb :students
end

# Add a new student
post "/students" do
  first_name = params[:first_name].strip
  last_name = params[:last_name].strip
  instrument = params[:instrument].strip

  error = error_for_new_student(first_name, last_name, instrument)
  if error
    session[:error] = error
    erb :new_student
  else
    @storage.create_new_student(first_name, last_name, instrument)
    session[:success] = "The new student was added."
    redirect "/students"
  end
end

# Render form for adding a new student
get "/students/new" do
  check_login
  erb :new_student
end

# Render form for editing a new student
get "/students/:student_id/edit" do
  validate_params
  check_login
  @student = load_student(params[:student_id])
  erb :edit_student
end

# Delete a student
post "/students/:student_id/destroy" do
  student_id = params[:student_id].to_i
  @storage.delete_student(student_id)
  session[:success] = "The student has been deleted."
  redirect "/students"
end

# Update information for a student
post "/students/:student_id/edit" do
  student_id = params[:student_id].to_i
  @student = load_student(student_id)
  first_name = params[:first_name].strip
  last_name = params[:last_name].strip
  instrument = params[:instrument].strip

  error = error_for_new_student(first_name, last_name, instrument)
  if error
    session[:error] = error
    erb :edit_student
  else
    @storage.update_student(student_id, first_name, last_name, instrument)
    session[:success] = "The student has been updated."
    redirect "/students"
  end
end

# Delete all students
post "/students/destroy_all" do
  @storage.delete_all_students
  session[:success] = "All students have been deleted."
  redirect "/students"
end

# Display lessons for a student
get "/students/:student_id" do
  validate_params

  check_login
  student_id = params[:student_id]
  @all_lessons = @storage.student_lessons(student_id)
  @student = load_student(student_id)
  @page = params["page"].to_i
  @page = 1 unless params["page"]

  if @page == 1
    @lessons = @all_lessons[0, 5]
  elsif params["page"]
    valid_page(@page, @all_lessons, student_id)
    @lessons = @storage.student_lessons_with_offset(student_id, @page)
  end

  erb :student
end

# Add a new lesson
post "/students/:student_id" do
  student_id = params[:student_id]
  @student = load_student(student_id)
  date = params[:date]
  start_time = params[:start_time]
  end_time = params[:end_time]

  error = error_for_new_lesson(date, start_time, end_time)
  if error
    session[:error] = error
    erb :new_lesson
  else
    @storage.new_lesson(student_id, date, start_time, end_time)
    session[:success] = "The lesson has been added."
    redirect "/students/#{student_id}"
  end
end

# Display form for adding a new lesson
get "/students/:student_id/lesson/new" do
  validate_params
  check_login
  @student = load_student(params[:student_id])
  erb :new_lesson
end

# Display form for editing a lesson
get "/students/:student_id/lesson/:lesson_id/edit" do
  validate_params
  check_login
  @student = load_student(params[:student_id])
  @lesson = load_lesson(params[:student_id], params[:lesson_id])
  erb :edit_lesson
end

# Delete all lessons from one student
post "/students/:student_id/lesson/destroy_all" do
  student_id = params[:student_id]
  @student = load_student(student_id)
  @storage.delete_students_lessons(student_id)
  session[:success] = "All of #{display_name(@student)}'s lessons were deleted."
  redirect "/students/#{student_id}"
end

# Update a lesson
post "/students/:student_id/lesson/:lesson_id" do
  student_id = params[:student_id]
  @student = load_student(student_id)
  date = params[:date]
  start_time = params[:start_time]
  end_time = params[:end_time]

  error = error_for_new_lesson(date, start_time, end_time)
  if error
    session[:error] = error
    erb :edit_lesson
  else
    @storage.update_lesson(student_id, params[:lesson_id], date, start_time, end_time)
    session[:success] = "The lesson has been updated."
    redirect "/students/#{student_id}"
  end
end

# Delete a lesson
post "/students/:student_id/lesson/:lesson_id/destroy" do
  student_id = params[:student_id]
  @storage.delete_lesson(student_id, params[:lesson_id])
  session[:success] = "The lesson has been deleted."
  redirect "/students/#{student_id}"
end

# Display all lessons of all students
get "/schedule" do
  check_login
  @all_lessons = @storage.all_students_future_lessons
  @page = params["page"].to_i
  @page = 1 unless params["page"]

  if @page == 1
    @lessons = @all_lessons[0, 5]
  elsif params["page"]
    valid_page(@page, @all_lessons)
    @lessons = @storage.all_students_future_lessons_with_offset(@page)
  end
  erb :schedule
end

# Delete all lessons
post "/students/lesson/destroy_all" do
  @storage.delete_all_lessons
  session[:success] = "The schedule has been cleared."
  redirect "/schedule"
end

not_found do
  session[:error] = "That page is nowhere to be found."
  redirect "/students"
end
