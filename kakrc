colorscheme gruvbox

source "%val{config}/plugins/plug.kak/rc/plug.kak"

plug "andreyorst/fzf.kak" config %{

} defer "fzf" %{
    set-option global fzf_file_command 'rg'
}

map global normal <c-p> ': fzf-mode<ret>'

hook global NormalKey y|d|c %{ nop %sh{
      printf %s "$kak_main_reg_dquote" | xsel --input --clipboard
}}

hook global BufOpenFile .* %{ editorconfig-load }
hook global BufNewFile .* %{ editorconfig-load }

eval %sh{kak-lsp --kakoune -s $kak_session}
lsp-enable
