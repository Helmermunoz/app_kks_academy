# Code-native monogram using the existing academy colors. No external image assets.
Add-Type -AssemblyName System.Drawing
$iconRoot = Join-Path $PSScriptRoot '..\web\icons'
foreach ($iconSize in @(192,512)) {
    $bitmap = [System.Drawing.Bitmap]::new($iconSize,$iconSize)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#080f1d'))
    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml('#c52e42'))
    $graphics.FillEllipse($brush,$iconSize*.15,$iconSize*.15,$iconSize*.7,$iconSize*.7)
    $font = [System.Drawing.Font]::new('Arial',$iconSize*.20,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Pixel)
    $format = [System.Drawing.StringFormat]::new()
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $graphics.DrawString('KKs',$font,[System.Drawing.Brushes]::White,[System.Drawing.RectangleF]::new(0,0,$iconSize,$iconSize),$format)
    foreach ($iconName in @("Icon-$iconSize.png","Icon-maskable-$iconSize.png")) {
      $bitmap.Save((Join-Path $iconRoot $iconName),[System.Drawing.Imaging.ImageFormat]::Png)
    }
    if ($iconSize -eq 192) {$bitmap.Save((Join-Path $PSScriptRoot '..\web\favicon.png'),[System.Drawing.Imaging.ImageFormat]::Png)}
    $format.Dispose(); $font.Dispose(); $brush.Dispose(); $graphics.Dispose(); $bitmap.Dispose()
}
