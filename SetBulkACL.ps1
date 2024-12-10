# Pfad zu den Hauptordnern
$BasePath = "D:\Firmendaten"

# Berechtigungen basierend auf der aktualisierten Tabelle
$Permissions = @{
    "Ordner 1"          = @("user1", "user2")
    "Ordner 2"          = @("Domänen-Benutzer")
}

function Set-FolderPermissions {
    param (
        [string]$FolderPath,
        [array]$Users
    )

    # Existiert der Ordner? Wenn nicht, Nachricht ausgeben und überspringen
    if (!(Test-Path -LiteralPath $FolderPath)) {
        Write-Host "Ordner '$FolderPath' nicht vorhanden. Überspringe..." -ForegroundColor Yellow
        return
    }

    try {
        # Hole aktuelle ACL
        $acl = Get-Acl -LiteralPath $FolderPath

        # Entferne alle bestehenden Berechtigungen und deaktiviere Vererbung
        $acl.SetAccessRuleProtection($true, $false)
        $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }

        # Füge Domain Admins mit Vollzugriff hinzu
        $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("CONTOSO\Domänen-Admins", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.AddAccessRule($adminRule)

        # Setze neue Berechtigungen für die angegebenen Benutzer oder Gruppen
        foreach ($User in $Users) {
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("CONTOSO\$User", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
            $acl.AddAccessRule($rule)
        }

        # Wende die neuen Berechtigungen an
        Set-Acl -LiteralPath $FolderPath -AclObject $acl

        Write-Host "Berechtigungen für '$FolderPath' erfolgreich gesetzt." -ForegroundColor Green
    }
    catch {
        Write-Host "Fehler beim Setzen der Berechtigungen für '$FolderPath': $_" -ForegroundColor Red
    }

}
# Rekursive Funktion zum Durchlaufen aller Unterordner
function Set-RecursiveFolderPermissions {
    param (
        [string]$FolderPath,
        [array]$Users
    )

    # Setze Berechtigungen für den aktuellen Ordner
    Set-FolderPermissions -FolderPath $FolderPath -Users $Users

    # Durchlaufe alle Unterordner
    Get-ChildItem -LiteralPath $FolderPath -Directory | ForEach-Object {
        Set-RecursiveFolderPermissions -FolderPath $_.FullName -Users $Users
    }
}

# Setze Berechtigungen für jeden Bereich
foreach ($Folder in $Permissions.Keys) {
    $FolderPath = Join-Path -Path $BasePath -ChildPath $Folder
    $Users = $Permissions[$Folder]

    # Nutze die rekursive Funktion
    Set-RecursiveFolderPermissions -FolderPath $FolderPath -Users $Users
}

Write-Host "NTFS-Berechtigungen wurden erfolgreich aktualisiert!" -ForegroundColor Cyan
