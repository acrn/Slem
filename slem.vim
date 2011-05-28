
py3 << endpython

import vim

def move_back(coords):
    l = coords[0]
    c = coords[1]
    c -= 1
    if c < 0:
        l -= 1
        while len(vim.current.buffer[l]) < 1:
            l -= 1
        c = len(vim.current.buffer[l]) - 1
    return (l, c)	

def move_ahead(coords):
    l = coords[0]
    c = coords[1]
    c += 1
    if c >= len(vim.current.buffer[l]):
        c = 0
        l += 1
        while len(vim.current.buffer[l]) < 1:
            l+=1
    return (l, c)    

def find_block_clj(coords):
    char_count = {
        '(':0,
        ')':0,
        '[':0,
        ']':0,
        '{':0,
        '}':0}
    l = coords[0] - 1
    c = coords[1]    
    char = vim.current.buffer[l][c]
    if char in ['(', '{', '[']:
        char_count[char] += 1
    while char_count[')'] >= char_count['('] \
          and char_count[']'] >= char_count['['] \
          and char_count['}'] >= char_count['{']:
        l, c = move_back((l, c))
        char = vim.current.buffer[l][c]
        if char in char_count:
            char_count[char] += 1
    start = (l, c)        
    while char_count['('] > char_count[')'] \
          or char_count['['] > char_count[']'] \
          or char_count['{'] > char_count['}']:
        l, c = move_ahead((l, c))
        char = vim.current.buffer[l][c]        
        if char in char_count:
            char_count[char] += 1
    end = (l, c)       
    return (start, end) 

def find_block_py(coords):
    l = coords[0] - 1
    line = vim.current.buffer[l]
    while len(line) < 1 or line[0].isspace() or line[0] == '#':
        l -= 1
        line = vim.current.buffer[l]
    start = (l, 0)
    if l == len(vim.current.buffer) - 1:
        return (start, (l, len(vim.current.buffer[l]) - 1))
    l += 1
    line = vim.current.buffer[l]
    while l < len(vim.current.buffer)-1 and \
        (len(line) < 1 or line[0].isspace() or line[0] == '#'):
        l += 1
        line = vim.current.buffer[l]
    if not (len(line) < 1 or line[0].isspace()):
        l -= 1    
        line = vim.current.buffer[l]
    while len(line) < 1 or line.isspace():
        l -= 1    
        line = vim.current.buffer[l]
    end = (l, len(vim.current.buffer[l]))
    return (start, end)

def make_find_block_toline(to_l):
    def find_block_toline(coords):
        l = coords[0] - 1
        return ((l, 0), (to_l-1, len(vim.current.buffer[to_l-1]) - 1))
    return find_block_toline

def find_block_line(coords):
    l = coords[0] - 1
    return ((l, 0), move_back((l + 1, 0)))

def get_file_ext():
    return vim.current.buffer.name.rsplit('.',1)[1]

def get_blocking_fn(args={}):
    if 'to_line' in args and int(args['to_line']) > 0:
        return make_find_block_toline(int(args['to_line']))
    fns = {
        'clj':find_block_clj,
        'py':find_block_py}
    if args['filetype'] in fns:
        return fns[args['filetype']]
    return find_block_line

def extract(start, end):    
    l = start[0]
    c = start[1]
    if l == end[0]:
        return [vim.current.buffer[l][c:end[1]+1]]
    o = [vim.current.buffer[l][c:]]
    l += 1
    while l < end[0]:
        if len(vim.current.buffer[l]) > 1:
            o.append(vim.current.buffer[l])
        l += 1
    o.append(vim.current.buffer[l][:end[1]+1])    
    return o    

slem_vars = {'screen':'', 'window':'0'}    

def ask_vars(screen=False, window=False):
    if screen:
        vim.command('let __slem_sc = input("screen name: ", "' + slem_vars['screen'] + '")')
        slem_vars['screen'] = vim.eval('__slem_sc')
    if window:    
        vim.command('let __slem_wd = input("window number: ", "' + slem_vars['window'] + '")')
        slem_vars['window'] = vim.eval('__slem_wd')

endpython
function! VimSlem(to_line)
py3 << endpython
import os
from pipes import quote
if len(slem_vars['screen']) < 1:
    ask_vars(screen=True, window=True)
block = get_blocking_fn({
    'filetype':get_file_ext(),
    'to_line':vim.eval('a:to_line')
    })(vim.current.window.cursor)
lines = extract(block[0], block[1])
text = '\n'.join(lines) + '\n'
if get_file_ext() == 'py' and lines[-1][0].isspace():
    text += '\n'
text = quote(text)
message = 'screen -S ' + slem_vars['screen']
message += ' -p ' + slem_vars['window']
message += ' -X stuff ' + text 
os.system(message)
vim.command('return 1')
endpython
endfunction

function! VimSlemSettings(args)
py3 << endpython
ask_vars(screen=('screen' in vim.eval('a:args')),
         window=('window' in vim.eval('a:args')))
endpython
endfunction

:imap <C-c><C-c> <C-O>:call VimSlem(-1)<CR>
:imap <C-c><C-l> <C-O>:call VimSlem(input("to line: ", ""))<CR>
:map <C-c><C-c> :call VimSlem(-1)<CR>
:map <C-c><C-l> :call VimSlem(input("to line: ", ""))<CR>
:map <C-c>v :call VimSlemSettings("window")<CR>
:map <C-c>V :call VimSlemSettings("screen,window")<CR>
