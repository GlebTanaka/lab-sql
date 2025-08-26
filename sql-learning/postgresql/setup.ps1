# Configuration
$ContainerName = "postgres-db"
$ImageName = "postgres:16-alpine"
$DataDir = "./data"
$Port = 5432

# Load .env file
$EnvFile = ".env"
$PostgresPassword = $null

if (Test-Path $EnvFile) {
    Get-Content $EnvFile | Where-Object { $_ -notmatch '^#' -and $_ -match '=' } |
        ForEach-Object {
            $parts = $_ -split '=', 2
            $name = $parts[0].Trim()
            $value = $parts[1].Trim()
            [System.Environment]::SetEnvironmentVariable($name, $value)

            # Store password in a separate variable for additional security
            if ($name -eq "POSTGRES_PASSWORD") {
                $PostgresPassword = $value
            }
        }
} else {
    Write-Warning ".env file not found. Set POSTGRES_PASSWORD manually or create one."
}

# Make sure we have a password, either from the .env file or from the environment
if (-not $PostgresPassword) {
    $PostgresPassword = $env:POSTGRES_PASSWORD
}

if (-not $PostgresPassword) {
    Write-Error "POSTGRES_PASSWORD is not set. Please set it in .env file or as an environment variable."
    exit 1
}

# Set the environment variable explicitly
$env:POSTGRES_PASSWORD = $PostgresPassword

# Ensure data directory exists
if (-not (Test-Path $DataDir)) {
    New-Item -ItemType Directory -Path $DataDir | Out-Null
}

# Check if container exists
$containerExists = podman container exists $ContainerName

if ($containerExists) {
    $running = podman ps --filter "name=$ContainerName" --filter "status=running" | Select-String $ContainerName
    if ($running) {
        Write-Output "✅ Container '$ContainerName' is already running."
    } else {
        Write-Output "🔁 Starting existing container '$ContainerName'..."
        podman start $ContainerName
    }
} else {
    Write-Output "🚀 Creating and starting container '$ContainerName'..."
    Write-Output "ContainerName: $ContainerName"
    Write-Output "POSTGRES_PASSWORD: $env:POSTGRES_PASSWORD"
    Write-Output "DataDir: $(Resolve-Path $DataDir)"
    Write-Output "Port: $Port"
    Write-Output "ImageName: $ImageName"
    podman run -d `
        --name $ContainerName `
        -e POSTGRES_PASSWORD="$PostgresPassword" `
        -v "$(Resolve-Path $DataDir):/var/lib/postgresql/data" `
        -p $Port:5432 `
        $ImageName

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to start container. Exit code: $LASTEXITCODE"
        exit $LASTEXITCODE
    } else {
        Write-Output "✅ Container created and started successfully."
    }
}