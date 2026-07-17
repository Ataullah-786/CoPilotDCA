"""CoPilotDCA Orchestrator — keyword-based intent routing API.

This module provides a Flask REST API that accepts natural-language prompts,
matches keywords to registered PowerShell scripts, and executes them. It serves
as the central dispatch layer for the CoPilotDCA DataOps automation framework.

Usage:
    python Orchestrator.py

The server listens on port 5000 and exposes a single endpoint:
    POST /run  — accepts {"prompt": "..."} and routes to the matching script.
"""

from flask import Flask, request, jsonify
import subprocess

app = Flask(__name__)

# KEYWORD COMBINATIONS AND THEIR CORRESPONDING SCRIPTS & FILEPATHS
# Each entry maps a set of required keywords (all must be present in the prompt)
# to the absolute path of the PowerShell script to execute.
SCRIPTS = [
    
    #=================================
    #IMPORT SCRIPTS
    #=================================
    {
        "keywords": ["IMPORT", "AREA"],
        "script": "C:\\CopilotDCA\\Repo\\IMPORT\\Import_Area.ps1"
    },
    {
        "keywords": ["IMPORT", "CONTACT"],
        "script": "C:\\CopilotDCA\\Repo\\IMPORT\\Import_Contact.ps1"
    },
    {
        "keywords": ["IMPORT", "LEASE"],
        "script": "C:\\CopilotDCA\\Repo\\IMPORT\\Import_Lease.ps1"
    },

    #=================================
    #EXPORT SCRIPTS
    #=================================    

    {
        "keywords": ["EXPORT", "CONTACT"],
        "script": "C:\\CopilotDCA\\Repo\\EXPORT\\Export_Contact.ps1"
    },
    {
        "keywords": ["EXPORT", "PMFULL"],
        "script": "C:\\CopilotDCA\\Repo\\EXPORT\\Export_PMFull.ps1"
    },
    {
        "keywords": ["EXPORT", "TRFULL"],
        "script": "C:\\CopilotDCA\\Repo\\EXPORT\\Export_TRFull.ps1"
    }
]


def find_script(prompt):
    """Match a user prompt to a registered script using keyword lookup.

    Performs case-insensitive matching by checking whether ALL keywords in a
    rule are present in the prompt. Returns the first matching script path,
    or None if no rule matches.

    Args:
        prompt: Natural-language string from the user (e.g. "import area data").

    Returns:
        Absolute path to the matched PowerShell script, or None if no match.
    """
    prompt_upper = prompt.upper()

    for rule in SCRIPTS:
        if all(keyword in prompt_upper for keyword in rule["keywords"]):
            return rule["script"]

    return None


@app.route('/run', methods=['POST'])
def run():
    """Execute a PowerShell script matched from the request prompt.

    Expects JSON body: {"prompt": "<keywords>"}
    Returns JSON with execution results or a 400/500 error.
    """
    data = request.json
    prompt = data.get("prompt", "")

    script_path = find_script(prompt)

    if not script_path:
        return jsonify({"error": "No matching script found"}), 400

    try:
        result = subprocess.run(
            [
                "powershell",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                script_path
            ],
            capture_output=True,
            text=True
        )

        return jsonify({
            "success": True,
            "script": script_path,
            "output": result.stdout.strip(),
            "errors": result.stderr.strip()
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(port=5000)
