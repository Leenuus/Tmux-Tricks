## Epilogue

You are playing with __CTF__? You are working with __gdb__? You are using __tmux__? Then you are in the right place.

__You must be like me, working with _gdb_ in a _tmux_ pane, and split another pane at the left or right of the _gdb_ pane, to craft some shellcodes or bash/python script.__ One thing I keep doing is scrolling up _gdb_ output, using _tmux_ copy-mode, yes, I disable pager in _gdb_, and copy some random address or instructions. In this situation, it won't be a good idea using commands like `copy-selection-and-cancel`, which quits after piping selection to system clipboard. Therefore, we should turn to its counter-part `copy-selection`. 

Seems problem solved? No, __it just emerges!__ 

I use `v` and then `y` for daily yanking in both _tmux_ and _neovim_. I can't tell myself, hi guy, just fix your habit, use `Y`, the `y` with shift to do that job, thing done, right? Hey, that's not what hackers should do. 

__Why not detect what applications are running in current pane? If it is something like _gdb_, we do the `copy-selection`, otherwise we do the `copy-selection-and-cancel`.__

Let's start __Hacking__.

## Coding

### How to detect process running in current pane?

```sh
# $HOME/bin/tmux-yank
TMUX_YANK_NOT_CANCEL_PAT='gdb'
ps -o state= -o comm= -t "$tty" |
  grep -iqE "^[^TXZ]+ +$TMUX_YANK_NOT_CANCEL_PAT"
```

Simple code, right? But lots to explain.

#### Grep

- `-E`, use extended regex, it is needed when you want something like `()` capture group, for me, I always apply this option to avoid strange posix regex.
- `-i`, tell `grep` to do case-insensitive search.
- `-q`, tell `grep` to be quiet. It suppress its output, because what we need is simply whether `grep` finds the result, which can be implied with exit status only.

#### Ps

`ps` code here is mystery. Some materials you should read here are:

- `man ps`, `PROCESS STATE CODES` section. Type `/^PROCESS STATE CODES<CR>` to jump to it in your pager.
- `-t`, specify which `tty` ps should look into. It tells `ps` to only return processes running in this `tty`, simply put, our current _tmux_ pane.
- `-o state=` ,  `-o comm=`, `-o` tells `ps` what it should output, we tell it to print __process__ state first and then __the first part of the command(only command's name, omitting options or arguments)__.

Combining those above, let's talk about the regex we use:

- `"^[^TXZ]+`, only match process which are not __stop__, __dead__ or __defunct__.
- ` +$TMUX_YANK_NOT_CANCEL_PAT`, simply spaces and process name we want to match


Here we set `$TMUX_YANK_NOT_CANCEL_PAT` to `gdb`, so if _gdb_ running in current pane, this script returns 0, otherwise a non-zero code is return.


### TMUX

So the next and last step is to bind a key in tmux, running this script, if it normally exits, do `copy-selection`, or do `copy-selection-and-cancel`. You should read `man tmux`:

- `if-shell` usage, in `MISCELLANEOUS` section. Use the jumping trick I mentioned above.
- Search for `brace`, you will see some examples of how to using brace to avoid escaping long shell commands in tmux configuration files. BTW, it is quite common a tmux command is followed by an optional part `[command]`, where you can specify some shell commands to run. __Escaping__ is always an evil thing, think of escaping `awk` script in `bash` script, __XSS__ attacks, and so on. Most of time, escaping makes your script a ugly monster no one can understand. Fortunately, _tmux_ provides you `{}` to group your shell commands, so no escaping needed.
- Search for `bind-key` to learn how to bind a key in tmux configuration.


```tmux.conf
# in your tmux.conf file
bind -T copy-mode-vi 'y' if-shell "$HOME/bin/tmux-yank #{pane_tty}" {
	send-keys -X copy-pipe 'xclip -in -selection clipboard >/dev/null'
} { 
	send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard >/dev/null'
}
```
- `bind -T copy-mode-vi 'y'` creates this keybinding for copy-mode-vi mode.
- `if-shell <condition cmd> <do cmd> [or cmd]`, if the condition returns zero, do the first cmd branch, otherwise the second branch.
- `send-keys -X`, run following tmux command in copy-mode-vi mode.
- `copy-pipe`, `copy-pipe-and-cancel` and their following commands, you may not find them in `man tmux`, but thry do work, or you can replace them with the pair we mentioned at the beginning of post. They are old ways to work with system clipboard I believe. See [tmux wiki]() for more information.

### More To Hack

You can do more things in the wrapped script, for example:

```sh
TMUX_YANK_NOT_CANCEL_PAT=${TMUX_YANK_NOT_CANCEL_PAT:-"gdb"}
```

So you can specify a group of processes in environment variables. You can even do some more tricks, for example, user still have to provide __a regex in environment variables__ with code above. You can do that job for them. Why not let user gives you a comma separate list?

```sh
TMUX_YANK_NOT_CANCEL_PAT='gdb,bash'

# your code
tr ',' '|' <<< "$TMUX_YANK_NOT_CANCEL_PAT"
```

Ha, we just finish a simple __tmux plugin__!

NOTE: Maybe you should disable some plugin like `tmux-plugins/tmux-yank`, it may overwrite some of your tweaking, so you may find out script we craft above won't work.

## Prologue

Nothing more to say, __JUST HAPPY CRAFTING!__

## References

- [__vim-tmux navigator__, which helps you navigate around tmux panes and vim windows seamlessly heavily inspires this post](https://github.com/christoomey/vim-tmux-navigator)
- [You may want `gef`, a __powerful__ `gdb` plugin](https://github.com/hugsy/gef)
- [I also craft my `ncspot` today; it is a TUI Spotify client](https://github.com/Leenuus/ncspot)
