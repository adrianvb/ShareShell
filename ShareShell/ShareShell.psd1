#
# Modulmanifest für das Modul "Invoke-SharePointApiRequest"
#
# Generiert von: bae6333
#
# Generiert am: 30.04.2014
#

@{

# Die diesem Manifest zugeordnete Skript- oder Binärmoduldatei.
# RootModule = ''

# Die Versionsnummer dieses Moduls
ModuleVersion = '1.1'

# ID zur eindeutigen Kennzeichnung dieses Moduls
GUID = '16272545-a9bf-4a36-9f9d-f6f6eebbb0e8'

# Autor dieses Moduls
Author = 'Adrian von Buttlar'

# Unternehmen oder Hersteller dieses Moduls
CompanyName = 'Universität Hamburg'

# Urheberrechtserklärung für dieses Modul
Copyright = '(c) 2014 Adrian von Buttlar. Alle Rechte vorbehalten.'

# Beschreibung der von diesem Modul bereitgestellten Funktionen
# Description = ''

# Die für dieses Modul mindestens erforderliche Version des Windows PowerShell-Moduls
PowerShellVersion = '3.0'

# Der Name des für dieses Modul erforderlichen Windows PowerShell-Hosts
# PowerShellHostName = ''

# Die für dieses Modul mindestens erforderliche Version des Windows PowerShell-Hosts
# PowerShellHostVersion = ''

# Die für dieses Modul mindestens erforderliche Microsoft .NET Framework-Version
# DotNetFrameworkVersion = ''

# Die für dieses Modul mindestens erforderliche Version der CLR (Common Language Runtime)
# CLRVersion = ''

# Die für dieses Modul erforderliche Prozessorarchitektur ("Keine", "X86", "Amd64").
# ProcessorArchitecture = ''

# Die Module, die vor dem Importieren dieses Moduls in die globale Umgebung geladen werden müssen
# RequiredModules = @()

# Die Assemblys, die vor dem Importieren dieses Moduls geladen werden müssen
# RequiredAssemblies = @()

# Die Skriptdateien (PS1-Dateien), die vor dem Importieren dieses Moduls in der Umgebung des Aufrufers ausgeführt werden.
# ScriptsToProcess = @()

# Die Typdateien (.ps1xml), die beim Importieren dieses Moduls geladen werden sollen
# TypesToProcess = @()

# Die Formatdateien (.ps1xml), die beim Importieren dieses Moduls geladen werden sollen
# FormatsToProcess = @()

# Die Module, die als geschachtelte Module des in "RootModule/ModuleToProcess" angegebenen Moduls importiert werden sollen.
NestedModules = @(
	'Utility\Utility.psm1'
	'API\API.psm1'
	'Convenience\Convenience.psm1'	
)

# Aus diesem Modul zu exportierende Funktionen
FunctionsToExport = '*'

# Aus diesem Modul zu exportierende Cmdlets
CmdletsToExport = '*'

# Die aus diesem Modul zu exportierenden Variablen
VariablesToExport = '*'

# Aus diesem Modul zu exportierende Aliase
AliasesToExport = '*'

# Liste aller Module in diesem Modulpaket
# ModuleList = @()

# Liste aller Dateien in diesem Modulpaket
FileList = @()

# Die privaten Daten, die an das in "RootModule/ModuleToProcess" angegebene Modul übergeben werden sollen.
# PrivateData = ''

# HelpInfo-URI dieses Moduls
# HelpInfoURI = ''

# Standardpräfix für Befehle, die aus diesem Modul exportiert werden. Das Standardpräfix kann mit "Import-Module -Prefix" überschrieben werden.
# DefaultCommandPrefix = ''

}

