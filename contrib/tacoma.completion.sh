_tacoma()
{
  local cur prev commands
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  commands="cd help install list switch"

  case "${prev}" in
    cd)
      local envs=$(echo $(tacoma list))
      COMPREPLY=( $(compgen -W "${envs}" -- ${cur}) )
      return 0
      ;;
    help)
      COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
      return 0
      ;;
    switch)
      local envs=$(echo $(tacoma list))
      COMPREPLY=( $(compgen -W "${envs}" -- ${cur}) )
      return 0
      ;;
    *)
      ;;
  esac
  COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
  return 0
}
complete -F _tacoma tacoma
