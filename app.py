"""CoPilotDCA Direct SQL Execution API.

This module provides a Flask REST API that executes arbitrary SQL script files
against a specified SQL Server instance. It delegates execution to a PowerShell
wrapper script (test.ps1) which handles the actual sqlcmd invocation.

Usage:
    python app.py

The server listens on port 5000 and exposes:
    POST /run-sql  — accepts server, database, and script path; returns output.
"""

from flask import Flask, request, jsonify
import subprocess

app = Flask(__name__)


@app.route("/run-sql", methods=["POST"])
def run_sql():
    """Execute a SQL script file on a specified server and database.

    Expects JSON body with:
        server   — SQL Server instance name
        database — target database name
        script   — absolute path to the .sql file to execute

    Returns JSON with success status, stdout output, and any stderr errors.
    """
    data = request.json

    server = data.get("server")
    database = data.get("database")
    script = data.get("script")

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy", "Bypass",
                "C:\\CopilotDCA\\test.ps1",
                server,
                database,
                script
            ],
            capture_output=True,
            text=True
        )


        return jsonify({
            "success": True,
            "output": result.stdout,
            "error": result.stderr
        })

    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        })

if __name__ == "__main__":
    app.run(port=5000)