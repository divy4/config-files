" arch linux
"runtime! archlinux.vim


" ######################## shortcuts

" arrowkey fix
"inoremap <Up> <C-o>gk
"nnoremap <Up> gk

"inoremap <Down> <C-o>gj
"nnoremap <Down> gj

" jump to line
imap PP <esc>:

" cut and paste line
imap KK <home><esc>v<end>d<insert>
imap UU <home><esc>vp<insert><end><cr>

" repeat command
imap AA <esc>:<up><cr><insert>
vmap AA <esc>:<up><cr>v
nmap AA :<up><cr> 

" exit vim
imap QQ <esc>:q<cr><insert>
vmap QQ <esc>:q<cr><insert>
nmap QQ :q!<cr><insert>

" save file
imap SS <esc>:w<cr><insert><right>
vmap SS <esc>:w<cr>v
nmap SS :w<cr>

" open file
imap OO <esc>:open<space>
vmap OO <esc>:open<space>
nmap OO :open<space>

" reload file
imap EE <esc>:e!<cr><insert>
vmap EE <esc>:e!<cr>v
nmap EE :e!<cr>

" undo
imap ZZ <esc>:undo<cr><insert>
vmap ZZ <esc>:undo<cr>v
nmap ZZ :undo<cr>

" redo
imap XX <esc>:redo<cr><insert>
vmap XX <esc>:redo<cr>v
nmap XX :redo<cr>

" search and replace (in file)
imap RR <esc>:%s///g<left><left><left>
vmap RR <esc>:%s///g<left><left><left>
nmap RR :%s///g<left><left><left>

" jump to insert mode
imap II <space><backspace>
vmap II <esc><insert>
nmap II <insert>

" jump to visual mode
imap VV <esc>v
vmap VV <shift>
nmap VV v

" split screen
" horizontial
imap HH <esc>:sp<cr>
vmap HH <esc>:sp<cr>
nmap HH :sp<cr>
" vertical
imap GG <esc>:vsp<cr>
vmap GG <esc>:vsp<cr>
nmap GG :vsp<cr>

" moving windows
" swap with one below
imap JJ <esc><c-w>x<insert>
vmap JJ <esc><c-w>xv
nmap JJ <c-w>x
" move to the top
imap YY <esc><c-w>K<insert>
vmap YY <esc><c-w>Kv
nmap YY <c-w>K
" move to bottom
imap BB <esc><c-w>J<insert>
vmap BB <esc><c-w>Jv
nmap BB <c-w>J

" search
imap FF <esc>/
vmap FF <esc>/
nmap FF /

" visual mode adjustments
vmap <backspace> d


" #####c++

" #include <>
imap cinclude <home>#include<space><lt>><cr><left><left>
" main file text
imap cmain <cr><cr><cr>int<space>main(int<space>argc,<space>char**<space>argv)<cr>{<cr><cr>return<space>0;<cr>}<cr><up><up><up><tab>
" header
imap hheader #pragma<space>once<cr><cr><cr>
" class header
imap hclass #pragma<space>once<cr><cr><cr>class<space><cr>{<cr><backspace>public:<cr><tab><cr><backspace>private:<cr><tab><cr>};<cr><up><up><up><up><up><up><up><end>



" #####python

" class
imap pyclass class<space>:<cr><tab>'''<space><cr>'''<cr><cr><tab><backspace>#<space>--------------------<space>inner<space>classes<space>--------------------<cr><cr><cr><cr><tab><backspace>#<space>--------------------<space>nonpublic<space>members<space>-----------------<cr><cr><cr><cr><tab><backspace>#<space>--------------------<space>public<space>members<space>--------------------<cr><cr><cr><cr><cr><backspace>if<space>__name__<space>==<space>'__main__':<cr>print(<space>'Not<space>implemented.'<space>)

" __init__
imap pyinit def<space>__init__(<space>self<space>):<cr><tab>
" __len__
imap pylen def<space>__len__(<space>self<space>):<cr><tab>return<space>
" __str__
imap pystr def<space>__str__(<space>self<space>):<cr><tab>out<space>=<space>''.format()<cr>return<space>out<up><left><left><left>
" __eq__
imap pyeq def<space>__eq__(<space>self,<space>left<space>):<cr><tab>return<space>
" generic class member function
imap pymem def<space>(<space>self<space>):<cr><tab><up><end><left><left><left><left><left><left><left><left><left>

" __name__
imap pyname if<space>__name__<space>==<space>'__main__':<cr>

" type tester
imap pytype if not isinstance(,<space>):<cr>raise<space>TypeError('<space>must<space>be<space>a<space>.')<up><end><left><left><left><left>

" error tester (pythonerror)
imap pyerr try:<cr><tab><cr><backspace>except<space>Error<space>as<space>error:<cr><tab>print(<space>'<space>error:',<space>error<space>)<cr><backspace>except<space>Exception<space>as<space>error:<cr><tab>print(<space>'Unexpected<space>error:',<space>error<space>)<cr><backspace><up><up><up><up><up><end>

" error tester (type)
imap pyerrtype try:<cr><tab><cr><backspace>except<space>TypeError<space>as<space>error:<cr><tab>print(<space>'Type<space>error:',<space>error<space>)<cr><backspace>except<space>Exception<space>as<space>error:<cr><tab>print(<space>'Unexpected<space>error:',<space>error<space>)<cr><backspace><up><up><up><up><up><end>

" error tester (value)
imap pyerrval try:<cr><tab><cr><backspace>except<space>ValueError<space>as<space>error:<cr><tab>print(<space>'Value<space>error:',<space>error<space>)<cr><backspace>except<space>Exception<space>as<space>error:<cr><tab>print(<space>'Unexpected<space>error:',<space>error<space>)<cr><backspace><up><up><up><up><up><end>


" ##### R

" headers
imap rheader #<space><esc>:put<space>=expand('%:T')<cr>


" ##### verilog

" # use these when making test cases of every possible binary input

"imap b1 0<down><left>1<down><left>

"imap b2 0<down><left>0<down><left>1<down><left>1<down><left>

"imap b3 0<down><left>0<down><left>0<down><left>0<down><left>1<down><left>1<down><left>1<down><left>1<down><left>

"imap b4 0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>

"imap b5 0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>

"imap b6 0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>

"imap b7 0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>0<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>1<down><left>



" ######################## settings

" colors
filetype plugin on
syntax on

" highlight searches
set hlsearch

" show line number and mark 81st character column
set number
set colorcolumn=100

" mouse
set mouse=a

" jump across line breaks
set whichwrap=b,s,<,>,[,]

" tab/indent settings
set tabstop=4
set shiftwidth=4
set softtabstop=4
set smarttab
set expandtab
set smartindent

" start in insert mode
au BufRead,BufNewFile * startinsert

" don't search boost files
set include=^\\s*#\\s*include\ \\(<boost/\\)\\@!
set include=^\\s*#\\s*include\ \\(<SDL2/\\)\\@!

" clipboard
set clipboard=unnamedplus

