# Setup user environment (personal prefs)
cp /usr/share/skel/dot.shrc .shrc
sed -E -i '' 's/set -o emacs/# set -o emacs/' .shrc
sed -E -i '' 's/# set -o vi/set -o vi/' .shrc
#sed -E -i '' 's/^# umask/umask/' .shrc
sed -E -i '' 's/^# umask	022/umask 022/' .shrc
sed -E -i '' "s/# alias cp='cp -ip'/alias cp='cp -ip'/" .shrc
sed -E -i '' "s/# alias mv='mv -i'/alias  mv='mv -i'/" .shrc
sed -E -i '' "s/# alias rm='rm -i'/alias  rm='rm -i'/" .shrc

