-- adding and deleting procedures
------------------------------------------------------------------------------------
-- 1)   user creation
CREATE OR REPLACE PROCEDURE create_user(
    p_user_id IN VARCHAR2,
    p_firstname IN VARCHAR2,
    p_lastname IN VARCHAR2,
    p_email_address IN VARCHAR2,
    p_gender IN CHAR,
    p_user_type IN CHAR
)
IS
BEGIN
    -- Insert user information into user_info table
    INSERT INTO user_info(user_id, firstname, lastname, email_address, gender, user_type)
    VALUES (p_user_id, p_firstname, p_lastname, p_email_address, p_gender, p_user_type);
    -- Output success message
    DBMS_OUTPUT.PUT_LINE('User created successfully. User ID: ' || p_user_id);

END;
/


--example check for user_creation procedure.
BEGIN
    create_user('2022A7PS0001H', 'John', 'Doe', 'john.doe@example.com', 'M', 'S');
END;
/



-------------------------------------------------------------------------------------------------------------------  

  
-- 2) delete_user procedure
  CREATE OR REPLACE PROCEDURE delete_user(
    p_user_id IN VARCHAR2
)
IS
BEGIN
    -- Delete user from user_info table
    DELETE FROM user_info
    WHERE user_id = p_user_id;

    -- Commit the transaction
    COMMIT;
    
    -- Output success message
    DBMS_OUTPUT.PUT_LINE('User with user_id ' || p_user_id || ' deleted successfully.');
EXCEPTION
    WHEN OTHERS THEN
        -- Error handling
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK;
END;
/


  --EXAMPLE USAGE
  BEGIN
    delete_user('2022A7PS0001H');
END;
/


-------------------------------------------------------------------------------------------------------------
--3) bicycle record creation (a person listing/registering their bicycle for rental)
CREATE OR REPLACE PROCEDURE create_bicycle_record(
    p_bicycle_type IN VARCHAR2,
    p_lender_id IN VARCHAR2,
    p_model_type IN VARCHAR2
)
IS
    v_bicycle_id NUMBER;
BEGIN
    -- Insert record into bicycle table
    INSERT INTO bicycle(bicycle_id, bicycle_type, lender_id, model_type)
    VALUES (bicycle_seq.NEXTVAL, p_bicycle_type, p_lender_id, p_model_type)
    RETURNING bicycle_id INTO v_bicycle_id;

 
 DBMS_OUTPUT.PUT_LINE('Bicycle record created successfully. Bicycle ID: ' || v_bicycle_id);

END;
/

--example
BEGIN
    create_bicycle_record('2022A7PS0001H', 'Mountain Bike', 'Model XYZ');
END;
/



------------------------------------------------------------------------------------------------------------


-- 4) deletion of bicycle record (a person deleted/delists their bicycle from the system

CREATE OR REPLACE PROCEDURE delete_bicycle(
    p_bicycle_id IN NUMBER
)
IS
BEGIN
    -- Delete bicycle from bicycle table
    DELETE FROM bicycle
    WHERE bicycle_id = p_bicycle_id;

    -- Delete corresponding records from bicycle_color table
    DELETE FROM bicycle_color
    WHERE bicycle_id = p_bicycle_id;
    -- Output success message
    DBMS_OUTPUT.PUT_LINE('Bicycle with bicycle_id ' || p_bicycle_id || ' deleted successfully.');

END;
/



    --example 
    BEGIN
    delete_bicycle(123); -- Replace 123 with the actual bicycle_id
END;
/
-----------------------------------------------------------------------------
    -- 5) insert phno
CREATE OR REPLACE PROCEDURE insert_phone(
    p_user_id IN VARCHAR2,
    p_phno IN VARCHAR2
)
IS
BEGIN
    -- Insert phone number into user_phno table
    INSERT INTO user_phno(user_id, phno)
    VALUES (p_user_id, p_phno);

    -- Output success message
    DBMS_OUTPUT.PUT_LINE('Phone number inserted successfully for User ID: ' || p_user_id);

END;
/

----------------------------------------------------------------------------------------------
-- 6) insert bicycle_color

    CREATE OR REPLACE PROCEDURE insert_bicycle_color(
    p_bicycle_id IN NUMBER,
    p_color IN VARCHAR2
)
IS
BEGIN
    -- Insert color for the bicycle into bicycle_color table
    INSERT INTO bicycle_color(bicycle_id, color)
    VALUES (p_bicycle_id, p_color);

    -- Output success message
    DBMS_OUTPUT.PUT_LINE('Color inserted successfully for Bicycle ID: ' || p_bicycle_id);

END;
/

    




----------------------------------------------------------------------------------------------------------
-- BUSINESS LOGIC
--     PROCEDURES

-------------------------------------------------------------------------------------------------------------
  --1) RENT A BICYCLE (CREATES A RECORD IN RENTAL TABLE WITH GIVEN VALUES AND OTHER DEFAULT VALUES)
 
CREATE OR REPLACE PROCEDURE create_rental_record(
    p_borrower_id IN VARCHAR2,
    p_rental_date IN DATE,
    p_bicycle_id IN NUMBER
)
IS
BEGIN
    -- Insert record into rental table
    INSERT INTO rental(rental_id, borrower_id, rental_date, bicycle_id)
    VALUES (rental_seq.NEXTVAL, p_borrower_id, p_rental_date, p_bicycle_id);

    -- Output success message
    DBMS_OUTPUT.PUT_LINE('Rental record created successfully.');

END;
/



-- example 
    BEGIN
    create_rental_record('200001JD0001H', TO_DATE('3-Nov-2013', 'DD-Mon-YYYY'), 123);
END;
/

-----------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE create_extension_record (
    p_rental_id IN NUMBER,
    p_extra_duration IN NUMBER
)
IS
    v_extra_charges NUMBER;
BEGIN
    -- Calculate extra charges
    v_extra_charges := 100 * p_extra_duration;

    -- Insert a new record into the extension table
    INSERT INTO extension (extension_id, rental_id, extra_duration, extra_charges)
    VALUES (extension_seq.NEXTVAL, p_rental_id, p_extra_duration, v_extra_charges);

    -- Output success message
    DBMS_OUTPUT.PUT_LINE('Extension record created successfully.');

EXCEPTION
    WHEN OTHERS THEN
        -- Output error message
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
END;
/

/


-------------------------------------------------------------------------------------------------
    --3)procedure to enter feedback
    CREATE OR REPLACE PROCEDURE enter_feedback(
    p_user_id IN VARCHAR2,
    p_rating IN NUMBER,
    p_comments IN VARCHAR2
)
IS
BEGIN
    -- Insert record into feedback table
    INSERT INTO feedback(feedback_id, user_id, rating, comments)
    VALUES (feedback_seq.NEXTVAL, p_user_id, p_rating, p_comments);

    -- Output success message
    DBMS_OUTPUT.PUT_LINE('Feedback record entered successfully.');

END;
/



----------------------------------------------------------------------------------

-- 4) confirm rental record
CREATE OR REPLACE PROCEDURE confirm_rental(
    p_return_date IN DATE,
    p_rental_id IN NUMBER,
    p_damage_flag IN CHAR
)
IS
    v_rental_status VARCHAR2(10);
BEGIN
    -- Update return date in rental table
    UPDATE rental
    SET return_date = p_return_date
    WHERE rental_id = p_rental_id;

    -- Update rental status based on damage flag
    IF p_damage_flag = 'Y' THEN
        v_rental_status := 'damaged';
    ELSE
        v_rental_status := 'inactive';
    END IF;

    -- Update rental status in rental table
    UPDATE rental
    SET rental_status = v_rental_status
    WHERE rental_id = p_rental_id;

    -- Output success message
    DBMS_OUTPUT.PUT_LINE('Rental confirmed successfully.');

END;
/

   ----------------- --example usage
    BEGIN
    confirm_rental(TO_DATE('2024-04-20', 'YYYY-MM-DD'), 123, 'Y'); -- Replace 123 with the actual rental_id and adjust other inputs as needed
END;
/


------------------------------------------------------------------------------------------------------
 ----- JOIN PROCEDURES

--------------------------------------------------------------------------
--1) Fetch borrowers
CREATE OR REPLACE PROCEDURE fetch_borrowers(
    p_lender_id IN VARCHAR2
)
IS
BEGIN
    -- Fetch user_id and names of borrowers
    FOR borrower_rec IN (
        SELECT DISTINCT ui.user_id, ui.firstname, ui.lastname
        FROM user_info ui
        JOIN rental r ON ui.user_id = r.borrower_id
        JOIN bicycle b ON r.bicycle_id = b.bicycle_id
        WHERE b.lender_id = p_lender_id
    ) LOOP
        -- Output the fetched data
        DBMS_OUTPUT.PUT_LINE('User ID: ' || borrower_rec.user_id);
        DBMS_OUTPUT.PUT_LINE('Name: ' || borrower_rec.firstname || ' ' || borrower_rec.lastname);
        DBMS_OUTPUT.PUT_LINE('---------------------------');
    END LOOP;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No borrowers found for the specified lender.');
        WHEN OTHERS THEN
            -- Error handling
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/


-----------------------------------------------------------------------------------------
---2) data of people who borrowed  and lent their bicycle on date1
CREATE OR REPLACE PROCEDURE fetch_borrowers_and_lenders(
    p_date1 IN DATE
)
IS
BEGIN
    -- Fetch data of people who borrowed bicycles on date1
    FOR borrower_rec IN (
        SELECT DISTINCT ui.user_id, ui.firstname, ui.lastname
        FROM user_info ui
        JOIN rental r ON ui.user_id = r.borrower_id
        WHERE TRUNC(r.rental_date) = TRUNC(p_date1)
    ) LOOP
        -- Output borrower data
        DBMS_OUTPUT.PUT_LINE('Borrower ID: ' || borrower_rec.user_id);
        DBMS_OUTPUT.PUT_LINE('Name: ' || borrower_rec.firstname || ' ' || borrower_rec.lastname);
        DBMS_OUTPUT.PUT_LINE('Action: Borrowed');
        DBMS_OUTPUT.PUT_LINE('---------------------------');
    END LOOP;

    -- Fetch data of people who lent bicycles on date1
    FOR lender_rec IN (
        SELECT DISTINCT ui.user_id, ui.firstname, ui.lastname
        FROM user_info ui
        JOIN bicycle b ON ui.user_id = b.lender_id
        JOIN rental r ON b.bicycle_id = r.bicycle_id
        WHERE TRUNC(r.rental_date) = TRUNC(p_date1)
    ) LOOP
        -- Output lender data
        DBMS_OUTPUT.PUT_LINE('Lender ID: ' || lender_rec.user_id);
        DBMS_OUTPUT.PUT_LINE('Name: ' || lender_rec.firstname || ' ' || lender_rec.lastname);
        DBMS_OUTPUT.PUT_LINE('Action: Lent');
        DBMS_OUTPUT.PUT_LINE('---------------------------');
    END LOOP;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No data found for the specified date.');
        WHEN OTHERS THEN
            -- Error handling
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/
