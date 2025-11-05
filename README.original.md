IMPORTANT: be sure to check out ./ai/**/**

SYSTEM:
i am designing a new type of process manager/development environment.

logically, this will be a 'box of boxes', paradigm.

where a box is analogous to an iterm tab running a tmux session but, then,
more things on down, services, editors, claude sessions, each with thier own
set of subprocesses, env settings, etc.

we desire this tool (un-named) to be ultra simple and ultra unix.  home row
key bindings.  vim level efficiency with zero fucking bloat.

we want a directory based approach

  ./projects/a
  ./projects/b
  ./projects/c

here i want an easy way to ensure that:

i have 'all the right stuff' running for a, b, and c.

this would include, perhaps

  ~terminal-1> ./script/server
  ~terminal-2> ./script/test
  ~terminal-3>  $EDITOR ./src/server.py

in a normal 'tmux' fashion (one window per process - no fancy split tabs, etc)

we desire automation of what should be running, and support for configuring
it.  so

  ./projects/a            # ai figures how to run this one....
  ./projects/b/config.rb
  ./projects/c/config.yml

i want to support the following idea:

- each box is a combination of state (env, files, db) and behavior (code) and
  is doing a useful thing (running a server, etc)

- these might be servers, editing sessions, long running claude / ai
  experiments, etc.


we want, more or less, a tmux session manager that also supports notions like
automatic naming, automatic guessing of what to run, the ability to start/stop
these things so that we could run a long lived process *safely* there and know
that it would 'be up' (similar to pm2 in this regard) and for all of this,
essentailly just create a super clean, easy to navigate, tmux session manager.

finally, we want the ability to 'create' one of this on the fly.  eg, to kick
off a process that will run for a long time, perhaps requiring another process
such as log tailing, in combination, that would be 'temporary' but still
'directory' based.  a way to kick of a 'sub-box' that would inherity env,
naming, and whatever else.   this could present itself to ai agents, such as
claude, to allow the agent to kick off a process in a way that would allow the
terminal to re-attach to it, explore logs, hit control-c, etc.   this concept
of 'sub process management' through tmux/tty is novel.

ok.  finally finally... think of this tool as similar, in spirt, to workflowy
in that it aims to be very abstract / support *many* use cases like research,
writing, coding, project management, etc.  i want a very unixy philosophy to
this and, in a way, imagine this practically replacing my desktop with this
would be ideal.   imaging sending messages from one box to the next like
'restart this' or 'how are you doing - done yet?'.   one part deve
environment.  one part window manager.  one part outlining tool.   one part
daemon/service manager.  one part dev env.

i see tools like  copy and paste that works across machines, so ssh , mosh,
and local sessions could all be nested and cut-n-past work from the CLI across
them.... support for loading .env files or (preferred, dotenvx files) to start
'environment trees'.   essentially, just making sure all tmux windows have the
env loaded as  pre-load step... etc. 

and i want to support an 'ai first' and 'cli first' approach.  by this i mean
a cli that 'figures things out' but which also allows ultrea simple nexted
configuration and customization through a file (or directory of files likely)
in the file system.  i imagine $name.yml or .$name/config.yml,db.sqlite, etc,
to be the way to customize.  stuff checked into git/revision control.

we desire low deps but a rich experience and will favor ruby.  see ./ai/.
consider sqlite and turso for local state and pub/sub.  i am leaning towards
making a 'one db per project' and a 'master db for projects' approach on turso
but, this could simply be all local.  we could/should also consider supporting
local only or cloud enabled.  the reason cloud enabled would be cool is cross
machine setups and durable history.  so, your entire desktop/thought system,
it's history, commands to run, machine it was running on, what was running,
etc.  is known in a veyr simple 'unix command history' + config sort of way.

again. think tmux config or tmuxinator on steroids.  also see.  https://github.com/joshmedeski/sesh

we need.

1. a super unix killer name for this.  haX0r to the max
2. a rough design plan including technologies, libs, etc.  with ascii art.
