#
# This function provide simple autocompletion to zbx_backup script
# Place it to /etc/bash_completion.d and run next command:
# . /etc/bash_completion.d/zbx_backup.bash
# 

_zbx_backup() {
	local cur prev opts
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"
	opts="--help --version --save-to --temp-folder --compress-with --rotation --use-xtrabackup --use-mysqldump --db-only --db-user --db-password --db-name --debug"
	
	if [[ ${cur} == -* ]]; then
		COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
		return 0
	fi
}
complete -F _zbx_backup zbx_backup.sh
