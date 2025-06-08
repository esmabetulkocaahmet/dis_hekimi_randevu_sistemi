import psycopg2

def get_db_connection():
    return psycopg2.connect(
        host="localhost",
        database="dis_randevu_sistemi",
        user="postgres",
        password="123456"
    )
