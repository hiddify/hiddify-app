$NDK_VERSION = "29.0.14206865"
$LocalAppData = $env:LOCALAPPDATA
$NDK_BIN = "$LocalAppData\Android\Sdk\ndk\$NDK_VERSION\toolchains\llvm\prebuilt\windows-x86_64\bin"

if (-not (Test-Path $NDK_BIN)) {
    Write-Error "NDK path not found: $NDK_BIN"
    exit 1
}

# Create directories (relative to root)
New-Item -ItemType Directory -Force -Path "android/app/src/main/jniLibs/arm64-v8a" | Out-Null
New-Item -ItemType Directory -Force -Path "android/app/src/main/jniLibs/armeabi-v7a" | Out-Null
New-Item -ItemType Directory -Force -Path "android/app/src/main/jniLibs/x86_64" | Out-Null

# Set CGO_ENABLED
$env:CGO_ENABLED = 1

# Move into libcore to build
Push-Location libcore

try {
    # Common flags
    # -ldflags="-checklinkname=0" is required for some libs accessing internal runtime/net symbols in newer Go versions
    $LDFLAGS = "-checklinkname=0 -s -w"

    # ARM64
    Write-Host "Building for arm64-v8a..."
    $env:GOOS = "android"
    $env:GOARCH = "arm64"
    $env:CC = "$NDK_BIN\aarch64-linux-android26-clang.cmd"
    go build -buildmode=c-shared -ldflags="$LDFLAGS" -o "../android/app/src/main/jniLibs/arm64-v8a/libcore.so" ./mobile
    if ($LASTEXITCODE -ne 0) { throw "Build failed for arm64" }

    # ARMv7
    Write-Host "Building for armeabi-v7a..."
    $env:GOOS = "android"
    $env:GOARCH = "arm"
    $env:GOARM = "7"
    $env:CC = "$NDK_BIN\armv7a-linux-androideabi26-clang.cmd"
    go build -buildmode=c-shared -ldflags="$LDFLAGS" -o "../android/app/src/main/jniLibs/armeabi-v7a/libcore.so" ./mobile
    if ($LASTEXITCODE -ne 0) { throw "Build failed for armv7" }

    # x86_64
    Write-Host "Building for x86_64..."
    $env:GOOS = "android"
    $env:GOARCH = "amd64"
    $env:CC = "$NDK_BIN\x86_64-linux-android26-clang.cmd"
    go build -buildmode=c-shared -ldflags="$LDFLAGS" -o "../android/app/src/main/jniLibs/x86_64/libcore.so" ./mobile
    if ($LASTEXITCODE -ne 0) { throw "Build failed for x86_64" }

    Write-Host "Build Complete!"
}
catch {
    Write-Error $_
    exit 1
}
finally {
    Pop-Location
}
