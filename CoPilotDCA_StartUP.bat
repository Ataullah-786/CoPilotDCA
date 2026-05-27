@echo off

echo Starting Flask API...
start cmd /k "cd /d C:\CopilotDCA && py app.py"

timeout /t 5

echo Starting ngrok...
start cmd /k "ngrok http 5000"

timeout /t 10

echo Sending test request...
curl -X POST https://cake-overhead-browbeat.ngrok-free.dev/run-sql ^
-H "Content-Type: application/json" ^
-d "{\"server\":\"test\",\"database\":\"test\",\"script\":\"C:\\test.sql\"}"

