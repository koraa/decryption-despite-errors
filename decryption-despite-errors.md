# Abstract

This paper introduces the notion of decryption despite errors: ciphers that remain secure in the presence of adversarial errors in the cipher text without the requirement of discarding the message entirely.
Definitions of and fundamental limits of security under these constraints are presented. Informally, it should be infeasible for an attacker to do any better than raising the (random) noise level in the plain text in the attempt to forge messages. More formally, asymptotic infeasibility of distinguishing the decryption of two challenger-chosen error-patterns (bit flips) with the same number of errors must be demonstrated for security.
Security against fuzzing is formalized.
The outline of a construction that operates as a mode for a pseudo random function is presented; the construction is based on multiple rounds of an error correcting code and interleaver, both randomized using the PRF generated key stream.

This paper is currently very much a draft. It has not been peer reviewed and I  — the author — may decide that some parts are flat out wrong. MUMBLE MUMBLE indicates references and content to be filled in. Proofs of security and correctness are TBD. For now, the constructions have informal arguments of security/correctness.

# Introduction

## Use Case

All physical channels are nosy, meaning that the rate of transmission errors can be reduced, but never to zero. Reducing the noise level to the degree required for most applications by increasing the reliability of the physical system is often impractical, as is usually the case with transmissions over radio. There is a better way to deal with this: Forward Error Correction — codes designed to detect and correct errors in return for extra overhead. These codes usually make many assumptions about the distribution of errors in the channel and yield much reduced error correction rates when these assumptions fail to be met. E.g., convolutional codes [citation needed, probably wrong, replace example] operate at much greater efficiencies when the errors are randomly distributed while Reed-Solomon codes are most efficient against bursts [citation needed, probably wrong]. Convolutional codes also suffer from error floor problems, operating at reduced efficiency when MUMBLE MUMBLE MUMBLE [citation needed, mumbled]. Interleaving schemes are used to combine such codes, yielding codes that correct errors reliably in a greater range of scenarios. E.g. CDs use a complex scheme of interleaved Reed-Solomon codes and MUMBLE MUMBLE to correct errors, see a description in [citation needed].

Cryptographic systems are usually layered on top of these error corrected channels to protect the integrity of the data. Modern authenticated encryption schemes protect the integrity and privacy [citation needed] of the data transmitted, even against very dedicated adversaries with large resources. Data protected with these schemes either arrives as sent by the communication partner or it does not arrive at all, with absolutely overwhelming probability. Authenticated encryption schemes usually represents the strongest part of any communications system. Note that while authenticated encryption guarantees authenticity, integrity, and privacy of the data transmitted, it explicitly does not provide reliability of the transmission. In fact, it makes denial of services significantly easier because AE ensures as a property that a minimum number of modifications to the cipher text suffices to ensure the message is rejected. One bit flip, erasure, or insertion suffices to have the message rejected. This is a necessity to achieve security under an adaptive chosen cipher text attack [citation needed] — the common definition provided by most security protocols today.

The forward error correction employed on communication channels improve that situation but being designed for very specific noise profiles, finding some error pattern that has the message rejected is easy for a determined adversary. The practical implications of that situation are limited: Fuzzing of radio transmissions can usually be addressed by intervention teams by disabling the fuzzer; most transmissions are secured physically, and data rates are large enough that a few packets lost do not make a big difference.

Still, improving the reliability of error correction in data transmissions has significant potential to improve transmission efficiencies and reliability, especially in niche use cases like long range radio transmission, spacecraft.

## Prior Art

### Approximate Message Authentication

A limited amount of prior work exists on the problem of cryptographically securing error correction and error resilience in cryptographic protocols. Excellent papers have been written on the problem of Approximate Message Authentication codes; see MUMBLE MUMBLE [citation needed] for a relatively recent work with good references. These are extensions of message authentication codes: While a valid MAC implies with overwhelming probability that the tag was generated from the exactly same message as is being verified, AMACs extend this to messages with a certain constant distance from each other. AMACs still output a hard decision in general; for the schemes presented in this paper, more precise information about the distance between plain text and plain text with errors would be desired.

### Existing hybrid FEC and symmetric crypto schemes

There has also been some work on producing hybrid ciphers integrating error correction and block ciphers, most recently MUMBLE MUMBLE [citation needed] producing what the call MUMBLE MUMBLE. I know of no attacks against this most recent works, but earlier constructions employing FEC to achieve security have been proven insecure. The work referenced here is a from scratch construction of a pseudo random permutation, and therefore unfortunately hard to prove as secure. This is not uncommon in PRPs and also the case for very widely used constructions [citation needed], however since this is a fairly niche application cryptanalysis is likely to focus on one of these more widely used constructions. Confidence in this specific scheme is therefore limited.

## Contributions in this paper

This paper focuses primarily on two properties:

**Security Against Fuzzing (short FEC-security):** Authenticated encryption schemes with this property ensure, that given a limited maximum number of bit flips, finding some error pattern in the cipher text that maximizes the number of bit flips in the plain text is computationally hard. Basically, this formalizes the security of the forward error correction and provides error correction even in the presence of a determined adversary trying to jam message transmission with minimal effort. It also ensures that as long as some information can be transmitted, there exists some redundancy parameter for the cipher that will extract the message being transmitted successfully (although trying this in the real world might be entirely impractical).

**Partial Message Recovery (short PMR):** Authenticated encryption schemes that allow the decryption of a cipher text even if the original message cannot be recovered. As such schemes are by their very nature malleable schemes, analysis will focus on what standard notions of security can be achieved, what new notions of security can be introduced in this setting and how these relate to standard notions. The practical use cases for schemes with that property is increasing transmission efficiency if the data being transmitted has some inherent redundancy (e.g., media streaming). The idea is this:
A dropped package will generally result in big artifacts; a small number of bit flips on the other hand are barely noticeable. Right now, the redundancy level has to be chosen such that a single bit flip occurs on average just every couple of messages to avoid packet loss. With DDE, a much lower redundancy level could be chosen such that the effective error rate is closer to a few per packet because these could still be successfully decrypted.

Formal security games modeling both properties are given as well as an analysis of the maximum achievable security for each property are given. **PMR** is incompatible with full **CCA2** security, so a formalization of **CCA2** security "up to" some proposition is presented that can encapsulate what is achievable with **DDE** is presented. **FEC-security** is compatible with **CCA2**.

Schemes conjectured to possess these properties are presented.

# Quick Reference

##### Standard operations

  ------------------------------------------- -----------------------------------------------------------------------------------------------------
                         $\cdot \oplus \cdot$ Exclusive or over bits or vectors of bits.  

                                   $W(\cdot)$ The hamming weight (number of bits set to one in a vector of bits).  

                      $W(\cdot \oplus \cdot)$ The hamming distance.  

                                    $|\cdot|$ Size of a vector.
  ------------------------------------------- -----------------------------------------------------------------------------------------------------

##### Definition of the scheme

This paper uses a slightly modified definition of a symmetric cipher applicable to decryption despite errors: A redundancy parameter is added; the scheme takes the cipher text or a cipher-text with errors and returns the original plain text or a related plain text as well as an error estimate. The error estimate $w$ replaces the usual construction in authenticated encryption where a message or the bottom element is returned. The message is rejected if $w > w_{max}$.

The paper also discusses the case of standard authenticated definitions with additional security against fuzzing. In this case standard definitions are applicable.

  ------------------------------------------- -----------------------------------------------------------------------------------------------------
                    $Enc_{K, R}(k, n, x) = y$ The polynomial time encryption algorithm. The shorthands $Enc(k, n, x)$ and $Enc(x)$ may be used.

             $Dec_{K, R}(k, n, y') = (x', w)$ The polynomial time decryptiion algorithm. The shorthands $Dec(k, n, y')$ and $Dec(y')$ may be used.


                                          $K$ The security parameter.  

                                          $R$ Redundancy parameter.  

                                $w_{max} : Q$ Maxmimum allowed error. If $w > w_max$, $Dec$ will discard the message. If $w_{max} = 0$ the loss estimate shall be a normal message authentication code.

                                   $k, n : N$ Symmetric key, nonce.  

                          $(x, y) : {0, 1}^*$ The *original* plain text, cipher text.  

                        $(x', y') : {0, 1}^*$ The cipher text with errors/plain text after decryption with errors.  

                          $e_y = y \oplus y'$ Speak "The syndrome". Error vector in the cipher text.  

                          $e_x = x \oplus x'$ Speak "The residual". Error vector after decryption in the plain text.  

           $W_{ey} = W(e_y) = W(y \oplus y')$ Speak "The syndrome weight". Number of bit flips in the cipher text.  

           $W_{ex} = W(e_x) = W(x \oplus x')$ Speak "The residual weight". Number of bit flips in the plain text.  

                    $w : Q, w \approx W_{ex}$ Speak "loss estimate". Generalization of message authentication to soft decision; returned by the decryption agorithm.
  ------------------------------------------- -----------------------------------------------------------------------------------------------------

##### Security Notions

  ------------------------------------------- -----------------------------------------------------------------------------------------------------
                          fec+CCA2 $\iff$ ... Speak "fec and CCA2 security". Security notion capturing CCA2 secure authenticated encryption with
                                              additional security against fuzzing.

                          DDE-CCA2 $\iff$ ... Speak "decryption despite errors under CCA2 attack".

                          DDE-CCA1 $\iff$ ... Speak "decryption despite errors under CCA2 attack".

                                  fec-NM-CCA1 Speak "forward error correction non malleability under CCA1 attack". Formalization of security against fuzzing.

                                  fec-NM-CCA2 Speak "forward error correction non malleability under CCA2 attack". Formalization of security against fuzzing.

                                   pl-NM-CCA1 Speak "proportional loss non malleability under CCA1 attack". Formalization of Non Malleability under decryption against errors
  
                                   pl-NM-CCA2 Speak "proportional loss non malleability under CCA2 attack". Formalization of Non Malleability under decryption against errors
  
                                   le-NM-CCA1 Speak "loss estimate non malleability under CCA1 attack". Formalization of the loss estimate security.
  
                                   le-NM-CCA2 Speak "loss estimate non malleability under CCA2 attack". Formalization of the loss estimate security.
  ------------------------------------------- -----------------------------------------------------------------------------------------------------
  
fec+CCA2 $\iff$ fec-NM-CCA2 $\land$ IND-CCA2.

DDE-CCA2 $\iff$ IND-CCA1 $\land$ NM-CCA1 $\land$ pl-IND-CCA2 $\land$ pl-NM-CCA2 $\land$ le-NM-CCA2 $\land$ fec+CCA2.

DDE-CCA1 $\iff$ IND-CCA1 $\land$ NM-CCA1 $\land$ pl-IND-CCA1 $\land$ pl-NM-CCA1 $\land$ le-NM-CCA1 $\land$ fec+CCA1.

##### Instantiations
  
  ------------------------------------------- -----------------------------------------------------------------------------------------------------
                         fec-cipher-auth-cca2 Cipher defined below with conjectured fec+CCA2 security.
  
                               ddecipher-cca1 Cipher defined below with conjectured DDE-CCA1 security.
  
                               ddecipher-cca2 Cipher defined below with conjectured DDE-CCA2 security.
  
                         ddecipher-cca2-nopin Cipher defined below with conjectured DDE-CCA2 security *without* use of the pinning technique described below.
  ------------------------------------------- -----------------------------------------------------------------------------------------------------

# Notions of security

## Security Against Fuzzing

Informally, a scheme is secure against fuzzing if it is hard for an adversary to thwart the successful decoding by flipping bits. The number of bit flips is chosen as the limited resource on the part of the adversary. This restriction on fuzzer capability is necessary, because if all information is erased from the message, recovering the message would obviously be impossible. This model is also justified by real world application because this notion  captures the scenario of a radio transmitter in a shared medium (e.g. wifi) whose goal it is to overwhelm the communications channel with noise. It appears likely that drastically reducing the transmission rate of the radio channel would be relatively easy for the adversary while further decreases in transmission rate would be asymptotic (i.e. there are diminishing returns). Whether this model captures reality needs to be empirically established but this is out of scope for this this paper. 

A proper security definition in the game playing framework by [citation needed] is yet to be created.
A scheme is considered to be fec-NM-CCA2 secure if an adversaries advantage in winning the game is negligible.
The game is won if the adversary can win either challenge:

1. Adversary produces a pair of messages $x_0, x_1$ of the same length and redundancy parameters $R_0, R_1$ with access to the relevant oracles
2. The game encrypts the messages at the specified redundancy yielding $y_0, y_1$
3. Adversary produces pair of syndromes $e_{y1}, e_{y2}$ of the same weight with access to the relevant oracles and state made in 1.
4. Game decrypts the derived messages at the specified redundancy parameters
5. Adversary wins if the redundancy levels do not predict the residual weight, provided they did not try to cheat with the syndrome weight or message length. $$comp(R_0, R_1) \ne comp(W_{ex0}, W_{ex1}) \land |x_0| = |x_1| \land W_{ey0} = W_{ey1}$$ $$comp(a, b) = \begin{cases} a < b : -1 \\ a = b : 0 \\ a > b : 1 \end{cases}$$

When applied to a CCA2 secure authenticated encryption (i.e. a scheme without partial message recovery) scheme, set $W_{ex} \gets 0$ if the message passes authentication and $W_{ex} \gets 1$ otherwise.

## Partial Message Recovery

*PMR* covers the notion that it should be possible to decrypt a message even if the syndrome weight is beyond the schemes ability to recover the original message. If the original message cannot be recovered, then the decryption algorithm must return some other message in its place so the scheme is necessarily cipher-text and plain-text malleable which has a direct, negative impact on security. The key insight here is that to be secure, an adversary should be be unable to do anything but raise the noise level; a channel with a dedicated adversary systematically flipping bits should look just like a channel with an increased noise level to the recipient.

More formally, for every syndrome space containing all syndromes of the same hamming weight, there is some probability space of residual errors in the decrypted plain text. This space must be the same for each element of the syndrome space.

Since the scheme returns an error estimate instead of a hard decision, an appropriate notion of unforgability has to be arrived at as well.

<!-- Todo: Make formula -->

### Incompatibility with NM-CPA

Partial Message Recovery is incompatible with NM-CPA, NM-CCA1 and NM-CCA2. Since IND-CCA2 $\iff$ IND-CCA2, PRM is also incompatible with IND-CCA2. To brake non-malleability games an adversary can simply flip a single bit in the cipher-text and then construct a relation from the hamming distance.

A scheme that cannot provide NM-CPA should usually not be considered secure enough for any real world application beyond the construction of other, more secure, schemes. Let me point out though that the usual security definitions simply don't capture
the properties of partial message recovery very well. PMR can provide a decent level of security, even under adaptive chosen cipher text attack if the security definitions are made aware of the non malleability properties. This may seem like a potentially dangerous move, but there is some precedence: Ciphers generally do not hide the size of the message so the usual security definitions where defined to not include attacks based on the size of the message. Analogously to the restriction of standard security notions to messages of the same length, the next sections will define further weakened security notions applicaple to PMR.

### proportional-loss indistinguishably

A proper game based definition needs to be created still. For now the following rough definition is given:

1. The adversary chooses a message $x$
2. Game encrypts the state $y = Enc(x)$
3. Adversary chooses two syndromes of the same hamming weight $e_{y0}, e_{y1}$ with access to the usual oracles and the state produced in 1
4. Game randomly applies and decrypts one of the error patterns: $$b = \gets^R \{0, 1\}; x' = Dec(y \oplus e_{yb})$$
5. Adversary outputs a guess of $b_g$ given the oracles, the state from 3. and $x'$
6. Challenger wins if their guess is right and they didn't cheat with syndrome weight $$b = b_g \land W_{ey0} = W_{ey1}$$

The adversary also loses if they decrypted $y \oplus e_{y0}$ or $y \oplus e_{y1}$ using the oracle.

### proportiona-loss non-malleability

Again, a proper game is yet to be arrived at. For now the following definition based on [citation needed] is used:

1. The adversary chooses a valid message space $M$
2. The game chooses two messages at random $x_0, x_1 \gets^R M$
3. The game encrypts both $y_0 \gets Enc(x_0); y_1 \gets Enc(x_1)$
4. The adversary outputs a relation and a vector of syndromes of the same hamming weight $(R, S)$ given $y_1$, oracles and the state from 1.
5. The game chooses a random syndrome of the same hamming weight, applies it two both cipher texts and decrypts them: $$e_{y0} \gets^R {0, 1}^{|S_0|}; x_0' = Dec(y_0 \oplus e_{y0}), x_1' = Dec(y_1 \oplus e_{y1})$$
6. The game applies each syndrome and decrypts the resulting cipher texts: $E' \gets Dec(y_1 \oplus S)$
7. The game randomly chooses one of the two messages $b \gets^R \{0, 1\}$
7. The adversary wins the game if the relation holds and they didn't attempt to cheat by outputting syndromes of different weights or of weight zero: $$R(x_b', E') \land (\forall s_u, s_v \in S, W(s_u) = W(s_v) \land W(s_u) > 0)$$

### The Short Distance Brute Force Attack


## Composite Notions

fec+ATK and DDE-ATK notions are composite notions. fec+ATK refers to a strengthening of the standard security notions to include partial message recovery so fec+CCA2 refers to authenticated encryption plus resistance against fuzzing. DDE-ATK refers to a weakening of standard security definitions to allow partial message recovery. DDE-ATK always includes resistance against fuzzing.

# Constructions

By convention in this paper a python-like pseudocode is used to specify algorithms. A parameter `&<name>` denotes a reference to a value. This specification style is intended to be replaced with a formal specification in some established grammar. `clone(v)` where v is a reference denotes taking a copy of the value referenced to; assignment to references assigns to the value.

## Choice of FEC

$fec(\dot)$ and $unfec(\dot)$ are two polynomial time, deterministic and stateless algorithms such that $unfec$ is the inverse of $fec$. The code is able to correct random errors better than bursts.

An FEC for this particular use case has not been chosen.
The precise properties required from the code are at the current time not well understood. In the DDE-CCA2 secure construction the code is used to induce diffusion, formalization of the requirements will be guided by that application.
Some definate properties the code should have are: Constant time decoder and encoder, space-efficiency, fast decoder and encoder, optimized for randomly distributed errors. Space efficiency is particularly important in **DDE** because the primary motivation behind using DDE is space efficiency.

The proper proof of security for the instantiations will largely depend on the specifics of the FEC scheme.

## Choice of RNG

The `rng` parameter in the specifications below denotes some unique random oracle. `clone(rng)` duplicates the state of random oracle such that $a = f(clone(rng)); b = f(rng); a = b$ for any function $f$ that is not probabilistic or statefull.

All constructions require instantiation of the random oracle with a random number generator. Which RNG is chosen is not explicitly mandated by this paper. However, I strongly suggest using either chacha20 or shake256.

## The Grind Shuffle

In the specifications below $shuffle(rng, data)$ and $unshuffle(rng, data)$ denote two stateless, deterministic, polynomial time algorithms such that $unshuffle(rng, \dot)$ is the inverse of $shuffle(rng, \dot)$ provided that the state in both random number generators is the same.

An efficient, cryptographic, bitwise shuffle is required to instantiate the scheme. Standard shuffling methods such as the fisher-yates [citation needed] shuffle are not suitable as these algorithms use key dependant memory accesses thereby introducing a timing side channel. Cryptographic shuffles such as the thorp-shuffle [citation needed] or the swap-or-not shuffle [citation needed] are slow to [is this actually the case?] implement.

The grind shuffle is a cryptographic shuffle mixing two blocks of data using only rotate and standard bitwise operations. It needs to be seeded with a random number generator (random oracle). The grind shuffle is conjectured to asymptotically approach a truly uniform, random shuffle.

### Definition

The grind shuffle takes a random number generator and two blocks of data to be mixed as input. The bits of both blocks are swapped with a random mask, then both blocks are rotated by a randomly chosen distance. These two steps are repeated until sufficiently mixed.

```python
def grind_round(&block0, &block1, &rng):
  swap_with_mask(block0, block1, rng.getBytes(blockSize))
  block0 <<<= rng.getInt(0, blockSize) # Random integer in the interval [0; blockSize)
```

Bitwise swap with mask can easily be defined as a bitwise operation (a more efficient definition using XOR can likely be found):

```python
def swap_with_mask(&block1, &block2, mask):
  t1 = clone(block1), t2 = clone(block2)
  block1 = (t1 & ~mask) | (t2 & mask)
  block2 = (t2 & ~mask) | (t2 & mask)
```

Each of the operations is fully reversible. Creating the inverse of the shuffle only requires extracting the parameters to grind_round from the key stream in reverse and applying rotation before swapping.

### Constant time rotation

Constant time bitwise rotation within the architecture's word size is a standard operation in most cryptographic implementation libraries. Its efficient implementation on real hardware is out of scope for this paper. In some situations, constant time rotation by a variable distance may not be supported; possibly because the rotation distance is large.
In these cases, it can be implemented as the sum of a number of fixed distance rotations by a power of two. Rotations that are not needed are masked. Rotating the elements of an array by a fixed amount without side channel can be accomplished with standard techniques.

### Correctness argument

During each round, exactly half of bits are randomly selected for a rotation by a random distance. After r rounds the rotation distance for a particular bit starting at position $i_0$ is $i_0 + \sum_{n=0}^{r} d_n * b_n$. $d_n$ is the same for each bit during each round, but the value of $d_n$ (the switch enabling the rotation for a particular round) is correlated with just the complementary bit. The total space of possible rotation distances after r rounds is $R = 2^r$ so for any block size $B$ there is a small r such that $R \gg B$ so shuffling should be achievable in $O(log(B))$ rounds.

### Grind as a structured method of constructing regular permutations

Since any permutation can be encoded in the grind framework in a small number of rounds by choosing the appropriate key. This may be useful in the implementation of bitwise permutations. Computing the appropriate key in the general case is an open problem; optimal would be a some function $grind_from_fy$ converting the fisher-yates representation of the permutation to the grind representation.

The following constructions build on the previously defined grind round function.

#### Shuffling longer vectors

While long-distance rotation can be implemented using the techniques outlined in above, it may be more efficient to just split the data into multiple chunks and mix them incrementally.
Used like this, the round function mixes the bits from two blocks at a time; like in the two block variant rotation serves to decorrelate the relative shift of bits from the same block of origin.  
In this mode of operation, both blocks should be rotated by a random amount, not just the first.  
Finding an optimal, deterministic mixing pattern remains an open question for now.

#### Shuffling with a mask

It is possible to ensure that some bits remain fixed while the rest of the bits are shuffled randomly. In the mask, all bits that should remain in place are set to zero, all others are set to one. 

```python
def grind_round(&block0, &block1, &rot0, &mask0, &mask1, rng):
  swap_with_mask(block0, block1, mask0 & mask1 & rng.getBytes(blockSize))
  dist = rng.getInt(0, blockSize)
  rot0 += dist
  block0 <<<= dist
  mask0 <<<= dist

def grind(&block0, &block1, mask0, mask1, &rng):
  rot0 = 0
  for _ in range(roundCount):
    grind_round(block0, block1, rot0, mask0, mask1, rng)
  block0 >>>= rot0 % blockSize
  # mask0 >>>= rot0 % blockSize # Never used again
```

This works for two reasons: The masked bits are never moved to the other block. Static bits from block two are never rotated so they stay in place. Static bits from block one are rotated but their offset is kept track of through the `rot0` variable. `mask0` is rotated as well so we can keep track of all the masked bits. After all rounds of shuffling have been reset, their absolute rotation is reset to zero with a right shift by rot0.

Note that masking clearly increases the required number of rounds especially in extreme scenarios like masking all but one bit. Masking all bits disables the shuffling altogether. Further analysis is required to find a variant that is not susceptible to these issues.

#### Shuffling arbitrarily long bit vectors

Use padding to achieve the required block size. Use shuffling with mask to shuffle without moving the padding. Discard the padding.

## DDE construction under CCA1 attacks

By using a random shuffle we can mask the locations used during forward error correction; by using well a well analyzed PRF for encryption and for randomization fully linear, easily analyzed operations can be used for encryption so a security proof in the random oracle model should be possible.

The cipher design outlined in this section aims to achieve simplicity and provable security. Specifically, the cipher should be implemented as a reduction to a common PRF (e.g. blake2, chacha, keccak) instead of a from scratch construction to achieve a high level of security but not depend on the specifics of that PRF. Security in the following games is conjectured IND-CCA1, pl-ND-CCA1, fec-IND-CCA1 and le-NM-CCA1. For this security level to be realistic the implementation must reliably prevent the reuse of nonces; this is possible in some streaming scenarios.

IND-CCA1 can be achieved by using unauthenticated encryption in the random oracle model [citation needed]. This scheme provides fantastic malleability; bit flips are 1:1 carried over to the plain text. We could perform FEC on cipher text or plain text. This scheme also gives the adversary the ability to induce arbitrary error patterns in the plain text. This is an extremely efficient construction in terms of both ciphertext size and performance, but is not secure. Still it provides a good basis to build the full scheme on.

```python
def encrypt(&rng, plaintext):
  return plaintext ^ rng.getBytes(len(plaintext))

def decrypt(&rng, ciphertext):
  return encrypt(rng, ciphertext)
```

To achieve the security claims given above the forward error correction step and the location of bits needs to be masked.
For this purpose, the forward error correction sandwiched in shuffle operations and forward error correction is used. You may notice that this function does not return an error estimate. It is likely that the error estimate generated by the FEC can be directly used, but that depends on the specific FEC that will be chosen.

```python
def encrypt(rng, plaintext):
  x = plaintext
  x = x ^ rng.getBytes(len(x))
  x = shuffle(rng, x) # Some cryptographic shuffle
  x = fec(x)
  x = shuffle(rng, x)
  x = x ^ rng.getBytes(len(x))
  return x

def decrypt(rng, ciphertext):
  rng.seek(bitsNeeded) # Need to consume random bytes in reverse
  x = plaintext
  x = x ^ rng.reverse().getBytes(len(x))
  x = unshuffle(rng, x) # Inverse of shuffle
  (x, w) = unfec(x) # Inverse of FEC
  x = unshuffle(rng, x)
  x = x ^ rng.getBytes(len(x))
  if w > w_max:
    return None
  else
    return (x, w) 
```

$w_{max}$ needs to be chosen so there are at least $2^128$ valid messages per invalid message.

### Security Argument

Encryption in the random oracle model is secure despite just using a linear operation on the plain text: XOR may be linear but it is used with a large amount of random information. The cipher outlined above should be secure for the same reasons.

The adversary has minimal information about the input and the output of the FEC. Despite knowing the plain text and cipher text, hey know neither the input values nor the output of the FEC since those are obscured by the two XOR operations with the key stream. Nor do they know which bits in the cipher text relate to which bits in the fec output or which bits in the plain text relate to which bits in the fec input under the assumed correctness of the shuffle. Assuming that the FEC is better at correcting some error patterns than therrs, the adversary doesn't know the number of bit flips in the plain text after decryption, since the shuffle obscures the error pattern. The adversary knows just the statistical distribution of errors in the plain text.

Under the random oracle model, the key stream under one nonce/key combination is independent from any other key stream. Nonce reuse is prohibited either by use of a stateful encryption oracle or by choosing nonces at random from a large space. An adversary may encrypt some plain text and submit modified versions of the associated cipher-text to fully recover the key stream used for it's encryption but since key streams are independent no information about the key stream used in the challenge is gained.

An adversary may try to submit cipher texts with new nonces but since the scheme is le-NM-CCA1 secure and $w_{max}$ was chosen such that there are at least $2^128$ invalid cipher texts so the probability of gaining any information is neglible in $w_{max}$.

Glossing over a lot of details, this lack of information on the part of the adversary should justify IND-CCA1, pl-ND-CCA1, fec-IND-CCA1 and le-NM-CCA1.

## DDE construction under CCA2 attack

Achieving CCA2 security necessitates the use of techniques from permutation based encryption as recovering even some bits from the keystream may enable an attack. A construction similar to a substitution-permutation network is constructed using shuffles and FEC instead of S- and P-boxes. The scheme is conjectured to provide IND-CCA1, pl-IND-CCA2, pl-ND-CCA2, le-NM-CCA2 and fec-IND-CCA2 security.

The scheme from the previous section is insecure under adaptive chosen cipher text attacks; just determining part of the inner and outer shuffle would suffice to enhance the adversaries ability to produce specific error patterns. This structure can be probed using a differential attacks. In order to achieve CCA2 security it is thus necessary to mask the keystream even under differential attack.

In non-malleable schemes (i.e. authenticated encryption) CCA2 attacks are reduced to CPA attacks because the authentication tag constitutes a proof that the adversary knows the plain text. DDE schemes specifically provide cipher text and plain text malleability as a feature, so using the authentication technique is out of the question.

Instead of using authentication, techniques from block ciphers are used to obscure the key stream. Shuffle constitutes a fully randomized permutation on location and is used as a P-box. FEC is used to provide diffusion. One round of the cipher is FEC sandwiched in two shuffles. Shuffles from adjacent rounds are merged since shuffle is a linear operation (two shuffles by a random key just yield a third shuffle by a random key with the *same amount of randomness*). Before and after the rounds of FEC/shuffle, the data is XORed with the key stream which is much less than in block ciphers but still sufficient because the key stream is generated by a random oracle.

The error estimate of the last FEC operation is used during decryption.

```python
def encrypt(rng, plaintext):
  x = plaintext
  x = x ^ rng.getBytes(len(x))
  for _ in roundCount:
    x = shuffle(rng, x) # Some cryptographic shuffle
    x = fec(x)
  x = shuffle(rng, x)
  x = x ^ rng.getBytes(len(x))
  return x

def decrypt(rng, ciphertext):
  rng.seek(bitsNeeded) # Need to consume random bytes in reverse
  x = plaintext
  x = x ^ rng.reverse().getBytes(len(x))
  for _ in roundCount:
    x = unshuffle(rng, x) # Inverse of shuffle
    (x, w) = unfec(x) # Inverse of FEC
  x = unshuffle(rng, x)
  x = x ^ rng.getBytes(len(x))
  if w > w_max:
    return None
  else
    return (x, w) 
```

Note that in this scheme, security and redundancy are proportional. This is undesirable as this likely will lead to excessive redundancy levels just to achieve a sufficient number of rounds for security. Puncturing (removing some bits from the FEC output) can be used to reduce the redundancy level. Instead of filling those with a constant value during decoding, a second oracle dedicated to masking the decoding process is generated from the cipher text: $decRNG \gets Rng(k, n, y')$. This construction is similar to a message authentication code, except that it produces arbitrarily many bits and is kept private.

This construction provides extra methods of adjusting the cipher parameters:

- Adding more rounds increases security and redundancy
- Puncturing more bits increases security and decreases redundancy
- Using a code with higher redundancy increases redundancy and might increase redundancy

### Security Argument

This DDE-CCA2 secure scheme is an extension of the previously defined DDE-CCA1 secure scheme; therefore the same arguments for DDE-CCA1 security apply here. To achieve DDE-CCA2 security this scheme provides additional security against differential cryptoanalytic attacks.

The proper security proof of the scheme will depend on the properties of the specific FEC. Since the FEC has not been chosen a model of it's regular properties that this scheme is supposed to obscure is needed. The following properties are chosen:

1. **Locality:** The location of an errors in the code predict the location of errors after decoding regardless of the actual value of code points or data. This relationship is assumed to be simply (errors in start/middle/end of are likely to yield errors at start/middle/end of the data). This choice is justified because locality of data usually leads to increased performance in most cpu architectures. It is also a natural choice because it is easy to think about.
2. **Preference for sparse syndromes:** The code is assumed to be better at correcting randomly distributed errors than correcting burst errors. While there are many FECs that perform better with bursts, this choice makes sense as the FEC is paired with a shuffle which will spread apart bursts of errors. This assumption also makes sense with locality as to correct burst errors, more distant bits need to be involved in the decoding process than just the close neighbours.

Under a differential attack with a small number of errors, all bit flips are likely going to be corrected. The adversary keeps adding bit flips, which due to the random shuffle surmounts to flipping random bits in the code. At some point in this process, the syndrome is sufficiently dense that the outer round of FEC is no longer able to correct all errors.

In the case of a single round variant, errors are starting to appear in the plain text. Due to the outer shuffle, these errors appear at random location even if the syndrome density is high enough to produce multiple errors close to each other. As the adversary keeps adding errors, some bits in the plain text will be flipped a *second time*; i.e., they are reset to their original value. While the overall error density in the data keeps increasing, this is not necessarily the case when just considering a small number of bits in the output. Picture how the error vector changes during decoding: The errors in the data after decoding may jitter around in place slightly, while the average error rate within a window of a few bits keeps increasing. After shuffling the decoded bits, this jitter effect will no longer be localized. Instead, the relative error density may change quite drastically; in some cases, with errors moving location across the entire width of the ciphers block size.

Let us now consider the case of a second layer. In general the same process as in the first round now repeats with the following exception: While in the input to the first FEC the error density for each window of adjacent bits increases monotonically, the error density in the input to the second round occasionally decreases. Recall, that the FEC chosen is better at correcting errors if the syndrome is sparse so the changes in error density produced by the first round may actually yield a syndrome that is easier to decode for the second. This effect can outweigh the mere increase in bit flips.

**After two rounds, adding more an error may actually decrease the number of errors after decoding even if the FEC used doesn't provide such a behaviour.** Every added round amplifies that effect. Hopefully a upper bound for the number rounds required can be derived at by using the fact that the shuffles are fully randomized with a random oracle.

#### Security with puncturing

The puncturing technique described above serves to improve security further. Note that the decoding RNG produces arbitrarily many secret bits because it is initialized with the symmetric key and nonce and it's values are never exposed by the decoder. Note also, that the stream can not be probed during a CCA2 attack because the derived cipher text is also used to initialize the RNG.

This provides a vastly more direct way of randomizing the decoding process than relying on the diffusion properties of the cipher. This should drastically reduce the number of rounds required and substantially increase the chances of being able to arrive at a formally proven upper bound for the number of rounds needed.

## FEC-Secure, fully IND-CCA2 secure Authenticated Encryption

To achieve full CCA2 security and fec-NM-CCA2 on top, the technique from "DDE construction under CCA2 attacks" is combined with any authenticated encryption scheme.

The inner XOR with the key stream is replaced with the authenticated encryption scheme; in other words crypto first and FEC on top of that. The error estimate is ignored; using it to abort early would introduce a timing side channel.

For increased performance, a final round of our normal FEC followed by a hard-decision algebraic code should be used to mop up any remaining errors, especially if a noise floor is present. These improve the efficiency of the FEC and are not used for security.

The scheme either returns the valid plain text or yields an authentication error; this means probing this should be harder than in the partial message scenario. The number of rounds may be adjusted appropriately.

### Security argument

The scheme is CCA2 secure since it operates only the cipher text generated by a CCA2 secure authenticated encryption scheme.

The argument for fec-NM-CCA2 security is that this scheme encompasses a fec-NM-CCA2 secure scheme, namely the one from "DDE construction under CCA2 attacks".

<!-- TODO: Isn't using a code that can correct a fixed number of errors fec-NM-CCA2 secure? What is the advantage of this? -->

