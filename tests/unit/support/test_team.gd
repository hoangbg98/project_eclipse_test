class_name TestTeam
extends RefCounted
## Dữ liệu test: save mới kèm đội 3 người cũ (Enkiba, Raikiba, Kazeyumi). Từ 2026-11-14 game mới chỉ có Enkiba;
## các test viết trước đó cần đủ đội 3 người thì dùng hàm này thay cho SaveSchema.default_data().


static func three() -> Dictionary:
	var d := SaveSchema.default_data()
	for id in ["char_lightning_01", "char_wind_01"]:
		d["characters"][id] = SaveSchema.default_character()
	d["party"] = ["char_fire_01", "char_lightning_01", "char_wind_01"]
	return d
