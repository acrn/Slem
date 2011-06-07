import vim
import os
import pipes

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

def vim_slem(to_line):
    if len(SLEM_VARS['screen']) < 1:
        ask_vars(screen=True, window=True)
    file_extension = vim.current.buffer.name.rsplit('.',1)[1]
    block = get_blocking_fn({
        'filetype':file_extension,
        'to_line':vim.eval(to_line)
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
