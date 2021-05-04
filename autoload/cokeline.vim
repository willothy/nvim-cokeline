function! cokeline#handle_click(minwid, clicks, button, modifiers)
  let s:command = (a:button =~ 'l') ? 'buffer ' : 'bdelete '
  execute s:command . a:minwid
endfunction

function! cokeline#handle_close_icon_click(minwid, clicks, button, modifiers)
  if a:button =~ 'l' | execute 'bdelete ' . a:minwid | endif
endfunction
