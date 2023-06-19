neo-latte
=========

*A new, pleasant companion for unit testing*

## What

neo-latte is the spiritual successor to [vim-latte][1], written completely in Lua for Neovim. It is an asynchronous unit test runner, designed to get out of your way when everything is fine, and do the helpful things you'd expect when it isn't.

If all the tests you want to run pass, neo-latte will echo a nice "All tests passed" message in green. If there were errors, neo-latte will open a window with the output of the test run so you can review them. If the test takes a while to run, it will open that window so you can follow along.

## How

Install with your favorite plugin manager. I like [Plug][2]. You will also need [vim-test][3], which neo-latte uses to determine how to run the test(s) for the current file:

```vim
Plug 'vim-test/vim-test'
Plug 'dhleong/neo-latte'
```

neo-latte doesn't come with any mappings out of the box, but here are some ideas:

```vim
# Toggle automatically running all the tests in the file whenever any buffer
# in the current tabpage is saved.
nnoremap <leader>tt <cmd>lua require'neo-latte'.toggle_auto_test()

# toggle_auto_test accepts an optional first argument to specify which types of
# tests to run. This is the same param from vim-test
nnoremap <leader>tn <cmd>lua require'neo-latte'.toggle_auto_test('nearest')

# You can also trigger a one-off without watching for changes
nnoremap <leader>trn <cmd>lua require'neo-latte'.run('nearest')

# If a test is taking too long, you kill it
nnoremap <leader>tq <cmd>lua require'neo-latte'.stop()
```

[1]: https://github.com/dhleong/vim-latte
[2]: https://github.com/junegunn/vim-plug
[3]: https://github.com/vim-test/vim-test
