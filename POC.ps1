Add-Type @"
using System;
using System.Runtime.InteropServices;

public class CursorControl {
    [DllImport("user32.dll")]
    public static extern bool ShowCursor(bool bShow);
}
"@

# Cargar librerías de WPF y Forms
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# Ruta de las imágenes
$imagePaths = @(
    "\\Covt-security\popup\image1.png",
    "\\Covt-security\popup\image2.png",
    "\\Covt-security\popup\image3.png"
)
$image4Path = "\\Covt-security\popup\image5.png"

# Verificar si todas las imágenes existen
$imagePaths += $image4Path
$imagePaths = $imagePaths | Where-Object {
    if (-Not (Test-Path $_)) {
        Write-Host "La imagen '$_' no existe. Será omitida." -ForegroundColor Yellow
        $false
    } else {
        $true
    }
}

if ($imagePaths.Count -eq 0) {
    Write-Host "No se encontró ninguna imagen válida. Finalizando proceso." -ForegroundColor Red
    exit
}

# Función para cargar una imagen de manera robusta
function Load-Image {
    param (
        [string]$imagePath
    )

    try {
        $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
        $bitmap.BeginInit()
        $bitmap.UriSource = [Uri]::new($imagePath, [UriKind]::Absolute)
        $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bitmap.EndInit()
        return $bitmap
    }
    catch {
        Write-Host "Error al cargar la imagen: $imagePath. Detalles: $_" -ForegroundColor Red
        return $null
    }
}

# Función para crear una ventana con una imagen
function Create-ImageWindow {
    param (
        [string]$imagePath,
        [string]$title,
        [System.Drawing.Rectangle]$monitorBounds
    )

    try {
        # Crear la ventana
        $window = New-Object System.Windows.Window
        $window.Title = $title
        $window.WindowStartupLocation = "Manual"
        $window.Topmost = $true
        $window.ResizeMode = "NoResize"
        $window.WindowStyle = "None"
        $window.ShowInTaskbar = $false
        $window.Left = $monitorBounds.Left
        $window.Top = $monitorBounds.Top
        $window.Width = $monitorBounds.Width
        $window.Height = $monitorBounds.Height

        # Crear y cargar el control de imagen
        $imageControl = New-Object System.Windows.Controls.Image
        $imageControl.Stretch = "UniformToFill"

        # Cargar la imagen
        $imageSource = Load-Image -imagePath $imagePath
        if ($imageSource -ne $null) {
            $imageControl.Source = $imageSource
        } else {
            Write-Host "No se pudo cargar la imagen: $imagePath." -ForegroundColor Yellow
        }

        # Asignar el control de imagen al contenido de la ventana
        $window.Content = $imageControl
        $window.Show()

        return $window
    }
    catch {
        Write-Host "Error al crear la ventana para la imagen: $imagePath. Detalles: $_" -ForegroundColor Red
        return $null
    }
}

# Función para mostrar imágenes principales en secuencia con cambio casi inmediato
function Show-ImagesSequentially {
    param (
        [System.Drawing.Rectangle]$monitorPrincipal
    )

    $imageDisplayTimes = @(
        300,   # Tiempo en segundos para la primera imagen
        300,   # Tiempo en segundos para la segunda imagen
        300    # Tiempo en segundos para la tercera imagen
    )

    $windows = @()  # Para mantener un registro de las ventanas abiertas
    $currentWindow = $null

    for ($i = 0; $i -lt $imagePaths.Count - 1; $i++) {
        $imagePath = $imagePaths[$i]
        
        # Crear la ventana de la nueva imagen
        $newWindow = Create-ImageWindow -imagePath $imagePath -title "Imagen Principal" -monitorBounds $monitorPrincipal
        if ($newWindow) {
            # Si hay una ventana anterior abierta, cerrarla inmediatamente
            if ($currentWindow -ne $null) {
                $currentWindow.Dispatcher.Invoke([Action]{ $currentWindow.Close() })
            }
            
            # Guardar la nueva ventana como la actual
            $currentWindow = $newWindow
        }

        # Mostrar la nueva imagen durante el tiempo configurado
        Start-Sleep -Seconds $imageDisplayTimes[$i]
    }

    # Esperar a que la última ventana se cierre
    if ($currentWindow -ne $null) {
        $currentWindow.Dispatcher.Invoke([Action]{ $currentWindow.Close() })
    }
}

# Función para mostrar la imagen en el monitor secundario
function Show-ImageOnSecondaryMonitor {
    param (
        [System.Drawing.Rectangle]$monitorSecundario
    )

    $window = Create-ImageWindow -imagePath $image4Path -title "Imagen Secundaria" -monitorBounds $monitorSecundario
    return $window
}

# Función principal
function Run-Process {
    $secondaryWindow = $null
    try {
        [CursorControl]::ShowCursor($false)  # Ocultar cursor

        # Obtener monitores
        $monitorPrincipal = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        $monitorSecundario = [System.Windows.Forms.Screen]::AllScreens | Where-Object { -Not $_.Primary } | Select-Object -First 1

        if ($monitorSecundario -eq $null) {
            Write-Host "No se detectó un monitor secundario. Continuando con imágenes principales." -ForegroundColor Yellow
        } else {
            # Mostrar imagen secundaria
            $secondaryWindow = Show-ImageOnSecondaryMonitor -monitorSecundario $monitorSecundario.Bounds
        }

        # Mostrar imágenes principales en secuencia con transición casi inmediata
        Show-ImagesSequentially -monitorPrincipal $monitorPrincipal
    }
    catch {
        Write-Host "Ocurrió un error: $_" -ForegroundColor Red
        Write-Host "Detalles del error: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        # Cerrar la ventana secundaria
        if ($secondaryWindow -ne $null) {
            $secondaryWindow.Dispatcher.Invoke([Action]{ $secondaryWindow.Close() })
        }
        [CursorControl]::ShowCursor($true)  # Restaurar cursor
    }
}

# Ejecutar el proceso
Run-Process