let s:path = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
let s:bundle_path = s:path."/bundle"

" tab formatting settings - automatically provided by vim-sleuth

" ####################################################################
" integratino with vim-alchemist
nnoremap <buffer> <silent> F1 :call alchemist#exdoc()<CR>

let g:alchemist#elixir_erlang_src = expand("<sfile>:p:h:h") . "/source"

let g:ConqueTerm_CloseOnEnd=1
let g:alchemist_iex_term_size = 15

"map <F12> :IEx<CR>

"function! ErlBalloonExpr()
"	"	return 'Cursor is at line ' . v:beval_lnum .
"	"	\', column ' . v:beval_col .
"	"	\ ' of file ' .  bufname(v:beval_bufnr) .
"	"	\ ' on word "' . v:beval_text . '"'
"
"	let text = alchemist#get_doc(v:beval_text)
"	return text
"endfunction
"
"set bexpr=ErlBalloonExpr()
"set ballooneval



" ####################################################################
" integration with Tagbar
"
function! Tag_transform(tags) " {{{
  " remove OTP callbacks from ordinary function list
  call filter(a:tags, ' !(v:val.fields.kind == "f" && v:val.name =~ "\\v(handle_call|handle_info|handle_cast|init|terminate)") ')

  function! Arity_extract(idx, tag)
    if a:tag.fields.kind == 'f' || a:tag.fields.kind == 'g'
      let args_string = substitute(a:tag.pattern, "^.*defp\\?[ \t]*".a:tag.name."[ \t]*", "", "")
      let args_string = substitute(args_string, "do[ \t]*\\\\[$]$", "", "") " multiline
"      TODO: remove
"      if a:tag.pattern =~ "defp reply" 
"        debug echo("asd")
"      endif
      let args_string = substitute(args_string, ")\\([ \t]*when.*\\)\\?,[ \t]*do.*\\\\[$]$", ")", "")
      let args_string = substitute(args_string, "[ \t]*", "", "g")

      let args_len = len(args_string)

      if args_len == 0
        let a:tag.name = a:tag.name."/0"
      else
        let old_args_len = -10000
        while args_len != old_args_len
          let args_string = substitute(args_string, "{[^}]*}", "", "g")
          let args_string = substitute(args_string, "\\[[^]]*\\]", "", "g")
          let old_args_len = args_len
          let args_len = len(args_string)
        endwhile

        let comma_count = len(substitute(args_string, "[^,]", "", "g"))
        let a:tag.name = a:tag.name . "/" . (comma_count + 1)
      endif

      return a:tag
    else
      return a:tag
    endif
  endfunction

  " replaces function names with function_name/arity notation
  call map(a:tags, function('Arity_extract'))

  let seen_list = map(copy(a:tags), '[v:val.fields.kind, v:val.name, v:val.fields.line]')

  let seen_fnames = {}
  for [kind, fname, line] in seen_list
    if ! has_key(seen_fnames, kind.fname)
      let seen_fnames[kind.fname] = line
    endif
  endfor

  " leaves only first definition of function with same arity
  function! Filter_fun(seen_hash, idx, tag)
    let key = a:tag.fields.kind . a:tag.name
    let line = a:tag.fields.line

    return a:seen_hash[key] == line
  endfunction

  call filter(a:tags, function('Filter_fun', [seen_fnames]))

  return a:tags
endfunction " }}}

let g:tagbar_type_elixir = {
    \ 'ctagstype' : 'elixir',
    \ 'deffile' : s:path . '/extras/elixir-ctags/.ctags',
    \ 'transform': function("Tag_transform"),
    \ 'kinds' : [
        \ 'm:modules:1',
        \ 'O:OTP callbacks',
        \ 't:tests',
        \ 'f:functions (public)',
        \ 'g:functions (private)',
        \ 'c:callbacks',
        \ 'd:delegates',
        \ 'e:exceptions',
        \ 'i:implementations',
        \ 'a:macros',
        \ 'o:operators',
        \ 's:structs',
        \ 'p:protocols',
        \ 'r:records',
        \ 'T:types',
        \ 'z:foo'
    \ ]
\ }


" keyboard shortcuts
nmap <F4> :TagbarToggle<CR>
nmap <C-@> :CtrlPTagbar<CR>
nmap <Leader>l :CtrlPLine<CR>


" ####################################################################
" Integration with Tabularize


" tabularize both => and =
map <Leader>= =:Tabularize /=><CR>
map <Leader>eq =:Tabularize /=/<CR>
" tabularize case clauses
map <Leader>- =:Tabularize /-><CR>
" tabularize hashmaps and similar
map <Leader>: =:Tabularize /\v(:)@<=\s/l0<CR>




" ####################################################################
" Elixir commenting/uncommenting shortcuts


" TODO: make it work better with vim-elixir-fold
" and do not break folds of functions, make commend on column where
" indent level is
"
" commenting and uncommenting with  # sign
map <C-k>[ :let old_src = @/<CR>:s/^/#/<CR>:nohlsearch<CR>:let @/ = old_src<CR>
map <C-k>] :let old_src = @/<CR>:s/^#//<CR>:nohlsearch<CR>:let @/ = old_src<CR>
imap <C-k>[ <Esc>:let old_src = @/<CR>:s/^/#/<CR>:nohlsearch<CR>:let @/ = old_src<CR>a
imap <C-k>] <Esc>:let old_src = @/<CR>:s/^#//<CR>:nohlsearch<CR>:let @/ = old_src<CR>a

vmap <C-k>[ :<BS><BS><BS><BS><BS>let old_src = @/<CR>:'<,'>s/^/#/<CR>:nohlsearch<CR>:let @/ = old_src<CR>
vmap <C-k>] :<BS><BS><BS><BS><BS>let old_src = @/<CR>:'<,'>s/^#//<CR>:nohlsearch<CR>:let @/ = old_src<CR>

map <C-k><C-[> <C-k>[
map <C-k><C-]> <C-k>]

imap <C-k><C-[> <C-k>[
imap <C-k><C-]> <C-k>]


map <Leader>trailing :%s/\s*$//<CR>
map <Leader>$ :%s/\s*$//<CR>

set wildignore=*.o,*.obj,*.beam

" save file like in `borland-ides`
nmap <F2> :w<CR>
imap <F2> <Esc>:w<CR>a

" refactoring support
map <C-K><C-w> :%s#\<<c-r><c-w>\>#
map <C-K><C-a> :%s#\<<c-r><c-a>\>#

" delete buffer and keep split
cab bdd bp\|bd #

" cross reference
"
"  mix xref callers Mod
"  mix xref callers Mod.Fun
"  mix xref callers Mod.Fun/Arity
"
"
"  which files are called/included
"  mix xref graph --source lib/feed/betco_pusher/stream/api.ex --format pretty
"
"  which files call/include this one
"  mix xref graph --sink lib/feed/betco_pusher/stream/api.ex --format pretty
"
"  mix xref unreachable
"  mix xref warnings
"

function! s:ShowXRef() 
  " does not work well right now :)
  let a=alchemist#get_current_module_details()['module']['name']
  let b=tagbar#currenttag('%s', '')
  let c=a.".".b
  exec "Mix xref callers ".c
endfunction






