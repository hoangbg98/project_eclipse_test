extends GdUnitTestSuite
## Test NakamaApi (M9-1): chuẩn hóa địa chỉ, dựng request đăng nhập / RPC, đọc kết quả và lỗi.


func test_normalize_url() -> void:
	assert_str(NakamaApi.normalize_url("  http://127.0.0.1:7350/ ")).is_equal("http://127.0.0.1:7350")
	assert_str(NakamaApi.normalize_url("127.0.0.1:7350")).is_equal("http://127.0.0.1:7350")
	assert_str(NakamaApi.normalize_url("localhost:7350")).is_equal("http://localhost:7350")
	assert_str(NakamaApi.normalize_url("192.168.1.5:7350")).is_equal("http://192.168.1.5:7350")
	assert_str(NakamaApi.normalize_url("abc-def.trycloudflare.com/")).is_equal("https://abc-def.trycloudflare.com")
	assert_str(NakamaApi.normalize_url("https://abc.trycloudflare.com//")).is_equal("https://abc.trycloudflare.com")
	assert_str(NakamaApi.normalize_url("   ")).is_equal("")


func test_authenticate_device_request() -> void:
	var r := NakamaApi.authenticate_device("http://127.0.0.1:7350", "eclipse-test-key", "0123456789abcdef")
	assert_int(r["method"]).is_equal(HTTPClient.METHOD_POST)
	assert_str(r["url"]).is_equal("http://127.0.0.1:7350/v2/account/authenticate/device?create=true")
	# "eclipse-test-key:" base64
	assert_bool((r["headers"] as PackedStringArray).has("Authorization: Basic ZWNsaXBzZS10ZXN0LWtleTo=")).is_true()
	assert_dict(JSON.parse_string(r["body"])).is_equal({"id": "0123456789abcdef"})


func test_rpc_request_wraps_payload_as_json_string() -> void:
	var r := NakamaApi.rpc("https://x.trycloudflare.com", "TOKEN", "eclipse_profile", {"a": "x"})
	assert_str(r["url"]).is_equal("https://x.trycloudflare.com/v2/rpc/eclipse_profile")
	assert_bool((r["headers"] as PackedStringArray).has("Authorization: Bearer TOKEN")).is_true()
	var inner: Variant = JSON.parse_string(r["body"])
	assert_bool(inner is String).is_true()
	assert_dict(JSON.parse_string(inner)).is_equal({"a": "x"})


func test_parse_session() -> void:
	var ok := NakamaApi.parse_session(200, '{"created":true,"token":"T","refresh_token":"R"}')
	assert_bool(ok["ok"]).is_true()
	assert_str(ok["token"]).is_equal("T")
	assert_bool(ok["created"]).is_true()
	var bad := NakamaApi.parse_session(401, '{"code":16,"message":"Server key invalid"}')
	assert_bool(bad["ok"]).is_false()
	assert_str(bad["error"]).is_equal("Server key invalid")
	assert_str(NakamaApi.parse_session(0, "")["error"]).is_equal("HTTP 0")


func test_parse_rpc_payload_and_module_error() -> void:
	var body := JSON.stringify({"payload": JSON.stringify({"code": "32354120", "wallet": {"gems": 600}})})
	var r := NakamaApi.parse_rpc(200, body)
	assert_bool(r["ok"]).is_true()
	assert_str(r["data"]["code"]).is_equal("32354120")
	assert_int(int(r["data"]["wallet"]["gems"])).is_equal(600)
	var e := NakamaApi.parse_rpc(500, '{"code":13,"message":"Error: cần đăng nhập at rpcProfile (index.js:98:11(5))"}')
	assert_bool(e["ok"]).is_false()
	assert_str(e["error"]).is_equal("cần đăng nhập")


func test_format_code_and_device_id() -> void:
	assert_str(NakamaApi.format_code("32354120")).is_equal("3235 4120")
	assert_str(NakamaApi.format_code("123")).is_equal("123")
	assert_bool(NakamaApi.valid_device_id("short")).is_false()
	assert_bool(NakamaApi.valid_device_id("0123456789abcdef0123456789abcdef")).is_true()


func test_account_requests() -> void:
	var reg := NakamaApi.register_account("http://h", "k", "tester_1", "a@b.vn", "matkhau123")
	assert_str(reg["url"]).is_equal("http://h/v2/account/authenticate/email?create=true&username=tester_1")
	assert_dict(JSON.parse_string(reg["body"])).is_equal({"email": "a@b.vn", "password": "matkhau123"})
	var by_name := NakamaApi.login_account("http://h", "k", " tester_1 ", "matkhau123")
	assert_str(by_name["url"]).is_equal("http://h/v2/account/authenticate/email?create=false&username=tester_1")
	assert_dict(JSON.parse_string(by_name["body"])).is_equal({"password": "matkhau123"})
	var by_email := NakamaApi.login_account("http://h", "k", "a@b.vn", "matkhau123")
	assert_str(by_email["url"]).is_equal("http://h/v2/account/authenticate/email?create=false")
	var rf := NakamaApi.refresh_session("http://h", "k", "RT")
	assert_str(rf["url"]).is_equal("http://h/v2/account/session/refresh")
	assert_dict(JSON.parse_string(rf["body"])).is_equal({"token": "RT"})


func test_input_validation() -> void:
	assert_str(NakamaApi.username_error("tester_1")).is_empty()
	assert_str(NakamaApi.username_error("ab")).is_equal("LOGIN_ERR_USERNAME")
	assert_str(NakamaApi.username_error("có dấu")).is_equal("LOGIN_ERR_USERNAME")
	assert_str(NakamaApi.username_error("a".repeat(21))).is_equal("LOGIN_ERR_USERNAME")
	assert_str(NakamaApi.email_error(" a@b.vn ")).is_empty()
	assert_str(NakamaApi.email_error("a@b")).is_equal("LOGIN_ERR_EMAIL")
	assert_str(NakamaApi.password_error("matkhau123", "matkhau123")).is_empty()
	assert_str(NakamaApi.password_error("1234567", "1234567")).is_equal("LOGIN_ERR_PASSWORD_SHORT")
	assert_str(NakamaApi.password_error("matkhau123", "matkhau12")).is_equal("LOGIN_ERR_PASSWORD_MISMATCH")
