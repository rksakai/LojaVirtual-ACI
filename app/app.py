import os
import pyodbc
from flask import Flask, render_template

app = Flask(__name__)

def get_connection():
    server   = os.environ["DB_SERVER"]
    database = os.environ["DB_NAME"]
    username = os.environ["DB_USER"]
    password = os.environ["DB_PASSWORD"]
    driver   = "{ODBC Driver 18 for SQL Server}"

    conn_str = (
        f"DRIVER={driver};"
        f"SERVER={server},1433;"
        f"DATABASE={database};"
        f"UID={username};"
        f"PWD={password};"
        "Encrypt=yes;"
        "TrustServerCertificate=no;"
        "Connection Timeout=30;"
    )
    return pyodbc.connect(conn_str)

@app.route("/")
@app.route("/produtos")
def produtos():
    conn   = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT id, nome, descricao, valor "
        "FROM Produtos WHERE ativo = 1 ORDER BY nome"
    )
    rows = cursor.fetchall()
    conn.close()

    lista = [
        {"id": r[0], "nome": r[1], "descricao": r[2], "valor": r[3]}
        for r in rows
    ]
    return render_template("produtos.html", produtos=lista)

@app.route("/health")
def health():
    return {"status": "ok"}, 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
