$source = "C:\Users\lakri\.gemini\antigravity\brain\d50b5033-b50d-4388-a0be-f177b284119c\icon_premium_option_2_gentleman_monogram_1766769902010.png"
$dest = "c:\Users\lakri\Documents\GitHub\BarberShop-Gentleman\assets\images\icon_premium_v2.png"
Write-Host "Copying from $source to $dest"
Copy-Item -Path $source -Destination $dest -Force
if (Test-Path $dest) {
    Write-Host "Success: File exists"
} else {
    Write-Host "Error: File not found"
    exit 1
}
