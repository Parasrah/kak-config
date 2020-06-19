colorscheme gruvbox

set-option -add global autoinfo normal
set-option global startup_info_version 20200604
set-option global ui_options ncurses_assistant=cat
set-option global ui_options ncurses_set_title=false
# set-option global path '%/ ./ /usr/include'

################# hooks ###################

# editorconfig
hook global WinCreate ^[^*]+$ %{editorconfig-load}

# copy
hook global NormalKey y %{ nop %sh{
    printf %s "$kak_main_reg_dquote" | xsel --input --clipboard
}}

hook global BufCreate .* %{
    declare-option -hidden bool git_blame_enabled false
}

# filetypes
hook global BufCreate .*kitty[.]conf %{
    set-option buffer filetype ini
}

hook global WinSetOption filetype=(typescript|typescriptreact) %{
    set-option window lintcmd 'run() { cat "$1" | npx eslint -f ~/.npm-global/lib/node_modules/eslint-formatter-kakoune/index.js --stdin --stdin-filename "$kak_buffile";} && run '
    set-option window formatcmd "npx prettier --stdin-filepath %val{buffile}"
}

hook global WinSetOption filetype=(elixir) %{
    set-option window formatcmd "mix format -"
}

hook global BufWritePost filetype=(typescript|typescriptreact) %{
    lint
}

################ commands #################

define-command -hidden toggle-git-blame %{

}

################# keymaps #################

# replace line
map global user ' ' giGlc

# comment line
map global user c ':comment-line<ret>' -docstring 'comment selected lines'
map global user C ':comment-block<ret>' -docstring 'comment block'

# copy/paste
map global user p '<a-!>xsel --output --clipboard<ret>' -docstring 'paste from clipboard in front'
map global user P '!xsel --output --clipboard<ret>' -docstring 'paste from clipboard behind'

# formatting
map global user f ':format<ret>' -docstring 'Format'

declare-user-mode git
map global user g ':enter-user-mode git<ret>' -docstring 'git mode'
map global git b ' :toggle-git-blame<ret>' -docstring 'toggle blame'
map global git s ' :git status<ret>' -docstring 'git status'

map global normal <space> , -docstring 'leader'
map global normal , <space> -docstring 'remove all selections except main'

################# plugins #################

source "%val{config}/plugins/plug.kak/rc/plug.kak"

plug "andreyorst/plug.kak" noload

plug "ul/kak-lsp" do %{
    cargo install --locked --force --path .
} config %{
    echo -debug "configuring kak-lsp"
    # set-option global lsp_cmd "kak-lsp -s %val{session} -vvv --log /tmp/kak-lsp.log"
    declare-option -hidden str lsp_language ''

    set-option global lsp_hover_anchor true
    set-option global lsp_diagnostic_line_error_sign '✗'
    set-option global lsp_diagnostic_line_warning_sign '⚠'

    define-command lsp-hover-info -docstring "show hover info" %{
      set-option buffer lsp_show_hover_format 'printf %s "${lsp_info}"'
      lsp-hover
    }

    define-command lsp-hover-diagnostics -docstring "show hover info" %{
      set-option buffer lsp_show_hover_format 'printf %s "${lsp_diagnostics}"'
      lsp-hover
    }

    hook global WinSetOption filetype=(elixir|elm|javascript|typescript|typescriptreact|javascriptreact|csharp) %{
        echo -debug "initializing lsp for window"
        lsp-enable-window
        set-option window lsp_language %val{hook_param_capture_1}
        map buffer user k ':lsp-hover-info<ret>' -docstring 'LSP hover'
        map buffer user K ':lsp-hover-diagnostics<ret>' -docstring 'LSP diagnostics'
        map buffer goto I ':lsp-implementation<ret>' -docstring 'LSP implementation'
    }

    hook global WinSetOption lsp_language=elm %{
        # TODO: remove after https://github.com/ul/kak-lsp/issues/40 resolved
        set-option buffer lsp_completion_fragment_start %{execute-keys <esc><a-h>s\$?[\w.]+.\z<ret>}
    }
}

plug "andreyorst/fzf.kak" config %{
    map global normal <c-p> ': fzf-mode<ret>'
} defer "fzf" %{
    set-option global fzf_file_command 'rg'
    set-option global fzf_grep_command "rg --hidden --smart-case --line-number --no-column --no-heading --color=never ''"
}

plug "andreyorst/smarttab.kak" defer smarttab %{
} config %{
    hook global WinSetOption filetype=(?!makefile).* %{
        expandtab
        set-option window softtabstop %opt{indentwidth}
        hook window WinSetOption indentwidth=([0-9]+) %{
            echo -debug "setting softtabstop=%val{hook_param_capture_1}"
            set-option window softtabstop %val{hook_param_capture_1}
        }
    }
    hook global WinSetOption filetype=(makefile) noexpandtab
}

# for use with `man`
plug "eraserhd/kak-ansi" do %{
    make
}

plug "alexherbo2/surround.kak" defer surround %{
} config %{
    map global user s ': surround<ret>' -docstring 'Enter surround mode'
    map global user S ': surround _ _ * *<ret>' -docstring 'Enter surround mode with extra surrounding pairs'
}

plug "alexherbo2/prelude.kak"

plug "alexherbo2/connect.kak"

plug "alexherbo2/replace-mode.kak" config %{
    map global user r ': enter-replace-mode<ret>' -docstring 'Enter replace mode'
}

plug "Parasrah/csharp.kak"

plug "Parasrah/typescript.kak"

plug "Parasrah/i3.kak" config %{
    map global user w ': i3-mode<ret>' -docstring 'i3 mode'
} defer i3wm %{
    alias global new i3-new
    hook -group i3-hooks global KakBegin .* %{
        alias global terminal i3-terminal
    }
    define-command nnn -params .. -file-completion -docstring 'Open file with nnn' %{
        connect-terminal nnn -e %arg(@)
    }

    define-command nvim -docstring 'Open file with nvim' %{
        connect-terminal nvim %val{buffile}
    }
    map global normal <minus> ': nnn %sh{ dirname $kak_buffile }<ret>' -docstring 'open up nnn for the current buffer directory'
} demand
