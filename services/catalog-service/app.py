import os

import psycopg2
from flask import Flask, jsonify, request

app = Flask(__name__)


def get_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT", "5432"),
        database=os.getenv("DB_NAME", "shopdb"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD")
    )


def init_db():
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        CREATE TABLE IF NOT EXISTS products (
            id SERIAL PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            price NUMERIC(10, 2) NOT NULL
        )
    """)

    conn.commit()
    cur.close()
    conn.close()


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


@app.get("/products")
def get_products():
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("SELECT id, name, price FROM products ORDER BY id")

    rows = cur.fetchall()

    products = [
        {
            "id": row[0],
            "name": row[1],
            "price": float(row[2])
        }
        for row in rows
    ]

    cur.close()
    conn.close()

    return jsonify(products)


@app.post("/products")
def create_product():
    data = request.get_json()

    conn = get_connection()
    cur = conn.cursor()

    cur.execute(
        """
        INSERT INTO products (name, price)
        VALUES (%s, %s)
        RETURNING id
        """,
        (data["name"], data["price"])
    )

    product_id = cur.fetchone()[0]

    conn.commit()
    cur.close()
    conn.close()

    product = {
        "id": product_id,
        "name": data["name"],
        "price": data["price"]
    }

    return jsonify(product), 201


if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=8080)