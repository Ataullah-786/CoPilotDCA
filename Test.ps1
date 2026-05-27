# Requires: Invoke-Sqlcmd (SQLServer module)
Add-Type -AssemblyName System.Web

# --------------------------------------------------------------------------------
# Function: pickup the local SQL Server instances
# --------------------------------------------------------------------------------
# function Get-NetworkSqlInstances {
#     $sources = [System.Data.Sql.SqlDataSourceEnumerator]::Instance.GetDataSources()
#     $instances = @()
#     foreach ($row in $sources) {
#         if ([string]::IsNullOrEmpty($row.InstanceName)) {
#             $instances += $row.ServerName
#         } else {
#             $instances += "$($row.ServerName)\$($row.InstanceName)"
#         }
#     }
#     return $instances
# }

# --- List of SQL Servers ---
$serverList = @(
    "localhost",
    "MRIPF3DNGQF",
    "DBPGINT",
    "PRODINTEG"
)

# $serverList = Get-NetworkSqlInstances
# $mainFont = "Segoe UI"
$port = 8086

$global:stopListener = $false
function HtmlEncode($text) {
    return [System.Web.HttpUtility]::HtmlEncode($text)
}

function Format-Duration($duration) {
    $str = $duration.ToString().PadLeft(6,'0')
    return "$($str.Substring(0,2)):$($str.Substring(2,2)):$($str.Substring(4,2))"
}

function Format-DateTime($run_date, $run_time) {
    if (-not $run_date) { return "" }
    $dateStr = $run_date.ToString().PadLeft(8,'0')
    if ($run_time) {
        $timeStr = $run_time.ToString().PadLeft(6,'0')
    } else {
        $timeStr = '000000'
    }
    $dtStr = "$dateStr $timeStr"
    try {
        return [datetime]::ParseExact($dtStr, "yyyyMMdd HHmmss", $null).ToString("yyyy-MM-dd HH:mm:ss")
    } catch {
        return "$run_date $run_time"
    }
}

function Get-AllJobs {
    param($serverName)
    $sql = @"
WITH JobDetails AS (
    SELECT 
        j.job_id,
        j.name AS JobName,
        j.enabled,
        CASE WHEN js.schedule_id IS NOT NULL THEN 1 ELSE 0 END AS HasSchedule,
        s.schedule_id,
        s.name AS ScheduleName,
        s.enabled AS ScheduleEnabled,
        s.freq_type,
        s.freq_interval,
        s.freq_subday_type,
        s.freq_subday_interval,
        s.freq_relative_interval,
        s.freq_recurrence_factor,
        s.active_start_date,
        s.active_end_date,
        js.next_run_date,
        js.next_run_time
    FROM sysjobs j
    LEFT JOIN sysjobschedules js ON j.job_id = js.job_id
    LEFT JOIN sysschedules s ON js.schedule_id = s.schedule_id
),
JobHistory AS (
    SELECT job_id, run_status, run_date, run_time
    FROM (
        SELECT 
            job_id, 
            run_status, 
            run_date,
            run_time,
            ROW_NUMBER() OVER (PARTITION BY job_id ORDER BY run_date DESC, run_time DESC) AS rn
        FROM sysjobhistory
        WHERE step_id = 0
    ) AS ranked
    WHERE rn = 1
),
JobWithCategories AS (
    SELECT 
        jd.JobName,
        jd.job_id,
        jd.enabled,
        jd.HasSchedule,
        jd.ScheduleName,
        jd.ScheduleEnabled,
        jd.freq_type,
        jh.run_status,
        jh.run_date,
        jh.run_time,
        jd.next_run_date,
        jd.next_run_time,
        CASE 
            WHEN jd.enabled = 1 AND jd.HasSchedule = 1 AND jh.run_status = 1 THEN 'Active_wSchedule_Successful'
            WHEN jd.enabled = 1 AND jd.HasSchedule = 1 AND jh.run_status = 0 THEN 'Active_wSchedule_Failure'
            WHEN jd.enabled = 1 AND jd.HasSchedule = 0 AND jh.run_status = 1 THEN 'Active_Manual_Successful'
            WHEN jd.enabled = 1 AND jd.HasSchedule = 0 AND jh.run_status = 0 THEN 'Active_Manual_Failure'
            WHEN jd.enabled = 1 AND jh.run_status IS NULL THEN 'Active_Never_Executed'
            WHEN jd.enabled = 0 AND jd.HasSchedule = 1 THEN 'Inactive_Scheduled'
            WHEN jd.enabled = 0 AND jd.HasSchedule = 0 THEN 'Inactive_Manual'
            --ELSE 'Other/Review'
        END AS Category
    FROM JobDetails jd
    LEFT JOIN JobHistory jh ON jd.job_id = jh.job_id
)
SELECT 
    (select [name] from sys.servers where server_ID = 0) AS ServerName, 
    JobName,
    job_id,
    Category,
    ScheduleName,
    CASE WHEN HasSchedule = 1 THEN 'Yes' ELSE 'No' END AS HasSchedule,
    CASE 
        WHEN ScheduleEnabled = 1 THEN 'Enabled'
        WHEN ScheduleEnabled = 0 THEN 'Disabled'
        ELSE 'N/A'
    END AS ScheduleStatus, 
    CASE 
        WHEN freq_type = 1 THEN 'One time'
        WHEN freq_type = 4 THEN 'Daily'
        WHEN freq_type = 8 THEN 'Weekly'
        WHEN freq_type = 16 THEN 'Monthly'
        WHEN freq_type = 32 THEN 'Monthly (relative)'
        WHEN freq_type = 64 THEN 'When SQL Server Agent starts'
        WHEN freq_type = 128 THEN 'Start when CPU idle'
        ELSE 'Unknown'
    END AS Frequency,
    CASE WHEN enabled = 1 THEN 'Enabled' ELSE 'Disabled' END AS JobStatus,
    CASE 
        WHEN run_status = 0 THEN 'Failed'
        WHEN run_status = 1 THEN 'Succeeded'
        WHEN run_status = 2 THEN 'Retry (step failed and retried)'
        WHEN run_status = 3 THEN 'Canceled'
        WHEN run_status = 4 THEN 'In Progress (or Unknown)'
        WHEN run_status IS NULL THEN 'Never Executed'
        ELSE 'Unknown'
    END AS LastRunStatus,
    CASE 
        WHEN run_date > 0 THEN msdb.dbo.agent_datetime(run_date, run_time)
        ELSE NULL
    END AS LastRunDateTime,
    CASE 
        WHEN next_run_date > 0 THEN msdb.dbo.agent_datetime(next_run_date, next_run_time)
        ELSE NULL
    END AS NextRunDateTime
FROM JobWithCategories
ORDER BY LastRunDateTime desc;
"@
    Invoke-Sqlcmd -ServerInstance $serverName -Database "msdb" -Query $sql
}

function Get-JobHistory {
    param($serverName, $jobId)
    $sql = @"
SELECT 
    h.instance_id,
    j.job_id,
    j.name AS JobName,
    h.run_date,
    h.run_time,
    h.run_duration,
    h.run_status,
    h.message,
    h.sql_severity,
    h.step_id,
    s.step_name
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobhistory h ON j.job_id = h.job_id
LEFT JOIN msdb.dbo.sysjobsteps s ON j.job_id = s.job_id AND h.step_id = s.step_id
WHERE j.job_id = '$jobId'
ORDER BY h.run_date DESC, h.run_time DESC
"@
    Invoke-Sqlcmd -ServerInstance $serverName -Database "msdb" -Query $sql
}

# --- HTTP Server ---
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "Dashboard running at http://localhost:$port/"
Start-Process "http://localhost:$port/"

# while ($true) {
while (-not $global:stopListener) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    try {
        $path = $request.Url.AbsolutePath
        $query = [System.Web.HttpUtility]::ParseQueryString($request.Url.Query)

        #region Handle Shutdown before anything else
if ($path -eq "/shutdown") {
    $html = $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset='UTF-8'>
    <title>Shutting Down</title>
    <style>
        body {
            font-family: 'Segoe UI', sans-serif;
            background: linear-gradient(60deg, rgba(84,58,183,0.1) 0%, rgba(0,172,193,0.1) 100%);
            margin: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100vh;
        }
        .shutdown-container {
            background: #ffffff;
            padding: 40px 60px;
            border-radius: 12px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            text-align: center;
        }
        h1 {
            color: #1A237E;
            font-size: 28px;
            margin-bottom: 20px;
        }
        p {
            color: #555;
            font-size: 16px;
        }
        .wave {
            margin-top: 30px;
            width: 100%;
            max-width: 400px;
        }
    </style>
</head>
<body>
    <div class="shutdown-container">
        <h1>Server is shutting down...</h1>
        <p>Thank you for using the SQL Job Dashboard.</p>
        <svg class="wave" viewBox="0 24 150 28" preserveAspectRatio="none" shape-rendering="auto">
            <defs>
                <path id="wave-path" d="M-160 44c30 0 58-18 88-18s58 18 88 18 58-18 88-18 58 18 88 18v44h-352z" />
            </defs>
            <g class="parallax">
                <use href="#wave-path" x="48" y="0" fill="rgba(84,58,183,0.3)" />
                <use href="#wave-path" x="48" y="3" fill="rgba(0,172,193,0.3)" />
                <use href="#wave-path" x="48" y="5" fill="rgba(0,172,193,0.2)" />
                <use href="#wave-path" x="48" y="7" fill="#fff" />
            </g>
        </svg>
    </div>
</body>
</html>
"@

    $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
    $response.ContentType = "text/html"
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.Close()

    $global:stopListener = $true
    break
}
#endregion
        $categories = @(
            'Active_wSchedule_Successful',
            'Active_wSchedule_Failure',
            'Active_Manual_Successful',
            'Active_Manual_Failure',
            'Active_Never_Executed',
            'Inactive_Scheduled',
            'Inactive_Manual'
            # 'Other/Review'
        )

        if ($path -eq "/") {
            # Server selection page
            $serverOptions = ($serverList | ForEach-Object { "<option value='$_'>$_</option>" }) -join ""
            $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset='UTF-8'>
    <title>Select SQL Server</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        html, body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(to right, #667eea, #764ba2);
            color: #333;
            height: 100%;
            width: 100%;
        }

        body {
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            position: relative;
        }

        h1 { color:rgb(92, 59, 124); text-align: center; margin-top: 0; margin-bottom: 20px; }
        h2 { color: #00B8D4; text-align: center; }
        h3 { color: #1A237E; text-align: center; font-size: 12px; margin-top: 10px; }

        .container {
            background: rgba(255, 255, 255, 0.95);
            border-radius: 16px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.2);
            max-width: 420px;
            width: 90%;
            padding: 40px;
            text-align: center;
            z-index: 1;
        }

        .logo {
            width: 180px;
            margin: 0 auto 24px;
        }

        .server-select {
            width: 100%;
            padding: 12px 16px;
            font-size: 16px;
            border: 1px solid #ccc;
            border-radius: 8px;
            margin-bottom: 24px;
            transition: border 0.3s ease;
        }

        .server-select:focus {
            border-color: #00BCD4;
            outline: none;
        }

        .go-btn {
            background: #00BCD4;
            color: white;
            font-size: 16px;
            font-weight: 600;
            padding: 12px;
            width: 100%;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            transition: background 0.3s ease, transform 0.2s ease;
        }

        .go-btn:hover {
            background: #0097A7;
            transform: translateY(-1px);
        }

        .exit-btn {
            margin-top: 4px;
            background:rgb(242, 67, 96);
            color: white;
            font-size: 16px;
            font-weight: 600;
            padding: 12px;
            width: 100%;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            transition: background 0.3s ease, transform 0.2s ease;
        }

        .exit-btn:hover {
            background: rgb(130, 48, 62);
            transform: translateY(-1px);
        }        

        .wave-container {
            position: absolute;
            bottom: 0;
            left: 0;
            width: 100%;
            height: 120px;
            overflow: hidden;
            line-height: 0;
        }

        .waves {
            position: absolute;
            bottom: 0;
            width: 100%;
            height: 100%;
        }

        .parallax > use {
            animation: move-forever 25s cubic-bezier(.55, .5, .45, .5) infinite;
        }

        .parallax > use:nth-child(1) {
            animation-delay: -2s;
            animation-duration: 7s;
        }

        .parallax > use:nth-child(2) {
            animation-delay: -3s;
            animation-duration: 10s;
        }

        .parallax > use:nth-child(3) {
            animation-delay: -4s;
            animation-duration: 13s;
        }

        .parallax > use:nth-child(4) {
            animation-delay: -5s;
            animation-duration: 20s;
        }

        @keyframes move-forever {
            0% { transform: translate3d(-90px, 0, 0); }
            100% { transform: translate3d(85px, 0, 0); }
        }

        @media (max-width: 600px) {
            .logo {
                width: 140px;
            }

            .container {
                padding: 24px;
            }
        }
    </style>

    <script>
        function goToDashboard() {
            var sel = document.getElementById('serverSelect');
            if (sel.value) {
                window.location.href = '/dashboard?server=' + encodeURIComponent(sel.value);
            }
        }
    </script>
</head>
<body>
    <div class="container">
        <!-- Replace 'logo.png' with your actual logo path -->
        <!--<img src="file:\\\C:\Users\Ataullah.Toffar\OneDrive - MRI Software\Desktop\SCRIPTS\MRI\Hackathon 2025\concept_logo.png" alt="Company Logo" class="logo">-->
        <h1>Select SQL Server</h1>
        <select id="serverSelect" class="server-select">
            <option value="">-- Choose a server --</option>
            $serverOptions
        </select>
        <br/>
        <button class="go-btn" onclick="goToDashboard()">View Dashboard</button>
        <br/>
        <button class="exit-btn" onclick="window.location.href='/shutdown?server=' + encodeURIComponent(document.getElementById('serverSelect').value)">EXIT</button>
    </div>

    <!-- Waves at the bottom -->
    <div class="wave-container">
        <svg class="waves" xmlns="http://www.w3.org/2000/svg"
             xmlns:xlink="http://www.w3.org/1999/xlink"
             viewBox="0 24 150 28" preserveAspectRatio="none" shape-rendering="auto">
            <defs>
                <path id="gentle-wave"
                      d="M-160 44c30 0 58-18 88-18s 58 18 
                      88 18 58-18 88-18 58 18 88 18 v44h-352z" />
            </defs>
            <g class="parallax">
                <use xlink:href="#gentle-wave" x="48" y="0" fill="rgba(255,255,255,0.7)" />
                <use xlink:href="#gentle-wave" x="48" y="3" fill="rgba(255,255,255,0.5)" />
                <use xlink:href="#gentle-wave" x="48" y="5" fill="rgba(255,255,255,0.3)" />
                <use xlink:href="#gentle-wave" x="48" y="7" fill="#fff" />
            </g>
        </svg>
    </div>

</body>
</html>


"@
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            $response.ContentType = "text/html"
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
            continue
        }

        $server = $query["server"]
        if (-not $server) {
            # If no server selected, redirect to root
            $response.StatusCode = 302
            $response.RedirectLocation = "/"
            $response.Close()
            continue
        }

        #region New code to close port

if ($path -eq "/shutdown") {
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset='UTF-8'>
    <title>Shutting Down</title>
    <style>
        body {
            font-family: 'Segoe UI', sans-serif;
            background: linear-gradient(60deg, rgba(84,58,183,0.1) 0%, rgba(0,172,193,0.1) 100%);
            margin: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100vh;
        }
        .shutdown-container {
            background: #ffffff;
            padding: 40px 60px;
            border-radius: 12px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            text-align: center;
        }
        h1 {
            color: #1A237E;
            font-size: 28px;
            margin-bottom: 20px;
        }
        p {
            color: #555;
            font-size: 16px;
        }
        .wave {
            margin-top: 30px;
            width: 100%;
            max-width: 400px;
        }
    </style>
</head>
<body>
    <div class="shutdown-container">
        <h1>Server is shutting down...</h1>
        <p>Thank you for using the SQL Job Dashboard.</p>
        <svg class="wave" viewBox="0 24 150 28" preserveAspectRatio="none" shape-rendering="auto">
            <defs>
                <path id="wave-path" d="M-160 44c30 0 58-18 88-18s58 18 88 18 58-18 88-18 58 18 88 18v44h-352z" />
            </defs>
            <g class="parallax">
                <use href="#wave-path" x="48" y="0" fill="rgba(84,58,183,0.3)" />
                <use href="#wave-path" x="48" y="3" fill="rgba(0,172,193,0.3)" />
                <use href="#wave-path" x="48" y="5" fill="rgba(0,172,193,0.2)" />
                <use href="#wave-path" x="48" y="7" fill="#fff" />
            </g>
        </svg>
    </div>
</body>
</html>
"@



    $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
    $response.ContentType = "text/html"
    $response.ContentEncoding = [System.Text.Encoding]::UTF8
    $response.ContentLength64 = $buffer.Length
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.OutputStream.Flush()
    $response.Close()

    # give the client a moment to receive & render the response before stopping listener
    Start-Sleep -Milliseconds 1000

    $global:stopListener = $true
    continue
}


        #endregion

        $jobs = Get-AllJobs $server

        

        if ($path -eq "/dashboard") {
            # Dashboard
            $summaryRows = ""
            foreach ($cat in $categories) {
                $count = ($jobs | Where-Object { $_.Category -ieq $cat }).Count
                $summaryRows += "<tr><td><a href='/category?server=$server&cat=$cat'>$cat</a></td><td>$count</td></tr>`n"
            }
            $serverOptions = ($serverList | ForEach-Object { 
                if ($_ -eq $server) { 
                    "<option value='$_' selected>$_</option>" 
                } else { 
                    "<option value='$_'>$_</option>" 
                } 
            }) -join ""
            #region DASHBOARD HTML 
            $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset='UTF-8'>
    <title>SQL Job Dashboard</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        html, body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(to right, #667eea, #764ba2);
            color: #333;
            height: 100%;
            width: 100%;
        }

        body {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: flex-start;
            min-height: 100vh;
            position: relative;
            padding-top: 40px;
        }

        .page-wrapper {
            width: 100%;
        }

        h1, h2, h3 {
            margin: 0;
        }

        h1 {
            font-size: 24px;
            color: white;
        }

        h2 {
            color: #667eea;
            text-align: center;
            margin-top: 20px;
        }

        h3 {
            color: #1A237E;
            text-align: center;
            font-size: 12px;
            margin-top: 10px;
        }

        .dashboard-header {
            background: linear-gradient(135deg,rgb(86, 106, 194) 0%,rgb(101, 64, 137) 100%);
            color: white;
            padding: 20px 32px;
            border-radius: 8px 8px 0 0;
            margin: 30px auto 0 auto;
            width: 95%;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }

        .header-content {
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 20px;
        }

        .logo-section {
            display: flex;
            align-items: center;
            gap: 15px;
        }

        .logo-section img {
            width: 50px;
            height: 50px;
            object-fit: contain;
        }

        .controls-section {
            display: flex;
            align-items: center;
            gap: 15px;
            flex-wrap: wrap;
        }

        .server-group {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .server-label {
            font-size: 16px;
            font-weight: bold;
            color: white;
        }

        .server-select {
            font-size: 16px;
            padding: 8px 12px;
            border-radius: 6px;
            border: none;
            background: white;
            color: #1A237E;
            min-width: 150px;
        }

        .search-group {
            display: flex;
            align-items: center;
            gap: 10px;
            background: rgba(255,255,255,0.1);
            padding: 8px 12px;
            border-radius: 6px;
            backdrop-filter: blur(10px);
        }

        .search-input {
            font-size: 15px;
            padding: 8px 12px;
            border-radius: 4px;
            border: none;
            background: white;
            color: #333;
            min-width: 200px;
        }

        .search-btn, .shutdown-btn {
            background: #00B8D4;
            color: #fff;
            border: none;
            border-radius: 4px;
            padding: 8px 18px;
            font-size: 14px;
            font-weight: bold;
            cursor: pointer;
            transition: background 0.3s ease;
            text-decoration: none;
        }

        .search-btn:hover {
            background: #0097A7;
        }

        .shutdown-btn {
            background: #D32F2F;
        }

        .shutdown-btn:hover {
            background: #B71C1C;
            color: white;
        }

        .exact-label {
            font-size: 13px;
            color: white;
            display: flex;
            align-items: center;
            gap: 5px;
        }

        .main-container {
            background: #fff;
            border-radius: 0 0 8px 8px;
            box-shadow: 0 2px 8px #aaa;
            margin: 0 auto 20px auto;
            padding: 24px 32px;
            width: 95%;
        }

        table {
            border-collapse: collapse;
            width: 100%;
            margin: 20px auto 30px auto;
        }

        th, td {
            border: 1px solid #B3E5FC;
            padding: 8px;
            text-align: left;
        }

        th {
            background: #667eea;
            color: #FFFFFF;
        }

        tr:nth-child(even) {
            background: #E3F2FD;
        }

        tr:hover {
            background: #B3E5FC;
        }

        a {
            color: #1A237E;
            text-decoration: none;
        }

        a:hover {
            color: #00B8D4;
        }

        /* WAVE SECTION */
        .wave-container {
            position: absolute;
            bottom: 0;
            left: 0;
            width: 100%;
            height: 120px;
            overflow: hidden;
            line-height: 0;
        }

        .waves {
            position: absolute;
            bottom: 0;
            width: 100%;
            height: 100%;
        }

        

        .parallax > use {
            animation: move-forever 25s cubic-bezier(.55,.5,.45,.5) infinite;
        }

        .parallax > use:nth-child(1) { animation-delay: -2s; animation-duration: 7s; }
        .parallax > use:nth-child(2) { animation-delay: -3s; animation-duration: 10s; }
        .parallax > use:nth-child(3) { animation-delay: -4s; animation-duration: 13s; }
        .parallax > use:nth-child(4) { animation-delay: -5s; animation-duration: 20s; }

        @keyframes move-forever {
            0% { transform: translate3d(-90px, 0, 0); }
            100% { transform: translate3d(85px, 0, 0); }
        }

        @media (max-width: 768px) {
            .header-content,
            .controls-section,
            .server-group,
            .search-group {
                flex-direction: column;
                align-items: stretch;
            }

            .dashboard-header, .main-container {
                width: 95%;
            }

            .search-input {
                min-width: auto;
            }
        }

        .logo-icon {
    width: 45px;
    height: 45px;
    background: white;
    border-radius: 6px;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-right: 12px;
}

.logo-bars {
    display: flex;
    flex-direction: row;   /* horizontal layout */
    gap: 2px;             /* spacing between bars */
    align-items: flex-end; /* align bars to the bottom */
    height: 16px;          /* height of tallest bar */
}

.logo-bar {
    width: 5px;
    background: rgb(86, 106, 194);
    border-radius: 1px;
}

/* Heights for the bars */
.logo-bar:nth-child(1) { height: 8px; }
.logo-bar:nth-child(2) { height: 12px; }
.logo-bar:nth-child(3) { height: 16px; }
    </style>
    <script>
        function changeServer(sel) {
            window.location.href = '/dashboard?server=' + encodeURIComponent(sel.value);
        }
        function doSearch() {
            var val = document.getElementById('searchInput').value;
            var exact = document.getElementById('exactMatch').checked ? '1' : '0';
            window.location.href = '/search?server=' + encodeURIComponent(document.getElementById('serverSelect').value) + '&criteria=' + encodeURIComponent(val) + '&exact=' + exact;
            return false;
        }
    </script>
</head>
<body>
<div class="page-wrapper">
    <div class="dashboard-header">
        <div class="header-content">
            <div class="logo-section">
                <div class="logo-icon">
                    <div class="logo-bars">
                        <div class="logo-bar"></div>
                        <div class="logo-bar"></div>
                        <div class="logo-bar"></div>
                    </div>
                </div>
                <h1>SQL Job Dashboard ($server)</h1>
            </div>

            <div class="controls-section">
                <div class="server-group">
                    <label for="serverSelect" class="server-label">SQL Server:</label>
                    <select id="serverSelect" class="server-select" onchange="changeServer(this)">
                        $serverOptions
                    </select>
                </div>

                <div class="search-group">
                    <form method="get" action="" onsubmit="return doSearch();" style="display: flex; align-items: center; gap: 10px; margin: 0;">
                        <input id="searchInput" class="search-input" type="text" placeholder="Search job name..." />
                        <label class="exact-label">
                            <input type="checkbox" id="exactMatch" />
                            Exact match
                        </label>
                        <button type="submit" class="search-btn">Search</button>
                        <a href='/' class="shutdown-btn">EXIT</a>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <div class="main-container">
        <h2>Summary by Category</h2>
        <table>
            <thead><tr><th>Category</th><th>Job Count</th></tr></thead>
            <tbody>
                $summaryRows
            </tbody>
        </table>
        <h3>Click on the category name to view the jobs</h3>
    </div>
</div>

<!-- WAVES -->
<div class="wave-container">
    <svg class="waves" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
         viewBox="0 24 150 28" preserveAspectRatio="none" shape-rendering="auto">
        <defs>
            <path id="gentle-wave" d="M-160 44c30 0 58-18 88-18s 58 18 
                88 18 58-18 88-18 58 18 88 18 v44h-352z" />
        </defs>
        <g class="parallax">
            <use xlink:href="#gentle-wave" x="48" y="0" fill="rgba(255,255,255,0.7)" />
            <use xlink:href="#gentle-wave" x="48" y="3" fill="rgba(255,255,255,0.5)" />
            <use xlink:href="#gentle-wave" x="48" y="5" fill="rgba(255,255,255,0.3)" />
            <use xlink:href="#gentle-wave" x="48" y="7" fill="#fff" />
        </g>
    </svg>
</div>
</body>
</html>

"@

#endregion DASHBOARD HTML
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            $response.ContentType = "text/html"
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
            continue
        }

        if ($path -eq "/category") {
            $cat = $query["cat"]
            $group = $jobs | Where-Object { $_.Category -ieq $cat }
            $rows = ""
            foreach ($row in $group) {
                $jobNameHtml = HtmlEncode($row.JobName)
                $rows += "<tr>
                    <td><a href='/jobhistory?server=$server&jobid=$($row.job_id)'>$jobNameHtml</a></td>
                    <td>$($row.Category)</td>
                    <td>$($row.HasSchedule)</td>
                    <td>$($row.ScheduleName)</td>
                    <td>$($row.ScheduleStatus)</td>
                    <td>$($row.Frequency)</td>
                    <td>$($row.JobStatus)</td>
                    <td>$($row.LastRunStatus)</td>
                    <td>$($row.LastRunDateTime)</td>
                    <td>$($row.NextRunDateTime)</td>
                </tr>`n"
            }
            if (-not $rows) {
                $rows = "<tr><td colspan='10' style='text-align:center;color:#D32F2F;'>No jobs found for this category.</td></tr>"
            }
#region CATEGORY HTML            
            $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset='UTF-8'>
    <title>Jobs in $cat</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        html, body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(to right, #667eea, #764ba2);
            color: #333;
            height: 100%;
            width: 100%;
            overflow: hidden;
        }

        body {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: flex-start;
            position: relative;
        }

        .container {
            background: #fff;
            border-radius: 8px;
            box-shadow: 0 2px 8px #aaa;
            margin-top: 30px;
            padding: 24px 32px;
            width: 95%;
            height: calc(100vh - 150px);
            overflow-y: auto;
            z-index: 1;
        }

        h2 {
            color: #667eea;
            text-align: center;
            margin-bottom: 20px;
        }

        h3 {
            color: #1A237E;
            text-align: center;
            font-size: 12px;
            margin-top: 10px;
        }

        table {
            border-collapse: collapse;
            width: 100%;
            margin: 20px auto 30px auto;
        }

        th, td {
            border: 1px solid #B3E5FC;
            font-size: 12px;
            padding: 8px;
            text-align: left;
        }

        th {
            background: #667eea;
            color: #FFFFFF;
        }

        tr:nth-child(even) {
            background: #E3F2FD;
        }

        tr:hover {
            background: #B3E5FC;
        }

        a {
            color: #1A237E;
            text-decoration: none;
            cursor: pointer;
        }

        a:hover {
            color: #00B8D4;
        }

        .nav-btn {
            background: #00B8D4;
            color: #fff;
            border: none;
            border-radius: 4px;
            padding: 8px 18px;
            font-size: 14px;
            font-weight: bold;
            cursor: pointer;
            margin-bottom: 15px;
            transition: background 0.3s ease;
        }

        .nav-btn:hover {
            background: #0097A7;
        }

        .container::-webkit-scrollbar {
            width: 8px;
        }

        .container::-webkit-scrollbar-thumb {
            background: #ccc;
            border-radius: 4px;
        }

        .wave-container {
            position: fixed;
            bottom: 0;
            left: 0;
            width: 100%;
            height: 120px;
            overflow: hidden;
            line-height: 0;
            z-index: 0;
        }

        .waves {
            position: absolute;
            bottom: 0;
            width: 100%;
            height: 100%;
        }

        .parallax > use {
            animation: move-forever 25s cubic-bezier(.55,.5,.45,.5) infinite;
        }

        .parallax > use:nth-child(1) { animation-delay: -2s; animation-duration: 7s; }
        .parallax > use:nth-child(2) { animation-delay: -3s; animation-duration: 10s; }
        .parallax > use:nth-child(3) { animation-delay: -4s; animation-duration: 13s; }
        .parallax > use:nth-child(4) { animation-delay: -5s; animation-duration: 20s; }

        @keyframes move-forever {
            0% { transform: translate3d(-90px, 0, 0); }
            100% { transform: translate3d(85px, 0, 0); }
        }

        @media (max-width: 768px) {
            .container {
                width: 95%;
                padding: 16px;
            }

            .nav-btn {
                width: 100%;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <button class="nav-btn" onclick="window.location.href='/dashboard?server=$server'">Back to Dashboard</button>
        <h2>Jobs in Category: $cat</h2>
        <table>
            <thead>
                <tr>
                    <th>Job Name</th>
                    <th>Category</th>
                    <th>Has Schedule?</th>
                    <th>Schedule Name</th>                
                    <th>Schedule Status</th>
                    <th>Frequency</th>
                    <th>Job Status</th>
                    <th>Last Run Status</th>
                    <th>Last Run Date & Time</th>
                    <th>Next Run Date & Time</th>
                </tr>
            </thead>
            <tbody>
                $rows
            </tbody>
        </table>
        <h3>Click on the job name to view its history</h3>
    </div>

    <!-- WAVES -->
    <div class="wave-container">
        <svg class="waves" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
             viewBox="0 24 150 28" preserveAspectRatio="none" shape-rendering="auto">
            <defs>
                <path id="gentle-wave" d="M-160 44c30 0 58-18 88-18s 58 18 
                    88 18 58-18 88-18 58 18 88 18 v44h-352z" />
            </defs>
            <g class="parallax">
                <use xlink:href="#gentle-wave" x="48" y="0" fill="rgba(255,255,255,0.7)" />
                <use xlink:href="#gentle-wave" x="48" y="3" fill="rgba(255,255,255,0.5)" />
                <use xlink:href="#gentle-wave" x="48" y="5" fill="rgba(255,255,255,0.3)" />
                <use xlink:href="#gentle-wave" x="48" y="7" fill="#fff" />
            </g>
        </svg>
    </div>
</body>
</html>


"@
#endregion CATEGORY HTML
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            $response.ContentType = "text/html"
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
            continue
        }

        if ($path -eq "/jobhistory") {
            $jobId = $query["jobid"]
            $job = $jobs | Where-Object { $_.job_id -eq $jobId } | Select-Object -First 1
            $jobName = HtmlEncode($job.JobName)
            
            $historyRows = Get-JobHistory $server $jobId | Sort-Object -Property @{ Expression = { [datetime]::ParseExact(($_.run_date.ToString().PadLeft(8,'0') + ' ' + $_.run_time.ToString().PadLeft(6,'0')), 'yyyyMMdd HHmmss', $null) }; Descending = $true }
$instances = @{}
foreach ($row in $historyRows) {
    $id = $row.instance_id
    if (-not $instances.ContainsKey($id)) { $instances[$id] = @() }
    $instances[$id] += $row
}

# Sort the keys by combined run_date and run_time descending
$sortedKeys = $instances.Keys | Sort-Object -Descending -Property @{
    Expression = {
        $run = $instances[$_] | Where-Object { $_.step_id -eq 0 } | Select-Object -First 1
        if ($run) {
            [datetime]::ParseExact(
                $run.run_date.ToString().PadLeft(8,'0') + ' ' + $run.run_time.ToString().PadLeft(6,'0'),
                'yyyyMMdd HHmmss',
                $null
            )
        } else {
            [datetime]::MinValue
        }
    }
}

$rows = ""
foreach ($id in $sortedKeys) {
    $steps = $instances[$id]
    $run = $steps | Where-Object { $_.step_id -eq 0 } | Select-Object -First 1
    if (-not $run) { continue }

    # Main row with expand/collapse button
    $rows += @"
<tr>
    <td>
        <button onclick='toggleSteps("$id")' style='
            background:#fff;
            border:1px solid #00B8D4;
            color:#00B8D4;
            border-radius:50%;
            width:22px;
            height:22px;
            font-weight:bold;
            font-size:15px;
            cursor:pointer;
            margin-right:6px;
            vertical-align:middle;
        '>+</button>
        $(Format-DateTime $run.run_date $run.run_time)
    </td>
    <td>$(switch ($run.run_status) { 0 {'Failed'} 1 {'Succeeded'} 2 {'Retry'} 3 {'Canceled'} default {'Unknown'} })</td>
    <td>$(Format-Duration $run.run_duration)</td>
    <td>$(HtmlEncode $run.message)</td>
    <td>$(HtmlEncode $run.sql_severity)</td>
</tr>
"@

    # Step rows (hidden by default)
    foreach ($step in $steps | Where-Object { $_.step_id -gt 0 }) {
        $rows += @"
<tr class='step-row' data-parent='$id' style='display:none; background:#F5F7FA;'>
    <td></td>
    <td>Step $($step.step_id): $(HtmlEncode $step.step_name)</td>
    <td>$(Format-Duration $step.run_duration)</td>
    <td>$(HtmlEncode $step.message)</td>
    <td>$(HtmlEncode $step.sql_severity)</td>
</tr>
"@
    }
}



            if (-not $rows) {
                $rows = "<tr><td colspan='10' style='text-align:center;color:#D32F2F;'>No history found for this job.</td></tr>"
            }
#region JOB HISTORY HTML            
            $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset='UTF-8'>
    <title>Job History for $jobName</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

    html, body {
        font-family: 'Inter', sans-serif;
        background: linear-gradient(to right, #667eea, #764ba2);
        color: #333;
        height: 100%;
        width: 100%;
        overflow: hidden; /* Prevent full-page scroll */
    }

    body {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: flex-start;
        position: relative;
    }

    .container {
        background: #fff;
        border-radius: 8px;
        box-shadow: 0 2px 8px #aaa;
        margin-top: 30px;
        padding: 24px 32px;
        width: 95%;
        height: calc(100vh - 150px); /* Adjust height to fit screen minus header/waves */
        overflow-y: auto; /* Enable scrolling inside the container */
        z-index: 1;
    }

    .containerTable {
        background: #fff;
        border-radius: 8px;
        box-shadow: 0 2px 8px #aaa;
        margin-top: 10px;
        padding: 24px 32px;
        width: 100%;
        height: calc(100vh - 150px); /* Adjust height to fit screen minus header/waves */
        overflow-y: auto; /* Enable scrolling inside the container */
        z-index: 1;
    }    

        h2 {
            color: #667eea;
            text-align: center;
            margin-bottom: 20px;
        }

        table {
            border-collapse: collapse;
            width: 100%;
            margin: 20px auto 30px auto;
        }

        th, td {
            border: 1px solid #B3E5FC;
            font-size: 12px;
            padding: 8px;
            text-align: left;
        }

        th {
            background: #667eea;
            color: #FFFFFF;
        }

        tr:nth-child(even) {
            background: #E3F2FD;
        }

        tr:hover {
            background: #B3E5FC;
        }

        a {
            color: #1A237E;
            text-decoration: none;
            cursor: pointer;
        }

        a:hover {
            color: #00B8D4;
        }

        .nav-btn {
            background: #00B8D4;
            color: #fff;
            border: none;
            border-radius: 4px;
            padding: 8px 18px;
            font-size: 14px;
            font-weight: bold;
            cursor: pointer;
            margin-bottom: 15px;
            transition: background 0.3s ease;
        }

        .nav-btn:hover {
            background: #0097A7;
        }

        /* WAVES */
        .wave-container {
        position: fixed;
        bottom: 0;
        left: 0;
        width: 100%;
        height: 120px;
        overflow: hidden;
        line-height: 0;
        z-index: 0;
    }

    .waves {
        position: absolute;
        bottom: 0;
        width: 100%;
        height: 100%;
    }

    /* Keep content above waves */
    .container::-webkit-scrollbar {
        width: 8px;
    }

    .container::-webkit-scrollbar-thumb {
        background: #ccc;
        border-radius: 4px;
    }

    .containerTable::-webkit-scrollbar {
        width: 8px;
    }

    .containerTable::-webkit-scrollbar-thumb {
        background: #ccc;
        border-radius: 4px;
    }

        .parallax > use {
            animation: move-forever 25s cubic-bezier(.55,.5,.45,.5) infinite;
        }

        .parallax > use:nth-child(1) { animation-delay: -2s; animation-duration: 7s; }
        .parallax > use:nth-child(2) { animation-delay: -3s; animation-duration: 10s; }
        .parallax > use:nth-child(3) { animation-delay: -4s; animation-duration: 13s; }
        .parallax > use:nth-child(4) { animation-delay: -5s; animation-duration: 20s; }

        @keyframes move-forever {
            0% { transform: translate3d(-90px, 0, 0); }
            100% { transform: translate3d(85px, 0, 0); }
        }

        @media (max-width: 768px) {
        .container {
            width: 95%;
            padding: 16px;
        }

            .nav-btn {
                width: 100%;
            }
        }
            .steps {
    background: #F5F7FA;
}
    </style>


    
</head>
<body>
    <div class="container">
        <button class="nav-btn" onclick="window.location.href='/category?server=$server&cat=$($job.Category)'">Back to Category</button>
        <h2>Job History for $jobName</h2>
        <div class="containerTable">
            <table>
                <thead>
                    <tr>
                        <th>Run Date</th>
                        <th>Status</th>
                        <th>Duration</th>
                        <th>Message</th>
                        <th>Severity</th>
                    </tr>
                </thead>
                <tbody>
                    $rows
                </tbody>
            </table>
        </div>    
    </div>

    <!-- WAVES -->
    <div class="wave-container">
        <svg class="waves" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
             viewBox="0 24 150 28" preserveAspectRatio="none" shape-rendering="auto">
            <defs>
                <path id="gentle-wave" d="M-160 44c30 0 58-18 88-18s 58 18 
                    88 18 58-18 88-18 58 18 88 18 v44h-352z" />
            </defs>
            <g class="parallax">
                <use xlink:href="#gentle-wave" x="48" y="0" fill="rgba(255,255,255,0.7)" />
                <use xlink:href="#gentle-wave" x="48" y="3" fill="rgba(255,255,255,0.5)" />
                <use xlink:href="#gentle-wave" x="48" y="5" fill="rgba(255,255,255,0.3)" />
                <use xlink:href="#gentle-wave" x="48" y="7" fill="#fff" />
            </g>
        </svg>
    </div>


<script>
function toggleSteps(instanceId) {
    var rows = document.querySelectorAll('tr.step-row[data-parent="' + instanceId + '"]');
    rows.forEach(function(row) {
        row.style.display = (row.style.display === 'none' ? '' : 'none');
    });
}
</script>

</body>
</html>


"@
#endregion JOB HISTORY HTML
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            $response.ContentType = "text/html"
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
            continue
        }

        if ($path -eq "/search") {
            $criteria = $query["criteria"]
            $exact = $query["exact"] -eq "1"
            $filtered = if ($exact) {
                $jobs | Where-Object { $_.JobName -eq $criteria }
            } else {
                $jobs | Where-Object { $_.JobName -like "*$criteria*" }
            }
            $rows = ""
            foreach ($row in $filtered) {
                $jobNameHtml = HtmlEncode($row.JobName)
                $rows += "<tr>
                    <td><a href='/jobhistory?server=$server&jobid=$($row.job_id)'>$jobNameHtml</a></td>
                    <td>$($row.Category)</td>
                    <td>$($row.HasSchedule)</td>
                    <td>$($row.ScheduleName)</td>
                    <td>$($row.ScheduleStatus)</td>
                    <td>$($row.Frequency)</td>
                    <td>$($row.JobStatus)</td>
                    <td>$($row.LastRunStatus)</td>
                    <td>$($row.LastRunDateTime)</td>
                    <td>$($row.NextRunDateTime)</td>
                </tr>`n"
            }
            if (-not $rows) {
                $rows = "<tr><td colspan='10' style='text-align:center;color:#D32F2F;'>No jobs found for '$criteria'.</td></tr>"
            }
#region SEARCH HTML            
            $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset='UTF-8'>
    <title>Search Results for $criteria</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        html, body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(to right, #667eea, #764ba2);
            color: #333;
            height: 100%;
            width: 100%;
            overflow: hidden;
        }

        body {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: flex-start;
            position: relative;
        }

        .container {
            background: #fff;
            border-radius: 8px;
            box-shadow: 0 2px 8px #aaa;
            margin-top: 30px;
            padding: 24px 32px;
            width: 95%;
            height: calc(100vh - 150px);
            overflow-y: auto;
            z-index: 1;
        }

        h2 {
            color: #667eea;
            text-align: center;
            margin-bottom: 20px;
        }

        table {
            border-collapse: collapse;
            width: 100%;
            margin: 20px auto 30px auto;
        }

        th, td {
            border: 1px solid #B3E5FC;
            font-size: 12px;
            padding: 8px;
            text-align: left;
        }

        th {
            background: #667eea;
            color: #FFFFFF;
        }

        tr:nth-child(even) {
            background: #E3F2FD;
        }

        tr:hover {
            background: #B3E5FC;
        }

        a {
            color: #1A237E;
            text-decoration: none;
            cursor: pointer;
        }

        a:hover {
            color: #00B8D4;
        }

        .nav-btn {
            background: #00B8D4;
            color: #fff;
            border: none;
            border-radius: 4px;
            padding: 8px 18px;
            font-size: 14px;
            font-weight: bold;
            cursor: pointer;
            margin-bottom: 15px;
            transition: background 0.3s ease;
        }

        .nav-btn:hover {
            background: #0097A7;
        }

        .container::-webkit-scrollbar {
            width: 8px;
        }

        .container::-webkit-scrollbar-thumb {
            background: #ccc;
            border-radius: 4px;
        }

        .wave-container {
            position: fixed;
            bottom: 0;
            left: 0;
            width: 100%;
            height: 120px;
            overflow: hidden;
            line-height: 0;
            z-index: 0;
        }

        .waves {
            position: absolute;
            bottom: 0;
            width: 100%;
            height: 100%;
        }

        .parallax > use {
            animation: move-forever 25s cubic-bezier(.55,.5,.45,.5) infinite;
        }

        .parallax > use:nth-child(1) { animation-delay: -2s; animation-duration: 7s; }
        .parallax > use:nth-child(2) { animation-delay: -3s; animation-duration: 10s; }
        .parallax > use:nth-child(3) { animation-delay: -4s; animation-duration: 13s; }
        .parallax > use:nth-child(4) { animation-delay: -5s; animation-duration: 20s; }

        @keyframes move-forever {
            0% { transform: translate3d(-90px, 0, 0); }
            100% { transform: translate3d(85px, 0, 0); }
        }

        @media (max-width: 768px) {
            .container {
                width: 95%;
                padding: 16px;
            }

            .nav-btn {
                width: 100%;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <button class="nav-btn" onclick="window.location.href='/dashboard?server=$server'">Back to Dashboard</button>
        <h2>Search Results for '$criteria'</h2>
        <table>
            <thead>
                <tr>
                    <th>Job Name</th>
                    <th>Category</th>
                    <th>Has Schedule?</th>
                    <th>Schedule Name</th>                
                    <th>Schedule Status</th>
                    <th>Frequency</th>
                    <th>Job Status</th>
                    <th>Last Run Status</th>
                    <th>Last Run Date & Time</th>
                    <th>Next Run Date & Time</th>
                </tr>
            </thead>
            <tbody>
                $rows
            </tbody>
        </table>
    </div>

    <!-- WAVES -->
    <div class="wave-container">
        <svg class="waves" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
             viewBox="0 24 150 28" preserveAspectRatio="none" shape-rendering="auto">
            <defs>
                <path id="gentle-wave" d="M-160 44c30 0 58-18 88-18s 58 18 
                    88 18 58-18 88-18 58 18 88 18 v44h-352z" />
            </defs>
            <g class="parallax">
                <use xlink:href="#gentle-wave" x="48" y="0" fill="rgba(255,255,255,0.7)" />
                <use xlink:href="#gentle-wave" x="48" y="3" fill="rgba(255,255,255,0.5)" />
                <use xlink:href="#gentle-wave" x="48" y="5" fill="rgba(255,255,255,0.3)" />
                <use xlink:href="#gentle-wave" x="48" y="7" fill="#fff" />
            </g>
        </svg>
    </div>
</body>
</html>


"@
#endregion SEARCH HTML
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            $response.ContentType = "text/html"
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
            continue
        }

        # Default: 404
        $response.StatusCode = 404
        $buffer = [System.Text.Encoding]::UTF8.GetBytes("<h1>404 Not Found</h1>")
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        $response.Close()
    } catch {
        $response.StatusCode = 500
        $buffer = [System.Text.Encoding]::UTF8.GetBytes("<h1>500 Internal Server Error</h1><pre>$($_.Exception.Message)</pre>")
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        $response.Close()
    }
 }

$listener.Stop()
Write-Host "Dashboard stopped on http://localhost:$port/"