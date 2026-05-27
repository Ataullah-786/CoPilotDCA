from flask import Flask, request, jsonify
import subprocess

app = Flask(__name__)

@app.route("/run-sql", methods=["POST"])
def run_sql():
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