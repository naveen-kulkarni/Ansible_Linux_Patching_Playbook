# Ansible_Linux_Patching_Playbook
Ansible playbook for complete patching. It includes pre-check and post-check.

Make the changes in /etc/anisble.cfg
inventory      = <PATH_OF_INVETORY_FILE>
forks          = 15
remote_user    = naveen_adm
roles_path    = /home/naveen/automation/roles:/usr/share/ansible/role
host_key_checking = False
retry_files_enabled = False
connect_timeout = 30
connect_retries = 30
connect_interval = 1




