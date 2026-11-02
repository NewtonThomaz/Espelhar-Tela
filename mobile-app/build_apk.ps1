$ErrorActionPreference = "Stop"

$appDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$buildDir = Join-Path $appDir "build"

# Localizar Android SDK
$sdkDir = $env:ANDROID_HOME
if (-not $sdkDir -or -not (Test-Path $sdkDir)) {
    $sdkDir = $env:ANDROID_SDK_ROOT
}
if (-not $sdkDir -or -not (Test-Path $sdkDir)) {
    $sdkDir = Join-Path $env:LOCALAPPDATA "Android\Sdk"
}
if (-not (Test-Path $sdkDir)) {
    throw "Android SDK nao encontrado. Defina a variavel ANDROID_HOME."
}

# Localizar versao mais recente de build-tools e platform
$buildToolsDir = Get-ChildItem (Join-Path $sdkDir "build-tools") -Directory | Sort-Object Name -Descending | Select-Object -First 1
if (-not $buildToolsDir) {
    throw "Nenhum build-tools encontrado no Android SDK."
}
$buildTools = $buildToolsDir.FullName

$platformDir = Get-ChildItem (Join-Path $sdkDir "platforms") -Directory | Sort-Object Name -Descending | Select-Object -First 1
if (-not $platformDir) {
    throw "Nenhuma plataforma Android encontrada no Android SDK."
}
$androidJar = Join-Path $platformDir.FullName "android.jar"

# Localizar JDK
$jdkBin = $null
if ($env:JAVA_HOME -and (Test-Path (Join-Path $env:JAVA_HOME "bin\javac.exe"))) {
    $jdkBin = Join-Path $env:JAVA_HOME "bin"
} elseif (Test-Path "C:\Program Files\Android\Android Studio\jbr\bin\javac.exe") {
    $jdkBin = "C:\Program Files\Android\Android Studio\jbr\bin"
} else {
    $javacCmd = Get-Command javac.exe -ErrorAction SilentlyContinue
    if ($javacCmd) {
        $jdkBin = Split-Path $javacCmd.Source
    } else {
        throw "JDK nao encontrado. Instale o Java SDK ou configure JAVA_HOME."
    }
}

if (Test-Path $buildDir) {
    Remove-Item $buildDir -Recurse -Force
}
New-Item -ItemType Directory -Path "$buildDir\gen", "$buildDir\obj", "$buildDir\apk" -Force | Out-Null

Write-Host "1. Compilando recursos com aapt2..."
& "$buildTools\aapt2.exe" compile --dir "$appDir\res" -o "$buildDir\resources.zip"
& "$buildTools\aapt2.exe" link -o "$buildDir\apk\unsigned.apk" `
    -I $androidJar `
    --manifest "$appDir\AndroidManifest.xml" `
    --java "$buildDir\gen" `
    "$buildDir\resources.zip"

Write-Host "2. Compilando classes Java com javac..."
$javaFiles = Get-ChildItem -Path "$appDir\src", "$buildDir\gen" -Filter "*.java" -Recurse | Select-Object -ExpandProperty FullName
& "$jdkBin\javac.exe" -source 1.8 -target 1.8 -encoding UTF-8 -bootclasspath $androidJar -classpath $androidJar -d "$buildDir\obj" $javaFiles

Write-Host "3. Convertendo bytecode para DEX com d8..."
$classFiles = Get-ChildItem -Path "$buildDir\obj" -Filter "*.class" -Recurse | Select-Object -ExpandProperty FullName
$env:JAVA_HOME = Split-Path $jdkBin
$env:PATH = "$jdkBin;$env:PATH"
& "$buildTools\d8.bat" --lib $androidJar --output "$buildDir\apk" $classFiles

Write-Host "4. Empacotando classes.dex e alinhando com zipalign..."
Push-Location "$buildDir\apk"
& "$jdkBin\jar.exe" -uf unsigned.apk classes.dex
Pop-Location

& "$buildTools\zipalign.exe" -f 4 "$buildDir\apk\unsigned.apk" "$buildDir\apk\aligned.apk"

$keystore = Join-Path $appDir "keystore.jks"
if (-not (Test-Path $keystore)) {
    Write-Host "5. Gerando chave de assinatura do APK..."
    & "$jdkBin\keytool.exe" -genkeypair -v -keystore $keystore -alias espelhar -keyalg RSA -keysize 2048 -validity 10000 -storepass android -keypass android -dname "CN=EspelharTela, OU=Dev, O=Newton, L=BR, S=BR, C=BR"
}

$finalApk = Join-Path $appDir "..\EspelharTela.apk"
Write-Host "6. Assinando APK final..."
& "$buildTools\apksigner.bat" sign --ks $keystore --ks-pass pass:android --key-pass pass:android --out $finalApk "$buildDir\apk\aligned.apk"

Remove-Item $buildDir -Recurse -Force
Get-Item $finalApk | Select-Object Name, Length, LastWriteTime
