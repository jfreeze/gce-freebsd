#!/bin/sh

echo "Installing vim-lite ..."
sudo pkg install -y vim-lite

# Setup user environment (personal prefs)

shrcSetup () {
  echo "  configuring .shrc ..."
  cp /usr/share/skel/dot.shrc ~/.shrc
  sed -E -i '' 's/set -o emacs/# set -o emacs/' ~/.shrc
  sed -E -i '' 's/# set -o vi/set -o vi/' ~/.shrc
  sed -E -i '' 's/^# umask	022/umask 022/' ~/.shrc
  sed -E -i '' "s/# alias cp='cp -ip'/alias cp='cp -ip'/" ~/.shrc
  sed -E -i '' "s/# alias mv='mv -i'/alias  mv='mv -i'/" ~/.shrc
  sed -E -i '' "s/# alias rm='rm -i'/alias  rm='rm -i'/" ~/.shrc
  sed '/alias g/ a \
alias d=\"ls -alFG\"
' ~/.shrc > /tmp/shrc
  mv /tmp/shrc ~/.shrc
  
cat << EOF >> ~/.shrc
# set prompt: ``username@hostname$ ''
PS1="\`whoami\`@\`hostname | sed 's/\..*//'\`"
case \`id -u\` in
 	0) PS1="\${PS1}# ";;
 	*) PS1="\${PS1}$ ";;
esac
EOF
}

if [ -f ~/.shrc ]; then
	echo "~/.shrc exists"
else
	shrcSetup
fi

if [ -f ~/.profile ]; then
	echo "~/.profile exists"
else
	echo "  creating .profile ..."
	cp /usr/share/skel/dot.profile ~/.profile
fi


