# Woman in Red App Icon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate and retain a production-sized app-icon master whose primary read is a red evening dress and whose secondary read is digital privacy.

**Architecture:** Use the approved design specification as the single visual source of truth. Generate one square raster master, validate it visually at full size and at 32 px, and save the accepted source under the project design assets without replacing platform icons yet.

**Tech Stack:** Built-in image generation, PNG, local image inspection.

## Global Constraints

- Canvas is square and at least 1024 x 1024 pixels.
- Use brand red `#FF2D3E` on near-black `#090A0F`.
- The centered subject is one original floor-length red evening-dress silhouette.
- Matrix-inspired glyphs appear sparsely inside the fabric only.
- No text, face, copied character, Hiddify resemblance, shield, padlock, blue, purple, watermark, or device mockup.
- Do not replace shipping iOS or Android icon assets during this task.

---

### Task 1: Generate and validate the app-icon master

**Files:**
- Read: `docs/superpowers/specs/2026-07-13-woman-in-red-app-icon-design.md`
- Create: `design/assets/woman-in-red-app-icon-master.png`
- Test: visual inspection at 1024 px and 32 px

**Interfaces:**
- Consumes: the approved icon specification and current generated concept as an edit reference.
- Produces: a square PNG master for later iOS and Android icon generation.

- [ ] **Step 1: Generate one revised concept**

Use this exact production prompt:

```text
Edit the reference app-icon concept. Replace the hooded figure and shield/tunnel emblem with one centered, elegant floor-length red evening-dress silhouette. The dress alone suggests a poised femme-fatale figure, but depicts no face, body, or existing character. Preserve the full-bleed near-black #090A0F background and the restrained premium flat-logo treatment. Use brand red #FF2D3E. Add only sparse, subtle Matrix-inspired digital glyphs inside the red fabric; they must read as texture and never break the outer silhouette. Keep smooth bold vector-friendly edges, generous Apple icon safe margins, and strong recognition at 32 px. No text, letters, wordmark, border, watermark, device mockup, shield, padlock, blue, purple, dense code rain, thin lines, glossy 3D, or photorealism.
```

- [ ] **Step 2: Save the generated PNG**

Copy the generated 1024 x 1024 PNG to:

```text
design/assets/woman-in-red-app-icon-master.png
```

- [ ] **Step 3: Validate the visual hierarchy**

At full size, confirm the first read is “red dress” and the second read is “digital privacy.” At 32 x 32 pixels, confirm the dress silhouette remains recognizable and the glyph texture does not create noisy edges.

- [ ] **Step 4: Verify the file**

Run:

```bash
file design/assets/woman-in-red-app-icon-master.png
```

Expected: PNG image data with equal width and height of at least 1024 pixels.
