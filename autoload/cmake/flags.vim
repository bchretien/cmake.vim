" File:             autoload/cmake/flags.vim
" Description:      Handles the act of injecting flags into Vim.
" Author:           Jacky Alciné <me@jalcine.me>
" License:          MIT
" Website:          https://jalcine.github.io/cmake.vim
" Version:          0.3.0

" TODO: Filter the flags so that we only have warnings and includes passed
" into the mix.
func! cmake#flags#filter(flags)
  let l:flags = a:flags
  if g:cmake_filter_flags == 1 && !empty(l:flags)
    for flag in flags
      let l:index         = index(flags, flag)
      let l:isAInclude    = stridx(flag, '-I') || stridx(flag, '-i')
      let l:isAWarning    = stridx(flag, '-W')
    endfor
  endif

  return l:flags
endfunc!

func! cmake#flags#inject()
  let target = cmake#targets#for_file(fnamemodify(bufname('%'), ':p'))

  if empty(target)
    return
  endif

  call cmake#flags#inject_to_ycm(target)
  call cmake#flags#inject_to_syntastic(target)
endfunc

" TODO Fix this; it doesn't use the right Syntastic option.
func! cmake#flags#inject_to_syntastic(target)
  if g:cmake_inject_flags.syntastic != 1
    return
  endif

  let l:syReg = g:SyntasticRegistry.Instance()

  let l:flags = cmake#targets#flags(a:target)
  if empty(l:flags)
    return
  endif

  for l:language in keys(l:flags)
    let syCheckers = syReg.getActiveCheckers(l:language)
    for checker in syCheckers
      let l:args = l:flags[l:language]
      let l:cmd = "let g:syntastic_" . l:language . "_" . checker.getName() .
          \  "_post_args = \"" . join(l:args, ' ') . "\""
      exec(l:cmd)
    endfor
  endfor
endfunc!

func! cmake#flags#collect(flags_file, prefix)
  let l:flags = split(system("grep '" . a:prefix . "_FLAGS = ' " . a:flags_file . 
    \ ' | cut -b ' . (strlen(a:prefix) + strlen('_FLAGS = ')) . '-'))
  let l:flags = cmake#flags#filter(l:flags)

  let l:defines = split(system("grep '" . a:prefix . "_DEFINES = ' " . a:flags_file 
    \ . ' | cut -b ' . (strlen(a:prefix) + strlen('_DEFINES = ')) . '-'))

  let l:params = l:flags + l:defines
  return l:params
endfunc!

" TODO: Don't clobber the values for vim data in YCM.
func! cmake#flags#inject_to_ycm(target)
  if g:cmake_inject_flags.ycm != 1
    return
  endif

  let g:cmake_binary_dir        = cmake#util#binary_dir()
  let g:cmake_current_flags     = cmake#targets#flags(a:target)
  let g:ycm_extra_conf_vim_data = ['g:cmake_binary_dir', 'g:cmake_current_flags']
endfunc!
