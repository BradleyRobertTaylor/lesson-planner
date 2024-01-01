Ruby Version: 2.7.6
Browser tested on: Google Chrome 106.0.5249.119
PostgreSQL: 14.5

To run this application download the files. You'll need to have the `bundler` gem
installed. Use the command `gem install bundler` if you don't have it. CD into the
`lesson_planner_project` directory and run `bundle install` to install the projects
dependencies using the Gemfile.

Make sure you have PostgreSQL installed and run the following command to create the
database:

`createdb students_and_lessons`

After creating this database run the following command to import the tables and seed
data:

`psql -d students_and_lessons < students_and_lessons.sql`

Run the following command to start the application:
`bundle exec ruby music_student_tracker.rb`

View it in your browser at `localhost:4567`.
To begin using the application you first have to login with:

User Name: admin
Password: admin

This is a very simple login verification without any encryption since this was not
required for the project.

For my project I have created a Sinatra application that is meant to keep track
of a music teachers students and lessons. The user can enter students names and the
instrument they play. They can also add lessons with a date, start time, and end
time for the lesson. I decided to allow the user to put in multiple lessons that
are at the same time and multiple names that are the same. I allowed this since
in the real world people can sometimes have the same names and sometimes people
may want to schedule music lessons at the same time. The databases reflect that each
student can have many lessons. This represents the 1:Many relationship in the data
of this application.

When displaying the home students page. Students are ordered by last name and then
first name. When displaying a students lesson page. The lessons are ordered by date
and time. When displaying the schedule page lessons are displayed ordered by date
and time. The schedule page only display lessons that are after the current time
and date. Each page that displays these rows of the database are limited to 5 per
page.

# Data Structures

#

# Student with lessons

# { student_id: 1,

# first_name: "Bradley",

# last_name: "Taylor",

# instrument: "Cello",

# lessons: [{lesson_id: 1, date: 2022-11-28, start_time: 04:00, end_time: 05:00}

# {lesson_id: 2, date: 2022-11-28, start_time: 04:00, end_time: 05:00}]

# Student

# { student_id: 1,

# first_name: "Bradley",

# last_name: "Taylor",

# instrument: "Cello" }

# Lesson

# { lesson_id: 1, date: 2022-11-28, start_time: 04:00, end_time: 05:00 }
