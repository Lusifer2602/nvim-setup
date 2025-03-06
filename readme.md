either navigate to (if exists) or create a directory named nvim in the .config folder under usernames's folder in home directory of root.

Would look something like /home/<admin`s username>/.config/nvim

run this command in the terminal ' curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim '

here paste the file named init.vim using mv command in terminal or manual copy pasting from the cloned repo.
or create a file names init.vim and paste the contentst of initial init.vim into this newly created one

now save this using :x 

in the command line type, ":PlugInstall", this will download the neccessary plugs

make sure to read the init file to ensure which config settings you need and which you don't

after completing all the steps above run ":PlugInstall" in nvim's command line.
