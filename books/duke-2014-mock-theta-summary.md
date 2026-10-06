# W. Duke — *Almost a Century of Answering the Question: What Is a Mock Theta Function?*

## Bibliographic note

William Duke, “Almost a Century of Answering the Question: What Is a Mock Theta Function?”, *Notices of the American Mathematical Society* **61** (2014), no. 11, 1314–1320.

DOI: https://doi.org/10.1090/noti1185

Official AMS PDF:
https://www.ams.org/journals/notices/201411/rnoti-p1314.pdf

Author page:
https://www.math.ucla.edu/~wdduke/

This repository does **not** contain a copy of the paper. The 2014 AMS article remains copyrighted; this file is an independent summary and set of working notes.

## Why this belongs here

The old “polynomial Tetris” sketch came from working through the beginning of Duke’s article, especially the partition generating function

\[
g(q)=\sum_{n\ge 0}p(n)q^n=\prod_{m\ge 1}(1-q^m)^{-1}.
\]

Expanding the product factor by factor gives a literal combinatorial construction: each factor contributes a choice of how many parts of a given size occur. Visually, this can be treated as colored blocks accumulating into coefficients of powers of \(q\). That is the natural mathematical basis for the Tetris-like interaction in this repository.

## Summary

Duke’s article tells the story of the phrase **mock theta function** from Ramanujan’s final letter to Hardy in 1920 to the modern theory of harmonic Maass forms.

Ramanujan did not give a modern axiomatic definition. Instead, he supplied examples of special \(q\)-series and described how they imitate ordinary theta functions near roots of unity while stubbornly failing to be ordinary theta functions themselves. The examples had striking identities and asymptotic behavior, but for decades the larger structure explaining them was unclear.

The article starts with familiar objects from partition theory. The partition generating function is an infinite product, and classical theta functions provide another family of \(q\)-series with strong modular transformation laws. Ramanujan’s mock theta functions look tantalizingly similar to such modular objects, particularly when one studies their behavior as \(q\) approaches roots of unity.

A major early step was G. N. Watson’s work in the 1930s. Watson proved many of Ramanujan’s claims and developed the analytic theory of the examples, but the name “mock theta function” still described a phenomenon more than a settled class of functions.

The conceptual breakthrough came much later, especially through Sander Zwegers’s 2002 thesis. Zwegers showed that Ramanujan’s mock theta functions can be completed by adding explicitly nonholomorphic correction terms. The completed functions transform like modular forms of a broader kind: harmonic Maass forms. In modern language, the holomorphic piece is a **mock modular form**, and the missing nonholomorphic piece is controlled by an associated modular form often called its **shadow**.

That viewpoint explains why Ramanujan’s series can imitate modular forms so closely without themselves being ordinary modular forms. They are not defective theta functions; they are holomorphic pieces of larger modular objects.

The modern theory connects mock modular forms to subjects including partitions, elliptic curves, singular moduli, Borcherds products, Eichler cohomology, and Galois representations. Duke’s main point is historical as well as mathematical: a question posed by a handful of mysterious examples eventually forced an enlargement of the surrounding theory.

## Mathematical landmarks

### 1. Partitions as a product

\[
\prod_{m\ge1}(1-q^m)^{-1}
=
\prod_{m\ge1}(1+q^m+q^{2m}+\cdots).
\]

Choosing the term \(q^{km}\) from the \(m\)-th factor means choosing \(k\) parts of size \(m\). The exponent of the resulting monomial is the integer being partitioned.

This is the most immediate route from the article to “polynomial Tetris”: multiplication of truncated power series can be displayed as blocks whose horizontal position or height records degree and whose color records which factor supplied the contribution.

### 2. Theta functions

Classical theta functions are \(q\)-series with precise transformation behavior under modular substitutions. Their coefficients, analytic continuation, asymptotics, and symmetries are tied together by this modular structure.

### 3. Ramanujan’s mock theta functions

Ramanujan gave several families of \(q\)-series that behave near roots of unity somewhat like theta functions but cannot globally be replaced by a single ordinary theta function with the same behavior.

A standard example from the third-order family is

\[
f(q)=1+\sum_{n\ge1}
\frac{q^{n^2}}
{(1+q)^2(1+q^2)^2\cdots(1+q^n)^2}.
\]

The important point for this project is not merely the closed formula: each denominator expands into a structured collection of power-series contributions that can again be visualized combinatorially.

### 4. Completion

The modern resolution adds a nonholomorphic correction to a mock modular form. The completed object has a genuine modular transformation law. The missing information is encoded by the shadow.

Schematically,

\[
\text{mock modular form}
+
\text{nonholomorphic correction}
=
\text{harmonic Maass form}.
\]

The slogan is only schematic; the actual weights, operators, multipliers, and normalizations matter.

### 5. Why the old problem survived so long

Ramanujan’s examples supplied extremely rigid identities without making the ambient category explicit. Watson and later authors could prove more and more identities inside the examples, but Zwegers’s completion placed those identities inside a general modular framework.

## Notes for the APK

A first executable interpretation should stay close to the algebra rather than simulate commercial Tetris rules.

Possible visual grammar:

- one color per Euler-product factor \((1-q^m)^{-1}\);
- blocks of width or label \(m\) represent parts of size \(m\);
- a stack represents one partition of \(n\);
- collecting every stack of total size \(n\) illustrates the coefficient \(p(n)\);
- a second mode can show polynomial multiplication directly, with each multiplication step adding a new colored layer;
- later screens can replace the partition product with a truncated mock-theta \(q\)-series and compare its coefficients and root-of-unity behavior.

The useful idea from the old sketch is that the animation is not decoration around the formula. The block mechanics *are* the multiplication and coefficient bookkeeping.

## Historical sources to add later

These are better represented by links, public-domain transcriptions when provenance is clear, or fresh summaries rather than casually copying modern editions.

- Srinivasa Ramanujan’s final 1920 letter to G. H. Hardy, where the term “mock theta function” first appears.
- G. N. Watson, “The Final Problem: An Account of the Mock Theta Functions” (1936).
- Sander Zwegers, *Mock Theta Functions* (PhD thesis, 2002).
- Amanda Folsom, “What is a mock modular form?” *Notices of the AMS* 57 (2010).

## Working interpretation

For this repository, “mock theta” should mean two related things:

1. the actual mathematics of Ramanujan’s \(q\)-series and their modern modular interpretation;
2. the older visual experiment in which formal power-series multiplication becomes a block game.

The second should remain mathematically faithful to the first rather than turning into a generic falling-block game with formulas pasted onto it.
