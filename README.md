### Birb

Help Birb get to her friends before dusk.

Use arrows to navigate Birb through the maze and get to her friends. Use space to flap wings.

This game was written during [Spring Lisp Game Jam 2021](https://itch.io/jam/spring-lisp-game-jam-2021 "Spring Lisp Game Jam 2021") with [Chickadee](https://dthompson.us/projects/chickadee.html "Chickadee") game development toolkit for Guile Scheme. This is my first attempt to code with any language from Lisp-family and the first game overall.

The pixel arts are mine and the music is by [Rick Hoppmann (TinyWorlds)](https://opengameart.org/users/tinyworlds "Rick Hoppmann (TinyWorlds)").


TODO: I'll try to finish it later with generated mazes, interaction with characters, etc.

### Run

1. Go to [Releases](https://github.com/kierros/birb/releases) and dowload tarball with all dependencies `birb-0.1-guix-pack.tar.gz`
2. Unpack the tarball 
`tar -xf birb-0.1-guix-pack.tar.gz`
3. Run the executable 
`./bin/birb`

### Build from source with Guix

To build it with Guix you also need [Chickadee](https://dthompson.us/projects/chickadee.html "Chickadee")
Clone the repo and run the following commands:
1. `guix environment -l /path/to/chickadee/guix.scm -- `
2. `/path/to/chickadee/pre-inst-env guile /path/to/birb/game.scm `
