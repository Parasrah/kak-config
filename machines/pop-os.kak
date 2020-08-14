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

plug "Parasrah/csharp.kak"
plug "Parasrah/typescript.kak"
