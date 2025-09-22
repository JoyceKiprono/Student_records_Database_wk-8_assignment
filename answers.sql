-- Create the database
CREATE DATABASE student_records_db
  CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

  USE student_records_db;
  -- Table: departments
  CREATE TABLE departments (
  department_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  code VARCHAR(10) NOT NULL UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Table: instructors
-- Each instructor optionally belongs to a department
-- department_id is nullable; if dept removed instructor stays (dept set to NULL)

CREATE TABLE instructors (
  instructor_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  hire_date DATE,
  department_id INT DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_instructor_dept FOREIGN KEY (department_id)
    REFERENCES departments(department_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Table: students
-- Master record for students

CREATE TABLE students (
  student_id INT AUTO_INCREMENT PRIMARY KEY,
  student_number VARCHAR(20) NOT NULL UNIQUE, -- university roll number
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  email VARCHAR(100) UNIQUE,
  phone VARCHAR(20),
  birth_date DATE,
  enrollment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status ENUM('active','inactive','graduated','suspended') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Table: student_addresses
-- One-to-one relationship with students: student_id is PK and FK
CREATE TABLE student_addresses (
  student_id INT PRIMARY KEY,
  address_line1 VARCHAR(255) NOT NULL,
  address_line2 VARCHAR(255),
  city VARCHAR(100) NOT NULL,
  state VARCHAR(100),
  postal_code VARCHAR(20),
  country VARCHAR(100) DEFAULT 'Kenya',
  CONSTRAINT fk_address_student FOREIGN KEY (student_id)
    REFERENCES students(student_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Table: courses
-- Each course belongs to a department. Optionally has a lead instructor.
CREATE TABLE courses (
  course_id INT AUTO_INCREMENT PRIMARY KEY,
  course_code VARCHAR(10) NOT NULL UNIQUE,
  title VARCHAR(150) NOT NULL,
  description TEXT,
  credits TINYINT NOT NULL DEFAULT 3,
  department_id INT NOT NULL,
  instructor_id INT DEFAULT NULL, -- lead instructor (optional)
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_course_dept FOREIGN KEY (department_id)
    REFERENCES departments(department_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT fk_course_instructor FOREIGN KEY (instructor_id)
    REFERENCES instructors(instructor_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Table: enrollments
-- Junction table: students <-> courses (many-to-many)
-- Unique constraint prevents duplicate enrollments per student/course/semester/year
CREATE TABLE enrollments (
  enrollment_id INT AUTO_INCREMENT PRIMARY KEY,
  student_id INT NOT NULL,
  course_id INT NOT NULL,
  semester ENUM('Spring','Summer','Fall','Winter') NOT NULL,
  year YEAR NOT NULL,
  grade VARCHAR(4), -- store letter grade or NULL if not graded yet
  enrollment_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_enrollment UNIQUE (student_id, course_id, semester, year),
  CONSTRAINT fk_enrollment_student FOREIGN KEY (student_id)
    REFERENCES students(student_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_enrollment_course FOREIGN KEY (course_id)
    REFERENCES courses(course_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Table: course_prerequisites
-- Self-referencing many-to-many for course prerequisites
CREATE TABLE course_prerequisites (
  course_id INT NOT NULL,
  prereq_course_id INT NOT NULL,
  PRIMARY KEY (course_id, prereq_course_id),
  CONSTRAINT fk_cp_course FOREIGN KEY (course_id)
    REFERENCES courses(course_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_cp_prereq FOREIGN KEY (prereq_course_id)
    REFERENCES courses(course_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

  
  -- Optional helpful indexes for lookups
CREATE INDEX idx_students_lastname ON students(last_name);
CREATE INDEX idx_courses_dept ON courses(department_id);
CREATE INDEX idx_enroll_student ON enrollments(student_id);
CREATE INDEX idx_enroll_course ON enrollments(course_id);


-- SAMPLE DATA (small set to test relationships)
INSERT INTO departments (name, code) VALUES
  ('Computer Science', 'CS'),
  ('Mathematics', 'MATH'),
  ('Business', 'BUS');
  
  INSERT INTO instructors (first_name, last_name, email, hire_date, department_id) VALUES
  ('Alice','Wang','alice.wang@example.com','2017-08-01', (SELECT department_id FROM departments WHERE code='CS')),
  ('Brian','Omondi','brian.omondi@example.com','2019-03-05', (SELECT department_id FROM departments WHERE code='MATH'));


INSERT INTO students (student_number, first_name, last_name, email, birth_date, enrollment_date) VALUES
  ('S1001','John','Doe','john.doe@example.com','2002-04-15','2020-09-01'),
  ('S1002','Mary','Kamau','mary.kamau@example.com','2001-11-20','2019-09-01');
  
  INSERT INTO student_addresses (student_id, address_line1, city, postal_code, country) VALUES
  ((SELECT student_id FROM students WHERE student_number='S1001'), '123 Main St', 'Nairobi', '00100', 'Kenya'),
  ((SELECT student_id FROM students WHERE student_number='S1002'), '45 Green Ave', 'Nairobi', '00100', 'Kenya');

INSERT INTO courses (course_code, title, description, credits, department_id, instructor_id) VALUES
  ('CS101','Intro to Computer Science','Foundations of programming and computing',3,
    (SELECT department_id FROM departments WHERE code='CS'),
    (SELECT instructor_id FROM instructors WHERE email='alice.wang@example.com')
  ),
  ('MATH101','Calculus I','Limits, derivatives, and integrals',3,
    (SELECT department_id FROM departments WHERE code='MATH'),
    (SELECT instructor_id FROM instructors WHERE email='brian.omondi@example.com')
  );

INSERT INTO enrollments (student_id, course_id, semester, year, grade) VALUES
  ((SELECT student_id FROM students WHERE student_number='S1001'),
   (SELECT course_id FROM courses WHERE course_code='CS101'),
   'Fall', 2020, 'A'
  ),
  ((SELECT student_id FROM students WHERE student_number='S1002'),
   (SELECT course_id FROM courses WHERE course_code='MATH101'),
   'Fall', 2019, 'B'
  );
