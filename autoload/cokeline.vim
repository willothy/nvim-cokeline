function! cokeline#toggle()
  let &showtabline = len(getbufinfo({'buflisted': 1})) > 1 ? 2 : 0
endfunction

function! cokeline#focus(index)
  let l:buffers = getbufinfo({'buflisted': 1})
  if a:index > len(l:buffers) | return | endif
  execute 'buffer ' . l:buffers[a:index - 1].bufnr
endfunction

function! cokeline#focus_cycle(bufnr, step, strict_cycling)
  let l:bufnrs = map(getbufinfo({'buflisted': 1}), 'v:val.bufnr')
  let l:index = index(l:bufnrs, a:bufnr) + a:step
  if (l:index < 0 || l:index >= len(l:bufnrs)) && a:strict_cycling | return | endif
  if l:index >= len(l:bufnrs)
    let l:index = l:index % len(l:bufnrs)
  endif
  execute 'buffer ' . l:bufnrs[l:index]
endfunction

function! cokeline#handle_click(minwid, clicks, button, modifiers)
  let l:command = (a:button =~ 'l') ? 'buffer' : g:cokeline_mouse_close_command
  execute printf('%s %s', l:command, a:minwid)
endfunction

function! cokeline#close_button_handle_click(minwid, clicks, button, modifiers)
  if a:button != 'l' | return | endif
  execute printf('%s %s', g:cokeline_mouse_close_command, a:minwid)
endfunction
