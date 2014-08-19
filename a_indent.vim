"==================
"indent object
"==================

vnoremap am <esc>:call SelectBlock( 'indentOutIncludingBlank' )<cr>
onoremap am :call SelectBlock( 'indentOutIncludingBlank' )<cr>

vnoremap au <esc>:call SelectBlock( 'indentChangeOrBlank' )<cr>
onoremap au :call SelectBlock( 'indentChangeOrBlank' )<cr>

vnoremap ai <esc>:call SelectBlock( 'indentOut' )<cr>
onoremap ai :call SelectBlock( 'indentOut' )<cr>

function SelectBlock( stop_anchor_type )
    "echo l:begin . ' - ' . l:end
    call cursor( GetBlockEdgeLineNumber( 'backward', a:stop_anchor_type) + 1 , 1 )
    normal! V
    call cursor( GetBlockEdgeLineNumber( 'forward', a:stop_anchor_type ) - 1 , 1 )
endfunction

"==================
"jump to indent
"==================

nnoremap M :call JumpToBlock('forward', 'false', 'indentOutOrEqual' )<cr>
vnoremap M :call JumpToBlock('forward', 'true', 'indentOutOrEqual')<cr>
nnoremap < :call JumpToBlock('backward', 'false', 'indentOutOrEqual')<cr>
vnoremap < :call JumpToBlock('backward', 'true', 'indentOutOrEqual')<cr>

nnoremap H :call JumpToBlock('backward', 'false', 'indentOut')<cr>
vnoremap H :call JumpToBlock('backward', 'true', 'indentOut')<cr>
nnoremap L :call JumpToBlock('forward', 'false', 'indentOut')<cr>
vnoremap L :call JumpToBlock('forward', 'true', 'indentOut')<cr>

"nnoremap < :call JumpToBlock('backward', 'false', 'indentEqual')<cr>
"vnoremap < :call JumpToBlock('backward', 'true', 'indentEqual')<cr>
"nnoremap M :call JumpToBlock('forward', 'false', 'indentEqual')<cr>
"vnoremap M :call JumpToBlock('forward', 'true', 'indentEqual')<cr>

function JumpToBlock( direction, selection, type )
    if a:selection == 'true'
        normal! gv
    endif

    call cursor( GetBlockEdgeLineNumber( a:direction , a:type ) , 1 )
    normal! ^
endfunction

"=======================
" core logic
"======================

function GetBlockEdgeLineNumber(direction, stop_anchor_type )
    let l:base_line = GetLineInfo( line('.') )
    if( l:base_line.isBlank )
        return AdjustBlankLine( a:direction, l:base_line.line_num )
    endif

    let l:current_line = l:base_line
    let l:last_line = l:current_line
    let l:iterator_offset = GetLineStep( a:direction )

    while 1
        "echo 'block edge : line_num=' . l:iterator_line . ' - indent=' . l:indent . ' - base_indent=' . l:base_indent

        if ( IsOutOfFileBound(a:direction, l:current_line.line_num ) )
            return l:current_line.line_num
        endif
        
        if IsStopAnchor( a:stop_anchor_type, l:current_line, l:last_line , l:base_line )
            return l:current_line.line_num
        endif

        let l:last_line = l:current_line
        let l:current_line = GetLineInfo( l:current_line.line_num + l:iterator_offset )
    endwhile
endfunction

function IsStopAnchor(stop_anchor_type, current_line, last_line, base_line )
        if a:stop_anchor_type == 'indentOutIncludingBlank' 
            if a:current_line.isBlank
               return IsIndentKeep ( a:last_line , a:base_line )
            else
               return ( IsIndentOut( a:current_line , a:base_line ) || ( IsIndentKeep( a:current_line, a:base_line ) && a:last_line.isBlank ) )
            endif
        endif

        if a:stop_anchor_type == 'indentChangeOrBlank' 
            if a:current_line.isBlank
               return IsIndentKeep ( a:last_line , a:base_line )
            else
               return ( IsIndentKeep( a:current_line, a:base_line ) == 0 || IsIndentKeep( a:current_line, a:base_line ) && a:last_line.isBlank ) 
            endif
        endif

        if a:stop_anchor_type == 'indentOut'
            if a:current_line.isBlank
                return 0
            else
                return ( IsIndentOut( a:current_line, a:base_line ) ) 
            endif
        endif

        if a:stop_anchor_type == 'indentOutOrEqual'
            if a:current_line.isBlank
                return 0
            else
                return ( IsIndentKeep( a:last_line, a:base_line ) == 0 && IsIndentKeep( a:current_line, a:base_line ) ) 
                        \ || ( a:last_line.isBlank && IsIndentKeep( a:current_line, a:base_line ) ) 
                        \ || ( IsIndentOut( a:current_line, a:base_line ))
            endif
        endif

        if a:stop_anchor_type == 'indentEqual' 
            if a:current_line.isBlank
                return 0
            else
                return ( IsIndentKeep( a:last_line, a:base_line ) == 0 && IsIndentKeep( a:current_line, a:base_line ) ) 
            endif
        endif

        if a:current_line.isBlank
            return 0
        else                       "0
            return 1
        endif
endfunction

function GetLineInfo( line_num )
    
    let l:line = {}

    let l:line.line_num = a:line_num
    let l:line.indent =  indent( a:line_num ) 
    let l:line.isBlank = ( getline( a:line_num ) =~ "^\\s*$" )

    return l:line

endfunction

"=======================
"util
"======================

function IsIndentIn( line_a, line_b )
    return a:line_a.indent > a:line_b.indent
endfunction

function IsIndentOut( line_a, line_b )
    return a:line_a.indent < a:line_b.indent
endfunction

function IsIndentKeep( line_a, line_b )
    return a:line_a.indent == a:line_b.indent
endfunction

function GetLineStep( direction )
    if a:direction == 'backward'
        return -1
    else
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


