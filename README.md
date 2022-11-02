[Inspiring video](https://www.youtube.com/watch?v=c33AZBnRHks)

The problem is simple: given the list of words in `words.txt`, finds all sets
of 5 5-letters words which spam 25 unique letters, that is, that have no
letters in common between (nor inside) them.

Examples:

```
jimpy gconv fultz hdqrs bawke
whick zygon bumps fldxt javer
zingy chowk jumps fldxt brave
zingy chowk jumps fldxt breva
brigs fldxt nymph quack vejoz
```

I tried to do it with the least amount of optimization possible, while still
getting nice times. I did, however:

- Take anagrams out
- Encode words as numbers to use bitwise operations
- Cache results of partially calculated things
- Separate words in groups by their vowels (also: no vowels, two vowels, more
  than two vowels), and loop only through sensible combinations of those
  groups (it makes no sense to try to find a solution with 6 vowels, you
  already got a repetition there for sure).

The two former I was "poisoned" by watching the video, the two latter I came
up with myself.

On a MacBook Air with M1:
- Python: about 3 minutes
- Zig: about 5 seconds

It is also my first Zig program, so there's that.

# LICENSE 

The MIT License (MIT)

Copyright (c) 2022 Álan Crístoffer

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
