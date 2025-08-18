# Do

1. Set up a connection to github. 
    This might be creating a new key or copying .ssh settings from another machine. 

2. Run the script to setup the system.
    ``` bash
    wget -qO- https://raw.githubusercontent.com/Stefantb/setup-machine/refs/heads/main/setup-pop-22.sh | bash
    ```


# Notes

## Once had to fix permissions on the .ssh directory
    ``` bash
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/*
    ```
## Pop!_OS 22.04 awesome wallpaper
    To set the background in gnome settings, remember that awesome will use the setting for the Light theme.



