# MT-T1 implementation and acceptance boundary

The permitted panel is still `A_n = (1 - q^n) B_n`, with
`B_n = 1 + sum_{j=1}^{n-1} (1 - q^j)`.
The deterministic order is 5, 4, 3, 2, 1. Signed cell provenance is retained;
degrees select horizontal columns. Whole-panel preview offsets affect only
presentation. The five-panel coefficient row is exactly
`15, -5, -5, -4, -4, -3, 2, 2, 1, 1`, for degrees 0 through 9.

## Interaction

The ICK-compiled core owns the addition prefix, whole-panel pointer capture,
hit testing, cancellation, one-time release, reset and framebuffer rendering.
Android translates pointer IDs and window coordinates and owns lifecycle,
NativeActivity, the window buffer and saved progress. It does not decide which
panel gets added. A second pointer cannot steal or commit the first pointer's
gesture. Resize, focus loss and cancellation return the preview without adding.

Drag the bounded next panel vertically into the green release band, then
release in that band. Degree columns remain fixed. A tap or release outside the
band returns the panel. Completion persists; Reset is an explicit button.
The layout reserves the complete 15-cell degree-zero stack so a moving preview
cannot cover accumulated cells. Signs are drawn on every cell, and both the
coefficient and degree rows are labeled.

## Regression evidence

The host test computes an independent polynomial oracle from the formula for
every permitted n, checks each shifted/negated pair and its seed provenance,
every prefix and the final row. It exercises legal addition, wrong-pointer and
repeated release, background touches, abandoned/reset gestures, cancellation,
completion and exact reset at six generic viewport sizes. It checks framebuffer
bounds with padded stride. The five-field state-size assertion forces review if
independent cell or other game state is introduced; mathematical commands in
Idris admit whole panels and reset only. No gravity, rotation, collision or
line-clearing machinery belongs to this state.

The typed model retains its original coefficient proofs and preview-motion law.
Additional proofs bind the arithmetic command to a whole typed Shape, the exact
five-command expression and row, and reset to an empty diagram.

Legal addition is not a mock-modularity proof. The finite Tetris expression
remains `Unverified`; the UI says `ADDITION ONLY`.

## Shared build boundary

The existing ARMv7 ICK-object/NDK-boundary workflow is retained as a **leaf CI
candidate**, with explicit PR-head checkout and source receipts. It strips the
native library before packaging, records pre/post-strip sizes, and requests the
existing Flexible Pipes `android-apk-preflight` pipeline. That pipeline owns
orchestration of the existing AICI producer/signing gate. It does not establish
paired application-build execution or physical acceptance.

Device/ABI/priority policy is read from the exact Cat Food checkout's
`android/application-targets.tsv`, retained in the build artifact, never copied
into a local maintained device table. Signers remain in AICI; packaging remains
in Android-NDK. No new producer gate, signer registry or deployment script is
introduced.

The maintained paired build is blocked: Flexible Pipes main
`c8cb7ac069a798eaf6cc228de9a2c23b2b351587` has only APK preflight. Its retained
registered Android operation at
`fc4443f27ae11dcae32ab62d62f510812be9a57d` is `UNQUALIFIED`, limited to
Crystal/Halite on A1, and requires independently approved producer and delivery
deployment. It cannot admit Mock Theta or request the standard A1+C67 APK pair.
The narrow missing owning capability is an admitted application recipe with a
paired target plan and the independently qualified producer/delivery inputs.
Changing a leaf workflow cannot grant that authority.

Existing owning work:
- [Flexible Pipes PR #33, Register Android producer and diagnostic operations
  with actual behavioral replay](https://github.com/isomorphisms/flexible-pipes/pull/33).
- [AICI producer composition issue #207](https://github.com/isomorphisms/ai-ci/issues/207).
- [Cat Food producer/delivery issue #109](https://github.com/isomorphisms/catfood/issues/109).

This PR leaves that blocked authority explicit and does not create a competing
paired producer. A leaf ARMv7 artifact is not the requested maintained A1
artifact. No C67 APK is claimed. The graphics/tests can run at C67 dimensions
without qualifying an arm64 APK or a physical C67.

## Physical procedure after an admitted candidate exists

Install the exact signed candidate without uninstalling an existing package.
Launch; drag and release all five whole panels. Check readable signs, unclipped
degree columns, the green target and touch alignment. Verify the final row
above, including degree zero `15`; a repeated release must leave it visible.
Tap Reset once and verify an empty sum and the first blue panel. Record the
device instance and exact APK digest separately for A1 and C67.
