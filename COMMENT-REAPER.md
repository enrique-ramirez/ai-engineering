# Why the comment reaper finds bugs

A comment says what code is meant to do; the code says what it does. Nobody compares the two, because reading the comment first tells the reader what to see. The reaper compares them by asking a reader who was never shown the comment.

## A toy case

```python
# Only allow admin users
if user.name.startswith("admin"):
    grant_access()
```

Read with the comment, this looks fine. Delete the comment and ask a stranger who gets in, and the answer is "anyone whose name begins with a-d-m-i-n". `administrator_intern` gets in, and so does `adminbot`. The comment describes the intent, the stranger describes the behaviour, and the gap between them is the bug.

## A real one

The code decided whether an address was on the home network, in front of a route that hands out a token:

```cpp
// fc00::/7, unique local.
if (address.rfind("fc", 0) == 0 || address.rfind("fd", 0) == 0)
    return true;
```

With the comment stripped, a fresh agent was asked when this treats an address as local. Its answer: when the address text begins with `fc` or `fd`.

That sounds like `fc00::/7` and is not. IPv6 lets leading zeros drop, so `fc::1` means `00fc::1`:

| written | first byte | local? |
|---|---|---|
| `fc00::1` | `fc` | yes |
| `fc::1` | `00` | no |

Both begin with the letters `fc`; only one is a local address. The check read text, not an address, and the same pass found loopback spelled out in full (`0:0:0:0:0:0:0:1`) treated as not local. The fix parses the address into its sixteen bytes and checks the number.

## Why review misses this

1. **The comment primes the reader.** `fc00::/7` goes in first and the brain lays it over `rfind("fc")`.
2. **Nobody diffs the two claims.** The reaper makes it a step: describe the behaviour, compare it with the stated intent.
3. **The reader has no stake.** It did not write the code and has nothing to defend.

## The caveat

The reaper finds where comment and code disagree; it cannot say which is wrong. In the same pass a comment claimed a string type was not null-terminated, the agent disagreed, and the vendor's source showed the comment was the wrong one. The output is a short list of places where two descriptions of the same code do not match, each worth a person's attention.
