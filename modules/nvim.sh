#!/usr/bin/env bash

is_installed() {
    cmd nvim
}

install() {
    NVIM_VER=$(latest neovim/neovim)
    NVIM_URL=https://github.com/neovim/neovim/releases/download/$NVIM_VER/nvim.appimage
    curl -o "$BIN/nvim" "$NVIM_URL"
    chmod +x "$BIN/nvim"
    rm -rf "$CONFIG/nvim" "$SHARE/nvim"
    curl -O https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    mkdir -p "$CONFIG/nvim" "$SHARE/nvim/site/autoload"
    mv -f plug.vim "$SHARE/nvim/site/autoload"
    configure
}

configure() {
cat <<EOF >"$CONFIG/nvim/init.vim"
call plug#begin('$SHARE/nvim/plugged')
Plug 'davidhalter/jedi-vim', {'do': ':UpdateRemotePlugins'}
Plug 'jiangmiao/auto-pairs', {'do': ':UpdateRemotePlugins'}
Plug 'machakann/vim-highlightedyank', {'do': ':UpdateRemotePlugins'}
Plug 'neomake/neomake', {'do': ':UpdateRemotePlugins'}
Plug 'numirias/semshi', {'do': ':UpdateRemotePlugins'}
Plug 'sbdchd/neoformat', {'do': ':UpdateRemotePlugins'}
Plug 'scrooloose/nerdcommenter', {'do': ':UpdateRemotePlugins'}
Plug 'scrooloose/nerdtree', {'do': ':UpdateRemotePlugins'}
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'terryma/vim-multiple-cursors', {'do': ':UpdateRemotePlugins'}
Plug 'tmhedberg/SimpylFold', {'do': ':UpdateRemotePlugins'}
Plug 'vim-airline/vim-airline', {'do': ':UpdateRemotePlugins'}
Plug 'vim-airline/vim-airline-themes', {'do': ':UpdateRemotePlugins'}
Plug 'zchee/deoplete-jedi', {'do': ':UpdateRemotePlugins'}
call plug#end()
autocmd InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif
inoremap <expr><tab> pumvisible() ? "\<c-n>" : "\<tab>"
let g:airline_theme='minimalist'
let g:deoplete#auto_complete_delay = 100
let g:deoplete#enable_at_startup = 1
set splitbelow
EOF
}
