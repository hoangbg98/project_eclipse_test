# assets/characters

One folder per character ID. Each has `frames/{animation}/`, `portrait/`,
`vfx/` and `frames_manifest.json`.

- Frame size and pivot: 384x384, pivot (192, 336). See README Section 2.2.
- File names: `{id}_{animation}_{NNN}.png`, numbered from 000.
- To deliver frames: copy PNGs into the animation folder, then set `frames`
  (and `fps` if needed) for that animation in `frames_manifest.json`.
- `frames: 0` means not delivered yet; placeholders are used.

Full rules: README Section 17.4.
