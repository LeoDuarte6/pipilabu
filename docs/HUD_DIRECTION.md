# Pipi Labu HUD Direction

The HUD exists to support the next handoff, not narrate the game. Leo and Jon approved `assets/concepts/pipi_labu_hud_direction_v1.png` as the permanent interface direction. The implementation translates that board into native responsive Roblox UI rather than shipping a baked image: three warm top-left state medallions, a restrained contextual notice, the customer's circular order/patience medallion, and a dedicated completion medallion that leads directly to `NEXT SHIFT`.

The concept's prominent upright Shiba ears are explicitly rejected character geometry. Interface approval does not approve every object depicted on the board.

## Design contract

- **Purpose/audience:** make the apple-service loop readable and inviting for Roblox players across desktop, console, and mobile.
- **Register:** warm Japanese-market craft, tactile wood/gold, cute without becoming toy-menu noise.
- **Preserve:** literal TIME/SERVED/MISSED state, safe-inset placement, world-first serving, color-plus-name redundancy, haptics, and the strong customer handoff.
- **Focal event:** the customer order while active; `SHIFT CLEAR -> NEXT SHIFT` when a run ends.
- **Proof:** every emphasized state comes from live server-owned shift/order attributes rather than decorative or invented status.
- **Accepted:** small circular status icons, circular urgency, warm medallion completion, native responsive construction.
- **Contextual:** a thin instruction notice remains only because wrong-apple and held-apple feedback need literal explanation during the current teaching gate.
- **Rejected:** large equal black rectangles, persistent branding, long patience bars, center-screen copy during ordinary play, baked concept art, generic glass/glow, and the concept character's top ears.

## Rules

- Preserve the center and lower center for world interaction, order cards, and the customer reaction.
- Keep stable run state in fixed positions; change color or pulse only when the underlying state changes.
- Use the apple's world color only for matching state. Never depend on color alone: every crate and order also has a literal name.
- Make the serve, not the HUD, the sensory reward. The served medallion receives a restrained pulse while animation, sound, held prop, and customer reaction carry the event.
- Keep the panel inside Roblox Core UI safe insets. Controls remain supported through Roblox prompts and bindings; do not append keyboard/gamepad notation to every button label.
- Treat readability, spatial flow, and explicit points of interest as map and UI responsibilities together.
- On narrow viewports, move the completion medallion toward center without covering the ordinary interaction area.

## References

- Approved project board: `assets/concepts/pipi_labu_hud_direction_v1.png`.
- Blizzard's accessibility work exposes text sizing, background/color controls, previews, cursor sizing, and warning colors; the transferable principle is configurable, redundant signaling rather than ornamental copy: https://overwatch.blizzard.com/ja-jp/news/23912175/
- Blizzard describes map improvements in terms of readability, stronger themes, flow, highlighted entrances, and clearer points of interest; Pipi Labu applies the same logic to its centered customer and two readable crates: https://overwatch.blizzard.com/en-gb/news/patch-notes/live/2025/07/
- Valve's Panorama UI replaced older Scaleform HUDs with a dynamic web-like system, supporting clean state-driven composition rather than baked decorative panels: https://developer.valvesoftware.com/wiki/Counter-Strike%3A_Global_Offensive
