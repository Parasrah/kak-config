# TODO: highlight todo
# TODO: ignore git files in fzf
# TODO: change main client when switching between windows
# TODO: use i3 split for 'terminal'
# TODO: use '-' to open 'nnn' {above} current file (like netrw)
# TODO: fix keymap missing <ret>
# TODO: make 'terminal' open below current i3 window
# TODO: make Y copy (not yank)
# TODO: make <c-w> go back wordwise in fzf
# TODO: how to replicate R from vim?
# TODO: add margin on left
colorscheme gruvbox

set-option -add global autoinfo normal
set-option global startup_info_version 20200604
set-option global ui_options ncurses_assistant=cat

map global normal <space> , -docstring 'leader'
map global normal , <space> -docstring 'remove all selections except main'

################# hooks ###################

# editorconfig
hook global WinCreate ^[^*]+$ %{editorconfig-load}

# copy
hook global NormalKey y %{ nop %sh{
    printf %s "$kak_main_reg_dquote" | xsel --input --clipboard
}}

# lsp hover
hook global RawKey k %{
    set-option window lsp_show_hover_format 'printf %s "${lsp_info}"'
}

hook global RawKey K %{
    set-option window lsp_show_hover_format 'printf %s "${lsp_diagnostics}"'
}

# filetypes
hook global BufCreate kitty\.conf %{
    set-option window filetype ini
}

################ commands #################

define-command nnn -params .. -file-completion %(connect-terminal nnn %arg(@)) -docstring "Open with nnn"

################# keymaps #################

# replace line
map global user ' ' giGlc

# comment line
map global user c ':comment-line<ret>' -docstring 'comment selected lines'
map global user C ':comment-block' -docstring 'comment block'

# copy/paste
map global user p '<a-!>xsel --output --clipboard<ret>' -docstring 'paste from clipboard in front'
map global user P '!xsel --output --clipboard<ret>' -docstring 'paste from clipboard behind'

# formatting
map global user f ':format<ret>' -docstring 'Format'

################### i3 ####################
# TODO: i3 commands should open a new session with the same cwd & file open
# having it open the same session is currently a problem for things like fzf
# the con of this is that the buffer list is lost
# could alternively have them open in same session, fzf etc opens i3 window
# (always at bottom with full width and focus) and use 'FocusIn' hook (if supported
# by kitty) to change the main client (if that's possible) when focus changes and
# it's not a fzf window

define-command -hidden -params 1.. i3-new-impl %{
  evaluate-commands %sh{
    if [ -z "$kak_opt_termcmd" ]; then
      echo "fail 'termcmd option is not set'"
      exit
    fi
    i3_split="$1"
    shift
    # clone (same buffer, same line)
    cursor="$kak_cursor_line.$kak_cursor_column"
    kakoune_args="-e 'execute-keys $@ :buffer <space> $kak_buffile <ret> :select <space> $cursor,$cursor <ret>'"
    {
      # https://github.com/i3/i3/issues/1767
      [ -n "$i3_split" ] && i3-msg "split $i3_split"
      exec $kak_opt_termcmd "kak -c $kak_session $kakoune_args"
    } < /dev/null > /dev/null 2>&1 &
  }
}
define-command i3-new-down -docstring "Create a new window below" %{
  i3-new-impl v 
}

define-command i3-new-up -docstring "Create a new window below" %{
  i3-new-impl v :nop <space> '%sh{ i3-msg move up }' <ret>
}

define-command i3-new-right -docstring "Create a new window on the right" %{
  i3-new-impl h
}

define-command i3-new-left -docstring "Create a new window on the left" %{
  i3-new-impl h :nop <space> '%sh{ i3-msg move left }' <ret>
}

define-command i3-new -docstring "Create a new window in the current container" %{
  i3-new-impl ""
}

# Suggested aliases

alias global new i3-new

declare-user-mode i3
map global i3 n :i3-new<ret> -docstring "new window in the current container"
map global i3 h :i3-new-left<ret> -docstring '← new window on the left'
map global i3 l :i3-new-right<ret> -docstring '→ new window on the right'
map global i3 k :i3-new-up<ret> -docstring '↑ new window above'
map global i3 j :i3-new-down<ret> -docstring '↓ new window below'

# Suggested mapping

map global user w ': enter-user-mode i3<ret>' -docstring 'i3 mode'

declare-user-mode git
map global user g ':enter-user-mode git<ret>' -docstring 'git mode'

# Plugins

source "%val{config}/plugins/plug.kak/rc/plug.kak"

plug "andreyorst/plug.kak" noload

plug "ul/kak-lsp" do %{
        cargo install --locked --force --path .
} config %{
    set-option global lsp_hover_anchor true
    set-option global lsp_diagnostic_line_error_sign '✗'
    set-option global lsp_diagnostic_line_warning_sign '⚠'

    # debug
    # set global lsp_cmd "kak-lsp -s %val{session} -vvv --log /tmp/kak-lsp.log"
    hook global WinSetOption filetype=(elixir|elm|javascript|typescript) %{
        lsp-enable-window
        map buffer user k ':lsp-hover<ret>' -docstring 'LSP hover'
        map buffer goto I ':lsp-implementation<ret>' -docstring 'LSP implementation'
        map buffer user K ':lsp-hover<ret>' -docstring 'LSP hover (ignore diagnostics)'
        # TODO: hook to prevent 'K' from printing diagnostics
        map buffer user f ':lsp-formatting<ret>' -docstring 'LSP Format'
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
    # softtabstop
    hook global WinSetOption indentwidth=([0-9]+) %{
        echo -debug setting softtabstop to %val{hook_param_capture_1}
        # TODO: only do if softtabstop exists
        set-option window softtabstop %val{hook_param_capture_1}
    }

    # TODO: inverse of below
    hook global WinSetOption filetype=(elixir|javascript|typescript|rust|nix|kak|elm) expandtab
    hook global WinSetOption filetype=(makefile) noexpandtab
}

plug "alexherbo2/surround.kak" defer surround %{
} config %{
    map global user s ': surround<ret>' -docstring 'Enter surround mode'
    map global user S ': surround _ _ * *<ret>' -docstring 'Enter surround mode with extra surrounding pairs'
}

plug "eraserhd/kak-ansi" do %{
    make
}

plug "alexherbo2/connect.kak"
