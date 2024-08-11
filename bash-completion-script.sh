_mytool_completion() {
    local cur prev words cword
    _init_completion || return

    case "${prev}" in
        mytool)
            COMPREPLY=($(compgen -W "subcommand1 subcommand2 subcommand3" -- "${cur}"))
            return 0
            ;;
        subcommand1)
            COMPREPLY=($(compgen -W "--option1 --option2" -- "${cur}"))
            return 0
            ;;
        subcommand2)
            COMPREPLY=($(compgen -W "--flag1 --flag2" -- "${cur}"))
            return 0
            ;;
        subcommand3)
            COMPREPLY=($(compgen -f -- "${cur}"))
            return 0
            ;;
    esac

    COMPREPLY=($(compgen -W "subcommand1 subcommand2 subcommand3" -- "${cur}"))
}

complete -F _mytool_completion mytool
