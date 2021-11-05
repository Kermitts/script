#
#Funciones en la cabcera del script
#

function Show-Menu
{
     param (
           [string]$Titulo = 'Menú principal'
     )
     Clear-Host
     Write-Host "================ $Titulo ================"
    
     Write-Host "1: Opción '1' Creacion de usuarios de direcciones personales."
     Write-Host "2: Opción '2' Menu 2"
     Write-Host "3: Opción '3' SetADUserLogonTime.psm1"
     Write-Host "Q: Opción 'S' Salir."
}
#
# Antes de insertar un objeto en AD, hay que comprobar que NO existe
#

#Primero comprobaremos si se tiene cargado el módulo Active Directory
if (!(Get-Module -Name ActiveDirectory)) #Accederá al then solo si no existe una entrada llamada ActiveDirectory
{
  Import-Module ActiveDirectory #Se carga el módulo
}

#Cada vez que se inserta un objeto en AD, primero hay que comprobar que no existe
#Comprobar si existe un objeto UO en el Controlador del Dominio
$UO=UnidadOrganizativa
if ( !(Get-ADOrganizationalUnit -Filter{ name -eq $UO })) #Devuelve false cuando ya existe la unidad organizativa $UO, y true cuando no existe.
{
}

#Para Grupos
$GRP=Grupo1
if ( !(Get-ADGroup -Filter { name -eq $GRP })) #Devuelve false cuando ya existe el grupo $GRP, y true cuando no existe.
{
}

#Para usuarioshttps://www.youtube.com/channel/UCwkrdXV20xLACxHTuFg6PZA/videos
$usu=JC
if ( !!(Get-ADUser -filter { name -eq $usu }) ) #Devuelve false cuando ya existe el grupo $usu, y true cuando no existe.
{
}
#Para equipos
$computer=W7-001
if ( !!(Get-ADComputer -filter { name -eq $computer }) ) #Devuelve false cuando ya existe el ordenador $computer, y true cuando no existe.
{
}
#
# Fin comprobación de objetos
#

#
#MENU PRINCIPAL
#
do
{
     Show-Menu
     $input = Read-Host "Por favor, pulse una opción"
     switch ($input)
     {
           '1' {
             
#A la ejeción del script le pasamos 2 parámetros para capturar el nombre del dominio y sufijo (donde queremos crear los usuarios)
#Parámetro 1: el nombre netbios del dominio.
#Parámetro 2: el sufijo del dominio
#Ejemplo: smr.local --> Parámetro 1 sería smr y Parámetro 2 local
# Ejemplo de ejecución del script: alta_Usuarios-DirPersonales.ps1 smr local 

#
#Capturamos los 2 parámetros que hemos pasado en la ejecución del script ($a será el nombre del dominio y $b el sufijo)
#
param($a,$b)
$dominio=$a
$sufijo=$b
#En la variable dc componemos el nombre dominio y sufijo. Ejemplo: dc=smr,dc=local.
$dc="dc="+$dominio+",dc="+$sufijo

#
#Primero hay que comprobar si se tiene cargado el módulo Active Directory
#
if (!(Get-Module -Name ActiveDirectory)) #Accederá al then solo si no existe una entrada llamada ActiveDirectory
{
  Import-Module ActiveDirectory #Se carga el módulo
}

#
#Creación de los usuarios
#
#
#Preguntamos al usuario que nos indique el fichero csv
#
$fichero_csv=Read-Host "Copia de usuariosSistema 2.ods - usuarios-Subdominio4(1)"

#El fichero csv tiene esta estructura (14 campos)
#Name:Surname:Surname2:NIF:Group:ContainerPath:Computer:Hability:DaysAccountExpire:HomeDrive:HomeDirectory:PerfilPath:ScriptPath:Teletrabajo

#
#Importamos el fichero csv (comando import-csv) y lo cargamos en la variable fichero_csv. 
#El delimitador usado en el csv es el : (separador de campos)
#
$fichero_csv_importado = import-csv -Path $fichero_csv -Delimiter : 			     
foreach($linea_leida in $fichero_csv_importado)
{
	#Componemos la ruta donde queda ubicado el objeto a crear (usuario). Ejemplo: OU=DepInformatica,dc=smr,dc=local
  	$rutaContenedor =$linea_leida.ContainerPath+","+$dc 
	#
  	#Guardamos de manera segura la contraseña con el comando ConvertTo-SecureString. En este caso, la contraseña corresponde al NIF (9 números + letra)
	#
  	$passAccount=ConvertTo-SecureString $linea_leida.NIF -AsPlainText -force
	
	$name=$linea.Name
	$nameShort=$linea.Name+'.'+$linea_leida.Surname
	$Surnames=$linea.Surname+' '+$linea_leida.Surname2
	$nameLarge=$linea.Name+' '+$linea_leida.Surname+' '+$linea_leida.Surname2
	$computerAccount=$linea_leida.Computer
	$email=$nameShort+"@"+$a+"."+$b
	$perfilmovil=$linea_leida.PerfilMovil+"\"+$nameShort
  
  
	#Si el usaurio ya existe (Nombre + 1er Apellido), ampliamos el nombre corto con el 2 Apellido   
	if (Get-ADUser -filter { name -eq $nameShort })
	{
		$nameShort=$linea_leida.Name+'.'+$linea_leida.Surname+$linea_leida.Surname2
	}
	#
  	#El parámetro -Enabled es del tipo booleano por lo que hay que leer la columna del csv
	#que contiene el valor true/false para habilitar o no habilitar el usuario y convertirlo en boolean.
  	#
	[boolean]$Habilitado=$true
  	If($linea_leida.Hability -Match 'false') { $Habilitado=$false}
  
  	$ExpirationAccount = $linea_leida.DaysAccountExpire
 	$timeExp = (get-date).AddDays($ExpirationAccount)
	
	New-ADUser `
    		-SamAccountName $nameShort `
   	 	-UserPrincipalName $nameShort `
    		-Name $nameShort `
		-Surname $Surnames `
    		-DisplayName $nameLarge `
    		-GivenName $name `
    		-LogonWorkstations:$linea_leida.Computer `
		-Description "Cuenta de $nameLarge" `
    		-EmailAddress $email `
		-AccountPassword $passAccount `
    		-Enabled $Habilitado `
		-CannotChangePassword $false `
    		-ChangePasswordAtLogon $true `
		-PasswordNotRequired $false `
    		-Path $rutaContenedor `
    		-AccountExpirationDate $timeExp `
		-HomeDrive "$linea.HomeDrive:" `
    		-HomeDirectory "$linea_leida.DirPersonales\$nameShort" `
    		-ProfilePath $perfilmovil `
    		-ScriptPath $linea.ScriptPath
	
  		#Asignar la cuenta de Usuario creada a un Grupo
		# Distingued Name CN=Nombre-grupo,ou=..,ou=..,dc=..,dc=...
		$cnGrpAccount="Cn="+$linea_leida.Group+","+$rutaContenedor
		Add-ADGroupMember -Identity $cnGrpAccount -Members $nameShort
	
	#
	## Establecer horario de inicio de sesión de 8am - 6pm Lunes (Monday) to Viernes (Friday)   
	# Para ello, importamos una utilidad (Set-OSCLogonHours) que nos permite establecer el horario
 	# El SetADUserLogonTime.psm1 está situado en este ejemplo en C:\Scripts\LogonHours
	#
	Import-Module C:\Scripts\LogonHours\SetADUserLogonTime.psm1
	Set-OSCLogonHours -SamAccountName $nameShort -DayofWeek Monday,Tuesday,Wednesday,Thursday,Friday -From $linea_leida.Schedule
	
	#
	#Creamos el directorio personal de cada usuario con los permisos adecuados. Control Total para el usuario
	#
	$pathDirPersonales="$linea_leida.HomeDrive:"+"$linea_leida.DirPersonales\$nameShort"
	New-Item -Path $pathDirPersonales -ItemType Directory
	$nueva_ACL = new-object System.Security.AccessControl.FileSystemAccessRule("$dominio\$nombreCorto","FullControl","Allow")
	$acl.AddAccessRule($nueva_ACL)
	set-acl $pathDirPersonales $acl_actual
}




                #llamar a la función que haga la acción 1
           } '2' {
                
#./menu.ps1 param1 param2
#o 
#./menu.ps1 -Param1 parametro1 -Param2 parametro2
#Los parámetros son opcionales, si la llamada es:./menu.ps1 --> los valores de $Param1 y $Param2, será la cadena de texto vacía.
Param(
  [string]$Param1,
  [string]$Param2
)
Write-Host "Los parámetros son:"$Param1 " " $Param2
pause

#Función 1. Promocionar a CD
function promocionarCD
{
Write-Host "a"
}


function mostrarMenu 
{ 
     param ( 
           [string]$Titulo = 'Selección de opciones' 
     ) 
     Clear-Host 
     Write-Host "================ $Titulo================" 
      
     
     Write-Host "1) Crear usuario" 
     Write-Host "2) Segunda Opción" 
     Write-Host "3) Crear Unidad Organizativa"
     Write-Host "4) Cambiar contraseña de usuario" 
     Write-Host "S) Presiona 'S' para salir" 
}
#Bucle principal del Script. El bucle se ejecuta de manera infinita hasta que se cumple
#la condición until ($input -eq 's'), es decir, hasta que se pulse la tecla s.
do 
{ 
     #Llamamos a la función mostrarMenu, para dibujar el menú de opciones por pantalla
     mostrarMenu 
     #Recogemos en la varaible input, el valor que el usuario escribe por teclado (opción del menú)
     $input = Read-Host "Elegir una Opción" 
     #https://ss64.com/ps/switch.html
     switch ($input) 
     { 
           '1' { 
                New-ADUser -Name "George" -Path "OU=Administracion Parcial 1, DC=edu-gva, DC=es" -SamAccountName "George" -UserPrincipalName "george@edu-gva.es" -AccountPassword (ConvertTo-secureString "Chubbyemu01" -AsPlainText -Force) -GivenName "George" -Surname "george" -ChangePAsswordAtLogon $true -Enabled $true
                'Crear usuario' 
                pause
           } '2' { 
                Remove-ADUser -Identity "CN=Sebastian, OU=Administracion Parcial 1, DC=edu-gva, DC=es"  
                'Eliminar usuario' 
                pause
           } '3' { 
                New-ADOrganizationalUnit -Name "Administracion Parcial 1"
                'Crear Unidad Organizativa' 
                pause
           } '4' { 
               wmic Xuser set PasswordExpires=True
                pause
           } 's' {
                'Saliendo del script...'
                return 
           } 
	   #Xuser=usuario al que se le quiere cambiar la contraseña 
           #Si no se selecciona una de las opciones del menú, es decir, se pulsa algun carácter
           #que no sea 1, 2, 3 o s, sacamos por pantalla un aviso e indicamos lo que hay que realizar.
           default { 
              'Por favor, Pulse una de las opciones disponibles [1-3] o s para salir'
           }
     } 
     pause 
} 
until ($input -eq 's')
                #llamar a la función que haga la acción 2
           } '3' {
                #requires -Version 2.0

#Check if ActiveDirectory module is imported.
If(-not(Get-Module -Name ActiveDirectory))
{
    Import-Module -Name ActiveDirectory
}

Function Set-OSCLogonHours
{
<#
 	.SYNOPSIS
        Set-OSCLogonHours is an advanced function which can be used to set active directory user's logon time.
    .DESCRIPTION
        Set-OSCLogonHours is an advanced function which can be used to set active directory user's logon time.
    .PARAMETER  SamAccountName
        Specifies the SamAccountName
    .PARAMETER  CsvFilePath
		Specifies the path you want to import csv files.
    .PARAMETER  DayofWeek
		Specifies the day of the week.
    .PARAMETER  From
		Specifies a start time.
    .PARAMETER  To
		Specifies an end time.
    .EXAMPLE
        C:\PS> Set-OSCLogonHours -SamAccountName doris,katrina -DayofWeek Monday,Saturday -From 6AM -To 7PM
        Successfully set user 'doris' logon time.
        Successfully set user 'katrina' logon time.
		This command will set user's logon time attributes.
    .EXAMPLE
        C:\PS> Set-OSCLogonHours -CsvFilePath C:\Script\SamAccountName.csv -DayofWeek Wednesday,Friday -From 7AM -To 8PM
        
        Successfully set user 'doris' logon time.
        Successfully set user 'katrina' logon time.
		This command will set user's logon time attributes based on imported user list.
#>
    [CmdletBinding(DefaultParameterSetName = 'SamAccountName')]
    Param
    (
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='SamAccountName')]
        [Alias('sam')][String[]]$SamAccountName,

        [Parameter(Mandatory=$true,Position=0,ParameterSetName='CsvFilePath')]
        [Alias('')][String]$CsvFilePath,

        [Parameter(Mandatory=$true,Position=1)]
        [ValidateSet("Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday")]
        [Alias('day')][String[]]$DayofWeek,

        [Parameter(Mandatory=$true,Position=2)]
        [ValidateSet("12AM","1AM","2AM","3AM","4AM","5AM","6AM","7AM","8AM","9AM","10AM",
        "11AM","12PM","1PM","2PM","3PM","4PM","5PM","6PM","7PM","8PM","9PM","10PM","11PM")]
        [Alias('f')][String]$From,

        [Parameter(Mandatory=$true,Position=3)]
        [ValidateSet("12AM","1AM","2AM","3AM","4AM","5AM","6AM","7AM","8AM","9AM","10AM",
        "11AM","12PM","1PM","2PM","3PM","4PM","5PM","6PM","7PM","8PM","9PM","10PM","11PM")]
        [Alias('t')][String]$To
    )

    
    #Define a custom 24-hours hashtable
    $Objs = @()
    Foreach($i in 1..24)
    {
        $Obj = New-Object -TypeName PSObject
        $Obj | Add-Member -MemberType NoteProperty -Name "12Hours" -Value $(If($i -le 11)
        {"$($i)AM"}Else{If($i -eq 12){"12PM"}ElseIf($i -eq 24){"12AM"}Else{"$($i-12)PM"}})
        $Obj | Add-Member -MemberType NoteProperty -Name "24Hours" -Value $i

        $Objs += $Obj
    }
   
    #The 12-hours will be convert into 24-hours type.
    $HrsFrom = $Objs | Where{$_."12Hours" -eq $From} | Select-Object -ExpandProperty "24Hours"
    $HrsTo = $Objs | Where{$_."12Hours" -eq $To} | Select-Object -ExpandProperty "24Hours"

    If($HrsFrom -le $HrsTo)
    {
       #Define 3 time binary blocks
       $HoursBlock1 = @{"12AM"=1; "1AM"=2; "2AM"=4; "3AM"=8; "4AM"=16; "5AM"=32; "6AM"=64; "7AM"=128}
       $HoursBlock2 = @{"8AM"=1; "9AM"=2; "10AM"=4; "11AM"=8; "12PM"=16; "1PM"=32; "2PM"=64; "3PM"=128}
       $HoursBlock3 = @{"4PM"=1; "5PM"=2; "6PM"=4; "7PM"=8; "8PM"=16; "9PM"=32; "10PM"=64; "11PM"=128}

       #Initialize multiple values to multiple variables.
       $HourBinary1,$HourBinary2,$HourBinary3 = 0,0,0

       $TimePeriod = $HrsFrom..$($HrsTo-1)
       Foreach($Time in $TimePeriod)
       {
            #The 24-hours will be convert into 12-hours type.
            $Hour = $Objs | Where{$_."24Hours" -eq $Time} | Select-Object -ExpandProperty "12Hours"  

            If($HoursBlock1.ContainsKey($Hour))
            {
                $HourBinary1 += $HoursBlock1.$Hour
            }
            If($HoursBlock2.ContainsKey($Hour))
            {
                $HourBinary2 += $HoursBlock2.$Hour
            }
            If($HoursBlock3.ContainsKey($Hour))
            {
                $HourBinary3 += $HoursBlock3.$Hour
            }
        }
            
        #Define Initial logon time
        $HourBinary = 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

        #Iterating replace the specified value
        Foreach($day in $DayofWeek)
        {
            Switch($day)
            {
                "Sunday" {$HourBinary[1],$HourBinary[2],$HourBinary[3] = $HourBinary1,$HourBinary2,$HourBinary3;Break}
                "Monday" {$HourBinary[4],$HourBinary[5],$HourBinary[6] = $HourBinary1,$HourBinary2,$HourBinary3;Break}
                "Tuesday" {$HourBinary[7],$HourBinary[8],$HourBinary[9] = $HourBinary1,$HourBinary2,$HourBinary3;Break}
                "Wednesday" {$HourBinary[10],$HourBinary[11],$HourBinary[12] = $HourBinary1,$HourBinary2,$HourBinary3;Break}
                "Thursday" {$HourBinary[13],$HourBinary[14],$HourBinary[15] = $HourBinary1,$HourBinary2,$HourBinary3;Break}
                "Friday" {$HourBinary[16],$HourBinary[17],$HourBinary[18] = $HourBinary1,$HourBinary2,$HourBinary3;Break}
                "Saturday" {$HourBinary[19],$HourBinary[20],$HourBinary[0] = $HourBinary1,$HourBinary2,$HourBinary3;Break}
            }
        }
    
        #Assign logon binary value to 'Logonhours' attribute.
        If($SamAccountName)
        {
            Foreach($User in $SamAccountName)
            {
                Get-ADUser -Identity $User | Set-ADUser -Replace @{Logonhours = [Byte[]]$HourBinary}
                Write-Host "Successfully set user '$User' logon time."
            }
        }

        If($CsvFilePath)
        {
            If(Test-Path -Path $CsvFilePath)
            {
                #import the csv file and store in a variable
                $Names = (Import-Csv -Path $CsvFilePath).SamAccountName

                Foreach($Name in $Names)
                {
                    Get-ADUser -Identity $Name | Set-ADUser -Replace @{Logonhours = [Byte[]]$HourBinary}
                    Write-Host "Successfully set user '$Name' logon time."
                }
            }
            Else
            {
                Write-Warning "Cannot find path '$CsvFilePath', because it does not exist."
            } 
        }
    }
    Else
    {
        Write-Warning "You enter the wrong time period, please make sure that input correct."
    }
}
                #llamar a la función que haga la acción 2
           } 'q' {
                'Salimos de la App'
                return
           }
     }
     pause
}
until ($input -eq 'q')

# A continuación, las propiedades de New-ADUser que se han utilizado son:
#SamAccountName: nombre de la cuenta SAM para compatibilidad con equipos anteriores a Windows 2000.
#UserPrincipalName: Nombre opcional que puede ser más corto y fácil de recordar que el DN (Distinguished Name) y que puede ser utilizado por el sistema.
#Name: Nombre de la cuenta de usuario.
#Surname: Apellidos del usuario.
#DisplayName: Nombre del usuario que se mostrará cuando inicie sesión en un equipo.
#GivenName: Nombre de pila.
#Description: Descripción de la cuenta de usuario.
#EmailAddress: Dirección de correo electrónico.
#AccountPassword: Contraseña encriptada.
#Enabled: Cuenta habilitada ($true) o deshabilitada ($false).
#CannotChangePassword: El usuario no puede cambiar la contraseña (como antes, tiene dos valores: $true y $false).
#ChangePasswordAtLogon: Si su valor es $true obliga al usuario a cambiar la contraseña cuando vuelva a iniciar sesión.
#PasswordNotRequired: Permite que el usuario no tenga contraseña.
#HomeDrive "H:" : La carpeta personal aparecerá en la unidad de red H:
#HomeDirectory "$linea.DirPersonales\$nameShort": La carpeta personal se hallará en \\NombreServidor\Dir-Personales\Cuenta-Usuario
#ProfilePath $perfilmovil: El perfil del usuario se almacenará en \\NombreServidor\Dir-Perfiles\$nombreCorto
#ScriptPath $linea.ScriptPath: El script de inicio de sesión se halla en \\NombreServidor\Scripts\logon
