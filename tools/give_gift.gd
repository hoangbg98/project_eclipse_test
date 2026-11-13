extends SceneTree
## Gửi quà thử nghiệm vào save từ dòng lệnh (owner 2026-11-14). Dùng qua tools/give_gift.ps1:
##   powershell -ExecutionPolicy Bypass -File tools\give_gift.ps1 gems=5000 equip:all preset:level_up
##   powershell -ExecutionPolicy Bypass -File tools\give_gift.ps1 --list
## Logic nằm ở DebugGift.run_args (có test). ĐÓNG GAME trước khi chạy: game đang mở sẽ ghi đè save khi thoát.


func _initialize() -> void:
	TranslationServer.set_locale("vi")
	var res := DebugGift.run_args(OS.get_cmdline_user_args())
	for line in res["lines"]:
		print(line)
	quit(int(res["code"]))
