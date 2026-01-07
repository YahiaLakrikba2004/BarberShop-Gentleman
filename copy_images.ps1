$source = "C:\Users\lakri\Desktop"
$dest = "c:\Users\lakri\Documents\GitHub\BarberShop-Gentleman\assets\images\gallery"
$files = @{
    "559369300_18059933282453525_1390866222774554323_n..jpg" = "gallery_user_1.jpg";
    "568191015_18051660764649505_6742582659389823600_n..jpg" = "gallery_user_2.jpg";
    "568826707_18026890292734034_4452958032942761751_n..jpg" = "gallery_user_3.jpg";
    "569768428_18084831305058443_584600004985830437_n..jpg" = "gallery_user_4.jpg";
    "570357856_18070385330029675_8043649317022584049_n..jpg" = "gallery_user_5.jpg";
    "579728175_18170565385374025_2788789791144170794_n..jpg" = "gallery_user_6.jpg";
    "581708172_18244835692290888_4696405989649926804_n..jpg" = "gallery_user_7.jpg"
}

if (!(Test-Path $dest)) { New-Item -ItemType Directory -Force -Path $dest }

foreach ($key in $files.Keys) {
    $srcPath = Join-Path $source $key
    $destPath = Join-Path $dest $files[$key]
    if (Test-Path $srcPath) {
        Copy-Item $srcPath $destPath -Force
        Write-Host "Copied $key to $files[$key]"
    } else {
        Write-Host "Source not found: $srcPath"
    }
}
