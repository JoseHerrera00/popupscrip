# ----------------------------------------------
# video.ps1 - Reproducción de video en pantalla completa
# ----------------------------------------------

# Cargar librerías necesarias de WPF
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# Ruta local del video que ya fue descargado por el main.ps1
$videoPath = "C:\Temp\video.mp4"

# Validar que el video exista antes de continuar
if (-not (Test-Path $videoPath)) {
    Write-Host "❌ No se encontró el archivo de video en: $videoPath"
    exit
}

# Función para crear y mostrar la ventana de reproducción
function Show-FullscreenVideo {
    param (
        [string]$videoFile,
        [System.Drawing.Rectangle]$monitorBounds
    )

    # Crear una nueva ventana sin bordes, a pantalla completa
    $window = New-Object System.Windows.Window
    $window.WindowStartupLocation = "Manual"
    $window.Left = $monitorBounds.Left
    $window.Top = $monitorBounds.Top
    $window.Width = $monitorBounds.Width
    $window.Height = $monitorBounds.Height
    $window.Topmost = $true
    $window.ResizeMode = 'NoResize'
    $window.WindowStyle = 'None'
    $window.ShowInTaskbar = $false
    $window.Background = [System.Windows.Media.Brushes]::Black

    # Crear el reproductor de video (MediaElement)
    $media = New-Object System.Windows.Controls.MediaElement
    $media.Source = [Uri]::new("file:///" + $videoFile.Replace('\', '/'))
    $media.LoadedBehavior = "Play"
    $media.UnloadedBehavior = "Stop"
    $media.Stretch = "UniformToFill"
    $media.Volume = 1.0

    # Hacer que el video se repita en bucle
    $media.MediaEnded += {
        $media.Position = [TimeSpan]::Zero
        $media.Play()
    }

    # Asignar el reproductor como contenido de la ventana
    $window.Content = $media

    # Mostrar la ventana
    $window.Show()

    # Iniciar la reproducción manualmente (por si acaso)
    $media.Play()

    # Mantener el proceso abierto mientras la ventana esté visible
    while ($window.IsVisible) {
        Start-Sleep -Milliseconds 500
    }
}

# Obtener el monitor principal
$primaryMonitor = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds

# Ejecutar la función
Show-FullscreenVideo -videoFile $videoPath -monitorBounds $primaryMonitor
