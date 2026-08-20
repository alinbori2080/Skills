# Prompt templates

Use only the sections needed for the request. Replace bracketed values with observed facts, not guesses.

## First generation

```text
Use case: style-transfer
Asset type: standalone premium dual-zone editorial poster
Input image: Image 1 is the sole subject reference and edit target.

Canvas:
Create ONE [aspect ratio] vertical poster. Divide it at the exact horizontal midpoint into two equal-height regions, each precisely 50% of the canvas.

Visual lock from Image 1:
- Subject identity and defining features: [facts]
- Pose and silhouette: [facts]
- Camera/viewpoint: [facts]
- Head, shoulder, and torso angles: [facts]
- Foreshortening and near/far scale: [facts]
- Palette and atmosphere: [facts]

TOP 50%:
Preserve the subject's identity, pose, viewpoint, anatomy, proportions, materials, natural lighting logic, and original atmosphere. [Remove named UI elements if requested.] Reframe through cropping or natural background extension only. Apply restrained editorial grading. Do not stretch, warp, or redesign the subject.

BOTTOM 50%:
Abstract the same subject using flat geometric color fields, thin precise lines, and generous negative space. Trace the exact source silhouette, pose, body rotation, shoulder slope, limb directions, and near-large/far-small relationship. Simplify detail only. Keep asymmetry and foreshortening. The result must be recognizable as the same subject from the same camera angle.

Style:
[Background], [palette], premium international design studio, architectural poster, art exhibition catalogue, disciplined grid, restrained and contemporary.

Text (verbatim):
"[exact text or NONE]"

Constraints:
One poster, no collage, no extra panels, no frontalization, no mirroring, no symmetry normalization, no T-pose, no extra limbs, no anatomy distortion, no UI unless requested, no logo, no watermark, no mockup frame, no cheap texture, no template look.
```

## Correct one drifted lower pose

Use the current poster as Image 1 and the original source as Image 2.

```text
Use case: precise-object-edit
Asset type: revised premium dual-zone poster
Input images:
- Image 1 is the edit target.
- Image 2 is the strict pose and perspective reference.

Edit ONLY the abstract subject in the BOTTOM 50% of Image 1.

Match Image 2 exactly:
- Body rotation: [facts]
- Head and shoulder angles: [facts]
- Viewer-left limb direction and scale: [facts]
- Viewer-right limb direction and scale: [facts]
- Near limb: [which limb], visibly larger because of foreshortening
- Far limb: [which limb], visibly smaller and farther away

Preserve the lower-half abstraction style, palette, whitespace, grid, and exact text. Keep the entire TOP 50%, canvas ratio, midpoint split, margins, and all unrelated elements visually unchanged.

Do not normalize, mirror, symmetrize, front-face, flatten, or convert the pose into a T-pose. No new text, objects, limbs, or decoration.
```

## Revision rule

For later feedback, keep the same image roles and change only one named issue. Repeat all preservation constraints on every pass.
