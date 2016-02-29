# Wordpress on nginx server
Assumptions for this script are - 
**1.**	SELinux is not enabled or is in enforced mode. 
**2.**	Script is being used for a fresh installation or configuration setup.
**3**		There is no previous messed package or configuration.
**4.**	Php is interfacing with MySQL by root account and a default root password is set, incase some other account is being used. That has to be edited in line 121 and 122.
**5** 	No special character such as, “/”, “\”, “.”, or characters that are not allowed in file names is to be given when prompted for domain name.

