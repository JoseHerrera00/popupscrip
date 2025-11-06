# Descargar el script desde GitHub y guardarlo como popupaudio.ps1
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/JoseHerrera00/popupscrip/main/popupaudio.ps1" -OutFile "C:\Temp\popupaudio.ps1" -UseBasicParsing

# Definir la hora a la que quieres que se ejecute la tarea (ejemplo: 16:49)
$horaEjecucion = Get-Date -Hour 14 -Minute 10 -Second 1

# Crear la acción para ejecutar el script con PowerShell
$Action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -WindowStyle Normal -File "C:\Temp\popupaudio.ps1"'

# Crear el trigger para que se ejecute solo una vez en la fecha y hora especificadas
$Trigger = New-ScheduledTaskTrigger -Once -At $horaEjecucion

# Obtener el usuario actual para ejecutar la tarea con ese usuario
$usuario = (Get-WmiObject -Class Win32_ComputerSystem).UserName

# Registrar o reemplazar la tarea programada con privilegios elevados
Register-ScheduledTask -TaskName "InteractiveTask" -Action $Action -Trigger $Trigger -RunLevel Highest -User $usuario -Force








































