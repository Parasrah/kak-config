colorscheme gruvbox

source "%val{config}/plugins/plug.kak/rc/plug.kak"

plug "andreyorst/fzf.kak" config %{
    map global normal <c-p> ': fzf-mode<ret>'
} defer "fzf" %{
    set-option global fzf_file_command 'rg'
}

plug "andreyorst/smarttab.kak" defer smarttab %{

} config %{
    hook global WinSetOption filetype=(elixir|elm|javascript|typescript) noexpandtab
}

hook global NormalKey y %{ nop %sh{
    printf %s "$kak_main_reg_dquote" | xsel --input --clipboard
}}

hook global WinCreate ^[^*]+$ %{editorconfig-load}

eval %sh{kak-lsp --kakoune -s $kak_session}
set global lsp_hover_anchor true
hook global WinSetOption filetype=(elixir|elm|javascript|typescript) %{
    lsp-enable-window
    lsp-auto-hover-enable
}
