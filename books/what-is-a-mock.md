# What is a “mock” function?

“Mock” in mock theta function and mock modular form does **not** mean a disposable fake in the software-testing sense.

There is a limited analogy worth keeping.

A software mock imitates selected observable behavior of another object while not being that object. A mock modular form similarly exhibits much of the behavior that makes one expect modularity, but the holomorphic function by itself does not satisfy the full modular transformation law. The analogy stops there. A mathematical mock form is not a test double manufactured for convenience. It is an intrinsic mathematical object whose failure of modularity contains structured information.

## The central pattern

Very schematically, a mock modular form \(f\) is the holomorphic part of a larger real-analytic modular object:

\[
\widehat f(\tau)
  =
f(\tau)
  +
\text{nonholomorphic correction}.
\]

The completed object \(\widehat f\) transforms modularly. The correction is governed by another modular form called the **shadow**.

A useful way to read the word “mock” is:

- \(f\) looks modular in striking and systematic ways;
- \(f\) alone misses part of the transformation law;
- the failure is not noise;
- the missing piece can be described;
- after completion, the larger object belongs to a clean modular theory.

Ramanujan's mock theta functions are historically earlier special examples. Zwegers' work placed them inside the modern theory of real-analytic modular forms and harmonic Maass forms.

## Why introduce mocks at all?

They are not introduced because mathematicians wanted weakened modular forms. They appeared because naturally occurring \(q\)-series had identities, asymptotics and root-of-unity behavior strongly reminiscent of theta functions while refusing to fit the classical definition.

The right response was not to discard the examples. The ambient theory had to grow.

This pattern recurs elsewhere. A “mock” object often records a holomorphic or otherwise preferred piece of a better-behaved completed object. The obstruction to being classical is itself meaningful data.

## Related usages

### Mock theta functions

Ramanujan's original examples. They predate the language of shadows and harmonic Maass forms.

### Mock modular forms

The modern general setting. The holomorphic mock form has a modular completion and an associated shadow.

### Mock Jacobi forms

Jacobi-form analogues occur naturally in partition theory, moonshine and mathematical physics. Their completion restores the relevant Jacobi and modular transformation behavior.

### Mixed mock modular forms

Products or combinations involving mock and ordinary modular objects. The terminology varies somewhat across the literature, so a concrete transformation law matters more than the adjective.

### Mock period functions

An analogous completion idea can be applied to period-function and cohomological structures. “Mock” again signals a controlled failure followed by completion, rather than a software-style fake.

### Quantum modular forms

These are related historically and conceptually but are not simply another synonym for mock modular forms. Their modularity defect is studied on subsets such as \(\mathbb{Q}\), with regularity properties of the defect playing the central role.

## The software-testing analogy, stated carefully

The resemblance is:

    passes a conspicuous family of expected behaviors
    but is not literally an instance of the classical object

The differences are more important:

| Software mock | Mock modular form |
| --- | --- |
| deliberately manufactured | naturally occurring mathematical object |
| substitutes for another component | is not a substitute for a modular form |
| usually throws information away | its modularity defect carries information |
| useful because tests need isolation | useful because completion exposes hidden structure |
| normally judged against an interface | characterized by analytic and modular data, shadow and completion |

So “mock” in the two fields is related at the level of ordinary English: imitation without identity. It is not the same technical construction.

## A useful UI idea

The app can make this visible rather than only explain it in text.

Show three synchronized panes:

1. the holomorphic \(q\)-series;
2. a validator reporting which modular or theta expectations it satisfies or fails;
3. the completion and shadow data needed to repair the transformation law.

Then moving through nearby functions makes the rarity of genuine theta or modular behavior visible. A classical theta function is not just a visually similar series; it lands on a rigid set of transformation constraints.

## Starting references

- William Duke, “Almost a Century of Answering the Question: What Is a Mock Theta Function?” (2014), summarized in this repository.
- Sander Zwegers, *Mock Theta Functions* (PhD thesis, 2002):
  https://research-portal.uu.nl/en/publications/mock-theta-functions/
- arXiv copy of Zwegers' thesis:
  https://arxiv.org/abs/0807.4834
- Don Zagier, “Ramanujan's Mock Theta Functions and Their Applications”:
  https://archive.numdam.org/item/AST_2009__326__143_0/
- Atish Dabholkar, Sameer Murthy and Don Zagier, “Quantum Black Holes, Wall Crossing, and Mock Modular Forms”:
  https://arxiv.org/abs/1208.4074
