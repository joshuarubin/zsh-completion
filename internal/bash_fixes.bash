#!/bin/bash

case "$COMP_WORDBREAKS" in
*:*) : great ;;
*)   COMP_WORDBREAKS="$COMP_WORDBREAKS:"
esac

__zsh_bash_reassemble_comp_words_by_ref()
{
	local exclude i j first
	# Which word separators to exclude?
	exclude="${1//[^$COMP_WORDBREAKS]}"
	cword_=$COMP_CWORD
	if [ -z "$exclude" ]; then
		words_=("${COMP_WORDS[@]}")
		return
	fi
	# List of word completion separators has shrunk;
	# re-assemble words to complete.
	for ((i=0, j=0; i < ${#COMP_WORDS[@]}; i++, j++)); do
		# Append each nonempty word consisting of just
		# word separator characters to the current word.
		first=t
		while
			[ $i -gt 0 ] &&
			[ -n "${COMP_WORDS[$i]}" ] &&
			# word consists of excluded word separators
			[ "${COMP_WORDS[$i]//[^$exclude]}" = "${COMP_WORDS[$i]}" ]
		do
			# Attach to the previous token,
			# unless the previous token is the command name.
			if [ $j -ge 2 ] && [ -n "$first" ]; then
				((j--))
			fi
			first=
			words_[$j]=${words_[j]}${COMP_WORDS[i]}
			if [ $i = $COMP_CWORD ]; then
				cword_=$j
			fi
			if (($i < ${#COMP_WORDS[@]} - 1)); then
				((i++))
			else
				# Done.
				return
			fi
		done
		words_[$j]=${words_[j]}${COMP_WORDS[i]}
		if [ $i = $COMP_CWORD ]; then
			cword_=$j
		fi
	done
}

if ! type _get_comp_words_by_ref >/dev/null 2>&1; then
_get_comp_words_by_ref ()
{
	local exclude cur_ words_ cword_
	if [ "$1" = "-n" ]; then
		exclude=$2
		shift 2
	fi
	__zsh_bash_reassemble_comp_words_by_ref "$exclude"
	cur_=${words_[cword_]}
	while [ $# -gt 0 ]; do
		case "$1" in
		cur)
			cur=$cur_
			;;
		prev)
			prev=${words_[$cword_-1]}
			;;
		words)
			words=("${words_[@]}")
			;;
		cword)
			cword=$cword_
			;;
		esac
		shift
	done
}
fi

if ! type _init_completion >/dev/null 2>&1; then
_init_completion()
{
    COMPREPLY=()
    _get_comp_words_by_ref cur prev words cword
}
fi

_expand()
{
	[ "$cur" != "${cur%\\}" ] && cur="$cur\\"

	# expand ~username type directory specifications
	if [[ "$cur" == \~*/* ]]; then
		eval cur=$cur

	elif [[ "$cur" == \~* ]]; then
		cur=${cur#\~}
		COMPREPLY=( $( compgen -P '~' -u $cur ) )
		return ${#COMPREPLY[@]}
	fi
}

_filedir()
{
	local IFS=$'\t\n' xspec #glob

	_expand || return 0

	#glob=$(set +o|grep noglob) # save glob setting.
	#set -f		 # disable pathname expansion (globbing)

	if [ "${1:-}" = -d ]; then
		COMPREPLY=( ${COMPREPLY[@]:-} $( compgen -d -- $cur ) )
		#eval "$glob"    # restore glob setting.
		return 0
	fi

	xspec=${1:+"!*.$1"}	# set only if glob passed in as $1
	COMPREPLY=( ${COMPREPLY[@]:-} $( compgen -f -X "$xspec" -- "$cur" ) \
		    $( compgen -d -- "$cur" ) )
	#eval "$glob"    # restore glob setting.
} # _filedir()
