class_name TopupScreen
extends Control
## Màn Nạp (M9-2): bảng giá (lấy từ máy chủ nên đổi giá không cần build lại), gói còn thưởng nạp lần đầu, thẻ tháng, và phần
## thanh toán: mã QR chuyển khoản (VietQr, vẽ ngay trong game) + thông tin tài khoản nhận tiền + nội dung chuyển khoản có mã
## người chơi. Người chơi chuyển khoản, QTV xác nhận và phát gói (server\grant.ps1); màn tự kiểm tra mỗi 20 giây và báo
## khi nhận được. Màn chỉ gọi OnlineService; không chứa luật.

const POLL_SEC := 20.0
const QR_PX := 8

## Test gán OnlineService giả; null = autoload.
var service: Node
## false: không chuyển scene thật (test).
var navigate := true
## Kết quả topup_info gần nhất.
var info: Dictionary = {}
var selected_pack := ""
## Thông báo gần nhất (đã nhận Ngọc, đã chép...).
var toast_text := ""

var _pack_buttons: Dictionary = {}
var _group := ButtonGroup.new()
var _wallet: Label
var _toast: Label
var _status: Label
var _packs_box: VBoxContainer
var _pay_box: VBoxContainer
var _qr: TextureRect
var _pay_title: Label
var _pay_lines: VBoxContainer
var _card_status: Label
var _claim: Button
var _log_box: VBoxContainer
var _locked: VBoxContainer
var _content: HBoxContainer
var _timer: Timer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if service == null:
		service = UiKit.autoload("OnlineService")
	_build()
	if service:
		service.purchased_applied.connect(_on_purchased)
	_timer = Timer.new()
	_timer.wait_time = POLL_SEC
	_timer.timeout.connect(func() -> void: refresh())
	add_child(_timer)
	_timer.start()
	refresh()


# ---------- Dữ liệu ----------

func usable() -> bool:
	return service != null and service.is_online()


## Lấy lại bảng giá + ví từ máy chủ rồi vẽ lại. Trả về true nếu thành công.
func refresh() -> bool:
	_locked.visible = not usable()
	_content.visible = usable()
	if not usable():
		return false
	var r: Dictionary = await service.topup_info()
	if not r["ok"]:
		_status.text = tr("TOPUP_ERR_LOAD") % tr(str(r["error"]))
		return false
	_status.text = ""
	info = r["data"]
	await service.refresh_profile()   # ví mới (QTV vừa phát) → cộng vào save
	if selected_pack.is_empty() or _pack(selected_pack).is_empty():
		selected_pack = _first_sellable()
	_rebuild()
	return true


func catalog() -> Dictionary:
	var c: Variant = info.get("catalog")
	return c if c is Dictionary else {}


func packs() -> Array:
	return catalog().get("packs", [])


func _pack(id: String) -> Dictionary:
	for p: Dictionary in packs():
		if p["id"] == id:
			return p
	return {}


func _first_sellable() -> String:
	for p: Dictionary in packs():
		if p.get("price") != null:
			return str(p["id"])
	return ""


func is_first_bonus(id: String) -> bool:
	return bool(info.get("eligible", {}).get(id, false))


func select_pack(id: String) -> void:
	if _pack(id).is_empty() or _pack(id).get("price") == null:
		return
	selected_pack = id
	_rebuild_payment()
	for k: String in _pack_buttons:
		(_pack_buttons[k] as Button).button_pressed = k == id


## Nhận quà thẻ tháng hôm nay. Trả về khóa lỗi ("" = thành công).
func claim_card() -> String:
	var r: Dictionary = await service.card_claim()
	if not r["ok"]:
		var err := str(r["error"])
		if err.contains("card_claimed_today"):
			_toast.text = tr("TOPUP_ERR_CARD_TODAY")
		elif err.contains("card_none"):
			_toast.text = tr("TOPUP_ERR_CARD_NONE")
		else:
			_toast.text = tr("TOPUP_ERR_LOAD") % tr(err)
		return err
	var d: Dictionary = r["data"]
	toast_text = tr("TOPUP_CARD_CLAIMED") % [int(d["gems"])]
	_toast.text = toast_text
	await refresh()
	return ""


func _on_purchased(gems: int) -> void:
	toast_text = (tr("TOPUP_RECEIVED") % gems) if gems > 0 else tr("TOPUP_REVOKED") % -gems
	_toast.text = toast_text
	_update_wallet()


# ---------- Thanh toán ----------

## Chuỗi QR + các dòng thông tin cho gói `id`: {amount, memo, payload, bank_name, account, account_name}.
func payment_for(id: String) -> Dictionary:
	var pay: Dictionary = catalog().get("payment", {})
	var pack := _pack(id)
	if pack.is_empty() or pack.get("price") == null or pay.is_empty():
		return {}
	var memo := ("%s %s" % [pay.get("memo_prefix", "ECL"), str(info.get("code", ""))]).strip_edges()
	var amount := int(pack["price"])
	return {"amount": amount, "memo": memo, "bank_name": str(pay.get("bank_name", "")), "account": str(pay.get("account_number", "")),
			"account_name": str(pay.get("account_name", "")),
			"payload": VietQr.payload(str(pay.get("bank_bin", "")), str(pay.get("account_number", "")), amount, memo)}


static func money(vnd: int) -> String:
	var s := str(vnd)
	var out := ""
	for i in s.length():
		if i > 0 and (s.length() - i) % 3 == 0:
			out += "."
		out += s[i]
	return out + "đ"


func pack_title(p: Dictionary) -> String:
	if p["kind"] == "card":
		return tr("TOPUP_CARD_NAME")
	return "%d %s" % [int(p["amount"]), tr("CURRENCY_" + str(p["currency"]).to_upper())]


# ---------- Vẽ ----------

func _rebuild() -> void:
	_rebuild_packs()
	_rebuild_card()
	_rebuild_log()
	_rebuild_payment()
	_update_wallet()


func _update_wallet() -> void:
	if service == null:
		return
	var save: Node = service.current_saves()
	var gems := int(save.data["currencies"].get("gems", 0)) if save else 0
	_wallet.text = "%s %d   ·   %s %d" % [tr("CURRENCY_GEMS"), gems, tr("CURRENCY_CORONA"), service.wallet_amount("corona")]


func _rebuild_packs() -> void:
	for c in _packs_box.get_children():
		_packs_box.remove_child(c)
		c.queue_free()
	_pack_buttons.clear()
	for group: Array in [["gems", "TOPUP_GEMS_PACKS"], ["corona", "TOPUP_CORONA_PACKS"]]:
		var list: Array = packs().filter(func(p: Dictionary) -> bool: return p.get("currency", "") == group[0])
		if list.is_empty():
			continue
		_packs_box.add_child(UiKit.label(tr(group[1]), 30))
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 14)
		_packs_box.add_child(grid)
		for p: Dictionary in list:
			grid.add_child(_pack_button(p))


func _pack_button(p: Dictionary) -> Button:
	var id := str(p["id"])
	var b := Button.new()
	b.name = "Pack_" + id
	b.toggle_mode = true
	b.button_group = _group
	b.custom_minimum_size = Vector2(320, 150)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var text := "%s\n%s" % [pack_title(p), money(int(p["price"]))] if p.get("price") != null else pack_title(p)
	if is_first_bonus(id):
		text += "\n" + tr("TOPUP_FIRST_BONUS") % int(p["amount"])
	b.text = text
	b.add_theme_font_size_override("font_size", 28)
	b.button_pressed = id == selected_pack
	b.pressed.connect(select_pack.bind(id))
	_pack_buttons[id] = b
	return b


func _rebuild_card() -> void:
	var card: Dictionary = info.get("card", {})
	var cd: Dictionary = catalog().get("card", {})
	var left := int(card.get("claims_left", 0))
	var text := tr("TOPUP_CARD_RULES") % [int(cd.get("days", 30)), int(cd.get("daily", 30)), int(cd.get("milestone_every", 15)),
			int(cd.get("milestone_bonus", 500))]
	text += "\n" + (tr("TOPUP_CARD_LEFT") % [left, int(card.get("claims_total", 0))] if left > 0 else tr("TOPUP_CARD_NONE"))
	_card_status.text = text
	_claim.disabled = not bool(card.get("can_claim", false))
	_claim.text = tr("TOPUP_CARD_CLAIM") % int(card.get("next_gems", 0)) if bool(card.get("can_claim", false)) \
			else (tr("TOPUP_CARD_DONE_TODAY") if left > 0 else tr("TOPUP_CARD_CLAIM_NONE"))


func _rebuild_log() -> void:
	for c in _log_box.get_children():
		_log_box.remove_child(c)
		c.queue_free()
	var log: Array = info.get("log", [])
	if log.is_empty():
		_log_box.add_child(UiKit.label(tr("TOPUP_LOG_EMPTY"), 24))
		return
	for e: Dictionary in log.slice(0, 5):
		var d := Time.get_datetime_dict_from_unix_time(int(e["t"]) + int(Time.get_time_zone_from_system().get("bias", 0)) * 60)
		var pack := _pack(str(e["pack"]))
		var what := pack_title(pack) if not pack.is_empty() else str(e["pack"])
		var extra := " (+%d)" % int(e["bonus"]) if int(e.get("bonus", 0)) > 0 else ""
		_log_box.add_child(UiKit.label("%02d/%02d %02d:%02d   %s%s" % [d.day, d.month, d.hour, d.minute, what, extra], 24))


func _rebuild_payment() -> void:
	for c in _pay_lines.get_children():
		_pay_lines.remove_child(c)
		c.queue_free()
	var pay := payment_for(selected_pack)
	_qr.visible = not pay.is_empty()
	if pay.is_empty():
		_pay_title.text = tr("TOPUP_PICK_PACK")
		return
	_pay_title.text = "%s — %s" % [pack_title(_pack(selected_pack)), money(int(pay["amount"]))]
	var qr := QrCode.encode_text(str(pay["payload"]), QrCode.Ecc.MEDIUM)
	if qr:
		_qr.texture = ImageTexture.create_from_image(qr.to_image(QR_PX, 4))
	for row: Array in [["Bank", tr("TOPUP_BANK"), str(pay["bank_name"]), ""],
			["Account", tr("TOPUP_ACCOUNT"), str(pay["account"]), str(pay["account"])],
			["Owner", tr("TOPUP_OWNER"), str(pay["account_name"]), ""],
			["Amount", tr("TOPUP_AMOUNT"), money(int(pay["amount"])), str(pay["amount"])],
			["Memo", tr("TOPUP_MEMO"), str(pay["memo"]), str(pay["memo"])]]:
		_pay_lines.add_child(_pay_row(row))


func _pay_row(row: Array) -> Control:
	var box := UiKit.hbox(12)
	var cap := UiKit.label(str(row[1]), 24)
	cap.custom_minimum_size.x = 190
	cap.autowrap_mode = TextServer.AUTOWRAP_OFF
	box.add_child(cap)
	var val := UiKit.label(str(row[2]), 30)
	val.name = "Pay" + str(row[0])
	val.autowrap_mode = TextServer.AUTOWRAP_OFF
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(val)
	if str(row[3]) != "":
		var copy := UiKit.button(tr("TOPUP_COPY"), 130.0, 24)
		copy.name = "Copy" + str(row[0])
		copy.custom_minimum_size.y = 56.0
		copy.pressed.connect(func() -> void:
			DisplayServer.clipboard_set(str(row[3]))
			_toast.text = tr("TOPUP_COPIED"))
		box.add_child(copy)
	return box


func _go_back() -> void:
	var router := UiKit.autoload("SceneRouter")
	if navigate and router:
		router.go_back()


func _login() -> void:
	var router := UiKit.autoload("SceneRouter")
	if navigate and router:
		router.replace(GameConfig.SCENE_LOGIN)


# ---------- Dựng khung ----------

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#1B1E2B")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 70)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	add_child(margin)
	var root := UiKit.vbox(14)
	margin.add_child(root)

	var head := UiKit.hbox(20)
	var title := UiKit.label(tr("SUPPLY_TOPUP_TITLE"), UiKit.FONT_TITLE)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(title)
	_wallet = UiKit.label("", 34)
	_wallet.name = "Wallet"
	_wallet.autowrap_mode = TextServer.AUTOWRAP_OFF
	_wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_wallet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_wallet)
	var back := UiKit.button(tr("UI_BACK"), 220.0, 30)
	back.name = "BackButton"
	back.custom_minimum_size.y = 72.0
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_go_back)
	head.add_child(back)
	root.add_child(head)

	_status = UiKit.label("", 24)
	_status.name = "Status"
	_status.add_theme_color_override("font_color", Color("#FF9E80"))
	root.add_child(_status)
	_toast = UiKit.label("", 28)
	_toast.name = "Toast"
	_toast.add_theme_color_override("font_color", Color("#8DFFB0"))
	root.add_child(_toast)

	_locked = UiKit.vbox(24)
	_locked.name = "LockedBox"
	_locked.add_child(UiKit.label(tr("TOPUP_NEED_LOGIN"), 34))
	var login := UiKit.button(tr("ONLINE_OPEN_LOGIN"), 480.0, 30)
	login.name = "LoginButton"
	login.custom_minimum_size.y = 96.0
	login.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	login.pressed.connect(_login)
	_locked.add_child(login)
	root.add_child(_locked)

	_content = UiKit.hbox(28)
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_content)

	# Trái: gói, thẻ tháng, lịch sử.
	var left := UiKit.vbox(16)
	_packs_box = UiKit.vbox(12)
	_packs_box.name = "Packs"
	left.add_child(_packs_box)
	left.add_child(UiKit.label(tr("TOPUP_CARD_TITLE"), 30))
	_card_status = UiKit.label("", 24)
	_card_status.name = "CardStatus"
	left.add_child(_card_status)
	_claim = UiKit.button("", 420.0, 28)
	_claim.name = "ClaimButton"
	_claim.custom_minimum_size.y = 80.0
	_claim.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_claim.pressed.connect(claim_card)
	left.add_child(_claim)
	left.add_child(UiKit.label(tr("TOPUP_LOG_TITLE"), 30))
	_log_box = UiKit.vbox(6)
	_log_box.name = "Log"
	left.add_child(_log_box)
	var scroll := UiKit.scroll(left)
	scroll.size_flags_stretch_ratio = 1.5
	_content.add_child(scroll)

	# Phải: thanh toán.
	_pay_box = UiKit.vbox(12)
	_pay_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pay_title = UiKit.label("", 34)
	_pay_title.name = "PayTitle"
	_pay_box.add_child(_pay_title)
	_qr = TextureRect.new()
	_qr.name = "QrImage"
	_qr.custom_minimum_size = Vector2(360, 360)
	_qr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_qr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_qr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_qr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_pay_box.add_child(_qr)
	_pay_lines = UiKit.vbox(8)
	_pay_lines.name = "PayLines"
	_pay_box.add_child(_pay_lines)
	_pay_box.add_child(UiKit.label(tr("TOPUP_HOW"), 22))
	var refresh_btn := UiKit.button(tr("ONLINE_REFRESH"), 320.0, 28)
	refresh_btn.name = "RefreshButton"
	refresh_btn.custom_minimum_size.y = 72.0
	refresh_btn.pressed.connect(func() -> void: refresh())
	_pay_box.add_child(refresh_btn)
	var pay_panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#232838")
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(24)
	pay_panel.add_theme_stylebox_override("panel", sb)
	pay_panel.add_child(UiKit.scroll(_pay_box))   # cuộn được khi màn thấp
	pay_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(pay_panel)
