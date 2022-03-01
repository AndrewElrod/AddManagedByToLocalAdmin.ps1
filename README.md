# AddManagedByToLocalAdmin.ps1
Central management of approved local admin rights on end user workstations.
Script to query the ManagedBy attribute and add it, if populated, to the local admin group.
Script needs to be deployed to local workstations via a GPO, and a scheduled task setup to run it on a schedule.
When it runs, it will query the LOGONSERVER for the hostname's workstation object and get the value of the ManagedBy attribute.
If the attribute is populated, it stores that account in the registry, and adds it to the local admin group.
If the attribute is blank, it will check the registry to see if an admin has previously been listed, and then remove it from the local admin group.

You will need to replace the two "DOMAIN/" entries on Lines 35 and 42 with the shortname of your domain, i.e. "contoso/".
Lines 4, 5 and 11 should have "Company" replaced with the name of your organization.
