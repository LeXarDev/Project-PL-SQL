-------Create the Books table
CREATE TABLE Books (
  book_id INT PRIMARY KEY,
  title VARCHAR(350),
  author VARCHAR(100),
  publication_year INT,
  available CHAR(1)
);

----------- Create the Members table
CREATE TABLE Members (
  member_id INT PRIMARY KEY,
  name VARCHAR(50),
  email VARCHAR(100),
  phone VARCHAR(20)
);

CREATE TABLE Borrowings (
  member_id INT,
  book_id INT,
  borrow_date DATE
);

CREATE TABLE Book_Count (
  count INT
);

 
---///--here add a new book 

CREATE OR REPLACE PROCEDURE add_new_book(
  p_book_id INT,
  p_title VARCHAR,
  p_author VARCHAR,
  p_publication_year INT
) IS
BEGIN
  INSERT INTO Books (book_id, title, author, publication_year, available)
  VALUES (p_book_id, p_title, p_author, p_publication_year, 'Y');
  
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    ROLLBACK;
END;
/

--//-from here our starting we using procdure and  ROWTYPE  
CREATE OR REPLACE PROCEDURE get_book_details_by_title(
  p_title VARCHAR2
) IS
 
  var_book Books%ROWTYPE;
BEGIN
  SELECT * INTO var_book
  FROM Books
  WHERE title = p_title;

  DBMS_OUTPUT.PUT_LINE('Book ID: ' || var_book.book_id);
  DBMS_OUTPUT.PUT_LINE('Author: ' || var_book.author);
  DBMS_OUTPUT.PUT_LINE('Publication Year: ' || var_book.publication_year);

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('No book found with title: ' || p_title);
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

----///--- Here is  procedure to add a new member 
CREATE OR REPLACE PROCEDURE add_member(
  p_member_id INT,
  p_name VARCHAR,
  p_email VARCHAR,
  p_phone VARCHAR
) IS
BEGIN
  INSERT INTO Members (member_id, name, email, phone)
  VALUES (p_member_id, p_name, p_email, p_phone);

  COMMIT;
END;
/

-----///---thiss function to check if a book is available
CREATE OR REPLACE FUNCTION is_book_available(
  p_book_id INT
) RETURN BOOLEAN IS
  var_available CHAR(1);
BEGIN
  SELECT available INTO var_available FROM Books WHERE book_id = p_book_id;

  IF var_available IS NULL OR var_available = 'N' THEN
    RETURN FALSE; 
  ELSE
    RETURN TRUE; 
  END IF;
END;




---///-- here is internal Cursor show info from books table
BEGIN
 
  FOR v_book IN (SELECT * FROM Books) LOOP
  
    DBMS_OUTPUT.PUT_LINE('Book ID: ' || v_book.book_id);           
    DBMS_OUTPUT.PUT_LINE('Title: ' || v_book.title);               
    DBMS_OUTPUT.PUT_LINE('Author: ' || v_book.author);             
    DBMS_OUTPUT.PUT_LINE('Publication Year: ' || v_book.publication_year); 
    DBMS_OUTPUT.PUT_LINE('Is Available: ' || v_book.available);  
    DBMS_OUTPUT.PUT_LINE('----------------------------------');  
  
  END LOOP;

END;
/

----///--- External  Cursor show members 
DECLARE
  CURSOR c_members IS
    SELECT * FROM Members;
    
  v_member_id Members.member_id%TYPE;
  v_name Members.name%TYPE;
  v_email Members.email%TYPE;
  v_phone Members.phone%TYPE;
BEGIN
  OPEN c_members;
    LOOP
    FETCH c_members INTO v_member_id, v_name, v_email, v_phone;
    EXIT WHEN c_members%NOTFOUND;
    
    DBMS_OUTPUT.PUT_LINE('Member Name: ' || v_name);
  END LOOP;
  
  CLOSE c_members;
END;
/
----///- Here is Borrow part -  procedure to borrow a book
CREATE OR REPLACE PROCEDURE borrow_book(
  p_member_id INT,
  p_book_id INT
) IS
BEGIN
  IF is_book_available(p_book_id) = FALSE THEN
    RAISE_APPLICATION_ERROR(-20001, 'The book is not available for borrowing.');
  END IF;

  UPDATE Books SET available = 'N' WHERE book_id = p_book_id;
  INSERT INTO Borrowings (member_id, book_id, borrow_date) VALUES (p_member_id, p_book_id, SYSDATE);
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    ROLLBACK;
END;

----//- Here is part of  package - package specification
CREATE OR REPLACE PACKAGE library_pkg IS
  PROCEDURE return_book(p_member_id INT, p_book_id INT);
  PROCEDURE print_book_count;
END library_pkg;
/


--//---- here the package body
CREATE OR REPLACE PACKAGE BODY library_pkg IS
  PROCEDURE return_book(p_member_id INT, p_book_id INT) IS
  BEGIN
    UPDATE Books SET available = 'Y' WHERE book_id = p_book_id;
    DELETE FROM Borrowings WHERE member_id = p_member_id AND book_id = p_book_id;
    COMMIT;
  END return_book;

  PROCEDURE print_book_count IS
    v_count INT;
  BEGIN
    SELECT COUNT(*) INTO v_count FROM Books;
    DBMS_OUTPUT.PUT_LINE('Total books: ' || v_count);
  END print_book_count;
END library_pkg;
/


-- Create a trigger to update the book count when a new book is added
CREATE OR REPLACE TRIGGER update_book_count
BEFORE INSERT ON Books
FOR EACH ROW
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) + 1
  INTO v_count
  FROM Books;
  
  -- Update the book count 
  UPDATE Book_Count
  SET count = v_count;
END;
/


 -- Inserting data into the Members table

 INSERT INTO Members (member_id, name, email, phone)
VALUES (201, 'test', 'test@email.com', '123-456-7890');

INSERT INTO Members (member_id, name, email, phone)
VALUES (202, 'test2', 'test2@email.com', '987-654-3210');

-- Inserting data into the Books table

INSERT INTO Books (book_id, title, author, publication_year, available)
VALUES (101, 'test1 ', 'test3', 1951, 'Y');

INSERT INTO Books (book_id, title, author, publication_year, available)
VALUES (102, 'test2', 'test4', 1960, 'Y');

-- Inserting data into the Borrowings table

INSERT INTO Borrowings (member_id, book_id, borrow_date)
VALUES (201, 101, SYSDATE);
INSERT INTO Borrowings (member_id, book_id, borrow_date)
VALUES (202, 102, SYSDATE);

-- Inserting data into the Book_Count table
INSERT INTO Book_Count (count)