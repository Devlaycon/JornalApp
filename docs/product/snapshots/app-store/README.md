# App Store Screenshot Frames

These screenshots are Duolingo-inspired in structure, but Circleu-branded in content, color, and message. They use real simulator screenshots from `docs/product/snapshots/`.

## Files

1. `01-reflect-in-your-own-voice.png`
2. `02-turn-check-ins-into-insight.png`
3. `03-save-your-private-journal.png`
4. `04-practice-one-small-step.png`
5. `05-share-support-with-circles.png`

Each image is `1290 x 2796` PNG for a large iPhone portrait App Store/TestFlight-style listing.

## Caption Strategy

- Keep headlines short and benefit-led.
- Show one product idea per image.
- Use real app UI, not fake screen mockups.
- Keep the tone playful, warm, and focused on reflection.

## Regenerate

Open or render `index.html` with a `slide` query parameter from `0` to `4`.

Example:

```bash
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --headless=new \
  --disable-gpu \
  --hide-scrollbars \
  --window-size=1290,2796 \
  --screenshot=docs/product/snapshots/app-store/01-reflect-in-your-own-voice.png \
  "file://$PWD/docs/product/snapshots/app-store/index.html?slide=0"
```
