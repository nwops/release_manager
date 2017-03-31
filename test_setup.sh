#!/usr/bin/env bash

cat > ~/.bash_profile <<'EOF'
#!/usr/bin/env bash
#
# setup ssh-agent
#


# set environment variables if user's agent already exists
[ -z "$SSH_AUTH_SOCK" ] && SSH_AUTH_SOCK=$(ls -l /tmp/ssh-*/agent.* 2> /dev/null | grep $(whoami) | awk '{print $9}')
[ -z "$SSH_AGENT_PID" -a -z `echo $SSH_AUTH_SOCK | cut -d. -f2` ] && SSH_AGENT_PID=$((`echo $SSH_AUTH_SOCK | cut -d. -f2` + 1))
[ -n "$SSH_AUTH_SOCK" ] && export SSH_AUTH_SOCK
[ -n "$SSH_AGENT_PID" ] && export SSH_AGENT_PID

# start agent if necessary
if [ -z $SSH_AGENT_PID ] && [ -z $SSH_TTY ]; then  # if no agent & not in ssh
  eval `ssh-agent -s` > /dev/null
fi

# setup addition of keys when needed
if [ -z "$SSH_TTY" ] ; then                     # if not using ssh
  ssh-add -l > /dev/null                        # check for keys
  if [ $? -ne 0 ] ; then
    alias ssh='ssh-add -l > /dev/null || ssh-add && unalias ssh ; ssh'
    if [ -f "/usr/lib/ssh/x11-ssh-askpass" ] ; then
      SSH_ASKPASS="/usr/lib/ssh/x11-ssh-askpass" ; export SSH_ASKPASS
    fi
  fi
fi

EOF

if [[ -d ~/repos ]]; then
  exit 0

fi
git config --global user.email "user@example.com"
git config --global user.name "Example User"

mkdir -p ~/repos/r10k-control
cd ~/repos/r10k-control
git init
cat > Puppetfile <<'EOF'
# track master from GitHub
mod 'systemstd',
   :git => 'git://github.com/jorhett/puppet-systemstd.git'

# Get a specific release from GitHub
mod 'puppet4',
   :git => 'git://github.com/jorhett/module-puppet4.git'

mod 'stdlib',
   :git => 'git://github.com/puppetlabs/puppetlabs-stdlib'
EOF

cd ~/repos/r10k-control
git add Puppetfile
git commit -m "init"
#git clone https://github.com/puppetlabs/puppetlabs-stdlib
#git clone git://github.com/jorhett/puppet-systemstd.git
#git clone git://github.com/jorhett/module-puppet4.git