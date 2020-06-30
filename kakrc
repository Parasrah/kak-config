#───────────────────────────────────#
#               style               #
#───────────────────────────────────#

colorscheme gruvbox
hook global WinCreate ^[^*]+$ %{ add-highlighter window/ number-lines -hlcursor }
add-highlighter global/ show-matching

#───────────────────────────────────#
#              options              #
#───────────────────────────────────#

set-option global startup_info_version 20200604
set-option global ui_options ncurses_assistant=cat
set-option global ui_options ncurses_set_title=false
set-option global path '%/ ./ /usr/include'
set-option global grepcmd 'rg -HLn --no-heading'

#───────────────────────────────────#
#               misc                #
#───────────────────────────────────#

hook global WinCreate ^[^*]+$ %{editorconfig-load}

# leader
map global normal <space> , -docstring 'leader'
map global normal , <space> -docstring 'remove all selections except main'

# copy
hook global NormalKey y %{ nop %sh{
    printf %s "$kak_main_reg_dquote" | xsel --input --clipboard
}}

# formatting
map global user f ':format<ret>' -docstring 'Format'

# comment line
map global normal '#' ':comment-line<ret>' -docstring 'comment selected lines'
map global normal <a-#> ':comment-block<ret>' -docstring 'comment block'

# terminal
map global user <ret> ' :connect-terminal bash<ret>' -docstring 'open terminal'

# nnn
map global normal <minus> ': nnn-current<ret>' -docstring 'open up nnn for the current buffer directory'

#───────────────────────────────────#
#             filetypes             #
#───────────────────────────────────#

hook global BufCreate .*kitty[.]conf %{
    set-option buffer filetype ini
}

hook global WinSetOption filetype=(typescript|typescriptreact) %{
    set-option window lintcmd 'run() { cat "$1" | npx eslint -f ~/.npm-global/lib/node_modules/eslint-formatter-kakoune/index.js --stdin --stdin-filename "$kak_buffile";} && run '
    set-option window makecmd 'npx tsc --noEmit'
    hook window BufWritePost .* %{
        lint
    }
}

hook global WinSetOption filetype=(typescript|typescriptreact|javascript|javascriptreact) %{
    set-option window formatcmd "npx prettier --stdin-filepath %val{buffile}"
}

hook global WinSetOption filetype=elm %{
    set-option window formatcmd 'elm-format --stdin'
}

hook global WinSetOption filetype=(elixir) %{
    set-option window formatcmd 'mix format -'
}

hook global WinSetOption filetype=python %{
    set-option window formatcmd 'autopep8 -'
}

#───────────────────────────────────#
#                git                #
#───────────────────────────────────#

hook global BufCreate .* %{
    declare-option -hidden bool git_blame_enabled false
}

define-command -hidden toggle-git-blame %{
    evaluate-commands %sh{
        if [ "$kak_opt_git_blame_enabled" = 'true' ]; then
            printf %s 'git hide-blame; set-option window git_blame_enabled false'
        else
            printf %s 'git blame; set-option window git_blame_enabled true'
        fi
    }
}

declare-user-mode git
map global user g ':enter-user-mode git<ret>' -docstring 'git mode'
map global git b ' :toggle-git-blame<ret>' -docstring 'toggle blame'
map global git s ' :git status<ret>' -docstring 'git status'
map global git c ' :git commit<ret>' -docstring 'git commit'
map global git d ' :git diff %val{buffile}<ret>' -docstring 'git diff (current file)'


#───────────────────────────────────#
#               casing              #
#───────────────────────────────────#

define-command camel-to-snake %{
    execute-keys -draft '<a-i>ws[A<minus>Z]<ret>`\i_<esc>'
}

define-command camel-to-capital %{
    execute-keys -draft '<a-i>w<a-semicolon><semicolon>~'
}

define-command capital-to-camel %{
    execute-keys -draft '<a-i>w<a-semicolon><semicolon>`'
}

define-command capital-to-snake %{
    execute-keys -draft '<a-i>ws[A<minus>Z]<ret>`i_<esc>[w<semicolon>d'
}

define-command snake-to-camel %{
    execute-keys -draft '<a-i>ws_<ret>d~'
}

define-command snake-to-capital %{
    execute-keys -draft '<a-i>ws_<ret>d~[w<semicolon>~'
}

#───────────────────────────────────#
#               ide                 #
#───────────────────────────────────#

map global user h ':grep-previous-match<ret>' -docstring 'Jump to the previous grep match'
map global user l ':grep-next-match<ret>' -docstring 'Jump to the next grep match'
map global user H ':make-previous-error<ret>' -docstring 'Jump to the previous make error'
map global user L ':make-next-error<ret>' -docstring 'Jump to the next make error'

map global user k ':lint-previous-message<ret>' -docstring 'Jump to the previous lint message'
map global user j ':lint-next-message<ret>' -docstring 'Jump to the next lint message' 

#───────────────────────────────────#
#            copy/paste             #
#───────────────────────────────────#

map global user p '<a-!>xsel --output --clipboard<ret>' -docstring 'paste from clipboard in front'
map global user P '!xsel --output --clipboard<ret>' -docstring 'paste from clipboard behind'

#───────────────────────────────────#
#            highlight              #
#───────────────────────────────────#
# https://github.com/mawww/config/blob/master/kakrc

declare-option -hidden regex curword
set-face global CurWord default,rgba:80808040

hook global NormalIdle .* %{
    eval -draft %{ try %{
        exec <space><a-i>w <a-k>\A\w+\z<ret>
        set-option buffer curword "\b\Q%val{selection}\E\b"
    } catch %{
        set-option buffer curword ''
    } }
}
add-highlighter global/ dynregex '%opt{curword}' 0:CurWord

#───────────────────────────────────#
#              plugins              #
#───────────────────────────────────#

source "%val{config}/plugins/plug.kak/rc/plug.kak"

plug "andreyorst/plug.kak" noload

plug "ul/kak-lsp" do %{
    cargo install --locked --force --path .
} config %{
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

    hook global WinSetOption filetype=(elm|elixir|javascript|typescript|typescriptreact|javascriptreact) %{
        echo -debug "initializing lsp for window"
        lsp-enable-window
        set-option window lsp_language %val{hook_param_capture_1}
        map window user ';' ':lsp-hover-info<ret>' -docstring 'hover'
        map window user ':' ':lsp-hover-diagnostics<ret>' -docstring 'diagnostics'
        map window user . ':lsp-code-actions<ret>' -docstring 'code actions'
        map window goto I ':lsp-implementation<ret>' -docstring 'goto implementation'
        map window user <a-h> ':lsp-goto-previous-match<ret>' -docstring 'LSP goto previous'
        map window user <a-l> ':lsp-goto-next-match<ret>' -docstring 'LSP goto next'
        map window user <a-k> ':lsp-find-error --previous<ret>' -docstring 'goto previous LSP error'
        map window user <a-j> ':lsp-find-error<ret>' -docstring 'goto next LSP error'
    }

    hook global WinSetOption lsp_language=elm %{
        # TODO: remove after https://github.com/ul/kak-lsp/issues/40 resolved
        set-option buffer lsp_completion_fragment_start %{execute-keys <esc><a-h>s\$?[\w.]+.\z<ret>}
    }
}

plug "andreyorst/fzf.kak" config %{
    map global normal <c-p> ': fzf-mode<ret>'
} subset %{
    fzf.kak
    fzf-file.kak
    fzf-buffer.kak
    fzf-search.kak
    fzf-cd.kak
    fzf-grep.kak
    fzf-project.kak
} defer "fzf" %{
    set-option global fzf_file_command 'rg --files --hidden -g "!.git" -g "!node_modules"'
    set-option global fzf_grep_command "rg --hidden --smart-case --line-number --no-column --no-heading --color=never ''"
    set-option global fzf_terminal_command 'kitty-terminal kak -c %val{session} -e "%arg{@}"'
    set-option global fzf_window_map 'ctrl-t'
    set-option global fzf_preview true
}

plug "andreyorst/smarttab.kak" defer smarttab %{
} config %{
    hook global WinSetOption filetype=(?!makefile).* %{
        expandtab
        set-option window softtabstop %opt{indentwidth}
        hook window WinSetOption indentwidth=([0-9]+) %{
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

plug "alexherbo2/terminal-mode.kak"

plug "alexherbo2/connect.kak" commit "05baa48582d383799e3e892d6c79656cf40b2f72" config %{
    define-command nnn-persistent -params 0..1 -file-completion -docstring 'Open file with nnn' %{
        connect-terminal nnn %sh{echo "${@:-$(dirname "$kak_buffile")}"}
    }

    alias global nnn nnn-persistent
}

plug "alexherbo2/replace-mode.kak" config %{
    map global user r ': enter-replace-mode<ret>' -docstring 'Enter replace mode'
}

plug "Parasrah/kitty.kak" defer kitty %{
    define-command nnn-current -params 0..1 -file-completion -docstring 'Open file with nnn (volatile)' %{
        kitty-overlay sh -c %{
            PAGER=""
            kak_buffile=$1 kak_session=$2 kak_client=$3
            shift 3
            kak_pwd="${@:-$(dirname "${kak_buffile}")}"
            filename=$(nnn -p - "${kak_pwd}")
            kak_cmd="evaluate-commands -client $kak_client edit $filename"
            echo $kak_cmd | kak -p $kak_session
        } -- %val{buffile} %val{session} %val{client} %arg{@}
    }

    define-command nvim -docstring 'Open current buffer in neovim' %{
        kitty-overlay sh -c %{
            kak_buffile=$1
            cursor_line=$2
            nvim $kak_buffile +$cursor_line -c "execute 'normal! zz'"
        } -- %val{buffile} %val{cursor_line}
    }
}

plug "Parasrah/csharp.kak"

plug "Parasrah/typescript.kak"

plug "Parasrah/i3.kak" config %{
    map global user w ': i3-mode<ret>' -docstring 'i3 mode'
} defer i3wm %{
    alias global new i3-new
    hook -group i3-hooks global KakBegin .* %{
        define-command -hidden set-i3-terminal-alias %{
            alias global terminal i3-terminal-b
        }
        set-i3-terminal-alias
    }
} demand

#───────────────────────────────────#
#                misc               #
#───────────────────────────────────#

nop %sh{ {
    status=$(http GET https://api.github.com/repos/ul/kak-lsp/issues/40 | jq '.state')
    if [ "$status" = '"closed"' ]; then
        echo "echo -debug https://github.com/ul/kak-lsp/issues/40 is closed" |
            kak -p ${kak_session}
    fi
} > /dev/null 2>&1 < /dev/null & }
