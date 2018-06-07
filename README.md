# klaxalk's Linux environment

This repo contains settings of my Linux work environment.
It could be summarized as follows:

* *i3* (i3gaps) tiling window manager with i3bar and vim-like controls
* *urxvt* terminal emulator with ability tu show images (when using the *ranger* file manager)
* *tmux* terminal emulator is running all the time
  * *tmuxinator* for automation of tmux session
  * motion shortcuts for panes compatible with vim
* *vim* is everywhere
  * pluginized for smooth c++ and ROS development
  * youcompleteme
* *athame* gives you vim in the terminal (bash/zsh)
* *zsh* better shell for everyday use
* *ranger* terminal file manager
* *epigen* for witching between machine-specific configurations (profiles withing dotfiles)

Everything is intended for and tested on **Ubuntu 16.04**.
To clone and install everything run following code. **BEWARE**, running this will **DELETE** your current .i3, tmux and vim dotfiles.
```bash
cd /tmp
echo "mkdir -p ~/git
cd ~/git
sudo apt-get -y install git
git clone https://github.com/klaxalk/linux-setup.git
cd linux-setup
./install.sh" > run.sh && source run.sh
```
**Calling install.sh repeatedly** will not cause acumulation code in your .bashrc, so feel free to update your configuration by rerunning it.

# How to? -> [wiki](https://github.com/klaxalk/linux-setup/wiki)

Refer to the project's [wiki](https://github.com/klaxalk/linux-setup/wiki) (work in progress).

# Credits

I thank following sources for inspiration:

* All guys behind [thoughtbot](https://www.youtube.com/user/ThoughtbotVideo) and namely following presenters:
  * Mike Coutermarsh, https://www.youtube.com/watch?v=_NUO4JEtkDw
  * Chris Toomey, https://www.youtube.com/watch?v=wlR5gYd6um0
  * Aaron Bieber, https://www.youtube.com/watch?v=JWD1Fpdd4Pc
* Nick Nisi, https://www.youtube.com/channel/UCbNhLf99gKKXdXm0aFfQFKw
* Luke Smith, https://www.youtube.com/channel/UC2eYFnH61tmytImy1mTYvhA
* Alex Booker, https://www.youtube.com/watch?v=_kjbj-Ez1vU
* Chris Hunt, https://www.youtube.com/watch?v=9jzWDr24UHQ
* Gaël Ecorchard, https://github.com/galou

# Toubleshooting

It is possible and probable that after you update using ```git pull```, something might not work anymore.
This usually happens due to new programs, plugins and dependencies that might not be satisfied anymore.
I suggest to re-run **install.sh**, after each update.

# Disclaimer

This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

