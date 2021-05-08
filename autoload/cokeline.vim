function! cokeline#toggle(filename, threshold)
  if !buflisted(a:filename) | return | endif
  let l:buffers = getbufinfo({'buflisted': 1})
  execute 'set showtabline=' . (len(l:buffers) > a:threshold ? '2' : '0')
endfunction

function! cokeline#handle_clicks(minwid, clicks, button, modifiers)
  let l:command = (a:button =~ 'l') ? 'buffer ' : 'bdelete '
  execute l:command . a:minwid
endfunction

function! cokeline#close_button_handle_clicks(minwid, clicks, button, modifiers)
  if a:button =~ 'l' | execute 'bdelete ' . a:minwid | endif
endfunction
