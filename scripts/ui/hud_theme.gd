class_name HudTheme
extends RefCounted
## Vị trí, kích thước, màu và thời gian của HUD trận đấu (README 15.5, 17.5), gom một chỗ.
## Toạ độ theo khung thiết kế 1920×1080; phần tử neo theo góc màn hình.

# --- Icon dự bị (góc trên-phải) ---
## Vùng chạm tối thiểu 140 px (README 15.5).
const RESERVE_ICON_SIZE := 160.0
const RESERVE_ICON_GAP := 28.0
const RESERVE_MARGIN := Vector2(56.0, 48.0)
const RESERVE_PORTRAIT_RADIUS := 56.0
const RESERVE_RING_RADIUS := 68.0
const RESERVE_RING_WIDTH := 7.0
const RESERVE_ARC_RADIUS := 78.0
const RESERVE_ARC_WIDTH := 3.0

# --- Vòng sáng Liên kết (README 17.5) ---
const RING_FADE_IN_SEC := 0.15
const RING_FADE_OUT_SEC := 0.3
const RING_PULSE_SEC := 0.8
const RING_SCALE_MAX := 1.12
const RING_BRIGHT_MIN := 0.6
const RING_BRIGHT_MAX := 1.0
const RING_BURST_SEC := 0.2
const RING_PARTICLES := 3
## Token màu vòng theo nguyên tố (placeholder, owner thay bằng art cuối).
const RING_COLOR := {
	"fire": Color("#FF6A3D"), "wind": Color("#3DDBB5"), "lightning": Color("#FFD93D"),
	"light": Color("#FFF2B8"), "dark": Color("#A855F7"), "earth": Color("#D99A3E"),
}

# --- Thẻ nhân vật trên sân (góc trên-trái) ---
const ACTIVE_CARD_POS := Vector2(40.0, 36.0)
const ACTIVE_CARD_SIZE := Vector2(520.0, 132.0)
const BAR_WIDTH := 380.0
## Nút Tạm dừng (vùng chạm ≥ 128 px).
const PAUSE_BUTTON_SIZE := 132.0
const HP_BAR_HEIGHT := 22.0
const SMALL_BAR_HEIGHT := 12.0

const COLOR_PANEL := Color(0.06, 0.07, 0.11, 0.72)
const COLOR_HP := Color("#E5484D")
const COLOR_HP_LOW := Color("#FF8A4D")
const COLOR_SHIELD := Color("#9FD8FF")
const COLOR_EN := Color("#4DA3FF")
const COLOR_UG := Color("#FFD93D")
const COLOR_BAR_BACK := Color(0, 0, 0, 0.6)
const COLOR_COOLDOWN := Color(0, 0, 0, 0.62)
const COLOR_DOWN := Color(0.35, 0.35, 0.38)


static func ring_color(element: String) -> Color:
	return RING_COLOR.get(element, Color.WHITE)
