function! cokeline#handle_clicks(minwid, clicks, button, modifiers)
  let s:command = (a:button =~ 'l') ? 'buffer ' : 'bdelete '
  execute s:command . a:minwid
endfunction

function! cokeline#close_button_handle_clicks(minwid, clicks, button, modifiers)
  if a:button =~ 'l' | execute 'bdelete ' . a:minwid | endif
endfunction
