#
# This function provides simple autocompletion to zbx_backup script
# Place it to /etc/bash_completion.d/ and run next command:
# . /etc/bash_completion.d/zbx_backup.bash
# Option set is corresponds to v0.5.2 and higher.
#

zbx_backup_autocomplete() {
	# Declare local variables
	local CUR PREV MAIN_OPTS COMPRESS_UTILS
	
	COMPREPLY=()
	CUR="${COMP_WORDS[COMP_CWORD]}"
	PREV="${COMP_WORDS[COMP_CWORD-1]}"
	MAIN_OPTS="--help --version --save-to --temp-folder --compress-with --rotation --use-xtrabackup --use-mysqldump --db-only --db-user --db-password --db-name --debug"
	COMPRESS_UTILS="gzip bzip2 lbzip2 pbzip2 xz"
	if [[ ${CUR} == -* ]]
	then
		COMPREPLY=( $(compgen -W "${MAIN_OPTS}" -- ${CUR}) )
		return 0
	fi
	
	if [[ ${PREV} == '--compress-with' ]]
	then
		case "${CUR}" in
			 [a-zA-Z])
				COMPREPLY=( $(compgen -W "${COMPRESS_UTILS}" -- ${CUR}) )
				return 0
				;;
			'')
				COMPREPLY=( $(compgen -W "${COMPRESS_UTILS}") )
				return 0
				;;
		esac
	fi
}

complete -F zbx_backup_autocomplete zbx_backup
