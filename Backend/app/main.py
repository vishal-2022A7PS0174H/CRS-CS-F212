import cx_Oracle as cx
from pydantic import ValidationError
from fastapi import FastAPI, status, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from .models import Query, User, Bicycle, Extension, Feedback, Rental, confirmObject
from datetime import datetime

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

connStr = 'crs/crs123@localhost:1521/xepdb1'



# HELPER FUNCTIONS



def get_connection():
    try:
        conn = cx.connect(connStr)
        conn.autocommit = False
        return conn
    except cx.Error as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

def create_user_procedure(user_id, firstname, lastname, email_address, gender, user_type, phones):
    try:

        conn = get_connection()
        cursor = conn.cursor()
        cursor.callproc("create_user", [user_id, firstname, lastname, email_address, gender, user_type])

        for phone in phones:
            cursor.callproc("insert_phone", [user_id, phone])

        conn.commit()

        cursor.close()
        conn.close()

    except cx.DatabaseError as e:
        print("Database error:", e)
        raise

def create_bicycle_procedure(bicycle_type, lender_id, model_type, colors):
    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.callproc("create_bicycle", [bicycle_type, lender_id, model_type])

        cursor.execute("SELECT bicycle_seq.currval FROM DUAL")
        generated_bicycle_id = cursor.fetchone()[0]

        for color in colors:
            cursor.callproc("insert_color", [generated_bicycle_id, color])

        conn.commit()

        cursor.close()
        conn.close()

    except cx.DatabaseError as e:
        print("error:", e)
        raise




# QUERYING INTERFACE




# Basic Querying interface of the database
@app.post("/query", status_code=status.HTTP_201_CREATED)
def query(query: Query):
    conn = get_connection()
    try:
        curr = conn.cursor()
        queries = query.query.split(';')
        for q in queries:
            if q.strip():
                curr.execute(q)
                if q.strip().upper().startswith('SELECT'):
                    output = curr.fetchall() # Fetch all the entities
                    columns = [desc[0] for desc in curr.description] # Get all the column names
                    results = [dict(zip(columns, row)) for row in output] # Attach all the entities with their respective attribute names.
                    return {"Data": results}
        conn.commit()
        return {"Message": "The queries have been successfully executed."}
    
    except cx.Error as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    finally:
        curr.close()  
        conn.close()  




# INSERTION AND CONFIRMATION OF THE RENTAL




@app.post("/rental", status_code=status.HTTP_201_CREATED)
async def create_rental_record(rental: Rental):
    try:
        conn = get_connection()
        cursor = conn.cursor()

        rental_date = datetime.strptime(rental.rental_date, "%Y-%m-%d")

        cursor.callproc("create_rental_record", [rental.borrower_id, rental.bicycle_id, rental_date])

        conn.commit()

        return {"message": "Rental record created successfully."}
    except cx.DatabaseError as e:
        error, = e.args
        raise HTTPException(status_code=500, detail=str(error))
    finally:
        cursor.close()
        conn.close()  

@app.post("/rent-confirm", status_code=status.HTTP_202_ACCEPTED)
def confirm(confirm: confirmObject):
    try:
        conn = get_connection()
        cursor = conn.cursor()

        rtn_date = datetime.strptime(confirm.return_date, "%Y-%m-%d")

        cursor.callproc("confirm_rental", [confirm.rental_id, rtn_date, confirm.damaged_flag])

    except ValidationError as e:
        return HTTPException(status_code=422, detail=str(e))
    
    except cx.DatabaseError as e:
        print("Database error:", e)
        raise




# CREATE AND REMOVE A USER FROM THE PORTAL




@app.post("/create-user", status_code=status.HTTP_201_CREATED)
async def create_user(user: User):
    try:
        user_data = user.dict()
        
        create_user_procedure(**user_data)
        
        return {"message": "User created successfully."}
    except ValidationError as e:
        raise HTTPException(status_code=422, detail=str(e))

    except cx.DatabaseError as e:
        print("Database error:", e)
        raise
    
@app.delete("/delete-user/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(user_id: str):
    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.callproc("delete_user", [user_id])

        conn.commit()

    except ValidationError as e:
        raise HTTPException(status_code=422, detail=str(e)) 



# CREATE AND REMOVE A BICYCLE FROM THE RECORDS




@app.post("/create-bicycle", status_code=status.HTTP_201_CREATED)
async def create_bicycle(bicycle: Bicycle):
    try:
        bicycle_data = bicycle.dict()
        
        create_bicycle_procedure(**bicycle_data)
        
    except ValidationError as e:
        raise HTTPException(status_code=422, detail=str(e))
    
    except cx.DatabaseError as e:
        print("Database error:", e)
        raise

@app.delete("/delete-bicycle/{bicycle_id}", status_code=status.HTTP_204_NO_CONTENT)
async def create_bicycle(bicycle_id: int):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        
        cursor.callproc("delete_bicycle", [bicycle_id])
        conn.commit()
        
    except ValidationError as e:
        raise HTTPException(status_code=422, detail=str(e))
    
    except cx.DatabaseError as e:
        print("Database error:", e)
        raise





# FEEDBACK AND EXTENSION



@app.post("/feedback", status_code=status.HTTP_201_CREATED)
def enter_feedback(feedback: Feedback):
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.callproc("enter_feedback", [feedback.user_id, feedback.rating, feedback.comments])

        conn.commit()

    except ValidationError as e:
        raise HTTPException(status_code=422, detail=str(e))
    
    except cx.DatabaseError as e:
        print("Database error:", e)
        raise 

@app.post("/extension", status_code=status.HTTP_201_CREATED)
def request_extension(extension: Extension):
    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.callproc("create_extension_record", [extension.rental_id, extension.extra_duration])
        
        conn.commit()

    except ValidationError as e:
        raise HTTPException(status_code=422, detail=str(e))
    
    except cx.DatabaseError as e:
        print("Database error:", e)
        raise
