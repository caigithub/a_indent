"==================
"indent object
"==================

vnoremap am <esc>:call SelectBlock( 'indentOutAndBlank' )<cr>
onoremap am :call SelectBlock( 'indentOutAndBlank' )<cr>

vnoremap au <esc>:call SelectBlock( 'indentChangeAndBlank' )<cr>
onoremap au :call SelectBlock( 'indentChangeAndBlank' )<cr>

vnoremap ai <esc>:call SelectBlock( 'indentOut' )<cr>
onoremap ai :call SelectBlock( 'indentOut' )<cr>

function SelectBlock( edge_type )
    let l:begin = GetBlockEdgeLineNumber( 'backward', a:edge_type, 'false') + 1
    let l:end = GetBlockEdgeLineNumber( 'forward', a:edge_type, 'false') - 1
    
    "echo l:begin . ' - ' . l:end
    call cursor( l:begin , 1 )
    normal! V
    call cursor( l:end, 1 )
endfunction

"==================
"jump to indent
"==================

nnoremap M :call JumpToBlock('forward', 'false', 'indentOutAndBlank' )<cr>
vnoremap M :call JumpToBlock('forward', 'true', 'indentOutAndBlank')<cr>
nnoremap < :call JumpToBlock('backward', 'false', 'indentOutAndBlank')<cr>
vnoremap < :call JumpToBlock('backward', 'true', 'indentOutAndBlank')<cr>

nnoremap m :call JumpToBlock('forward', 'false', 'indentChangeAndBlank')<cr>
vnoremap m :call JumpToBlock('forward', 'true', 'indentChangeAndBlank')<cr>
nnoremap , :call JumpToBlock('backward', 'false', 'indentChangeAndBlank')<cr>
vnoremap , :call JumpToBlock('backward', 'true', 'indentChangeAndBlank')<cr>

function JumpToBlock( direction, selection, type )
    let l:block_line = GetBlockEdgeLineNumber( a:direction , a:type, 'true') 
    
    let l:jumpLine = l:block_line
    let l:reason = 'jump to block'

    "let l:max_line = JumpToSeveralLine( a:direction )

    "if l:max_line < l:jumpLine
        "let l:jumpLine = l:max_line
        "let l:reason = 'jump to several lines'
    "endif
    
    if a:selection == 'true'
        normal! gv
    endif

    call cursor( l:jumpLine , 1 )
    normal! ^
endfunction

function JumpToSeveralLine( direction )
    return 10 + line('.')
endfunction

"=======================
"common
"======================

function GetBlockEdgeLineNumber(direction, edge_type, autoAdjustBlankLine )
    let l:iterator_offset = 1
    if a:direction == 'backward'
        let l:iterator_offset = -1
    endif

    let l:iterator_line = line('.')
    if getline( l:iterator_line ) =~ "^\\s*$"
        let l:iterator_line =  AdjustBlankLine( a:direction, l:iterator_line )
    endif

    let l:base_indent = indent( l:iterator_line )
    let l:indent = l:base_indent

    let l:current_link_is_blank = 0
    let l:last_line_is_blank = 0
    let l:last_line_is_same_indent = 1

    while 1
        "echo 'block edge : line_num=' . l:iterator_line . ' - indent=' . l:indent . ' - base_indent=' . l:base_indent

        if ( IsOutOfFileBound( a:direction, l:iterator_line ) )
            return l:iterator_line
        endif
        
        let l:current_line_is_blank = ( getline(l:iterator_line) =~ "^\\s*$" )
        
        if IsBoundEdge( a:edge_type, l:base_indent, l:indent, l:last_line_is_blank, l:last_line_is_same_indent, l:current_line_is_blank )
            return l:iterator_line
        endif

        let l:last_line_is_blank = l:current_line_is_blank
        let l:last_line_is_same_indent = l:base_indent == l:indent
            
        let l:iterator_line = l:iterator_line + l:iterator_offset
        let l:indent = indent( l:iterator_line )
    endwhile
endfunction

function IsBoundEdge( edge_type, base_indent, indent, last_line_is_blank, last_line_is_same_indent, current_line_is_blank  )
    if a:current_line_is_blank 
        if a:edge_type == 'indentOutAndBlank' || a:edge_type == 'indentChangeAndBlank'
           return a:last_line_is_same_indent 
        endif

        return 0
    else
        if a:edge_type == 'indentOutAndBlank'
           return ( ( a:base_indent > a:indent ) || ( a:base_indent == a:indent && a:last_line_is_blank ) )
        endif
        
        if a:edge_type == 'indentOut'
            return ( a:base_indent > a:indent ) 
        endif

        if a:edge_type == 'indentChangeAndBlank'
            return ( ( a:base_indent != a:indent ) || (  a:base_indent == a:indent && a:last_line_is_blank ) )
        endif
    
        return 1
    endif
endfunction

function IsOutOfFileBound( direction, line_num )
     if a:direction == 'forward'
        return ( a:line_num > line('$') )
     else
        return ( a:line_num <= 0 )
     endif
endfunction

function AdjustBlankLine( direction, line_num )
     if a:direction == 'forward'
        return nextnonblank( a:line_num )
     else
        return prevnonblank( a:line_num )
     endif
endfunction
