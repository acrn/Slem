python << endpython

import vim

def move_back(coords):
    '''Returns a position one step backwards in the buffer. should the current
    position be at the beginning of a line the last position of the previos
    line is given. No checks are made to prevent an out of bounds error if the
    current position is at the beginning of the file.'''

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
    '''Returns a position one step forwards in the buffer. should the current
    position be at the end of a line the first position of the next line is
    given. No checks are made to prevent an out of bounds error if the current
    position is at the end of the file.'''

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
    '''Finds a suitable range of code around the given position of the current
    buffer to be evaluated by a Clojure interpreter. This range is the function
    or data structure surrounding the coordinates. For instance, if '#' is the
    caret positon, the range:

        (* 2 #(+ 1 1))

    would result send '(* 2 #(+ 1 1))' to the interpreter while:

        (* 2 (+ 1 # 1))

    would only send '(+ 1 1)'.

    The same rules apply to [] and {} structures as well. Shorthand syntax
    abnormalities such as '() are not currently supported.'''

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
    '''Finds a suitable range of code around the given position in the current
    buffer to be sent to a python interpreter. This could imply:
        1) a class, if the position is within the class definition
        2) a function, if the position is within the function definition
        3) a plain line of code, if none of the above hold true.
        4) something else, if there is a bug in the code.
    The function does not support the special line termination rules depending
    on closing parenthesis, that is, this:

        >stuff = {'one_thing',
        >'another_thing'}
    
    will not be treated as an atomic statement, while:

        >stuff = {'one_thing',
        >    'another_thing'}
        
    will work as intended. I'll just assume no sane person writes code like the
    first example.'''

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
    '''Creates a function that returns a range from the given starting line
    number  to a given ending line number. The ending line is curried to give
    the method the same argument signature as the filetype specific functions,
    this is necessary since one of the 'find_block'-functions is to be
    returned from a function that decides which one should be used.
    It doesn't look that great and a better solution would be welcome.'''

    def find_block_toline(coords):
        l = coords[0] - 1
        return ((l, 0), (to_l-1, len(vim.current.buffer[to_l-1]) - 1))
    return find_block_toline

def find_block_line(coords):
    '''Returns a range that effectively is the entire line where coords are
    located. This is the fallback method if a more suitable function cannot
    be found, it's still pretty useful for interactively developing bash
    scripts.'''

    l = coords[0] - 1
    return ((l, 0), move_back((l + 1, 0)))

def get_blocking_fn(args={}):
    '''Returns a suitable function for selecting a range surrounding a position
    in the current buffer to send to an interpreter. The selection is based on
    a few things:
        
        1) if "args" contains the key 'to_line' a function is used that simply
           sends the range from the beginning of the line of the position to
           the end of the line given.
        2) otherwise, if the file extension is 'clj', a Clojure specific
           function is used.
        3) otherwise, if the file extension is 'py', a Python specific function
           is used.
        4) otherwise, give up and just return the whole line of the given
           position.

    it is possible that other interpreter specific functions will be added
    later.'''

    if 'to_line' in args and int(args['to_line']) > 0:
        return make_find_block_toline(int(args['to_line']))
    fns = {
        'clj':find_block_clj,
        'py':find_block_py}
    if args['filetype'] in fns:
        return fns[args['filetype']]
    return find_block_line

def extract(start, end):    
    '''Extracts the text in the range given of the current buffer to a list of
    strings'''

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

SLEM_VARS = {'screen':'', 'window':'0'}    

def ask_vars(screen=False, window=False):
    '''Ask the user to supply the specified variables. The answers are stored
    in the global dict 'SLEM_VARS'.
    TODO: Find out if there is a prettier way of doing this, without using
          vim commands.'''

    if screen:
        vim.command('let __slem_sc = input("screen name: ", "' +
            SLEM_VARS['screen'] + '")')
        SLEM_VARS['screen'] = vim.eval('__slem_sc')
    if window:    
        vim.command('let __slem_wd = input("window number: ", "' +
            SLEM_VARS['window'] + '")')
        SLEM_VARS['window'] = vim.eval('__slem_wd')

endpython
function! VimSlem(to_line)
python << endpython
import os
import pipes
if len(SLEM_VARS['screen']) < 1:
    ask_vars(screen=True, window=True)
file_extension = vim.current.buffer.name.rsplit('.',1)[1]
block = get_blocking_fn({
    'filetype':file_extension,
    'to_line':vim.eval('a:to_line')
    })(vim.current.window.cursor)
lines = extract(block[0], block[1])
text = '\n'.join(lines) + '\n'
if file_extension == 'py' and lines[-1][0].isspace():
    text += '\n'
text = pipes.quote(text)
message = 'screen -S ' + SLEM_VARS['screen']
message += ' -p ' + SLEM_VARS['window']
message += ' -X stuff ' + text 
os.system(message)
vim.command('return 1')
endpython
endfunction

function! VimSlemSettings(args)
python << endpython
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
