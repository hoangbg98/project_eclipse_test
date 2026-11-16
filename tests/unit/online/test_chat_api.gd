extends GdUnitTestSuite
## Test phần chat của NakamaApi (M9-6): địa chỉ websocket, request bạn bè / thông báo / lịch sử, đọc phản hồi, gói tin websocket.


func test_ws_url() -> void:
	assert_str(NakamaApi.ws_url("http://127.0.0.1:7360", "a.b.c")).is_equal("ws://127.0.0.1:7360/ws?format=json&token=a.b.c")
	assert_str(NakamaApi.ws_url("https://x.trycloudflare.com", "t")).is_equal("wss://x.trycloudflare.com/ws?format=json&token=t")
	assert_str(NakamaApi.ws_url("http://h", "a b")).contains("token=a%20b")


func test_rest_requests() -> void:
	var f := NakamaApi.friends_list("http://h", "T")
	assert_int(f["method"]).is_equal(HTTPClient.METHOD_GET)
	assert_str(f["url"]).is_equal("http://h/v2/friend?limit=100")
	assert_bool((f["headers"] as PackedStringArray).has("Authorization: Bearer T")).is_true()
	assert_str(NakamaApi.friend_add("http://h", "T", ["u1", "u2"])["url"]).is_equal("http://h/v2/friend?ids=u1&ids=u2")
	assert_int(NakamaApi.friend_add("http://h", "T", ["u1"])["method"]).is_equal(HTTPClient.METHOD_POST)
	var rm := NakamaApi.friend_remove("http://h", "T", ["u1"])
	assert_int(rm["method"]).is_equal(HTTPClient.METHOD_DELETE)
	assert_str(rm["url"]).is_equal("http://h/v2/friend?ids=u1")
	assert_str(NakamaApi.friend_block("http://h", "T", ["u1"])["url"]).is_equal("http://h/v2/friend/block?ids=u1")
	assert_str(NakamaApi.notifications_list("http://h", "T")["url"]).is_equal("http://h/v2/notification?limit=50")
	assert_int(NakamaApi.notifications_delete("http://h", "T", ["n1"])["method"]).is_equal(HTTPClient.METHOD_DELETE)
	var h := NakamaApi.channel_history("http://h", "T", "4.a.b.", 30)
	assert_str(h["url"]).is_equal("http://h/v2/channel/4.a.b.?limit=30&forward=false")


func test_socket_packets() -> void:
	var join: Dictionary = JSON.parse_string(NakamaApi.socket_join_room("1", "world"))
	assert_dict(join["channel_join"]).contains_key_value("target", "world")
	assert_int(int(join["channel_join"]["type"])).is_equal(1)
	var dm: Dictionary = JSON.parse_string(NakamaApi.socket_join_dm("2", "user-x"))
	assert_int(int(dm["channel_join"]["type"])).is_equal(2)
	var send: Dictionary = JSON.parse_string(NakamaApi.socket_send("3", "2...world", "xin chào"))
	assert_str(send["cid"]).is_equal("3")
	assert_str(send["channel_message_send"]["channel_id"]).is_equal("2...world")
	assert_str(JSON.parse_string(send["channel_message_send"]["content"])["text"]).is_equal("xin chào")


func test_parse_friends() -> void:
	var body := '{"friends":[{"user":{"id":"u1","username":"an","online":true},"state":0},{"user":{"id":"u2","username":"binh"},"state":2}]}'
	var r := NakamaApi.parse_friends(200, body)
	assert_bool(r["ok"]).is_true()
	assert_int(r["friends"].size()).is_equal(2)
	assert_dict(r["friends"][0]).is_equal({"id": "u1", "username": "an", "state": 0, "online": true})
	assert_int(r["friends"][1]["state"]).is_equal(NakamaApi.FRIEND_INVITE_RECEIVED)
	assert_bool(NakamaApi.parse_friends(200, "{}")["ok"]).is_true()
	assert_bool(NakamaApi.parse_friends(401, '{"message":"x"}')["ok"]).is_false()


func test_message_from_and_history_order() -> void:
	var raw := {"channel_id": "2...world", "message_id": "m1", "code": 0, "sender_id": "u1", "username": "an",
			"content": '{"text":"xin chào"}', "create_time": "2026-11-16T08:48:50.088925200Z"}
	var m := NakamaApi.message_from(raw)
	assert_str(m["text"]).is_equal("xin chào")
	assert_str(m["username"]).is_equal("an")
	assert_int(m["time"]).is_equal(1794818930)
	assert_dict(NakamaApi.message_from({"code": 1, "content": '{"text":"x"}'})).is_empty()
	assert_dict(NakamaApi.message_from({"code": 0, "content": "khong-phai-json"})).is_empty()
	var newest := raw.duplicate()
	newest["message_id"] = "m2"
	var body := JSON.stringify({"messages": [newest, raw]})   # API trả mới nhất trước
	var h := NakamaApi.parse_history(200, body)
	assert_str(h["messages"][0]["id"]).is_equal("m1")
	assert_str(h["messages"][1]["id"]).is_equal("m2")


func test_parse_notifications() -> void:
	var body := JSON.stringify({"notifications": [{"id": "n1", "code": 100, "sender_id": "u1",
			"content": JSON.stringify({"from_name": "an", "text": "chào"})}]})
	var r := NakamaApi.parse_notifications(200, body)
	assert_int(r["notifications"].size()).is_equal(1)
	assert_int(r["notifications"][0]["code"]).is_equal(NakamaApi.NOTIFY_DM)
	assert_str(r["notifications"][0]["content"]["from_name"]).is_equal("an")


func test_dm_peer() -> void:
	assert_str(NakamaApi.dm_peer("4.aaa.bbb.", "aaa")).is_equal("bbb")
	assert_str(NakamaApi.dm_peer("4.aaa.bbb.", "bbb")).is_equal("aaa")
	assert_str(NakamaApi.dm_peer("4.aaa.bbb.", "ccc")).is_empty()
	assert_str(NakamaApi.dm_peer("2...world", "aaa")).is_empty()


func test_token_expiry() -> void:
	var payload := Marshalls.utf8_to_base64('{"exp":1794780000,"uid":"x"}').replace("+", "-").replace("/", "_").trim_suffix("=")
	assert_int(NakamaApi.token_expiry("h." + payload + ".s")).is_equal(1794780000)
	assert_int(NakamaApi.token_expiry("T:tester1")).is_equal(0)
	assert_int(NakamaApi.token_expiry("a.%%%.c")).is_equal(0)


func test_chat_error_keys() -> void:
	assert_str(NakamaApi.chat_error_key("Error: chat_rate at beforeChannelMessageSend")).is_equal("CHAT_ERR_RATE")
	assert_str(NakamaApi.chat_error_key("Error: chat_muted:1794780000000 at x")).is_equal("CHAT_ERR_MUTED")
	assert_str(NakamaApi.chat_error_key("chat_blocked")).is_equal("CHAT_ERR_BLOCKED")
	assert_str(NakamaApi.chat_error_key("chat_too_long")).is_equal("CHAT_ERR_TOO_LONG")
	assert_str(NakamaApi.chat_error_key("chat_empty")).is_equal("CHAT_ERR_EMPTY")
	assert_str(NakamaApi.chat_error_key("chat_not_found")).is_equal("CHAT_ERR_NOT_FOUND")
	assert_str(NakamaApi.chat_error_key("gì đó lạ")).is_equal("CHAT_ERR_SEND")
