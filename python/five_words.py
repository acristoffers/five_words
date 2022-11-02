#!/usr/bin/env python3

from functools import reduce
from operator import or_
from itertools import combinations, product
from typing import Generator

Word = tuple[list[str], int]


def letters(word: str) -> int:
    _ord = lambda w: {"+": 124, "=": 125, "_": 126}.get(w, ord(w))
    return reduce(or_, (1 << (_ord(letter) - 97) for letter in word))


with open("words.txt", "rt") as file:
    words: list[Word] = []
    anagrams: dict[int, list[str]] = dict()
    for line in file.readlines():
        word = line.strip()
        ls = letters(word)
        if len(word) == ls.bit_count() == 5:
            if ls in anagrams:
                anagrams[ls].append(word)
            else:
                anagrams[ls] = []
                words.append(([word], ls))
    for k in list(anagrams.keys()):
        if not anagrams[k]:
            del anagrams[k]

aeiou = letters("aeiou")
a = letters("a")
e = letters("e")
i = letters("i")
o = letters("o")
u = letters("u")
words_groups = {
    "+": [w for w in words if (aeiou & w[1]).bit_count() > 2],
    "=": [w for w in words if (aeiou & w[1]).bit_count() == 2],
    "_": [w for w in words if (aeiou & w[1]).bit_count() == 0],
    "a": [w for w in words if (aeiou & w[1]) == a],
    "e": [w for w in words if (aeiou & w[1]) == e],
    "i": [w for w in words if (aeiou & w[1]) == i],
    "o": [w for w in words if (aeiou & w[1]) == o],
    "u": [w for w in words if (aeiou & w[1]) == u],
}


def ipair(xs: list[Word], ys: list[Word]) -> Generator[Word, None, None]:
    for u in xs:
        for w in ys:
            if not (u[1] & w[1]):
                yield (u[0] + w[0], u[1] | w[1])


def lpair(xs: list[Word], ys: list[Word]) -> list[Word]:
    return list(ipair(xs, ys))


lpair2_cache = dict()
lpair4_cache = dict()


def lpair2(a: str, b: str) -> list[Word]:
    global words_groups, lpair2_cache
    i = letters(f"{a}{b}")
    if i not in lpair2_cache:
        print(f"\t\tSearching for {a}{b}...")
        lpair2_cache[i] = lpair(words_groups[a], words_groups[b])
        print(f"\t\tFound {len(lpair2_cache[i])} solutions.")
    return lpair2_cache[i]


def lpair4(a: str, b: str, c: str, d: str) -> list[Word]:
    global ws, lpair4_cache
    i = letters(f"{a}{b}{c}{d}")
    if i not in lpair4_cache:
        print(f"\tSearching for {a}{b}{c}{d}...")
        p1 = lpair2(a, b)
        p2 = lpair2(c, d)
        lpair4_cache[i] = lpair(p1, p2)
        print(f"\tFound {len(lpair4_cache[i])} solutions.")
    return lpair4_cache[i]


def lpair5(a: str, b: str, c: str, d: str, e: str) -> list[Word]:
    global words_groups, lpair4_cache
    print(f"Searching for {a}{b}{c}{d}{e}...")
    cs = [
        [a, b, c, d, e],
        [a, b, c, e, d],
        [a, b, d, e, c],
        [a, c, d, e, b],
        [b, c, d, e, a],
    ]
    result = None
    for x, y, z, w, v in cs:
        i = letters(f"{x}{y}{z}{w}")
        if i in lpair4_cache:
            result = lpair(lpair4(x, y, z, w), words_groups[v])
    if not result:
        result = lpair(lpair4(a, b, c, d), words_groups[e])
    print(f"Found {len(result)} solutions.")
    return result


ps = []
for p in combinations("aeiou_____==+", 5):
    s = list(sorted(p))
    # not already there
    c1 = s not in ps
    # only 5 vowels, max
    weights = {"a": 1, "e": 1, "i": 1, "o": 1, "u": 1, "_": 0, "+": 3, "=": 2}
    c2 = sum([weights[c] for c in p]) <= 5
    if c1 and c2:
        ps.append(s)

print(f"Number fo words with a: {len(words_groups['a'])}")
print(f"Number fo words with e: {len(words_groups['e'])}")
print(f"Number fo words with i: {len(words_groups['i'])}")
print(f"Number fo words with o: {len(words_groups['o'])}")
print(f"Number fo words with u: {len(words_groups['u'])}")
print(f"Number fo words with +: {len(words_groups['+'])}")
print(f"Number fo words with =: {len(words_groups['='])}")
print(f"Number fo words with _: {len(words_groups['_'])}")
print(f"Number of possible combinations: {len(ps)}")

result = []
for a, b, c, d, e in ps:
    print((a, b, c, d, e))
    r = lpair5(a, b, c, d, e)
    for ws, _ in r:
        xs = [[w, *anagrams.get(letters(w), [])] for w in ws]
        for x in product(*xs):
            result.append(x)

print(f"Number of entries before cleanning up: {len(result)}")
final = []
for r in result:
    if (s := set(r)) not in final:
        final.append(s)
print(f"Number of entries after cleanning up: {len(final)}")

with open("output.csv", "w+") as f:
    for w in final:
        w = list(w)
        f.write(f"{w[0]},{w[1]},{w[2]},{w[3]},{w[4]}\n")
