## Usage
Run `make` in this directory to zip all lua files into a .love file, update the index.html to reflect the size of that file and serve the game on port 8000.

The default TARGET is `compat`. You can replace this term in the makefile with `release`.

## Dependencies
This sample depends on:
- make (for running the makefile)
- python3 (for serving the webpage with the appropriate headers, also works with python2 but the makefile will have to be modified), and 
zip (for zipping the lua files into a .love file)

On Ubuntu:
``` sh
sudo apt install python3 make zip
```

## TODO
### Cross Platform Support (Windows)
Right now this sample is linux based. It would be useful to replace the shell tools with lua and make it cross platform.

### File Watching
Rather than having to rerun the make command when you've altered your files it would be useful to watch the development folder and rebuild the game when changes are made.
