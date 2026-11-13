class_name SwitchInDef
extends Resource
## Phần dữ liệu Kĩ năng vào sân không nằm trong SkillDef (CHARACTER_SKILLS 8.5–8.10):
## buff cho bản thân khi vào sân và cơ chế giảm SI-CD riêng. Đòn đánh nằm trong
## data/skills/{id}/switch_in.tres (Thường) và switch_in_linked.tres (Liên kết).

const REDUCE_NONE := ""
## Mỗi kẻ địch đang Choáng trúng đòn vào sân (Aether).
const REDUCE_STUNNED_HIT := "stunned_target_hit"
## Né hoàn hảo trong cửa sổ sau khi vào sân (Lyra).
const REDUCE_PERFECT_DODGE := "perfect_dodge"
## Bùng nổ Sét (Dấu Sét đủ tầng do mình gây) trong cửa sổ sau khi vào sân (Kael).
const REDUCE_LIGHTNING_BURST := "lightning_burst"
## Hồi máu cho nhân vật dưới 50% HP trong cửa sổ sau khi vào sân (Hikarine; LightKit phát kit_event).
const REDUCE_HEAL_LOW := "heal_low_hp"
## Hạ gục kẻ địch mang Nguyền trong cửa sổ sau khi vào sân (Yomigari; DarkKit).
const REDUCE_CURSED_KILL := "cursed_kill"
## Chặn hoàn hảo trong cửa sổ sau khi vào sân (Iwagane; EarthKit).
const REDUCE_PERFECT_BLOCK := "perfect_block"

## Trạng thái áp lên bản thân khi vào sân (on_self không cần; luôn áp cho người vào sân).
@export var self_statuses_normal: Array[StatusApplication] = []
@export var self_statuses_linked: Array[StatusApplication] = []

@export_group("Giảm SI-CD")
## Cơ chế: "" (không), "stunned_target_hit", "perfect_dodge", "lightning_burst" (hằng REDUCE_*).
@export var reduce_on := ""
## Giây trừ mỗi lần.
@export var reduce_sec := 0.0
## Tối đa mỗi chu kỳ SI-CD.
@export var reduce_max_per_cycle_sec := 0.0
## Chỉ tính trong bấy nhiêu giây sau khi vào sân (0 = chỉ đòn vào sân).
@export var reduce_window_sec := 0.0
## Khoảng chờ giữa hai lần giảm.
@export var reduce_icd_sec := 0.0
