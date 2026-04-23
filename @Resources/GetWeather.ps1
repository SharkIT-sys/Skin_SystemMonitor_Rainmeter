$ErrorActionPreference = "Stop"

# Fetch data from wttr.in
$data = Invoke-RestMethod -Uri "https://wttr.in/?format=j1"

# Flatten hourly data
$allHourly = @()
foreach ($day in $data.weather) {
    foreach ($hour in $day.hourly) {
        $allHourly += $hour
    }
}

$currentIdx = [math]::Floor((Get-Date).Hour / 3)

function Get-WeatherEmoji ($codeStr) {
    $c_sunny = [char]::ConvertFromUtf32(0x2600)
    $c_pcloudy = [char]::ConvertFromUtf32(0x26C5)
    $c_cloudy = [char]::ConvertFromUtf32(0x2601)
    $c_mist = [char]::ConvertFromUtf32(0x1F32B)
    $c_prsn = [char]::ConvertFromUtf32(0x1F326)
    $c_snow = [char]::ConvertFromUtf32(0x1F328)
    $c_thunder = [char]::ConvertFromUtf32(0x26C8)
    $c_ice = [char]::ConvertFromUtf32(0x2744)
    $c_rain = [char]::ConvertFromUtf32(0x1F327)

    $weatherCodes = @{
        "113" = $c_sunny; "116" = $c_pcloudy; "119" = $c_cloudy; "122" = $c_cloudy; "143" = $c_mist; 
        "176" = $c_prsn; "179" = $c_snow; "182" = $c_snow; "185" = $c_snow; "200" = $c_thunder; 
        "227" = $c_snow; "230" = $c_ice; "248" = $c_mist; "260" = $c_mist; "263" = $c_rain; 
        "266" = $c_rain; "281" = $c_rain; "284" = $c_rain; "293" = $c_prsn; "296" = $c_rain; 
        "299" = $c_rain; "302" = $c_rain; "305" = $c_rain; "308" = $c_rain; "311" = $c_rain; 
        "314" = $c_rain; "317" = $c_rain; "320" = $c_snow; "323" = $c_snow; "326" = $c_snow; 
        "329" = $c_ice; "332" = $c_ice; "335" = $c_ice; "338" = $c_ice; "350" = $c_snow; 
        "353" = $c_prsn; "356" = $c_rain; "359" = $c_rain; "362" = $c_snow; "365" = $c_snow; 
        "368" = $c_snow; "371" = $c_ice; "374" = $c_snow; "377" = $c_snow; "386" = $c_thunder; 
        "389" = $c_thunder; "392" = $c_thunder; "395" = $c_ice
    }
    
    if ($weatherCodes.ContainsKey($codeStr)) { return $weatherCodes[$codeStr] }
    return [char]::ConvertFromUtf32(0x2753)
}

function Get-ForecastLine ($offsetHours) {
    $targetIdx = $currentIdx + [math]::Floor($offsetHours / 3)
    if ($targetIdx -ge $allHourly.Count) { $targetIdx = $allHourly.Count - 1 }
    $hourData = $allHourly[$targetIdx]
    
    $code = [string]$hourData.weatherCode
    $temp = $hourData.tempC
    $emoji = Get-WeatherEmoji $code
    return "$emoji ${temp}$([char]176)C"
}

# 1. Get Current
$currCond = $data.current_condition[0]
$currEmoji = Get-WeatherEmoji ([string]$currCond.weatherCode)
$currTemp = $currCond.temp_C
$fAhora = "$currEmoji ${currTemp}$([char]176)C"

# 2. Get 8h, 24h, 48h, 72h
$f8  = Get-ForecastLine 8
$f24 = Get-ForecastLine 24
$f48 = Get-ForecastLine 48
$f72 = Get-ForecastLine 72

# 3. Get Moon Phases
function Get-MoonPhaseEmoji ($date) {
    $knownNewMoon = [datetime]"2000-01-06"
    $diff = ($date - $knownNewMoon).TotalDays
    $lunarCycle = 29.53058867
    $phase = ($diff % $lunarCycle) / $lunarCycle
    if ($phase -lt 0) { $phase += 1 }
    
    if ($phase -lt 0.0625 -or $phase -ge 0.9375) { return [char]::ConvertFromUtf32(0x1F311) }
    elseif ($phase -lt 0.1875) { return [char]::ConvertFromUtf32(0x1F312) }
    elseif ($phase -lt 0.3125) { return [char]::ConvertFromUtf32(0x1F313) }
    elseif ($phase -lt 0.4375) { return [char]::ConvertFromUtf32(0x1F314) }
    elseif ($phase -lt 0.5625) { return [char]::ConvertFromUtf32(0x1F315) }
    elseif ($phase -lt 0.6875) { return [char]::ConvertFromUtf32(0x1F316) }
    elseif ($phase -lt 0.8125) { return [char]::ConvertFromUtf32(0x1F317) }
    else { return [char]::ConvertFromUtf32(0x1F318) }
}

$today = Get-Date
$m0 = Get-MoonPhaseEmoji $today
$m1 = Get-MoonPhaseEmoji $today.AddDays(1)
$m2 = Get-MoonPhaseEmoji $today.AddDays(2)
$m3 = Get-MoonPhaseEmoji $today.AddDays(3)
$m4 = Get-MoonPhaseEmoji $today.AddDays(4)

$outputFile = Join-Path $PSScriptRoot "Weather.txt"
$content = "$fAhora`n$f8`n$f24`n$f48`n$f72`n$m0`n$m1`n$m2`n$m3`n$m4"
# Using Unicode saves as UTF-16LE with BOM
[IO.File]::WriteAllText($outputFile, $content, [System.Text.Encoding]::Unicode)
