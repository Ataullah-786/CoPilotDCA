from flask import Flask, request, jsonify
import subprocess

app = Flask(__name__)

# KEYWORD COMBINATIONS AND THEIR CORRESPONDING SCRIPTS & FILEPATHS
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
    prompt_upper = prompt.upper()

    for rule in SCRIPTS:
        # Check if ALL keywords exist in the prompt
        if all(keyword in prompt_upper for keyword in rule["keywords"]):
            return rule["script"]

    return None


@app.route('/run', methods=['POST'])
def run():

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
