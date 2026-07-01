# PowerShell Lightweight HTTP Web Server
# This script starts a local server on port 3000 to run the Quiz Clone without any external dependencies (Node.js/Python).
# It handles clean routes like /anime and /desenho by serving the corresponding HTML files.

$port = 3000
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")

try {
    $listener.Start()
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "  Servidor Web Local iniciado com sucesso!" -ForegroundColor Green
    Write-Host "  Acesse: http://localhost:$port" -ForegroundColor Cyan
    Write-Host "  Pressione Ctrl+C no terminal para parar o servidor." -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Green
} catch {
    Write-Error "Não foi possível iniciar o servidor. Verifique se a porta $port já está em uso."
    exit
}

# Keep running until stopped
while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
    } catch {
        # Listener was stopped
        break
    }
    
    $request = $context.Request
    $response = $context.Response
    
    $urlPath = $request.Url.LocalPath
    Write-Host "[Request] $urlPath" -ForegroundColor DarkGray
    
    # Map root path
    if ($urlPath -eq "/") {
        $urlPath = "/index.html"
    }
    
    # Check for clean URLs (routes without .html like /anime or /desenho)
    $localFile = Join-Path $pwd.Path $urlPath
    if (-not (Test-Path $localFile -PathType Leaf)) {
        if (Test-Path "$localFile.html" -PathType Leaf) {
            $urlPath = "$urlPath.html"
            $localFile = "$localFile.html"
        }
    }
    
    # Serve the file if found
    if (Test-Path $localFile -PathType Leaf) {
        $bytes = [System.IO.File]::ReadAllBytes($localFile)
        
        # Determine content type
        $ext = [System.IO.Path]::GetExtension($localFile).ToLower()
        $contentType = "text/plain"
        if ($ext -eq ".html" -or $ext -eq ".htm") { $contentType = "text/html; charset=utf-8" }
        elseif ($ext -eq ".css") { $contentType = "text/css" }
        elseif ($ext -eq ".js") { $contentType = "application/javascript" }
        elseif ($ext -eq ".png") { $contentType = "image/png" }
        elseif ($ext -eq ".jpg" -or $ext -eq ".jpeg") { $contentType = "image/jpeg" }
        elseif ($ext -eq ".gif") { $contentType = "image/gif" }
        elseif ($ext -eq ".svg") { $contentType = "image/svg+xml" }
        elseif ($ext -eq ".webp") { $contentType = "image/webp" }
        
        $response.ContentType = $contentType
        $response.ContentLength64 = $bytes.Length
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
        # 404 Not Found
        $response.StatusCode = 404
        $errorBytes = [System.Text.Encoding]::UTF8.GetBytes("404 - Arquivo não encontrado")
        $response.OutputStream.Write($errorBytes, 0, $errorBytes.Length)
    }
    
    try {
        $response.Close()
    } catch {
        # Connection closed prematurely by browser
    }
}
