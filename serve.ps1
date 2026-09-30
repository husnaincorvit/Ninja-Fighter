$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:8080/")
$listener.Start()
Write-Host "Server started! Open http://localhost:8080 in your browser."
Write-Host "Press Ctrl+C to stop."
try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        $localPath = $request.Url.LocalPath
        if ($localPath -eq "/") { $localPath = "/index.html" }
        
        # Prevent directory traversal
        $localPath = $localPath.Replace("..", "")
        $fullPath = Join-Path (Get-Location).Path $localPath
        
        if (Test-Path $fullPath -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($fullPath)
            $response.ContentLength64 = $bytes.Length
            
            if ($fullPath -match "\.js$") { $response.ContentType = "application/javascript" }
            elseif ($fullPath -match "\.css$") { $response.ContentType = "text/css" }
            elseif ($fullPath -match "\.html$") { $response.ContentType = "text/html" }
            
            try {
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            } catch [System.Net.HttpListenerException] {
                # Browsers can cancel a request during navigation; keep serving later requests.
            }
        } else {
            $response.StatusCode = 404
        }
        $response.Close()
    }
} finally {
    $listener.Stop()
}
