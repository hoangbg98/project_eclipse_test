# Bộ kỹ năng 6 nhân vật — Project Eclipse

*Bản đề xuất v1. Tên nhân vật và tên chiêu là tên tạm. Mọi số liệu là giá trị khởi điểm để đưa vào file config, chỉnh lại sau khi chơi thử.*

**Cập nhật cấu trúc:** từ bản này chỉ có 1 nhân vật tham chiến. Hai nhân vật còn lại là dự bị, hiện thành icon ở góc trên bên phải và không hành động. **Mục 8 ghi đè** mọi chỗ ở mục 0–7 nhắc đến AI dự bị, đồng đội cùng sân hoặc nạp UG 50% cho dự bị.

## 0. Quy ước chung

### Đơn vị và pha đòn

- 1 thân người = 256 px (khung nhân vật ở README 2.2). Khoảng cách tính bằng px ở viewport 1920×1080. Thời gian tính bằng ms.
- Mỗi đòn có 3 pha: **Khởi động** (chưa gây sát thương) / **Hiệu lực** (hitbox bật theo track AnimationPlayer) / **Hồi phục** (nửa sau có thể hủy bằng né).
- Sát thương tính theo % ATK của người dùng ở cấp kỹ năng 1, tăng khoảng +6% mỗi cấp (chỉnh trong config). Hồi máu = % ATK + % HP tối đa của mục tiêu.
- **SC** là sức choáng: mỗi đòn mặc định gây SC bằng % ATK của đòn. Ghi chú ×1.5 hoặc ×2 là hệ số nhân. Thanh SC của kẻ địch đầy thì bị Choáng.
- **Khựng** là kẻ địch giật lùi ngắn khi bị đánh (boss kháng). **Kháng khựng** là không bị khựng khi nhận đòn.
- **ICD** là thời gian chờ nội bộ giữa hai lần kích hoạt của cùng một hiệu ứng.

### Tài nguyên

| Tài nguyên | Giá trị | Cách nạp |
| --- | --- | --- |
| EN (Năng lượng) | 0–100 | +2 mỗi giây. +3 mỗi đòn thường, giữ, trên không, đáp đất trúng mục tiêu |
| UG (Tuyệt kỹ) | 0–100 | +2 mỗi đòn thường trúng, +10 khi Kĩ năng thường trúng, +15 khi Kĩ năng vũ khí trúng, +0.3 mỗi 1% HP tối đa bị mất. Nhân vật dự bị nhận 50% |
| DG (Lượt né) | 2 lượt | Hồi 1 lượt mỗi 4.0s |

### Hồi chiêu

- **CDR** (chỉ số giảm hồi chiêu) tối đa 40%. Áp dụng cho Kĩ năng thường, Kĩ năng vũ khí và hồi lượt né. Không áp dụng cho Tuyệt kỹ: Tuyệt kỹ dùng UG, nên rút ngắn bằng cách nạp UG nhanh hơn.
- Mỗi nhân vật có thêm cơ chế **rút ngắn CD riêng** (trừ thẳng thời gian còn lại). Cơ chế này không bị trần 40% giới hạn, nhưng mỗi cơ chế có mức tối đa cho mỗi chu kỳ hồi để tránh lặp vô hạn.

### Né hoàn hảo

Né trong 150 ms trước khi đòn trúng: kẻ địch chậm 30% trong 0.6s, hoàn lại 1 lượt né, và kích hoạt hiệu ứng riêng của nhân vật. ICD 1.0s.

### Trạng thái dùng chung

| Trạng thái | Hiệu ứng |
| --- | --- |
| Cháy | 4s, tick mỗi 0.5s, 8% ATK mỗi tick. Làm mới thời gian, không cộng dồn |
| Chậm X% | Giảm X% tốc độ di chuyển |
| Dấu Sét | Tối đa 3 tầng mỗi mục tiêu, tồn tại 6s. Đủ 3 tầng thì Bùng nổ Sét |
| Phán quyết | Mục tiêu nhận thêm 8% sát thương từ mọi nguồn |
| Nguyền | −15% DEF |
| Giáp Địa | Giảm sát thương nhận (mức ghi ở từng kỹ năng), kháng khựng |
| Trói | Không di chuyển được (vẫn tấn công) |
| Choáng | Mất hành động 2.0s (boss 1.0s), sau đó kháng Choáng 8s |

### Loại tuyệt kỹ

- **Chuỗi đòn** (Aether, Kael, Noctis, Terra): nhân vật bất tử từ cut-in đến hết hiệu lực và không thể chuyển nhân vật.
- **Vùng/hỗ trợ** (Lyra, Seraphine): sau khi cast xong có thể chuyển nhân vật ngay, hiệu ứng vẫn chạy.

### Khóa dữ liệu và ngân sách frame

- ID kỹ năng = `{id nhân vật}.{khóa}`, dùng ID trung tính trong README, không dùng tên hiển thị. Khóa: `normal`, `dodge`, `passive`, `hold`, `air`, `landing`, `skill`, `weapon`, `ultimate`.
- Kĩ năng vũ khí gắn với loại vũ khí. Nếu sau này cho đổi vũ khí (OD-5), kỹ năng này đi theo vũ khí.
- Số frame ở mục Animation chỉ là gợi ý (24 fps cho đòn đánh). Số frame thật bạn gửi, timing sẽ chỉnh theo. Tổng gợi ý: 75–104 frame đòn mỗi nhân vật, cộng 42 frame cơ bản (idle 6, run 8, nhảy 3, rơi 3, đáp 3, bị thương 3, bật lùi 3, ngã 6, vào sân 4, ra sân 3) = 117–146, dưới trần 150 ở README 2.2. VFX và ảnh cut-in vẽ riêng, không tính vào trần.

## 1. Aether — Hỏa · Main DPS · Kiếm

*Đánh nhanh, đốt cháy mục tiêu, tích Nhiệt để tung kỹ năng mạnh hơn.*

### Tấn công thường — Hỏa Trảm (4 đòn)

- **Tiêu hao / Hồi chiêu:** không / không. Nối đòn nếu bấm trong 260 ms cuối pha hồi phục, chuỗi reset sau 0.8s.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** cung 120° phía trước, 140 px. Đòn 4 thêm sóng lửa 220×90 px bay 220 px.
- **Hiệu lực & sát thương:** 70% / 75% / 85% / 125% = 355% ATK (đòn 4: kiếm 85% + sóng 40%).
- **Hiệu ứng:** mỗi đòn tiến 40 px. Đòn 3 đẩy lùi 60 px. Đòn 4 áp Cháy 3s, SC ×1.5.
- **Động tác & animation:** Đ1 chém ngang phải sang trái. Đ2 hất ngược từ dưới lên. Đ3 xoay người đâm thẳng. Đ4 nhảy nhẹ bổ dọc, lưỡi kiếm xẻ sóng lửa trên mặt đất. Vệt kiếm cam, tia lửa nhỏ. ≈ 6 frame mỗi đòn, đòn 4 ≈ 8.
- **Timing (khởi động / hiệu lực / hồi phục):** Đ1 90/70/160. Đ2 90/70/160. Đ3 110/80/190. Đ4 160/120/320.

### Né tránh — Lướt Lửa

- **Tiêu hao / Hồi chiêu:** 1 lượt né / hồi 4.0s mỗi lượt.
- **Giảm hồi chiêu:** CDR chung.
- **Tầm & phạm vi:** lướt 280 px theo hướng đang di chuyển (hoặc hướng mặt).
- **Hiệu lực & sát thương:** vệt lửa dọc đường lướt tồn tại 0.8s, gây 25% ATK mỗi 0.4s cho kẻ địch chạm vào.
- **Hiệu ứng:** bất tử 40–220 ms. Né hoàn hảo — Hơi Nóng: đòn thường kế tiếp trong 3s +30% sát thương và áp Cháy 3s.
- **Động tác & animation:** nghiêng người về trước, lao vút, tóc và áo bay, vệt lửa cam phía sau, trượt chân dừng lại. ≈ 5 frame.
- **Timing:** 40/180/120.

### Bị động — Lửa Bùng Cháy

- **Tiêu hao / Hồi chiêu:** không / ICD 0.3s mỗi lần cộng tầng.
- **Giảm hồi chiêu:** đạt 5 tầng Nhiệt: −1.0s CD Kĩ năng thường (ICD 6s).
- **Tầm & phạm vi:** chỉ tác động lên Aether.
- **Hiệu lực & sát thương:** mỗi lần gây sát thương lên mục tiêu đang Cháy: +1 tầng Nhiệt (tối đa 5, tồn tại 6s, làm mới). Mỗi tầng +4% ATK (tối đa +20%).
- **Hiệu ứng:** ở 5 tầng, Kĩ năng thường hoặc Kĩ năng vũ khí kế tiếp +25% sát thương và tiêu hết tầng.
- **Động tác & animation:** không có. Gợi ý hiển thị: hạt lửa nhỏ quanh kiếm theo từng tầng, ở 5 tầng viền kiếm sáng trắng-cam và tóc bốc lửa nhẹ.
- **Timing:** —

### Nhấn giữ TC — Liệt Hỏa Tích Lực

- **Tiêu hao / Hồi chiêu:** không (+6 EN nếu trúng) / 1.0s sau khi nhả.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** Cấp 1: hất chém 180 px, cung 120°. Cấp 2: sóng chém 320×140 px bay 320 px.
- **Hiệu lực & sát thương:** giữ ≥ 400 ms để bắt đầu nạp (nhả sớm hơn = đòn thường). Cấp 1 tại 700 ms: 160% ATK. Cấp 2 tại 1500 ms: 280% ATK.
- **Hiệu ứng:** khi nạp, di chuyển chậm 40%. Cấp 1: khựng, SC ×1.5. Cấp 2: kháng khựng khi nhả, áp Cháy 4s, SC ×2.
- **Động tác & animation:** hạ thấp người, kiếm kéo ra sau, vòng lửa cam quanh chân (cấp 1) rồi chuyển trắng-vàng (cấp 2). Nhả: bước dài chém từ dưới lên. ≈ 4 frame nạp lặp + 8 frame chém.
- **Timing:** nhả Cấp 1 120/100/340. Cấp 2 160/140/420.

### TC trên không — Phi Trảm (2 đòn)

- **Tiêu hao / Hồi chiêu:** không (+3 EN mỗi đòn trúng) / tối đa 2 đòn mỗi lần nhảy.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** 150 px, cung 140° hơi chếch xuống.
- **Hiệu lực & sát thương:** 65% / 90% = 155% ATK.
- **Hiệu ứng:** đòn 2 đẩy kẻ địch xuống 30°. Aether treo không 150 ms sau đòn 2.
- **Động tác & animation:** Đ1 chém ngang khi lộn nhẹ. Đ2 chém chéo xuống từ trên cao, vệt lửa cung lớn. ≈ 5 frame mỗi đòn.
- **Timing:** Đ1 80/60/140. Đ2 100/80/200.

### TC đáp đất — Hỏa Trụy

- **Tiêu hao / Hồi chiêu:** không (+3 EN nếu trúng) / dùng được khi đã ra ≥ 1 đòn trên không và cao hơn mặt đất ≥ 200 px.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** kích hoạt bằng cách bấm TC khi đang rơi. Lao thẳng xuống 1400 px/s, nổ bán kính 180 px.
- **Hiệu lực & sát thương:** 140% ATK.
- **Hiệu ứng:** áp Cháy 2s, SC ×1.5. Miễn đẩy lùi trong lúc lao.
- **Động tác & animation:** mũi kiếm hướng xuống, người lao thẳng, đâm kiếm xuống đất, vòng lửa bung ra mặt đất, bụi lửa. ≈ 6 frame (lao 2, chạm đất 4).
- **Timing:** 60/120/280.

### Kĩ năng thường — Liệt Diễm Luân

- **Tiêu hao / Hồi chiêu:** 25 EN / 6.0s.
- **Giảm hồi chiêu:** mỗi đòn thường, giữ, trên không hoặc đáp đất trúng mục tiêu đang Cháy: −0.2s (tối đa −2.0s mỗi chu kỳ).
- **Tầm & phạm vi:** bán kính 200 px quanh Aether (360°).
- **Hiệu lực & sát thương:** 4 nhịp trong 600 ms: 80% × 3 + 110% (nhịp cuối) = 350% ATK.
- **Hiệu ứng:** áp Cháy 4s. Nhịp cuối đẩy lùi 120 px. Kháng khựng suốt hiệu lực. Có 5 Nhiệt: +25%.
- **Động tác & animation:** xoay người một vòng, kiếm kéo vòng lửa rộng quanh mình, nhịp cuối cắm kiếm ngang làm vòng lửa nổ. ≈ 10 frame.
- **Timing:** 120/600/260.

### Kĩ năng vũ khí — Thiên Hỏa Nhất Kích

- **Tiêu hao / Hồi chiêu:** 35 EN / 12.0s.
- **Giảm hồi chiêu:** hạ gục kẻ địch đang Cháy: −2.0s (tối đa −4.0s mỗi chu kỳ).
- **Tầm & phạm vi:** lướt xuyên 400 px theo đường thẳng, rộng 100 px. Vết chém lửa lưu lại tại đường lướt, nổ sau 1.0s bán kính 140 px.
- **Hiệu lực & sát thương:** lướt 220% ATK, vết chém nổ 130% ATK. Tổng 350%.
- **Hiệu ứng:** Nung chảy: −10% DEF 5s lên mục tiêu bị lướt trúng. Bất tử trong lúc lướt.
- **Động tác & animation:** gồng người, kiếm ngang, lao xuyên kẻ địch để lại vệt sáng cam. Dừng cuối đường lướt, tra kiếm nửa chừng, vết chém bùng nổ phía sau. ≈ 12 frame.
- **Timing:** 150/200/360, vết chém nổ sau 1000 ms.

### Tuyệt kỹ — Viêm Hoàng Tuyệt Trảm

- **Tiêu hao / Hồi chiêu:** 100 UG / không có CD, khóa 2.0s sau khi dùng.
- **Giảm hồi chiêu:** nạp UG +20% khi đang có ≥ 3 tầng Nhiệt.
- **Tầm & phạm vi:** tại mục tiêu gần nhất trong 500 px. Chém liên hoàn bán kính 350 px, nổ cuối bán kính 450 px.
- **Hiệu lực & sát thương:** 5 nhịp chém × 120% = 600%, nổ cuối 500%. Tổng 1100% ATK.
- **Hiệu ứng:** Cháy 6s. Hỏa Hoàng 8s: +20% sát thương, đòn thường thêm sóng lửa. Loại chuỗi đòn (không chuyển được).
- **Động tác & animation:** dừng thời gian 600 ms, hiện ảnh cut-in. Aether nhảy vọt, giương kiếm, lửa hóa thành phượng hoàng khổng lồ, lao xuống chém 5 nhát liên hoàn rồi nổ lớn. ≈ 18 frame + VFX riêng.
- **Timing:** cut-in 600 (dừng thời gian) / khởi động 300 / hiệu lực 1400 / hồi phục 500.

## 2. Lyra — Phong · Support · Cung

*Hỗ trợ tầm xa: bắn từ xa, làm chậm kẻ địch, tăng tốc cả đội.*

### Tấn công thường — Phong Tiễn (3 phát)

- **Tiêu hao / Hồi chiêu:** không / không. Chuỗi reset sau 0.8s.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** tên bay 1800 px/s, tối đa 700 px, tự nhắm kẻ địch gần nhất trong cung ±25°. Phát 3 xuyên tối đa 2 mục tiêu.
- **Hiệu lực & sát thương:** 55% / 55% / 90% = 200% ATK.
- **Hiệu ứng:** phát 3 áp Chậm 20% trong 2s.
- **Động tác & animation:** Lyra kéo cung đứng thẳng rồi thả tên, mỗi phát lùi nửa bước. Phát 3 kéo căng hơn, mũi tên bọc gió xanh nhạt. ≈ 5 frame mỗi phát, phát 3 ≈ 7.
- **Timing:** P1 100/40/140. P2 100/40/140. P3 180/60/260.

### Né tránh — Lộn Gió Lùi

- **Tiêu hao / Hồi chiêu:** 1 lượt né / hồi 4.0s mỗi lượt.
- **Giảm hồi chiêu:** CDR chung.
- **Tầm & phạm vi:** lộn ngược về sau 240 px, bắn 1 tên về phía trước (tầm 500 px) giữa lúc lộn.
- **Hiệu lực & sát thương:** tên bắn 40% ATK.
- **Hiệu ứng:** bất tử 30–190 ms. Né hoàn hảo — Gió Trợ Bước: +25% tốc độ di chuyển 3s, hồi 5 EN.
- **Động tác & animation:** nhún chân, lộn ngược một vòng, tóc và áo choàng tung, tên bắn ra giữa lúc lộn, tiếp đất bằng một chân. ≈ 6 frame.
- **Timing:** 30/160/110.

### Bị động — Gió Thuận

- **Tiêu hao / Hồi chiêu:** không / ICD 10s.
- **Giảm hồi chiêu:** mỗi mũi tên trúng kẻ địch đang bị Chậm: −0.3s CD Kĩ năng thường (tối đa −3.0s mỗi chu kỳ).
- **Tầm & phạm vi:** cả đội trong 800 px quanh Lyra.
- **Hiệu lực & sát thương:** khi Lyra bắn trúng 3 kẻ địch khác nhau trong 4s, cả đội nhận +10% tốc độ di chuyển và +8% tốc độ nạp EN trong 5s.
- **Hiệu ứng:** không thêm.
- **Động tác & animation:** không có. Gợi ý hiển thị: lá và gió xanh nhẹ quanh chân nhân vật trong thời gian hiệu lực.
- **Timing:** —

### Nhấn giữ TC — Xuyên Phong Tiễn

- **Tiêu hao / Hồi chiêu:** không (+6 EN nếu trúng) / 1.2s sau khi nhả.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** Cấp 1: xuyên 900 px. Cấp 2: xuyên tất cả mục tiêu trong 1200 px.
- **Hiệu lực & sát thương:** giữ ≥ 500 ms để bắt đầu nạp. Cấp 1 tại 900 ms: 180% ATK. Cấp 2 tại 1600 ms: 300% ATK.
- **Hiệu ứng:** khi nạp, di chuyển chậm 50% và hiện đường ngắm. Cấp 2: đẩy lùi 120 px, Chậm 30% trong 3s.
- **Động tác & animation:** quỳ nửa gối, kéo dây tới hết cỡ, mũi tên phát sáng xanh. Nhả tạo sóng khí hình nón sau mũi tên. ≈ 4 frame nạp lặp + 6 frame bắn.
- **Timing:** nhả 100/50/300.

### TC trên không — Thiên Phong Loạt Tiễn

- **Tiêu hao / Hồi chiêu:** không (+3 EN mỗi lần trúng) / tối đa 2 lần mỗi lần nhảy.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** quạt 3 tên chếch xuống 30° (lệch ±12°), tầm 600 px.
- **Hiệu lực & sát thương:** 45% × 3 = 135% ATK (khi cả 3 tên trúng một mục tiêu).
- **Hiệu ứng:** Lyra bật lùi 80 px và lơ lửng 200 ms.
- **Động tác & animation:** ngửa người ra sau, bắn 3 tên cùng lúc xuống đất theo hình quạt, váy và áo choàng tung lên. ≈ 6 frame.
- **Timing:** 90/90/160.

### TC đáp đất — Hạ Phong Trận

- **Tiêu hao / Hồi chiêu:** không / dùng được khi đã ra ≥ 1 đòn trên không và cao hơn mặt đất ≥ 200 px.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** bấm TC khi đang rơi. Bắn xuống đất tạo vùng gió bán kính 160 px kéo dài 1.5s, kéo kẻ địch nhẹ về tâm.
- **Hiệu lực & sát thương:** chạm đất 60% + 20% mỗi 0.5s × 3 = 120% ATK.
- **Hiệu ứng:** Chậm 35% trong vùng. Lyra đáp nhẹ, không bị khựng khi tiếp đất.
- **Động tác & animation:** giương cung chĩa xuống bắn một mũi tên dài, mũi tên cắm đất bung vòng gió xoáy xanh, Lyra rơi chậm như thả dù. ≈ 6 frame.
- **Timing:** 70 / vùng 1500 / 220.

### Kĩ năng thường — Phong Vực

- **Tiêu hao / Hồi chiêu:** 20 EN / 10.0s.
- **Giảm hồi chiêu:** mỗi tên thường trúng kẻ địch trong vùng: −0.3s (tối đa −3.0s mỗi chu kỳ).
- **Tầm & phạm vi:** bắn tên xuống đất cách 400 px phía trước, vùng bán kính 300 px, kéo dài 6s.
- **Hiệu lực & sát thương:** 20% ATK mỗi 0.5s = 240% nếu ở trong vùng đủ 6s.
- **Hiệu ứng:** đồng đội trong vùng: +15% tốc độ tấn công, +10% tốc độ di chuyển. Kẻ địch trong vùng: Chậm 20%, bị kéo nhẹ về tâm.
- **Động tác & animation:** Lyra đứng thẳng, giương cung chếch lên, bắn một tên rơi xuống như sao băng. Vòng gió xoay tròn với lá bay. ≈ 8 frame.
- **Timing:** 150/60/220, vùng tồn tại 6000.

### Kĩ năng vũ khí — Liên Châu Phong Tiễn

- **Tiêu hao / Hồi chiêu:** 35 EN / 13.0s.
- **Giảm hồi chiêu:** mỗi mục tiêu trúng đủ 6 tên: −2.0s (tối đa −4.0s mỗi chu kỳ).
- **Tầm & phạm vi:** Lyra nhảy lùi 150 px rồi bắn 6 tên trong 900 ms, tầm 800 px, hình quạt hẹp ±8°.
- **Hiệu lực & sát thương:** 60% × 6 = 360% ATK (+25% nếu mục tiêu đứng trong Phong Vực).
- **Hiệu ứng:** tên cuối đẩy lùi 100 px và Chậm 30% trong 2s.
- **Động tác & animation:** bật lùi, hạ thấp người, kéo thả liên tục, mỗi tên kéo một vệt gió. Tên cuối to hơn, nổ gió. ≈ 12 frame.
- **Timing:** 200/900/300.

### Tuyệt kỹ — Bão Tiễn Thiên Không

- **Tiêu hao / Hồi chiêu:** 100 UG / không có CD, khóa 2.0s sau khi dùng.
- **Giảm hồi chiêu:** nạp UG +20% từ đòn thường khi đứng trong Phong Vực.
- **Tầm & phạm vi:** bay lên 300 px. Bão bán kính 450 px quanh Lyra, kéo kẻ địch vào tâm 150 px/s.
- **Hiệu lực & sát thương:** 20 nhịp × 35% (mỗi 0.25s trong 5s) = 700%, nổ cuối 300%. Tổng 1000% ATK.
- **Hiệu ứng:** đồng đội trong bão 8s: +15% sát thương, +20% tốc độ di chuyển. Kẻ địch Chậm 30%. Loại vùng: sau khởi động 700 ms bất tử có thể chuyển nhân vật, Lyra vẫn giữ tư thế trên không và bắn đến hết 5s.
- **Động tác & animation:** cut-in. Lyra tung mình lên cao, gió quấn quanh, cung phát sáng xanh ngọc. Giữa bão bắn mưa tên rơi xuống, kết thúc bằng một mũi tên cực lớn nổ gió. ≈ 14 frame + VFX riêng.
- **Timing:** cut-in 500 / khởi động 700 / hiệu lực 5000 / hồi phục 400.

## 3. Kael — Lôi · Sub-DPS · Song đao

*Tốc độ cao: nhiều đòn nhanh, đánh dấu Sét lên mục tiêu rồi kích nổ.*

### Tấn công thường — Lôi Nhận Liên Hoàn (5 đòn)

- **Tiêu hao / Hồi chiêu:** không / không. Chuỗi reset sau 0.7s.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** 110 px, mỗi đòn tiến 50 px.
- **Hiệu lực & sát thương:** 45% / 45% / 55% / 55% / 110% = 310% ATK.
- **Hiệu ứng:** đòn 2, 4, 5 áp 1 Dấu Sét. Đòn 5 đẩy lùi 80 px.
- **Động tác & animation:** Đ1 chém chéo bằng đao phải. Đ2 chém ngược bằng đao trái. Đ3 hai đao cắt chữ X. Đ4 xoay người chém ngang hai đao. Đ5 nhảy lên bắt chéo bổ xuống, tia điện tóe. ≈ 4 frame mỗi đòn, đòn 5 ≈ 6.
- **Timing (khởi động / hiệu lực / hồi phục):** Đ1–Đ4 70/50/110. Đ5 130/90/260.

### Né tránh — Thiểm Điện

- **Tiêu hao / Hồi chiêu:** 1 lượt né / hồi 4.0s mỗi lượt.
- **Giảm hồi chiêu:** CDR chung.
- **Tầm & phạm vi:** dịch chuyển tức thì 320 px, xuyên kẻ địch và hiện ra sau lưng.
- **Hiệu lực & sát thương:** tia điện giữa hai điểm gây 40% ATK cho kẻ địch trên đường đi.
- **Hiệu ứng:** bất tử 20–200 ms. Né hoàn hảo — Sét Phản: nổ điện 80% ATK bán kính 150 px tại điểm xuất phát, áp 2 Dấu Sét.
- **Động tác & animation:** người nhòe thành tia sét vàng, biến mất, xuất hiện sau lưng kẻ địch trong tư thế hạ thấp, hai đao chéo sau lưng. ≈ 4 frame.
- **Timing:** 20/180/100.

### Bị động — Tích Điện Quá Tải

- **Tiêu hao / Hồi chiêu:** không / ICD 4s mỗi mục tiêu.
- **Giảm hồi chiêu:** mỗi lần Bùng nổ Sét: −1.0s CD Kĩ năng vũ khí (tối đa −3.0s mỗi chu kỳ).
- **Tầm & phạm vi:** Bùng nổ bán kính 140 px quanh mục tiêu.
- **Hiệu lực & sát thương:** mục tiêu đủ 3 Dấu Sét thì Bùng nổ Sét: 150% ATK, xóa dấu.
- **Hiệu ứng:** Bùng nổ có SC ×2. Sau mỗi Bùng nổ, Kael +10% tốc độ tấn công trong 3s.
- **Động tác & animation:** không có. Gợi ý hiển thị: mỗi Dấu Sét là một tia điện nhỏ nhấp nháy trên đầu kẻ địch (1–3 tia), tầng 3 sáng chói báo trước 200 ms rồi nổ.
- **Timing:** —

### Nhấn giữ TC — Lôi Quang Loạn Vũ

- **Tiêu hao / Hồi chiêu:** không (+1 EN mỗi nhịp trúng) / 3.0s sau khi kết thúc.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** giữ ≥ 350 ms: lao tới kẻ địch gần nhất trong 300 px rồi chém liên tục trong vùng 130 px quanh mục tiêu.
- **Hiệu lực & sát thương:** 30% ATK mỗi 150 ms, tối đa 8 nhịp (1.2s) = 240%.
- **Hiệu ứng:** áp 1 Dấu Sét mỗi 2 nhịp trúng. Thả nút để dừng sớm. Kháng khựng. Bị Choáng thì ngắt.
- **Động tác & animation:** biến thành tia sét lao tới, xoay vòng chém liên tục bằng hai đao tạo chùm tia chéo vàng, kết thúc bằng một nhát chéo xuống. ≈ 6 frame lặp + 4 frame kết thúc.
- **Timing:** khởi động 150 (lao) / hiệu lực tối đa 1200 / hồi phục 220.

### TC trên không — Phi Lôi Tam Kích (3 đòn)

- **Tiêu hao / Hồi chiêu:** không (+3 EN mỗi đòn trúng) / tối đa 3 đòn mỗi lần nhảy.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** 120 px, cung 180° quanh người.
- **Hiệu lực & sát thương:** 40% / 40% / 70% = 150% ATK.
- **Hiệu ứng:** mỗi đòn giữ Kael lơ lửng 100 ms. Đòn 3 áp 1 Dấu Sét.
- **Động tác & animation:** Đ1 và Đ2 chém chéo chữ X lúc xoay, Đ3 xoay ngang bằng hai đao. Hạt điện quanh người. ≈ 4 frame mỗi đòn.
- **Timing:** Đ1, Đ2 60/50/100. Đ3 90/70/140.

### TC đáp đất — Lôi Trụy Thuấn

- **Tiêu hao / Hồi chiêu:** không (+3 EN nếu trúng) / dùng được khi đã ra ≥ 1 đòn trên không và cao hơn mặt đất ≥ 200 px.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** bấm TC khi đang rơi. Lao chéo 45° về hướng mặt, nổ bán kính 170 px.
- **Hiệu lực & sát thương:** 130% ATK.
- **Hiệu ứng:** áp 1 Dấu Sét. Vệt điện trên mặt đất 1.0s: Chậm 20%.
- **Động tác & animation:** bắt chéo hai đao phía trước, người hóa tia vàng lao xiên xuống, chạm đất bung vòng điện. ≈ 5 frame.
- **Timing:** 50/110/240.

### Kĩ năng thường — Chớp Giật Liên Hoàn

- **Tiêu hao / Hồi chiêu:** 20 EN / 5.0s.
- **Giảm hồi chiêu:** mỗi mục tiêu bị Bùng nổ Sét: −1.0s (tối đa −3.0s mỗi chu kỳ).
- **Tầm & phạm vi:** lao thẳng 350 px, rộng 100 px, chém xuyên mọi kẻ địch trên đường.
- **Hiệu lực & sát thương:** 3 nhát × 70% = 210% ATK.
- **Hiệu ứng:** áp 2 Dấu Sét lên mọi mục tiêu bị chém. Bất tử trong lúc lao (100–450 ms).
- **Động tác & animation:** gập người, hai đao ra sau, vụt qua kẻ địch chém ba nhát nhanh để lại ba vệt vàng song song, trượt chân dừng lại. ≈ 8 frame.
- **Timing:** 100/350/200.

### Kĩ năng vũ khí — Song Lôi Phi Nhận

- **Tiêu hao / Hồi chiêu:** 30 EN / 11.0s.
- **Giảm hồi chiêu:** mỗi lưỡi đao trúng mục tiêu đang có Dấu Sét: −0.5s (tối đa −3.0s mỗi chu kỳ).
- **Tầm & phạm vi:** ném hai đao theo đường vòng cung hai bên, rộng 450 px. Bay đi 400 ms rồi quay về 400 ms.
- **Hiệu lực & sát thương:** mỗi đao mỗi lượt 50%, đi và về. Một mục tiêu bị cả hai đao ở cả hai lượt = 200% ATK.
- **Hiệu ứng:** áp 1 Dấu Sét mỗi lượt. Trong 800 ms Kael không dùng được đòn thường (vẫn di chuyển, né, dùng kỹ năng).
- **Động tác & animation:** xoay người ném hai đao ra hai hướng, đao xoay tít phát sáng vàng kéo vệt cung. Sau 400 ms đao quay lại tay như boomerang. ≈ 8 frame ném + 4 frame bắt đao.
- **Timing:** 140/800/180.

### Tuyệt kỹ — Lôi Thần Quyết

- **Tiêu hao / Hồi chiêu:** 100 UG / không có CD, khóa 2.0s sau khi dùng.
- **Giảm hồi chiêu:** mỗi Bùng nổ Sét cộng thêm 5 UG.
- **Tầm & phạm vi:** dịch chuyển tới mục tiêu gần nhất trong 600 px. Giai đoạn 2: sét đánh xuống bán kính 300 px.
- **Hiệu lực & sát thương:** 8 nhát dịch chuyển × 80% = 640%, sét đánh 450%. Tổng 1090% ATK.
- **Hiệu ứng:** mục tiêu đang có ≥ 1 Dấu Sét bị Bùng nổ ngay (+150%). Quá Tải 8s: +25% tốc độ tấn công, mọi đòn thường áp Dấu Sét. Loại chuỗi đòn.
- **Động tác & animation:** dừng thời gian, mắt Kael lóe lôi quang. Dịch chuyển nhiều điểm quanh kẻ địch chém từ mọi hướng để lại đường chéo vàng. Cuối cùng nhảy lên, hai đao chĩa lên trời hút một cột sét lớn đánh xuống. ≈ 16 frame + VFX riêng.
- **Timing:** cut-in 500 / khởi động 300 / hiệu lực 1500 (chuỗi 1100 + sét 400) / hồi phục 400.

## 4. Seraphine — Quang · Healer · Trượng

*Hồi phục và hộ thuẫn cả đội, đánh dấu Phán quyết để đồng đội gây thêm sát thương.*

### Tấn công thường — Quang Châm (3 đòn)

- **Tiêu hao / Hồi chiêu:** không / không. Chuỗi reset sau 0.9s.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** quả cầu sáng tự dẫn bay 450 px. Đòn 3 là tia sáng xuyên 450 px (2 mục tiêu).
- **Hiệu lực & sát thương:** 50% / 50% / 95% = 195% ATK.
- **Hiệu ứng:** đòn 3 hồi 40% ATK cho đồng đội có % HP thấp nhất trong 600 px.
- **Động tác & animation:** chạm đầu trượng về phía trước, quả cầu sáng bay ra. Đòn 3 xoay trượng bắn tia sáng, tay áo rộng tung nhẹ. ≈ 5 frame mỗi đòn, đòn 3 ≈ 7.
- **Timing (khởi động / hiệu lực / hồi phục):** Đ1 120/40/160. Đ2 120/40/160. Đ3 200/60/280.

### Né tránh — Quang Bộ

- **Tiêu hao / Hồi chiêu:** 1 lượt né / hồi 4.0s mỗi lượt.
- **Giảm hồi chiêu:** CDR chung.
- **Tầm & phạm vi:** hóa tia sáng dịch 260 px, để lại ảo ảnh sáng 1.0s.
- **Hiệu lực & sát thương:** không gây sát thương.
- **Hiệu ứng:** bất tử 40–180 ms. Ảo ảnh khiêu khích kẻ địch thường 1.0s (boss không bị). Né hoàn hảo — Hào Quang: hồi 3% HP tối đa cho cả đội, +10 EN.
- **Động tác & animation:** vòng tay trước ngực, thân thể tan thành hạt sáng bay đi, hiện ra lại với váy bay. ≈ 5 frame.
- **Timing:** 40/140/120.

### Bị động — Ân Huệ Ánh Sáng

- **Tiêu hao / Hồi chiêu:** không / ICD 2s mỗi mục tiêu.
- **Giảm hồi chiêu:** mỗi lần hồi cho đồng đội dưới 50% HP: −1.0s CD Kĩ năng thường (ICD 3s).
- **Tầm & phạm vi:** áp dụng cho mọi hồi máu của Seraphine.
- **Hiệu lực & sát thương:** hồi máu thừa vượt HP tối đa: 50% lượng thừa chuyển thành Khiên, tối đa 8% HP tối đa của mục tiêu, tồn tại 6s.
- **Hiệu ứng:** không thêm.
- **Động tác & animation:** không có. Gợi ý hiển thị: hạt sáng vàng tụ quanh chân đồng đội khi có khiên, khiên là vòng sáng mỏng.
- **Timing:** —

### Nhấn giữ TC — Thánh Quang Cầu Nguyện

- **Tiêu hao / Hồi chiêu:** 8 EN mỗi giây (tối đa 3.0s) / 2.0s sau khi kết thúc.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** vòng sáng bán kính 250 px quanh Seraphine.
- **Hiệu lực & sát thương:** giữ ≥ 400 ms để bắt đầu. Mỗi 0.5s hồi 25% ATK + 1% HP tối đa cho đồng đội trong vòng (≈ 50% ATK + 2% HP mỗi giây). Kẻ địch trong vòng nhận 20% ATK mỗi nhịp.
- **Hiệu ứng:** Seraphine giảm 70% tốc độ di chuyển khi cầu nguyện. Bị Choáng thì ngắt.
- **Động tác & animation:** chắp hai tay giữ trượng trước ngực, mắt nhắm. Vòng ma pháp sáng dưới chân quay chậm, hạt sáng bay lên. ≈ 6 frame lặp + 3 frame mở/đóng.
- **Timing:** khởi động 150 / hiệu lực tối đa 3000 / hồi phục 220.

### TC trên không — Thiên Quang Hạ Phúc

- **Tiêu hao / Hồi chiêu:** không (+3 EN mỗi lần trúng) / tối đa 2 lần mỗi lần nhảy.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** 3 tia sáng chéo xuống, tầm 400 px.
- **Hiệu lực & sát thương:** 45% × 3 = 135% ATK.
- **Hiệu ứng:** Seraphine lơ lửng 300 ms.
- **Động tác & animation:** giơ trượng lên trời, quả cầu trên đỉnh nở sáng rồi tách thành 3 tia bắn xuống. ≈ 6 frame.
- **Timing:** 110/90/180.

### TC đáp đất — Giáng Quang Trụ

- **Tiêu hao / Hồi chiêu:** không (+3 EN nếu trúng) / dùng được khi đã ra ≥ 1 đòn trên không và cao hơn mặt đất ≥ 200 px.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** bấm TC khi đang rơi. Cột sáng bán kính 160 px.
- **Hiệu lực & sát thương:** 110% ATK. Đồng đội trong vòng 160 px hồi 20% ATK.
- **Hiệu ứng:** khựng kẻ địch thường.
- **Động tác & animation:** cầm trượng thẳng đứng rơi xuống, đầu trượng chạm đất bung cột sáng thẳng lên trời, cánh sáng nhỏ tỏa ra. ≈ 6 frame.
- **Timing:** 70/100/260.

### Kĩ năng thường — Thánh Ân Chữa Lành

- **Tiêu hao / Hồi chiêu:** 25 EN / 9.0s.
- **Giảm hồi chiêu:** theo bị động (hồi cho đồng đội dưới 50% HP: −1.0s).
- **Tầm & phạm vi:** toàn đội trong 1200 px, tự nhắm, không cần hướng.
- **Hiệu lực & sát thương:** hồi ngay 90% ATK + 4% HP tối đa. Sau đó 20% ATK mỗi giây trong 4s (80%). Tổng 170% ATK + 4% HP. Đồng đội có % HP thấp nhất nhận ×1.3.
- **Hiệu ứng:** xóa 1 hiệu ứng xấu (Cháy, Chậm, Nguyền...) khỏi mỗi đồng đội, kể cả Seraphine.
- **Động tác & animation:** giơ trượng lên cao, ánh sáng vàng nhạt rơi như mưa hạt lên bản thân rồi bay tới đồng đội. ≈ 8 frame.
- **Timing:** 200/300/260.

### Kĩ năng vũ khí — Thái Dương Phán Xét

- **Tiêu hao / Hồi chiêu:** 35 EN / 12.0s.
- **Giảm hồi chiêu:** mỗi mục tiêu trúng: −0.5s (tối đa −2.5s mỗi chu kỳ).
- **Tầm & phạm vi:** đặt tại mục tiêu gần nhất trong 600 px phía trước, bán kính 200 px, có vòng cảnh báo.
- **Hiệu lực & sát thương:** nổ 280% ATK. Đồng đội trong vùng hồi 60% ATK.
- **Hiệu ứng:** kẻ địch trúng nhận Phán quyết 6s (+8% sát thương nhận). Quả cầu rơi trễ 600 ms.
- **Động tác & animation:** giơ trượng lên, quả cầu trên đầu trượng bay cao và phồng thành mặt trời nhỏ, rơi xuống nổ. ≈ 10 frame.
- **Timing:** 250 (cast) / nổ trễ 600 / hồi phục 300.

### Tuyệt kỹ — Thiên Sứ Giáng Lâm

- **Tiêu hao / Hồi chiêu:** 100 UG / không có CD, khóa 2.0s sau khi dùng.
- **Giảm hồi chiêu:** nạp UG +30% từ việc hồi máu cho đồng đội dưới 50% HP.
- **Tầm & phạm vi:** vùng thánh bán kính 500 px, cố định tại nơi cast, kéo dài 8s.
- **Hiệu lực & sát thương:** đồng đội hồi 4% HP tối đa mỗi giây (tổng 32%). Kẻ địch nhận 25% ATK mỗi 0.5s (tổng 400%).
- **Hiệu ứng:** đồng đội giảm 25% sát thương nhận. Kẻ địch nhận Phán quyết. Hồi sinh (tùy chọn, cờ config `revive_enabled`): đồng đội gục trong vùng được hồi sinh với 40% HP, một lần mỗi lần dùng. Loại vùng: sau khởi động 700 ms bất tử có thể chuyển nhân vật.
- **Động tác & animation:** 6 cánh sáng mở sau lưng, bay lên 200 px, hai tay mở rộng, vòng ma pháp rộng trải dưới đất, lông vũ sáng rơi. ≈ 14 frame + VFX riêng.
- **Timing:** cut-in 500 / khởi động 700 (bất tử) / vùng 8000 / hồi phục 400.

## 5. Noctis — Ám · Control · Lưỡi hái

*Khống chế và rút máu: nguyền rủa, kéo kẻ địch lại gần, trói chân.*

### Tấn công thường — Ảnh Liêm (4 đòn)

- **Tiêu hao / Hồi chiêu:** không / không. Chuỗi reset sau 0.9s.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** 200 px, cung 130°. Đòn 3 xoay vòng 180 px.
- **Hiệu lực & sát thương:** 70% / 70% / 90% / 130% = 360% ATK.
- **Hiệu ứng:** đòn 3 đẩy lùi 60 px. Đòn 4 kéo kẻ địch trong 200 px vào cách Noctis 80 px và áp Nguyền 2s.
- **Động tác & animation:** Đ1 chém ngang. Đ2 chém ngược lên. Đ3 xoay hái một vòng. Đ4 nhấc lưỡi hái bổ xuống rồi kéo ngược về như câu. Vệt tím đen, hạt tím. ≈ 7 frame mỗi đòn, đòn 4 ≈ 9.
- **Timing (khởi động / hiệu lực / hồi phục):** Đ1 120/70/200. Đ2 120/70/200. Đ3 150/100/230. Đ4 190/120/340.

### Né tránh — Ảnh Bộ

- **Tiêu hao / Hồi chiêu:** 1 lượt né / hồi 4.0s mỗi lượt.
- **Giảm hồi chiêu:** CDR chung.
- **Tầm & phạm vi:** hóa bóng dịch 300 px, xuyên kẻ địch và vật cản thấp.
- **Hiệu lực & sát thương:** không gây sát thương.
- **Hiệu ứng:** bất tử 30–270 ms (dài nhất nhóm). Né hoàn hảo — Phân Thân Bóng: bóng tại điểm xuất phát nổ sau 0.8s, 120% ATK bán kính 150 px, áp Nguyền 3s.
- **Động tác & animation:** cúi người, cơ thể tan thành khói tím đen bay ngang, hiện lại phía trước, áo choàng bay. ≈ 5 frame.
- **Timing:** 30/240/130.

### Bị động — Khế Ước Bóng

- **Tiêu hao / Hồi chiêu:** không / ICD 1.0s cho phần thưởng hạ gục.
- **Giảm hồi chiêu:** hạ gục kẻ địch mang Nguyền: −1.5s CD Kĩ năng thường, +10 EN.
- **Tầm & phạm vi:** chỉ tác động lên Noctis.
- **Hiệu lực & sát thương:** sát thương lên mục tiêu mang Nguyền: Noctis hồi 4% lượng sát thương gây ra (boss 2%).
- **Hiệu ứng:** không thêm.
- **Động tác & animation:** không có. Gợi ý hiển thị: kẻ địch bị Nguyền có vòng tím mờ dưới chân, hút máu thể hiện bằng hạt tím bay về Noctis.
- **Timing:** —

### Nhấn giữ TC — Ám Liêm Triệu Hồi

- **Tiêu hao / Hồi chiêu:** 10 EN khi bắt đầu / 2.5s sau khi kết thúc.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** xoáy bóng bán kính 260 px quanh Noctis, kéo kẻ địch vào 150 px/s.
- **Hiệu lực & sát thương:** giữ ≥ 450 ms. Mỗi 0.3s 28% ATK, tối đa 6 nhịp (1.8s) = 168%. Nhả nút hoặc hết nhịp: chém bổ cuối 90%. Tổng 258% ATK.
- **Hiệu ứng:** Chậm 30% trong xoáy. Nhát cuối áp Nguyền 4s. Noctis giảm 50% tốc độ di chuyển khi xoay. Bị Choáng thì ngắt.
- **Động tác & animation:** xoay lưỡi hái trên đầu như chong chóng, xoáy bóng tím đen cuộn quanh. Nhát cuối hạ hái bổ xuống tạo vết nứt bóng tối. ≈ 6 frame lặp + 6 frame kết.
- **Timing:** khởi động 180 / hiệu lực tối đa 1800 + nhát cuối 100 / hồi phục 320.

### TC trên không — Huyết Nguyệt Liêm (2 đòn)

- **Tiêu hao / Hồi chiêu:** không (+3 EN mỗi đòn trúng) / tối đa 2 đòn mỗi lần nhảy.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** bán nguyệt 240 px, cung 90°.
- **Hiệu lực & sát thương:** 80% / 100% = 180% ATK.
- **Hiệu ứng:** đòn 2 áp Nguyền 3s.
- **Động tác & animation:** Đ1 vung hái bán nguyệt ngang. Đ2 xoay ngược chiều chém lớn, vệt bán nguyệt tím đỏ. ≈ 6 frame mỗi đòn.
- **Timing:** Đ1 100/70/160. Đ2 120/80/200.

### TC đáp đất — Ám Trụy Lực

- **Tiêu hao / Hồi chiêu:** không (+3 EN nếu trúng) / dùng được khi đã ra ≥ 1 đòn trên không và cao hơn mặt đất ≥ 200 px.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** bấm TC khi đang rơi. Cắm hái xuống đất, vùng bóng bán kính 180 px, kéo kẻ địch trong vùng vào cách tâm 120 px.
- **Hiệu lực & sát thương:** 130% ATK.
- **Hiệu ứng:** áp Nguyền 2s.
- **Động tác & animation:** nâng hái bằng hai tay, rơi thẳng cắm xuống đất. Bóng tím bung rộng như mực loang, bàn tay bóng nắm lấy kẻ địch. ≈ 7 frame.
- **Timing:** 70/120/300.

### Kĩ năng thường — Vực Bóng Nguyền Rủa

- **Tiêu hao / Hồi chiêu:** 25 EN / 8.0s.
- **Giảm hồi chiêu:** theo bị động (hạ gục kẻ địch mang Nguyền: −1.5s).
- **Tầm & phạm vi:** đặt tại kẻ địch gần nhất trong 450 px, vùng bán kính 280 px, kéo dài 4s.
- **Hiệu lực & sát thương:** 25% ATK mỗi 0.5s = 200% ATK.
- **Hiệu ứng:** Chậm 35%. Nguyền (−15% DEF) làm mới liên tục khi còn trong vùng. Kéo nhẹ về tâm.
- **Động tác & animation:** cắm hái xuống đất, bóng tím lan ra như vũng mực, các cánh tay bóng vươn lên. ≈ 8 frame.
- **Timing:** 180 / vùng 4000 / 240.

### Kĩ năng vũ khí — Liêm Phá Hồn Trảm

- **Tiêu hao / Hồi chiêu:** 35 EN / 12.0s.
- **Giảm hồi chiêu:** mỗi mục tiêu bị Trói: −0.5s (tối đa −2.0s mỗi chu kỳ).
- **Tầm & phạm vi:** ném hái bay vòng cung 500 px, xoay cắt qua kẻ địch, quay lại sau 0.5s.
- **Hiệu lực & sát thương:** 130% mỗi lượt (đi và về) = 260% ATK.
- **Hiệu ứng:** Trói 1.5s (boss 0.6s). Noctis hồi 6% lượng sát thương gây ra. Trong 1.0s không dùng được đòn thường.
- **Động tác & animation:** quăng hái xoay tít như cánh quạt để lại vệt tím, hái bay quay về tay. ≈ 8 frame ném + 4 frame bắt hái.
- **Timing:** 220/1000/280.

### Tuyệt kỹ — Đêm Vĩnh Hằng

- **Tiêu hao / Hồi chiêu:** 100 UG / không có CD, khóa 2.0s sau khi dùng.
- **Giảm hồi chiêu:** nạp thêm 10 UG mỗi lần hạ gục kẻ địch mang Nguyền.
- **Tầm & phạm vi:** kéo kẻ địch trong 500 px vào tâm (0.4s), chém trong 350 px, nhát cuối 450 px.
- **Hiệu lực & sát thương:** 6 nhát × 100% = 600%, nhát cuối 550%. Tổng 1150% ATK.
- **Hiệu ứng:** Nguyền 8s, hút máu 10% sát thương. Thu hoạch: kẻ địch thường dưới 20% HP bị xử tử (boss thay bằng +25% sát thương). Dạ Vương 8s: +8% hút máu, +15% sát thương đòn thường. Loại chuỗi đòn.
- **Động tác & animation:** cut-in, màn hình tối lại, vầng trăng đen hiện sau lưng. Noctis hóa bóng khổng lồ chém liên hoàn, nhát cuối chém xuống xé đôi bóng tối. ≈ 18 frame + VFX riêng.
- **Timing:** cut-in 500 / khởi động 300 / hiệu lực 1900 (kéo 400 + chém 1200 + nhát cuối 300) / hồi phục 450.

## 6. Terra — Địa · Tank · Đại kiếm

*Chịu đòn, khiêu khích, phá thế đứng: càng bị đánh càng cứng, đòn nặng làm Choáng.*

### Tấn công thường — Đại Địa Trảm (3 đòn)

- **Tiêu hao / Hồi chiêu:** không / không. Chuỗi reset sau 1.0s.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** 220 px. Đòn 3 thêm sóng đá 260×80 px bay 260 px.
- **Hiệu lực & sát thương:** 100% / 110% / 180% = 390% ATK.
- **Hiệu ứng:** kháng khựng từ pha khởi động của đòn 2. SC ×1.5, đòn 3 SC ×2. Mỗi đòn tiến 30 px.
- **Động tác & animation:** Đ1 chém ngang nặng nề. Đ2 chém chéo đối chiều. Đ3 hai tay nâng đại kiếm qua đầu bổ xuống, đất nứt phát sóng đá. ≈ 8 frame mỗi đòn, đòn 3 ≈ 10.
- **Timing (khởi động / hiệu lực / hồi phục):** Đ1 180/90/260. Đ2 180/90/260. Đ3 260/130/420.

### Né tránh — Lăn Giáp

- **Tiêu hao / Hồi chiêu:** 1 lượt né / hồi 4.0s mỗi lượt.
- **Giảm hồi chiêu:** CDR chung.
- **Tầm & phạm vi:** lao vai 180 px (ngắn nhất nhóm).
- **Hiệu lực & sát thương:** không gây sát thương.
- **Hiệu ứng:** bất tử 50–140 ms, sau đó Giáp cứng đến 340 ms (−50% sát thương nhận, kháng khựng). Né hoàn hảo — Phản Chấn: sóng đá 100% ATK bán kính 160 px, +1 Cốt Đá.
- **Động tác & animation:** hạ vai, lao như xe ủi với đại kiếm vác trên lưng, bụi đất bay. ≈ 5 frame.
- **Timing:** 50/290/160.

### Bị động — Cốt Đá Bất Khuất

- **Tiêu hao / Hồi chiêu:** không / ICD 0.5s mỗi lần cộng tầng.
- **Giảm hồi chiêu:** mỗi lần nhận đòn: −0.5s CD Kĩ năng thường (ICD 2s, tối đa −3.0s mỗi chu kỳ).
- **Tầm & phạm vi:** chỉ tác động lên Terra.
- **Hiệu lực & sát thương:** mỗi lần nhận sát thương: +1 Cốt Đá (tối đa 5, tồn tại 8s, làm mới). Mỗi tầng giảm 3% sát thương nhận (tối đa 15%).
- **Hiệu ứng:** ở 5 tầng, Kĩ năng vũ khí kế tiếp +40% sát thương và nổ thêm, rồi tiêu hết tầng.
- **Động tác & animation:** không có. Gợi ý hiển thị: mảnh đá nhỏ nổi quanh giáp theo từng tầng, ở 5 tầng giáp phát sáng màu hổ phách.
- **Timing:** —

### Nhấn giữ TC — Thủ Thế Đại Địa

- **Tiêu hao / Hồi chiêu:** 6 EN mỗi giây (tối đa 2.5s) / 1.5s sau khi nhả.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** chắn phía trước, cung 150°.
- **Hiệu lực & sát thương:** giữ ≥ 300 ms: giảm 70% sát thương từ phía trước. Chặn hoàn hảo (trong 200 ms đầu khi đòn tới): phản 120% ATK, bán kính 180 px. Nhả nút sau khi chặn ≥ 1 đòn: chém ngang 170% ATK (SC ×1.5). Chưa chặn đòn nào: chém 90%.
- **Hiệu ứng:** kháng khựng, giảm 60% tốc độ di chuyển khi chắn. Mỗi đòn chặn được: +1 Cốt Đá.
- **Động tác & animation:** cắm đại kiếm xuống, hai tay giữ chuôi, thân kiếm chắn như tấm khiên, bụi đá bay. Nhả nút: xoay kiếm chém ngang. ≈ 4 frame lặp + 6 frame chém.
- **Timing:** dựng 120 / chắn tối đa 2500 / nhả 140/90/300.

### TC trên không — Thiên Trụy Trảm

- **Tiêu hao / Hồi chiêu:** không (+3 EN nếu trúng) / 1 đòn mỗi lần nhảy.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** 230 px, cung chéo xuống.
- **Hiệu lực & sát thương:** 120% ATK.
- **Hiệu ứng:** rơi nhanh hơn 30% trong lúc chém. Khựng kẻ địch 200 ms. SC ×1.5.
- **Động tác & animation:** nâng đại kiếm hai tay qua vai, chém chéo xuống rất mạnh, vệt kiếm to bản màu đồng. ≈ 6 frame.
- **Timing:** 140/90/220.

### TC đáp đất — Địa Chấn Trụy

- **Tiêu hao / Hồi chiêu:** không (+3 EN nếu trúng) / dùng được khi đã ra ≥ 1 đòn trên không và cao hơn mặt đất ≥ 200 px.
- **Giảm hồi chiêu:** —
- **Tầm & phạm vi:** bấm TC khi đang rơi. Bán kính 240 px, thêm hai sóng đá chạy sang hai bên 220 px.
- **Hiệu lực & sát thương:** 190% ATK + 2 sóng × 60% = tối đa 310%.
- **Hiệu ứng:** Giáp Địa 2s (−15% sát thương nhận). SC ×1.5. Kháng khựng khi tiếp đất.
- **Động tác & animation:** hai tay đâm đại kiếm thẳng xuống, đất nứt hình sao, hai sóng đá chạy sang hai bên. ≈ 7 frame.
- **Timing:** 60/140/380.

### Kĩ năng thường — Khiên Đá Hộ Thể

- **Tiêu hao / Hồi chiêu:** 25 EN / 10.0s.
- **Giảm hồi chiêu:** theo bị động (mỗi lần nhận đòn: −0.5s).
- **Tầm & phạm vi:** dậm đại kiếm, AoE bán kính 200 px. Khiêu khích trong 400 px.
- **Hiệu lực & sát thương:** 120% ATK lúc dậm.
- **Hiệu ứng:** Chậm 20% trong 2s. Giáp Địa 6s: −35% sát thương nhận, kháng khựng. Khiên đá hấp thụ tối đa 20% HP tối đa. Khiêu khích kẻ địch thường 3s (boss 1.5s).
- **Động tác & animation:** nâng đại kiếm lên cao, dậm xuống mạnh, đá mọc lên bao quanh thân tạo thành giáp. ≈ 8 frame.
- **Timing:** 200/120/300, Giáp Địa kéo dài 6000.

### Kĩ năng vũ khí — Thạch Phá Thiên Kích

- **Tiêu hao / Hồi chiêu:** 40 EN / 14.0s.
- **Giảm hồi chiêu:** mỗi mục tiêu bị Choáng bởi Terra: −2.0s (tối đa −4.0s mỗi chu kỳ).
- **Tầm & phạm vi:** sóng đá thẳng dài 500 px, rộng 120 px, xuyên mục tiêu.
- **Hiệu lực & sát thương:** 300% ATK.
- **Hiệu ứng:** Phá Giáp: −15% DEF 5s. SC ×2. Có 5 Cốt Đá: +40% sát thương và nổ cuối 130% ATK bán kính 200 px (rồi tiêu hết tầng). Giáp cứng suốt hiệu lực (−50% sát thương nhận, kháng khựng).
- **Động tác & animation:** nâng đại kiếm hai tay lên cao, bổ xuống dữ dội, đất nứt chạy thẳng về phía trước thành dãy gai đá. ≈ 12 frame.
- **Timing:** 300/500/420.

### Tuyệt kỹ — Sơn Băng Địa Liệt

- **Tiêu hao / Hồi chiêu:** 100 UG / không có CD, khóa 2.0s sau khi dùng.
- **Giảm hồi chiêu:** nạp UG +20% khi đang có Giáp Địa hoặc ≥ 3 Cốt Đá.
- **Tầm & phạm vi:** nhảy lên 400 px. AoE bán kính 500 px, 3 đợt sóng chấn lan ra.
- **Hiệu lực & sát thương:** tiếp đất 650% + 3 sóng × 150% = 450%. Tổng 1100% ATK.
- **Hiệu ứng:** Choáng toàn bộ kẻ địch thường 3.0s (boss 1.2s). Thạch Thần 8s: −40% sát thương nhận, +20% ATK. Khiêu khích kẻ địch thường 4s. Đồng đội trong 500 px nhận khiên 10% HP tối đa trong 6s. Loại chuỗi đòn.
- **Động tác & animation:** dậm chân bật vọt lên, đại kiếm giơ cao hóa khổng lồ bằng đá, rơi xuống cắm thẳng, mặt đất vỡ thành tảng, sóng chấn lan ba đợt. ≈ 18 frame + VFX riêng.
- **Timing:** cut-in 500 / nhảy 400 (bất tử) / rơi 250 / hiệu lực 1200 / hồi phục 500.

## 7. Ghi chú và bước tiếp theo

### Chưa thiết kế trong tài liệu này

- Đòn vào sân (switch-in) và đòn ra sân.
- Phản ứng nguyên tố giữa các trạng thái (Cháy, Dấu Sét, Nguyền...).
- Mục tiêu hạ gục kẻ địch thường và boss chưa tách riêng, mới chỉ ghi chú những chỗ boss khác.

### Gợi ý hành vi AI khi nhân vật ở dự bị

| Nhân vật | AI ưu tiên |
| --- | --- |
| Aether | Đánh thường liên tục, dùng Kĩ năng khi đủ 5 Nhiệt |
| Lyra | Phong Vực khi có ≥ 2 kẻ địch gần, bắn từ xa |
| Kael | Chớp Giật Liên Hoàn để dọn nhóm, Song Lôi Phi Nhận khi kẻ địch có Dấu Sét |
| Seraphine | Thánh Ân Chữa Lành khi có đồng đội dưới 60% HP, còn lại đánh từ xa |
| Noctis | Vực Bóng đặt lên kẻ địch mạnh nhất, Trói mục tiêu nguy hiểm |
| Terra | Khiên Đá khi có ≥ 2 kẻ địch tiến sát, đứng tuyến trước |

### Cân bằng

- Tuyệt kỹ khoảng 1000–1150% ATK. Kĩ năng thường 200–350%. Kĩ năng vũ khí 260–360%.
- Nhân vật hỗ trợ (Lyra, Seraphine) có sát thương thấp hơn nhưng giá trị đến từ buff, hồi máu và khống chế.
- Đây là số khởi điểm. Chỉnh bằng playtest, và viết test GdUnit4 cho tiêu hao tài nguyên, hồi chiêu, mức rút ngắn CD tối đa.

### Khi đưa vào dự án

- Chuyển mỗi kỹ năng thành data (Resource) theo ID `{id nhân vật}.{khóa}`, không viết cứng trong code.
- Khi bạn gửi số frame thật của từng nhân vật, mình chỉnh lại timing và ngân sách frame theo đó.
- Trước khi phát hành, đổi tên nhân vật và tên chiêu sang tên gốc (README 2.1).

## 8. Cấu trúc 1 nhân vật tham chiến và Kĩ năng vào sân (Switch-in)

### 8.1 Ghi đè các quy ước cũ

- Chỉ **1 nhân vật tham chiến**. 2 nhân vật dự bị hiện thành 2 icon ở góc trên bên phải, không xuất hiện trên sân, không có AI, không hành động.
- Mục 7 (Gợi ý hành vi AI khi nhân vật ở dự bị) không còn dùng.
- Nhân vật dự bị nạp EN +1 mỗi giây (thay vì +2) và nhận 30% lượng UG mà nhân vật trên sân nhận được (thay vì 50%).
- Hiệu ứng đồng đội hoặc cả đội: hồi máu cả đội hồi cho cả nhân vật dự bị. Buff và vùng cho đồng đội: nhân vật trên sân nhận nếu đứng trong vùng, nhân vật vào sân khi hiệu ứng còn hiệu lực nhận phần thời gian còn lại. Hồi sinh của Seraphine hồi sinh nhân vật dự bị đã gục.
- Tuyệt kỹ loại vùng (Lyra, Seraphine): sau khi cast xong có thể chuyển nhân vật, bão hoặc vùng vẫn chạy như hiệu ứng độc lập, nhân vật rời sân không còn giữ tư thế. Tuyệt kỹ loại chuỗi đòn vẫn khóa chuyển nhân vật.
- Bộ đếm thời gian cá nhân (Nhiệt, Cốt Đá, buff...) vẫn chạy khi nhân vật ở dự bị. Trạng thái đã áp lên kẻ địch (Cháy, Nguyền, Dấu Sét...) vẫn tồn tại sau khi nhân vật rời sân.
- **Không có kĩ năng ra sân.** Nhân vật rời sân chỉ chơi animation ra sân 3 frame rồi biến mất.

### 8.2 Quy tắc chuyển nhân vật

- Chạm icon dự bị để chuyển. Khoảng chờ chung giữa hai lần chuyển: 1.0s. Không chuyển được khi nhân vật trên sân đang trong Tuyệt kỹ loại chuỗi đòn, hoặc khi nhân vật dự bị đã gục (HP 0).
- **SI-CD** là hồi chiêu vào sân của từng nhân vật. Nó đếm ngược cả khi ở dự bị và chịu CDR chung.
- SI-CD đã hồi: nhân vật vào sân bằng Kĩ năng vào sân, ở mức **Thường**, hoặc mức **Liên kết** nếu vòng sáng đang sáng. Dùng xong thì SI-CD bắt đầu hồi lại.
- SI-CD chưa hồi: vào sân không dùng kĩ năng (animation vào sân mặc định, không có phản ứng).
- Kĩ năng vào sân không tốn EN. Nhân vật vào sân bất tử từ lúc xuất hiện đến hết pha hiệu lực (tối đa 500 ms).
- Kĩ năng vào sân thay thế animation vào sân mặc định 4 frame trong ngân sách frame. Tổng frame cao nhất (Noctis) khoảng 150, vừa chạm trần ở README 2.2.
- ID dữ liệu: `{id nhân vật}.switch_in`.

### 8.3 Liên kết và vòng sáng

- Mỗi nhân vật có một **điều kiện Liên kết** riêng: một việc mà nhân vật trên sân làm. Khi việc đó xảy ra, icon của nhân vật dự bị tương ứng sáng lên trong cửa sổ **6.0s**.
- Vòng sáng chỉ hiện khi cả hai đúng: điều kiện đã xảy ra trong 6.0s gần nhất và SI-CD đã hồi.
- Hai icon có thể sáng cùng lúc, người chơi chọn một. Chuyển bằng icon nào thì chỉ tiêu cửa sổ của icon đó.
- Vào sân Liên kết: Kĩ năng vào sân mạnh hơn, kích hoạt **phản ứng nguyên tố** giữa nguyên tố nhân vật vừa rời sân và nguyên tố nhân vật vào sân (bảng 8.4), và cộng +15 UG, +10 EN cho nhân vật vào sân.

**Hiệu ứng vòng sáng quanh icon dự bị:**

- Vòng tròn quanh icon, màu theo nguyên tố của nhân vật đó. Hiện trong 150 ms, nhịp đập 0.8s (phóng 1.0 → 1.12, độ sáng 0.6 → 1.0), hạt sáng nhỏ quay quanh vòng.
- Một cung tròn mỏng quanh vòng co dần theo thời gian còn lại của cửa sổ 6.0s.
- Hết hạn: mờ dần 300 ms. Khi dùng: vòng nổ sáng 200 ms. Có âm thanh ngắn khi vòng sáng bật lên.
- Màu vòng: Aether đỏ cam, Lyra xanh ngọc, Kael vàng, Seraphine trắng vàng, Noctis tím, Terra hổ phách.

| Nhân vật | Điều kiện Liên kết (nhân vật trên sân làm gì) | SI-CD |
| --- | --- | --- |
| Aether | Làm kẻ địch Choáng (phá đầy thanh SC) | 10.0s |
| Lyra | Né hoàn hảo | 9.0s |
| Kael | Gây hiệu ứng nguyên tố lên kẻ địch (Cháy, Chậm, Dấu Sét, Nguyền, Phán quyết, Trói...) | 8.0s |
| Seraphine | HP ≤ 50%, hoặc mất ≥ 25% HP tối đa trong 3s | 12.0s |
| Noctis | Hạ gục một kẻ địch | 11.0s |
| Terra | Dùng Kĩ năng vũ khí hoặc Tuyệt kỹ | 12.0s |

### 8.4 Bảng phản ứng nguyên tố

Nguyên tố: Hỏa (Aether), Phong (Lyra), Lôi (Kael), Quang (Seraphine), Ám (Noctis), Địa (Terra). Sáu nhân vật có sáu nguyên tố khác nhau nên mỗi lần chuyển luôn ra đúng một phản ứng, trong 15 cặp.

- Phản ứng chỉ xảy ra khi vào sân Liên kết và Kĩ năng vào sân trúng ít nhất 1 kẻ địch. Tâm phản ứng là kẻ địch trúng đầu tiên. Hai phản ứng hồi máu và khiên (Thanh Phong, Thánh Giáp) xảy ra tại nhân vật vào sân và không cần trúng kẻ địch.
- Phản ứng đối xứng: chỉ phụ thuộc cặp nguyên tố, không phụ thuộc ai vào ai ra.
- Sát thương phản ứng tính theo % ATK của nhân vật vào sân, cộng thêm vào sát thương Kĩ năng vào sân.
- ICD phản ứng chung 5.0s. Hiệu ứng khống chế (Trói, Choáng, Chậm) lên boss có hiệu lực ×0.5.
- Hiển thị: hai quả cầu màu của hai nguyên tố va vào nhau 300 ms, hit-stop 60 ms, tên phản ứng hiện 0.8s.

| Cặp | Phản ứng | Sát thương & phạm vi | Hiệu ứng |
| --- | --- | --- | --- |
| Hỏa + Phong | Hỏa Lốc | 180% ATK, bán kính 260 px | Áp Cháy 5s lên mọi kẻ địch trong vùng, kể cả kẻ chưa bị trúng |
| Hỏa + Lôi | Quá Tải | 220% ATK, bán kính 220 px | Đẩy lùi 200 px, SC ×2 |
| Hỏa + Quang | Nhật Thiêu | 160% ATK, bán kính 200 px, thêm vùng lửa thánh 3s (20% ATK mỗi 0.5s) | Phán quyết 5s |
| Hỏa + Ám | Thiêu Hồn | 150% ATK, bán kính 220 px | Cháy 5s với tick gấp đôi (16% ATK), Nguyền 5s |
| Hỏa + Địa | Dung Nham | 140% ATK, bán kính 200 px, thêm vùng dung nham 3s (24% ATK mỗi 0.5s) | Chậm 30% trong vùng |
| Phong + Lôi | Bão Sét | 4 tia sét × 70% = 280% ATK, rơi ngẫu nhiên trong bán kính 400 px, mỗi 0.3s | Mỗi tia áp 1 Dấu Sét |
| Phong + Quang | Thanh Phong | 100% ATK, bán kính 240 px | Hồi cả đội 8% HP tối đa, xóa 1 hiệu ứng xấu, +15% tốc độ di chuyển 5s |
| Phong + Ám | Lốc Oán | 4 nhịp × 30% = 120% ATK, bán kính 300 px, mỗi 0.4s | Kéo kẻ địch vào tâm, Nguyền 4s |
| Phong + Địa | Bão Cát | 8 nhịp × 15% = 120% ATK trong 4s, bán kính 280 px | Chậm 30%, Mù cát: −20% sát thương kẻ địch gây ra trong 4s |
| Lôi + Quang | Thần Phạt | 260% ATK lên 1 mục tiêu có HP cao nhất trong 500 px | Phán quyết 6s, SC ×1.5 |
| Lôi + Ám | Điện Hồn | 170% ATK, bán kính 240 px | Nguyền 6s, Chậm 40% trong 3s |
| Lôi + Địa | Từ Chấn | 200% ATK, bán kính 240 px | SC ×2.5 (dễ gây Choáng) |
| Quang + Ám | Nhật Thực | 200% ATK, bán kính 350 px | Phán quyết và Nguyền cùng lúc 5s |
| Quang + Địa | Thánh Giáp | 120% ATK, bán kính 200 px | Khiên 12% HP tối đa cho nhân vật vào sân 6s, Giáp Địa −20% sát thương nhận 6s |
| Ám + Địa | Địa Táng | 180% ATK, bán kính 200 px | Trói 2.0s (boss 0.8s), Nguyền 4s |

Dữ liệu: mỗi phản ứng là một Resource riêng theo khóa cặp nguyên tố, ví dụ `reaction.fire_wind`.

### 8.5 Aether — Hỏa Ảnh Đột Kích

- **Điều kiện kích hoạt (vòng sáng):** nhân vật trên sân làm kẻ địch Choáng trong 6.0s gần nhất.
- **Tiêu hao / Hồi chiêu:** không tốn EN / SI-CD 10.0s.
- **Giảm hồi chiêu:** mỗi kẻ địch Choáng trúng đòn vào sân: −1.0s (tối đa −3.0s mỗi chu kỳ).
- **Tầm & phạm vi:** lao 350 px tới kẻ địch gần nhất trong 500 px (ưu tiên kẻ đang Choáng), chém xuống bán kính 180 px.
- **Hiệu lực & sát thương:** Thường 130% ATK. Liên kết 190% ATK.
- **Hiệu ứng:** Thường: áp Cháy 3s. Liên kết: Cháy 5s, +2 tầng Nhiệt, kẻ địch đang Choáng nhận thêm +30% sát thương từ đòn này.
- **Phản ứng nguyên tố (Liên kết):** Hỏa với nguyên tố nhân vật vừa rời sân, theo bảng 8.4.
- **Động tác & animation:** nhân vật cũ tan thành ánh sáng. Aether lao vào từ phía sau trong vệt lửa cam, nhảy chém chéo từ trên xuống, kiếm cắm xuống đất nổ lửa rồi đứng dậy sẵn sàng. ≈ 8 frame.
- **Timing (khởi động / hiệu lực / hồi phục):** 220/120/260. Bất tử 0–340 ms.

### 8.6 Lyra — Phong Dực Giáng Tiễn

- **Điều kiện kích hoạt (vòng sáng):** nhân vật trên sân Né hoàn hảo trong 6.0s gần nhất.
- **Tiêu hao / Hồi chiêu:** không tốn EN / SI-CD 9.0s.
- **Giảm hồi chiêu:** Né hoàn hảo trong 4s sau khi vào sân: −1.5s (ICD 3s, tối đa −3.0s mỗi chu kỳ).
- **Tầm & phạm vi:** bắn 3 tên hình quạt ±15°, tầm 700 px. Vùng gió nơi tiếp đất bán kính 160 px.
- **Hiệu lực & sát thương:** Thường 3 × 40% = 120% ATK. Liên kết 3 × 60% = 180% ATK.
- **Hiệu ứng:** tên cuối đẩy lùi 100 px và Chậm 25% (Thường 2s, Liên kết 3s). Gió Trợ Bước: Thường +10% tốc độ di chuyển 3s, Liên kết +25% trong 4s.
- **Phản ứng nguyên tố (Liên kết):** Phong với nguyên tố nhân vật vừa rời sân, theo bảng 8.4.
- **Động tác & animation:** ánh sáng xanh rơi từ trên cao, Lyra lao xuống, xoay ngược giữa trời bắn ba tên hình quạt, váy và áo choàng tung, tiếp đất bằng một chân với gió xoáy quanh chân. ≈ 6 frame.
- **Timing:** 180/200/220. Bất tử 0–380 ms.

### 8.7 Kael — Lôi Ảnh Tập Kích

- **Điều kiện kích hoạt (vòng sáng):** nhân vật trên sân gây hiệu ứng nguyên tố lên kẻ địch (Cháy, Chậm, Dấu Sét, Nguyền, Phán quyết, Trói...) trong 6.0s gần nhất.
- **Tiêu hao / Hồi chiêu:** không tốn EN / SI-CD 8.0s.
- **Giảm hồi chiêu:** mỗi Bùng nổ Sét trong 5s sau khi vào sân: −1.0s (tối đa −3.0s mỗi chu kỳ).
- **Tầm & phạm vi:** dịch chuyển tới kẻ địch gần nhất trong 600 px (ưu tiên kẻ đang mang hiệu ứng), chém chữ X bán kính 150 px.
- **Hiệu lực & sát thương:** Thường 2 × 55% = 110% ATK. Liên kết 2 × 80% = 160% ATK.
- **Hiệu ứng:** Thường áp 1 Dấu Sét, Liên kết áp 2 Dấu Sét. Liên kết: Kael +15% tốc độ tấn công trong 4s.
- **Phản ứng nguyên tố (Liên kết):** Lôi với nguyên tố nhân vật vừa rời sân, theo bảng 8.4.
- **Động tác & animation:** tia chớp vàng đánh xuống chỗ nhân vật cũ, Kael hiện ra, vụt tới mục tiêu, hai đao chém chữ X rồi trượt chân dừng sau lưng. Hạt điện nhỏ bay quanh. ≈ 6 frame.
- **Timing:** 120/100/180. Bất tử 0–220 ms.

### 8.8 Seraphine — Quang Giáng Hộ Vệ

- **Điều kiện kích hoạt (vòng sáng):** HP nhân vật trên sân ≤ 50%, hoặc mất ≥ 25% HP tối đa trong 3s gần nhất.
- **Tiêu hao / Hồi chiêu:** không tốn EN / SI-CD 12.0s.
- **Giảm hồi chiêu:** mỗi lần hồi cho nhân vật dưới 50% HP sau khi vào sân: −1.5s (tối đa −3.0s mỗi chu kỳ).
- **Tầm & phạm vi:** vòng sáng bán kính 300 px quanh Seraphine. Hồi máu áp dụng cho cả đội, kể cả nhân vật dự bị.
- **Hiệu lực & sát thương:** Thường: sát thương 80% ATK, hồi cả đội 50% ATK + 2% HP tối đa. Liên kết: sát thương 120% ATK, hồi cả đội 100% ATK + 5% HP tối đa (nhân vật có HP thấp nhất nhận ×1.5).
- **Hiệu ứng:** Liên kết: xóa 1 hiệu ứng xấu cho cả đội, Khiên 8% HP tối đa cho Seraphine trong 5s.
- **Phản ứng nguyên tố (Liên kết):** Quang với nguyên tố nhân vật vừa rời sân, theo bảng 8.4.
- **Động tác & animation:** cột sáng từ trời hạ xuống, Seraphine đáp nhẹ, gõ trượng xuống đất tạo gợn sóng sáng lan ra, lông vũ sáng rơi. ≈ 6 frame.
- **Timing (khởi động / hiệu lực / hồi phục):** 250/150/220. Bất tử 0–400 ms.

### 8.9 Noctis — Ảnh Liêm Tập Hậu

- **Điều kiện kích hoạt (vòng sáng):** nhân vật trên sân hạ gục một kẻ địch trong 6.0s gần nhất.
- **Tiêu hao / Hồi chiêu:** không tốn EN / SI-CD 11.0s.
- **Giảm hồi chiêu:** hạ gục kẻ địch mang Nguyền trong 6s sau khi vào sân: −2.0s (tối đa −4.0s mỗi chu kỳ).
- **Tầm & phạm vi:** xuất hiện từ bóng của kẻ địch gần nhất trong 500 px, chém cung 180° bán kính 220 px, kéo kẻ địch trong 260 px vào cách Noctis 100 px.
- **Hiệu lực & sát thương:** Thường 130% ATK. Liên kết 180% ATK.
- **Hiệu ứng:** Thường: Nguyền 3s. Liên kết: Nguyền 5s, Trói 1.0s (boss 0.4s), Noctis hồi 6% lượng sát thương gây ra.
- **Phản ứng nguyên tố (Liên kết):** Ám với nguyên tố nhân vật vừa rời sân, theo bảng 8.4.
- **Động tác & animation:** bóng tím trồi lên dưới chân kẻ địch, Noctis bước ra từ bóng, vung hái một nhát ngang rộng, kẻ địch bị kéo lại gần. ≈ 8 frame.
- **Timing:** 220/140/280. Bất tử 0–360 ms.

### 8.10 Terra — Đại Địa Giáng Thế

- **Điều kiện kích hoạt (vòng sáng):** nhân vật trên sân vừa dùng Kĩ năng vũ khí hoặc Tuyệt kỹ trong 6.0s gần nhất.
- **Tiêu hao / Hồi chiêu:** không tốn EN / SI-CD 12.0s.
- **Giảm hồi chiêu:** chặn hoàn hảo sau khi vào sân: −2.0s (tối đa −4.0s mỗi chu kỳ).
- **Tầm & phạm vi:** AoE bán kính 220 px, khiêu khích trong 400 px.
- **Hiệu lực & sát thương:** Thường 140% ATK. Liên kết 190% ATK, SC ×2.
- **Hiệu ứng:** Thường: Chậm 20% trong 2s, +1 Cốt Đá. Liên kết: +3 Cốt Đá, Giáp Địa 4s (−25% sát thương nhận), khiêu khích kẻ địch thường 2s (boss 1s), Khiên 8% HP tối đa.
- **Phản ứng nguyên tố (Liên kết):** Địa với nguyên tố nhân vật vừa rời sân, theo bảng 8.4.
- **Động tác & animation:** Terra từ trên cao lao xuống, đại kiếm hướng xuống đâm vào đất, mặt đất nứt và sóng đá bung quanh, rồi đứng dậy rút kiếm. ≈ 8 frame.
- **Timing:** 280/140/340. Bất tử 0–420 ms.

### 8.11 HUD, rủi ro và việc cần cập nhật

- **HUD:** 2 icon dự bị ở góc trên bên phải. Mỗi icon có chân dung, thanh HP nhỏ, vòng hồi SI-CD và vòng sáng Liên kết. Vùng chạm tối thiểu 140 px. Nút Pause và bộ đếm combo cần dời khỏi góc này (README 15.5 đang đặt ở đó).
- **Rủi ro cảm giác chơi:** icon ở góc trên phải nằm xa ngón cái, người chơi phải nhấc ngón khỏi nút tấn công để chuyển. Giảm bằng vùng chạm lớn, bộ đệm đầu vào 150 ms, và thử trên máy Android thật. Nếu khó dùng, thêm tùy chọn trong Settings đổi vị trí icon.
- **README cần cập nhật:** Section 3 (cấu trúc party), 15.5 (bố cục HUD), 15.7 (cảm giác chơi), và thêm khóa `switch_in` vào mục 2.1 dữ liệu kỹ năng.
- **Test GdUnit4:** điều kiện Liên kết và cửa sổ 6.0s, SI-CD và các cơ chế giảm CD, ICD phản ứng 5.0s, bảng 15 phản ứng có đủ cặp, không thiếu, không trùng.
- **Để sau:** phản ứng giữa trạng thái đang có trên kẻ địch với nguyên tố nhân vật vào sân (ngoài cơ chế chuyển nhân vật), đòn kết hợp khi chuyển nhân vật hai lần liên tiếp.
