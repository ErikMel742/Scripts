Connect-AzAccount
function Show-SimilarUsers {
    param (
        [string]$searchTerm
    )
    $similarUsers = Get-AzADUser -Filter "startswith(DisplayName, '$searchTerm')" | Select-Object DisplayName, UserPrincipalName, Id
    
    if ($similarUsers) {
        Write-Host "Did you mean one of the following users?"
        $i = 1
        foreach ($user in $similarUsers) {
            Write-Host "$i. $($user.DisplayName) (UPN: $($user.UserPrincipalName))"
            $i++
        }
        return $similarUsers
    } else {
        Write-Host "No similar users found."
        return $null
    }
}

function Show-SimilarGroups {
    param (
        [string]$searchTerm
    )
    $similarGroups = Get-AzADGroup -Filter "startswith(DisplayName, '$searchTerm')" | Select-Object DisplayName, Id
    
    if ($similarGroups) {
        Write-Host "Did you mean one of the following groups?"
        $i = 1
        foreach ($group in $similarGroups) {
            Write-Host "$i. $($group.DisplayName)"
            $i++
        }
        return $similarGroups
    } else {
        Write-Host "No similar groups found."
        return $null
    }
}

function Show-UserMenu {
    Clear-Host
    Write-Host "User Management Options:"
    Write-Host "1. Show Users"
    Write-Host "2. Create a User"
    Write-Host "3. Delete a User"
    Write-Host "4. Recover a User"
    Write-Host "5. Return to Main Menu"
}

function Show-GroupMenu {
    Clear-Host
    Write-Host "Group Management Options:"
    Write-Host "1. Show Groups"
    Write-Host "2. Create a Group"
    Write-Host "3. Delete a Group"
    Write-Host "4. Recover a Group"
    Write-Host "5. Return to Main Menu"
}

function Show-Users {
    $users = Get-AzADUser | Select-Object DisplayName, UserPrincipalName
    if ($users) {
        Write-Host "List of Users:"
        foreach ($user in $users) {
            Write-Host "$($user.DisplayName) (UPN: $($user.UserPrincipalName))"
        }
    } else {
        Write-Host "No users found."
    }
}

function Show-Groups {
    $groups = Get-AzADGroup | Select-Object DisplayName
    if ($groups) {
        Write-Host "List of Groups:"
        foreach ($group in $groups) {
            Write-Host "$($group.DisplayName)"
        }
    } else {
        Write-Host "No groups found."
    }
}

function Create-User {
    $displayName = Read-Host "Enter the user's display name"
    $upn = Read-Host "Enter the user's UPN (or press Enter to use default domain @domain.com)"   # change the text to show your desired default domain aka the one you set

    if (-not $upn) {
        $upn = "$($displayName.Replace(' ', '.'))@domain.com" #set default domain here
    }

    $newUserParams = @{
        DisplayName = $displayName
        UserPrincipalName = $upn
        AccountEnabled = $true
        MailNickName = ($upn -split '@')[0]
        PasswordProfile = @{
            ForceChangePasswordNextSignIn = $true
            Password = Read-Host "Enter the user's password" -AsSecureString
        }
    }

    try {
        New-AzADUser @newUserParams
        Write-Host "User '$displayName' created successfully with UPN '$upn'."
    } catch {
        Write-Host "Failed to create user: $_"
    }
}

function Delete-User {
    $userInput = Read-Host "Enter the user's display name or user principal name (UPN) to delete"

    $user = Get-AzADUser -Filter "DisplayName eq '$userInput' or UserPrincipalName eq '$userInput'" -ErrorAction SilentlyContinue

    if ($user) {
        $confirm = Read-Host "Are you sure you want to delete the user: $($user.DisplayName) (UPN: $($user.UserPrincipalName))? (Y/N to confirm, C to cancel)"
        if ($confirm -eq 'Y') {
            Remove-AzADUser -ObjectId $user.Id
            Write-Host "User $($user.DisplayName) has been deleted."
        } elseif ($confirm -eq 'C') {
            Write-Host "User deletion cancelled."
        } else {
            Write-Host "Invalid option. Returning to menu."
        }
    } else {
        $similarUsers = Show-SimilarUsers -searchTerm $userInput
        if ($similarUsers) {
            $selection = Read-Host "Select a user number to delete (or type 'C' to cancel)"
            if ($selection -eq 'C') {
                Write-Host "User deletion cancelled."
            } else {
                $selectedUser = $similarUsers[$selection - 1]
                if ($selectedUser) {
                    $confirm = Read-Host "Are you sure you want to delete the user: $($selectedUser.DisplayName) (UPN: $($selectedUser.UserPrincipalName))? (Y/N to confirm, C to cancel)"
                    if ($confirm -eq 'Y') {
                        Remove-AzADUser -ObjectId $selectedUser.Id
                        Write-Host "User $($selectedUser.DisplayName) has been deleted."
                    } elseif ($confirm -eq 'C') {
                        Write-Host "User deletion cancelled."
                    } else {
                        Write-Host "Invalid option. Returning to menu."
                    }
                } else {
                    Write-Host "Invalid selection. Returning to menu."
                }
            }
        }
    }
}

function Recover-User {
    $searchTerm = Read-Host "Enter the display name or user principal name (UPN) to search for deleted users"

    # Retrieve all soft-deleted users
    $deletedUsers = Get-AzADUser -Filter "startswith(DisplayName, '$searchTerm')" -ErrorAction SilentlyContinue | Where-Object { $_.UserState -eq 'Deleted' }

    if ($deletedUsers) {
        Write-Host "Soft deleted users found:"
        $i = 1
        foreach ($user in $deletedUsers) {
            Write-Host "$i. $($user.DisplayName) (UPN: $($user.UserPrincipalName))"
            $i++
        }

        $selection = Read-Host "Select a user number to recover (or type 'C' to cancel)"
        if ($selection -eq 'C') {
            Write-Host "User recovery cancelled."
        } else {
            $selectedUser = $deletedUsers[$selection - 1]
            if ($selectedUser) {
                $confirm = Read-Host "Are you sure you want to recover the user: $($selectedUser.DisplayName) (UPN: $($selectedUser.UserPrincipalName))? (Y/N to confirm)"
                if ($confirm -eq 'Y') {
                    Restore-AzADUser -ObjectId $selectedUser.Id
                    Write-Host "User $($selectedUser.DisplayName) has been recovered."
                } else {
                    Write-Host "User recovery cancelled."
                }
            } else {
                Write-Host "Invalid selection. Returning to menu."
            }
        }
    } else {
        Write-Host "No soft deleted users found with the specified criteria."
    }
}

function Show-Groups {
    $groups = Get-AzADGroup | Select-Object DisplayName
    if ($groups) {
        Write-Host "List of Groups:"
        foreach ($group in $groups) {
            Write-Host "$($group.DisplayName)"
        }
    } else {
        Write-Host "No groups found."
    }
}

function Create-Group {
    $groupName = Read-Host "Enter the group's display name"
    $description = Read-Host "Enter a description for the group (press Enter to leave blank)"

    $newGroupParams = @{
        DisplayName = $groupName
        MailEnabled = $false
        MailNickName = ($groupName -replace ' ', '')
        SecurityEnabled = $true
    }

    if ($description) {
        $newGroupParams.Description = $description
    }

    try {
        New-AzADGroup @newGroupParams
        Write-Host "Group '$groupName' created successfully."
    } catch {
        Write-Host "Failed to create group: $_"
    }
}

function Delete-Group {
    $groupName = Read-Host "Enter the name of the group to delete"

    $group = Get-AzADGroup -Filter "DisplayName eq '$groupName'" -ErrorAction SilentlyContinue

    if ($group) {
        $confirm = Read-Host "Are you sure you want to delete the group: $($group.DisplayName)? (Y/N to confirm, C to cancel)"
        if ($confirm -eq 'Y') {
            Remove-AzADGroup -ObjectId $group.Id
            Write-Host "Group '$($group.DisplayName)' has been deleted."
        } elseif ($confirm -eq 'C') {
            Write-Host "Group deletion cancelled."
        } else {
            Write-Host "Invalid option. Returning to menu."
        }
    } else {
        $similarGroups = Show-SimilarGroups -searchTerm $groupName
        if ($similarGroups) {
            $selection = Read-Host "Select a group number to delete (or type 'C' to cancel)"
            if ($selection -eq 'C') {
                Write-Host "Group deletion cancelled."
            } else {
                $selectedGroup = $similarGroups[$selection - 1]
                if ($selectedGroup) {
                    $confirm = Read-Host "Are you sure you want to delete the group: $($selectedGroup.DisplayName)? (Y/N to confirm, C to cancel)"
                    if ($confirm -eq 'Y') {
                        Remove-AzADGroup -ObjectId $selectedGroup.Id
                        Write-Host "Group '$($selectedGroup.DisplayName)' has been deleted."
                    } elseif ($confirm -eq 'C') {
                        Write-Host "Group deletion cancelled."
                    } else {
                        Write-Host "Invalid option. Returning to menu."
                    }
                } else {
                    Write-Host "Invalid selection. Returning to menu."
                }
            }
        }
    }
}

function Recover-Group {
    $searchTerm = Read-Host "Enter the display name to search for deleted groups"

    # Retrieve all soft-deleted groups
    $deletedGroups = Get-AzADGroup -Filter "startswith(DisplayName, '$searchTerm')" -ErrorAction SilentlyContinue | Where-Object { $_.GroupState -eq 'Deleted' }

    if ($deletedGroups) {
        Write-Host "Soft deleted groups found:"
        $i = 1
        foreach ($group in $deletedGroups) {
            Write-Host "$i. $($group.DisplayName)"
            $i++
        }

        $selection = Read-Host "Select a group number to recover (or type 'C' to cancel)"
        if ($selection -eq 'C') {
            Write-Host "Group recovery cancelled."
        } else {
            $selectedGroup = $deletedGroups[$selection - 1]
            if ($selectedGroup) {
                $confirm = Read-Host "Are you sure you want to recover the group: $($selectedGroup.DisplayName)? (Y/N to confirm)"
                if ($confirm -eq 'Y') {
                    Restore-AzADGroup -ObjectId $selectedGroup.Id
                    Write-Host "Group '$($selectedGroup.DisplayName)' has been recovered."
                } else {
                    Write-Host "Group recovery cancelled."
                }
            } else {
                Write-Host "Invalid selection. Returning to menu."
            }
        }
    } else {
        Write-Host "No soft deleted groups found with the specified criteria."
    }
}

# Main loop
do {
    Clear-Host
    Write-Host "Main Menu"
    Write-Host "1. User Management"
    Write-Host "2. Group Management"
    Write-Host "3. Exit"
    
    $mainChoice = Read-Host "Enter your choice"

    switch ($mainChoice) {
        1 {
            do {
                Show-UserMenu
                $userChoice = Read-Host "Enter the number of your choice"

                switch ($userChoice) {
                    1 { Show-Users }
                    2 { Create-User }
                    3 { Delete-User }
                    4 { Recover-User }
                    5 { break } # Return to Main Menu
                    default { Write-Host "Invalid selection. Please try again." }
                }

                Read-Host "Press Enter to continue..."
            } while ($userChoice -ne 5)
        }
        2 {
            do {
                Show-GroupMenu
                $groupChoice = Read-Host "Enter the number of your choice"

                switch ($groupChoice) {
                    1 { Show-Groups }
                    2 { Create-Group }
                    3 { Delete-Group }
                    4 { Recover-Group }
                    5 { break } # Return to Main Menu
                    default { Write-Host "Invalid selection. Please try again." }
                }

                Read-Host "Press Enter to continue..."
            } while ($groupChoice -ne 5)
        }
        3 {
            Write-Host "Exiting..."
            exit
        }
        default {
            Write-Host "Invalid selection. Please try again."
        }
    }

    Read-Host "Press Enter to return to the main menu..."
} while ($true)
