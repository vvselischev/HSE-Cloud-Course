#!/usr/bin/env python3

import json
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
import psycopg2

port = 80
database_name = "service_database"
table_name = "service_status"
db_host = ""
local_host = ""


class myHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/healthcheck':
            conn = None
            try:
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()

                conn = psycopg2.connect(
                    host=db_host,
                    database=database_name,
                    user="postgres",
                    password="postgres")

                cur = conn.cursor()
                cur.execute(f"SELECT * from {table_name}")
                rows = cur.fetchall()

                response = []
                for row in rows:
                    d = {'ip': row[0], 'status': row[1]}
                    response.append(d)

                cur.close()

                self.wfile.write(json.dumps({'ip': local_host, 'services': response}).encode())
            except psycopg2.DatabaseError as error:
                self.wfile.write("Database is unavailable".encode())
                print(error)
            finally:
                if conn is not None:
                    conn.close()


if __name__ == '__main__':
    local_host = sys.argv[1]
    db_host = sys.argv[2]

    server = HTTPServer(('', port), myHandler)

    conn = None
    try:
        conn = psycopg2.connect(
            host=db_host,
            database=database_name,
            user="postgres",
            password="postgres")

        cur = conn.cursor()
        init_tuple = (local_host, 'AVAILABLE')
        cur.execute(f"INSERT INTO {table_name} VALUES {init_tuple} ON CONFLICT (id) DO UPDATE SET status = 'AVAILABLE'")
        conn.commit()
        cur.close()

        print(f"Server on {local_host} is up and running.")
        server.serve_forever()
    except psycopg2.DatabaseError as error:
        print(error)
    finally:
        if conn is not None:
            conn.close()
