# Why the comment reaper finds bugs

Presentation notes. The claim is counter-intuitive, so it is built up from a toy case before the real one.

## The one-sentence version

**A comment says what code is supposed to do. The code says what it actually does. Nobody ever compares the two, because reading the comment first tells you what to see in the code.** The reaper compares them, by asking somebody who was never shown the comment.

## The dumb example first

```python
# Only allow admin users
if user.name.startswith("admin"):
    grant_access()
```

Read that as a human. It looks fine. You read "admin users", then you read the code *as* "admin users", and you move on.

Now delete the comment and ask a stranger **"who gets in?"**

They say: *"anyone whose name begins with the letters a-d-m-i-n."*

That is not the same sentence. `administrator_intern` gets in. `adminbot` gets in. The comment described the **intent**; the stranger described the **behaviour**; the gap between them is the bug.

The comment was not wrong about what was *wanted*. It was wrong about what was *written*, and it stopped four reviewers from noticing.

## The real one, in five steps

The code decided whether an address was on your home network, before opening a window that hands out an authentication token.

**Step 1. The reaper strips the comment and keeps the code.**

```cpp
// fc00::/7, unique local.
if (address.rfind("fc", 0) == 0 || address.rfind("fd", 0) == 0)
    return true;
```

becomes

```cpp
if (address.rfind("fc", 0) == 0 || address.rfind("fd", 0) == 0)
    return true;
```

**Step 2. It asks a fresh agent, which has never seen that comment:**

> "When does this treat an address as being on the local network?"

**Step 3. The agent answers what the code does, not what it meant:**

> *"When the address text begins with the characters `fc` or `fd`."*

**Step 4. The reaper compares that with the comment's claim,** `fc00::/7`.

Those sound identical. They are not, and here is the whole trick, no IPv6 knowledge needed:

**IPv6 lets you drop leading zeros.** So `fc::1` is shorthand for `00fc::1`.

| written | actually starts with | on your network? |
|---|---|---|
| `fc00::1` | `fc` | yes |
| `fc::1` | `00` | **no** |

Both *begin with the letters `fc`*. Only one is actually a local address. The check was reading **text**, not an **address**.

**Step 5. Investigate, confirm, fix.** Four addresses from outside the network were being treated as local, at the door that hands out the token:

```
fe80::1          -> local        correct
fc::1            -> local        WRONG, this is 00fc::1
0:0:0:0:0:0:0:1  -> not local    WRONG, that IS loopback
```

Rewritten to convert the address to its sixteen bytes and check the number rather than the spelling. Nine assertions go red without the fix.

## Why this finds things review does not

1. **The comment primes the reader.** A human reads the comment, then reads the code *through* it. You see `fc00::/7` and your brain fills that in over `rfind("fc")`. Stripping the comment removes the prompt, and the reviewer has no choice but to read what is there.
2. **It forces the comparison to happen at all.** A comment and its code are two independent claims that nobody diffs. This makes it a mechanical step: describe the behaviour, then check it against the stated intent. A mismatch is a signal.
3. **The reviewer has no stake.** A fresh agent with no memory of writing the code, no idea what it was for, and nothing to defend.

## The honest caveat, for the skeptics

Put this on a slide too, because somebody will ask.

**It finds where comment and code disagree. It cannot tell you which one is wrong.**

In the same pass, a comment claimed a string type was not null-terminated. The agent disagreed with it, so the procedure *kept* the comment as load-bearing. Reading the vendor's source showed the **comment** was the wrong one.

So the output is not "here are your bugs". It is **"here are the places where two descriptions of the same code do not match"**: a short list, worth a human's attention. Sometimes the code is wrong. Sometimes the comment is. Either way you learned something.

Across one repository it produced three real code defects, all found while asking whether a *comment* deserved to exist:

- a security check that did not check what it said it checked
- an unchecked return value on a security-relevant call
- a branch that could never be false
