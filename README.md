# Fisher.rb
This is an interpreter of the language [><>](https://esolangs.org/wiki/Fish) (Fish).
The goal of this project is not only to have feature parity with the original python interpreter but also to add some extra features such as

- [*] Displaying the map in the terminal
- [ ] Stepping through individual moves
- [ ] Show more information when the program is running such as the stack of stacks/registers

*marked means done*

## Usage
```bash
$ ruby fisher.rb [file] [options]
```

where options include

* `-t [milliseconds]` - specify the delay between every move (default: 0)
* `-d` to show the map
* `-c [code]` - interpret a string of code from the terminal instead of from a file
* `-v [stack]` - specify the starting stack of the program with the stack as a string of numbers separated by numbers
* `-i [string]` - give the program a string as input (Will use stdin by default)

## FAQ

### Will this behave exactly like the original fish.py
That's the goal. There may be some edge cases which haven't been covered but it works for what I've tried.

### Why isn't my program working?
Is it working in the original fish.py? If so, please open an issue and I'll try and fix it. If it doesn't work in either implamantation it's probably

### Where is feature XYZ?
I'm still working on the program but don't be afraid to open an issue about any feature request or if it's something small, open a pull request.

### Is this slower than the original python implementation?
Yes but not by much if you don't draw the map. I don't think it makes that much of a difference as ><> programs aren't that heavy and I don't think the performance difference will affect anyone playing around with ><>.