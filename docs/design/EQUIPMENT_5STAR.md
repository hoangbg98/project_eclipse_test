# Vũ khí 5★ và Vết thánh 5★ — Project Eclipse

*Bản đề xuất v1. Tên vũ khí, tên bộ vết thánh là tên tạm (README 2.1). Mọi số liệu là giá trị khởi điểm để đưa vào config, chỉnh sau khi chơi thử. Cách diễn đạt mô tả tham khảo từ tựa game khác, cơ chế và số liệu đã viết lại theo kit của game này.*

Đặt tại `docs/design/EQUIPMENT_5STAR.md`. Tài liệu này đi cùng `CHARACTER_SKILLS.md`.

Tên nhân vật theo AGENTS.md (owner 2026-11-13): Enkiba = Aether cũ (`char_fire_01`), Kazeyumi = Lyra (`char_wind_01`), Raikiba = Kael (`char_lightning_01`), Hikarine = Seraphine (`char_light_01`), Yomigari = Noctis (`char_dark_01`), Iwagane = Terra (`char_earth_01`). Ô vết thánh dùng Đầu / Thân / Chân như trong game. Các quyết định của owner ngày 2026-11-14 ghi ở mục 5.

---

## Danh sách nhanh (2026-11-15)

Tóm tắt toàn bộ đồ 5★ đang có trong game. Chi tiết từng dòng hiệu ứng ở mục 1 (vũ khí) và mục 2 (vết thánh); số liệu thật nằm trong `data/equipment/`. Tên là tên tạm.

### Vũ khí 5★ (6 món)

Mỗi vũ khí khóa theo loại vũ khí của nhân vật (mục 5.1). Hiệu ứng độc quyền chỉ kích hoạt cho chủ sở hữu.

| # | Tên | Loại | Chủ sở hữu | Data ID | Chỉ số cộng | Mô tả sơ qua |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Hoàng Hôn Thiêu Rụi | Kiếm | Enkiba (Hỏa) | `eq_weapon_dusk_inferno` | ATK 230, Tỉ lệ chí mạng +6% | Vũ khí công Hỏa: +15% ST Hỏa, +8% tất cả ST, đánh mạnh hơn lên kẻ địch đang Cháy; skill_2 áp Cháy. Enkiba: toàn đội +8% ST (thêm +8% khi ≥ 3 Nhiệt), skill_2 hồi nhanh hơn |
| 2 | Hơi Thở Cuối Mùa Gió | Cung | Kazeyumi (Phong) | `eq_weapon_last_gale` | ATK 215, Tỉ lệ chí mạng +5% | Cơ động: +15% ST Phong, +8% tốc độ di chuyển, +6% tất cả ST, mạnh hơn lên kẻ địch bị Chậm; skill_2 gây Chậm. Kazeyumi: toàn đội +6% nạp EN, kẻ địch trong Phong Vực chịu thêm ST |
| 3 | Hai Tiếng Sấm | Song đao | Raikiba (Lôi) | `eq_weapon_twin_thunder` | ATK 220, ST chí mạng +15% | Tốc đánh: +15% ST Lôi, +8% tốc độ tấn công, +6% tất cả ST, mạnh hơn lên kẻ địch mang hiệu ứng nguyên tố. Raikiba: Bùng nổ Sét +40% ST, toàn đội +8% tốc độ tấn công sau Bùng nổ |
| 4 | Nhật Miện Phán Quyết | Trượng | Hikarine (Quang) | `eq_weapon_solar_verdict` | ATK 200, HP +1200 | Hỗ trợ: +15% ST Quang, +10% hiệu quả hồi máu; skill_2 hồi toàn đội 3% HP. Hikarine: toàn đội +8% hồi máu, Phán quyết mạnh hơn, khiên từ hồi thừa lớn hơn |
| 5 | Liềm Khế Ước Trăng Khuyết | Lưỡi hái | Yomigari (Ám) | `eq_weapon_crescent_pact` | ATK 225, ST chí mạng +15% | Duy trì: +15% ST Ám, +8% tất cả ST, +4% hút máu, hồi máu khi hạ gục, mạnh hơn lên kẻ địch dưới 30% HP. Yomigari: hạ gục rút hồi chiêu, Nguyền và hút máu skill_2 mạnh hơn |
| 6 | Cốt Sơn Bất Khuất | Đại kiếm | Iwagane (Địa) | `eq_weapon_unyielding_peak` | ATK 235, DEF +100 | Công thủ: +15% ST Địa, +8% tất cả ST, giảm 6% ST nhận, mạnh hơn lên kẻ địch bị giảm DEF. Iwagane: toàn đội giảm ST nhận sau skill_2, Cốt Đá kích hoạt ở 4 tầng |

### Vết thánh 5★ (6 bộ × 3 món = 18 món)

Chỉ số cộng theo ô (như nhau ở mọi bộ): **Đầu** ATK 80, Tỉ lệ chí mạng +8% · **Thân** ATK 50, HP +2000, DEF 60 · **Chân** ATK 60, Giảm hồi chiêu +8%. Phần *(chỉ hệ X)* chỉ có tác dụng khi người đeo cùng hệ với bộ.

| Bộ (chủ sở hữu) | Ô | Tên món | Data ID | Hiệu ứng chung (mọi người đeo) | Độc quyền (chỉ chủ sở hữu) |
| --- | --- | --- | --- | --- | --- |
| Antoine Lavoisier (Enkiba, Hỏa) | Đầu | Oxy | `eq_stigma_top_lavoisier` | ST Hỏa +10% *(chỉ hệ Hỏa)* | Nhiệt tồn tại 6s → 8s |
| | Thân | Định Luật Bảo Toàn Khối Lượng | `eq_stigma_mid_lavoisier` | HP tối đa +8%; bị Cháy ngắn hơn 30% *(chỉ hệ Hỏa)* | Mỗi tầng Nhiệt +5% ATK (thay +4%) |
| | Chân | Chuyên Luận Hóa Học | `eq_stigma_bot_lavoisier` | Tất cả ST +8% | Cộng tầng Nhiệt nhanh hơn |
| Leonardo da Vinci (Kazeyumi, Phong) | Đầu | Chong Chóng Trên Không | `eq_stigma_top_davinci` | ST Phong +10% *(chỉ hệ Phong)* | Gió Thuận chỉ cần trúng 2 kẻ địch |
| | Thân | Cỗ Máy Cánh Chim | `eq_stigma_mid_davinci` | Tốc độ di chuyển +8% | Gió Thuận kéo dài 5s → 7s |
| | Chân | Bản Thảo Codex | `eq_stigma_bot_davinci` | Tốc độ nạp EN +10% | Gió Thuận hồi nhanh hơn |
| Benjamin Franklin (Raikiba, Lôi) | Đầu | Con Diều Trong Bão | `eq_stigma_top_franklin` | ST Lôi +10% *(chỉ hệ Lôi)* | Dấu Sét tồn tại 6s → 8s |
| | Thân | Cột Thu Lôi | `eq_stigma_mid_franklin` | Tốc độ tấn công +8% | Bùng nổ Sét 150% → 170% ATK |
| | Chân | Niên Lịch Richard Nghèo | `eq_stigma_bot_franklin` | +8% ST lên kẻ địch mang hiệu ứng nguyên tố | Bùng nổ Sét lặp lại nhanh hơn trên cùng mục tiêu |
| Florence Nightingale (Hikarine, Quang) | Đầu | Ngọn Đèn Scutari | `eq_stigma_top_nightingale` | ST Quang +10% *(chỉ hệ Quang)* | Hồi thừa chuyển thành khiên nhiều hơn |
| | Thân | Biểu Đồ Hoa Hồng | `eq_stigma_mid_nightingale` | Hiệu quả hồi máu +10% | Khiên tối đa 8% → 10% HP |
| | Chân | Ghi Chép Về Điều Dưỡng | `eq_stigma_bot_nightingale` | HP tối đa +8% | Ân Huệ Ánh Sáng kích hoạt dày hơn |
| Edgar Allan Poe (Yomigari, Ám) | Đầu | Con Quạ | `eq_stigma_top_poe` | ST Ám +10% *(chỉ hệ Ám)* | Hút máu lên mục tiêu Nguyền cao hơn |
| | Thân | Trái Tim Tố Giác | `eq_stigma_mid_poe` | Hút máu +5% | Nguyền giảm DEF −15% → −18% |
| | Chân | Chiếc Hố Và Con Lắc | `eq_stigma_bot_poe` | +8% ST lên kẻ địch bị giảm DEF (hệ Ám tính cả Nguyền) | Phần thưởng hạ gục kích hoạt dày hơn |
| Charles Darwin (Iwagane, Địa) | Đầu | Chuyến Đi Beagle | `eq_stigma_top_darwin` | ST Địa +10% *(chỉ hệ Địa)* | Cốt Đá tồn tại 8s → 10s |
| | Thân | Chọn Lọc Tự Nhiên | `eq_stigma_mid_darwin` | Giảm 6% ST nhận | Mỗi tầng Cốt Đá giảm 3.5% ST nhận (thay 3%) |
| | Chân | Lý Luận Tiến Hoá | `eq_stigma_bot_darwin` | HP tối đa +12% | Cộng tầng Cốt Đá nhanh hơn |

**Hiệu ứng bộ (phần chung, mọi người đeo):**

| Bộ | 2 món | 3 món |
| --- | --- | --- |
| Antoine Lavoisier | +10% ST Hỏa; kẻ địch đang Cháy chịu thêm 5% *(chỉ hệ Hỏa)* | Dùng Tuyệt kỹ: toàn đội +8% ST trong 8s |
| Leonardo da Vinci | +10% ST Phong *(chỉ hệ Phong)*; né hoàn hảo: +10% ST 4s | Bắn trúng ≥ 3 kẻ địch: toàn đội +8% ST nguyên tố 6s |
| Benjamin Franklin | +10% ST Lôi *(chỉ hệ Lôi)*; mục tiêu mang hiệu ứng nguyên tố chịu +6% ST từ toàn đội | Gây hiệu ứng nguyên tố: +6% tốc độ tấn công 4s |
| Florence Nightingale | +10% ST Quang *(chỉ hệ Quang)*; mọi hồi máu +8% | Hồi cho đồng đội dưới 50% HP: toàn đội +8% ST 5s |
| Edgar Allan Poe | +10% ST Ám *(chỉ hệ Ám)*; hạ gục: hồi 3% HP | Kẻ địch dưới 30% HP chịu +10% ST |
| Charles Darwin | +10% ST Địa *(chỉ hệ Địa)*; dưới 50% HP: giảm thêm 8% ST nhận | Dùng skill_2 / Tuyệt kỹ: toàn đội giảm 6% ST nhận 6s |

Phần độc quyền của hiệu ứng bộ (chỉ chủ sở hữu): xem bảng "Mức bộ" ở mục 2.2–2.7.

## Danh sách nhanh trang bị 4★ (2026-11-15)

Đồ 4★ **không có chủ sở hữu và không có hiệu ứng độc quyền** (Q9): vũ khí chỉ có chỉ số cộng và khóa theo loại vũ khí; bộ vết thánh có hiệu ứng bộ 2 / 3 món, chỉ phần chung, số khoảng một nửa 5★. Mỗi loại vũ khí có 1 vũ khí 4★ và 1 bộ vết thánh 4★ cùng hệ với nhân vật dùng loại vũ khí đó. Nguồn: tất cả ra ở **Banner trang bị thường**; bậc 4★ của banner trang bị 5★ chỉ có Lõi vũ khí hỏa tinh, Đại kiếm Dung Nham, bộ Ấn Viêm Hoàng, bộ Ấn Nham Thạch và 2 vết thánh lẻ (4 bộ mới 2026-11-15 chỉ vào banner thường). Số là số tạm trong `data/equipment/`.

### Vũ khí 4★ (6 món)

| # | Tên | Loại | Hợp với | Data ID | Chỉ số cộng | Mô tả sơ qua |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Lõi vũ khí hỏa tinh | Kiếm | Enkiba (Hỏa) | `eq_weapon_flame` | ATK 160, Tỉ lệ chí mạng +5% | Kiếm công cân bằng, đi cùng bộ Ấn Viêm Hoàng |
| 2 | Đại kiếm Dung Nham | Đại kiếm | Iwagane (Địa) | `eq_weapon_greatsword_magma` | ATK 170, ST chí mạng +10% | ATK cao nhất bậc 4★; món đề cử của banner trang bị thường |
| 3 | Cung Lốc Xoáy | Cung | Kazeyumi (Phong) | `eq_weapon_bow_whirlwind` | ATK 155, Tỉ lệ chí mạng +5% | Cung chí mạng, đi cùng bộ Ấn Lốc Xoáy |
| 4 | Song đao Lôi Đình | Song đao | Raikiba (Lôi) | `eq_weapon_blades_thunderclap` | ATK 160, ST chí mạng +10% | Song đao nhiều đòn, ST chí mạng cao, đi cùng bộ Ấn Lôi Đình |
| 5 | Trượng Bình Minh | Trượng | Hikarine (Quang) | `eq_weapon_staff_dawnlight` | ATK 140, HP +800 | Trượng hỗ trợ: ATK thấp hơn, thêm HP, đi cùng bộ Ấn Bình Minh |
| 6 | Lưỡi hái Dạ Ảnh | Lưỡi hái | Yomigari (Ám) | `eq_weapon_scythe_nightshade` | ATK 170, Tỉ lệ chí mạng +4% | Lưỡi hái ATK cao, đi cùng bộ Ấn Dạ Ảnh |

### Bộ vết thánh 4★ (6 bộ × 3 món = 18 món)

Chỉ số cộng theo hai khuôn:
- **Khuôn công** (Viêm Hoàng, Lốc Xoáy, Lôi Đình, Dạ Ảnh): Đầu ATK 60 + Tỉ lệ chí mạng 6% · Thân ATK 40 + HP 1500 · Chân ATK 50 + Giảm hồi chiêu 6%.
- **Khuôn thủ** (Nham Thạch, Bình Minh): Đầu ATK 30 + HP 800 · Thân HP 1600 + DEF 80 · Chân ATK 40 + DEF 60 + Giảm hồi chiêu 5%.

| Bộ | Hệ (nhân vật) | Khuôn | Đầu / Thân / Chân (Data ID) | 2 món | 3 món |
| --- | --- | --- | --- | --- | --- |
| Ấn Viêm Hoàng | Hỏa (Enkiba) | Công | `eq_stigma_{top,mid,bot}_blaze` | +5% ST Hỏa *(chỉ hệ Hỏa)* | Kẻ địch đang Cháy chịu +4% ST Hỏa từ người đeo *(chỉ hệ Hỏa)* |
| Ấn Nham Thạch | Địa (Iwagane) | Thủ | `eq_stigma_{top,mid,bot}_bedrock` | +5% ST Địa *(chỉ hệ Địa)* | Người đeo giảm 3% ST nhận |
| Ấn Lốc Xoáy | Phong (Kazeyumi) | Công | `eq_stigma_{top,mid,bot}_whirlwind` | +5% ST Phong *(chỉ hệ Phong)* | Tốc độ nạp EN +5% |
| Ấn Lôi Đình | Lôi (Raikiba) | Công | `eq_stigma_{top,mid,bot}_thunderclap` | +5% ST Lôi *(chỉ hệ Lôi)* | +4% ST lên kẻ địch mang hiệu ứng nguyên tố |
| Ấn Bình Minh | Quang (Hikarine) | Thủ | `eq_stigma_{top,mid,bot}_dawnlight` | +5% ST Quang *(chỉ hệ Quang)* | Hiệu quả hồi máu +4% |
| Ấn Dạ Ảnh | Ám (Yomigari) | Công | `eq_stigma_{top,mid,bot}_nightshade` | +5% ST Ám *(chỉ hệ Ám)* | +4% ST lên kẻ địch bị giảm DEF (Nguyền cũng tính) |

Tên từng món theo mẫu "Ấn <tên bộ> (Đầu / Thân / Chân)", ví dụ Ấn Lôi Đình (Thân).

### Vết thánh 4★ lẻ (không thuộc bộ)

| Tên | Ô | Data ID | Chỉ số cộng | Mô tả sơ qua |
| --- | --- | --- | --- | --- |
| Ấn Hộ Vệ (Thân) | Thân | `eq_stigma_mid_guardian` | HP 1800, DEF 90 | Thân thủ thuần, HP / DEF cao nhất bậc 4★, không có hiệu ứng bộ |
| Ấn Đồng Hồ Cát (Chân) | Chân | `eq_stigma_bot_hourglass` | HP 400, Giảm hồi chiêu 8% | Chân giảm hồi chiêu cao nhất bậc 4★, không có hiệu ứng bộ |

---

## 0. Quy ước chung

### Hai tầng hiệu ứng

Mỗi vũ khí và mỗi vết thánh 5★ đều có 2 tầng hiệu ứng:

| Tầng | Ai nhận | Ghi chú |
| --- | --- | --- |
| **Hiệu ứng chung** | Mọi nhân vật đang đeo | Kể cả khi không phải chủ sở hữu |
| **Hiệu ứng độc quyền** | Chỉ **chủ sở hữu** (`owner_id`) | Nhân vật khác đeo cùng món thì **không** kích hoạt |

Mỗi món có trường `owner_id` (Data ID của **giáp**, ví dụ `char_fire_01`). Hiệu ứng độc quyền kiểm tra `wearer_id == owner_id`, so theo giáp chứ không theo `person_id`: giáp khác của cùng nhân vật **không** nhận hiệu ứng độc quyền (owner, 2026-11-14, mục 5.5 Q1). Chỉ cần đổi dữ liệu là đổi được chủ sở hữu.

### Thuật ngữ

- **ST** = sát thương. **ST nguyên tố** = ST của nguyên tố nhân vật gây ra.
- **Toàn đội** = cả 3 nhân vật, gồm 2 dự bị. Buff toàn đội đang chạy thì nhân vật vào sân nhận phần thời gian còn lại (CHARACTER_SKILLS 8.1).
- **Cộng hưởng nguyên tố:** người đeo cùng nguyên tố với món đồ thì nhận thêm ST nguyên tố (thay cho đặc tính tương thích của bản tham khảo).
- **Buff độc lập:** nhân với các nguồn khác, không cộng vào nhóm % chung.
- **Không cộng dồn:** cùng ID hiệu ứng từ nhiều người đeo thì chỉ lấy giá trị cao nhất, làm mới thời gian.
- **Làm mới:** nhận lại hiệu ứng khi còn hiệu lực thì tính lại thời gian, không tăng giá trị.
- **"A → B" (sửa giá trị gốc):** nhiều nguồn cùng sửa một giá trị thì **cộng dồn phần tăng** vào giá trị gốc (owner, 2026-11-14, mục 5.5 Q3). Ví dụ Raikiba Bùng nổ Sét: gốc 150%, vũ khí +40, Thân +20 → 210%. Iwagane Cốt Đá: gốc 3%, vũ khí +0.5, Thân +0.5 → 4% mỗi tầng. Kết quả vẫn bị chặn bởi các trần ở mục 3.4.
- CDR vẫn tối đa 40% (CHARACTER_SKILLS mục 0). Rút CD (trừ thẳng vào thời gian hồi còn lại) **chỉ có ở hiệu ứng độc quyền**, của vũ khí hoặc của vết thánh, không có ở hiệu ứng chung. Rút CD chỉ có tác dụng khi kĩ năng đang hồi. Nó không tính vào trần CDR 40%, nhưng CD thực tế vẫn không xuống dưới sàn CD (mục 3.4, dòng 1). Mỗi cơ chế rút CD có mức tối đa riêng cho mỗi chu kỳ hồi (owner, 2026-11-14, mục 5.5 Q5).

### Cỡ số

- Hiệu ứng chung: +5–12%. Ngoại lệ: Cộng hưởng nguyên tố của vũ khí là chỉ số chính, +15%, nằm ngoài khoảng này (owner, 2026-11-14, mục 5.5 Q6).
- Hiệu ứng độc quyền và buff toàn đội: +6–25%.
- Mọi buff toàn đội có thời lượng 5–8s và có ICD, để không thành buff vĩnh viễn.

### Vũ khí và Kĩ năng vũ khí (skill_2)

Kĩ năng vũ khí (`{id nhân vật}.weapon`) **thuộc về nhân vật**, vũ khí 5★ **nâng cấp** nó. Mỗi vũ khí có 2 dạng nâng cấp:

- **Dạng chung** (mọi người đeo): áp lên skill_2 của chính người đeo, **không giảm CD**.
- **Dạng độc quyền** (chỉ chủ sở hữu): thay CD và thêm hiệu ứng riêng.
- **Mô tả hiển thị cho người chơi** (qua `tr()`): "Giảm hồi chiêu chỉ có tác dụng với chủ sở hữu của vũ khí này. Nhân vật khác đeo vẫn nhận các hiệu ứng còn lại." Mô tả này đặt ở dòng Nâng cấp skill_2 của mọi vũ khí.

Điều này khác với ghi chú ở CHARACTER_SKILLS mục 0 ("kỹ năng đi theo vũ khí"). CHARACTER_SKILLS giữ nguyên; quy tắc ở đây được ưu tiên (mục 5.2).

### Vết thánh

- **Quy ước đặt tên:** mỗi bộ là một nhân vật nữ anime lấy cảm hứng từ một nhà văn hoặc nhà khoa học đã mất, đặt tên bộ theo tên người đó. 3 món Đầu, Thân, Chân mang tên 3 tác phẩm hoặc phát minh của họ. Đây là nhân vật vẽ lại theo phong cách riêng của game, không phải chân dung thật.
- 1 nhân vật có 1 bộ gồm 3 món: **Đầu**, **Thân**, **Chân** (ô `stigma_top`, `stigma_mid`, `stigma_bot`). Cả 3 đều là 5★.
- Mỗi món có hiệu ứng chung và hiệu ứng độc quyền.
- **Hiệu ứng chung gắn nguyên tố:** phần nào nêu tên nguyên tố (ví dụ "ST Hỏa") hoặc dùng trạng thái riêng của nguyên tố (Cháy, Dấu Sét, Nguyền, Phán quyết, Nhiệt, Cốt Đá) chỉ có tác dụng khi người đeo mang đúng nguyên tố của bộ (`wearer.element == set.element`). Người đeo khác nguyên tố thì phần đó **không kích hoạt** và không được thay bằng giá trị khác. Các phần không có nhãn *(chỉ hệ X)* có tác dụng với mọi nguyên tố. Dữ liệu: trường `requires_element` trên từng dòng hiệu ứng.
- Đeo **2 món** cùng bộ: kích hoạt **Hiệu ứng bộ 2 món**. Đeo **3 món**: kích hoạt thêm **Hiệu ứng bộ 3 món**. Mỗi mức đều có phần chung và phần độc quyền.
- Thuật ngữ trạng thái và số liệu gốc (Nhiệt, Cốt Đá, Dấu Sét, Nguyền, Phán quyết, Cháy...) lấy từ CHARACTER_SKILLS.

---

## 1. Vũ khí 5★

### 1.1 Enkiba — ★5 Kiếm "Hoàng Hôn Thiêu Rụi" (`wpn_fire_01`, owner `char_fire_01`)

| Mục | Hiệu ứng chung (mọi người đeo) | Hiệu ứng độc quyền (chỉ Enkiba) |
| --- | --- | --- |
| Cộng hưởng nguyên tố | Người đeo hệ Hỏa: +15% ST Hỏa | — |
| Nội tại 1 | Người đeo +8% tất cả ST | Toàn đội +8% tất cả ST. +8% nữa khi Enkiba đang có ≥ 3 Nhiệt |
| Nội tại 2 | Kẻ địch đang Cháy chịu +8% ST Hỏa từ người đeo *(chỉ hệ Hỏa)* | Kẻ địch đang Choáng chịu +15% tất cả ST từ Enkiba |
| Nâng cấp skill_2 | skill_2 của người đeo áp Cháy 3s lên mục tiêu trúng *(chỉ hệ Hỏa)*. | CD 12.0s → 10.0s. Nung chảy −10% DEF → −15% DEF. Bonus +25% của skill_2 vẫn cần đủ 5 Nhiệt, nhưng chỉ tiêu 3 tầng (giữ lại 2) thay vì tiêu hết. Trúng mục tiêu: toàn đội +10% ST Hỏa 8s (ICD 10s, làm mới) |
| Kĩ năng tăng thêm | Khi người đeo dùng Tuyệt kỹ: +6% tất cả ST trong 6s | Hỏa Hoàng kéo dài 8s → 10s |

### 1.2 Kazeyumi — ★5 Cung "Hơi Thở Cuối Mùa Gió" (`wpn_wind_01`, owner `char_wind_01`)

| Mục | Hiệu ứng chung | Hiệu ứng độc quyền (chỉ Kazeyumi) |
| --- | --- | --- |
| Cộng hưởng nguyên tố | Người đeo hệ Phong: +15% ST Phong | — |
| Nội tại 1 | Người đeo +8% tốc độ di chuyển, +6% tất cả ST | Toàn đội +6% tốc độ nạp EN |
| Nội tại 2 | Kẻ địch đang Chậm chịu +8% ST từ người đeo | Kẻ địch trong Phong Vực chịu +12% ST từ Kazeyumi |
| Nâng cấp skill_2 | skill_2 của người đeo thêm Chậm 20% trong 2s lên mục tiêu trúng. | CD 13.0s → 11.0s. Bonus mục tiêu đứng trong Phong Vực +25% → +35%. Né hoàn hảo: skill_2 giảm 3.0s CD (ICD 8s) |
| Kĩ năng tăng thêm | Khi người đeo bắn trúng 2 kẻ địch khác nhau trong 4s: +8% tốc độ di chuyển 4s | Đồng đội trong Phong Vực +10% ST nguyên tố |

### 1.3 Raikiba — ★5 Song đao "Hai Tiếng Sấm" (`wpn_lightning_01`, owner `char_lightning_01`)

| Mục | Hiệu ứng chung | Hiệu ứng độc quyền (chỉ Raikiba) |
| --- | --- | --- |
| Cộng hưởng nguyên tố | Người đeo hệ Lôi: +15% ST Lôi | — |
| Nội tại 1 | Người đeo +8% tốc độ tấn công, +6% tất cả ST | Sau mỗi Bùng nổ Sét, toàn đội +8% tốc độ tấn công trong 6s (làm mới, ICD 4s) |
| Nội tại 2 | Kẻ địch đang mang hiệu ứng nguyên tố chịu +8% tất cả ST từ người đeo | Bùng nổ Sét +40% ST (150% → 190% ATK) |
| Nâng cấp skill_2 | skill_2 của người đeo thêm 1 Dấu Sét lên mục tiêu trúng *(chỉ hệ Lôi)*. | CD 11.0s → 9.0s. skill_2 áp 2 Dấu Sét mỗi lượt đao thay vì 1. Có thêm cửa sổ đòn thường: khóa đòn thường 800 ms → 500 ms |
| Kĩ năng tăng thêm | Gây hiệu ứng nguyên tố lên kẻ địch: người đeo +6% tốc độ nạp EN trong 4s (ICD 4s) | Mỗi Bùng nổ Sét hồi 8 EN cho Raikiba (ICD 4s) |

### 1.4 Hikarine — ★5 Trượng "Nhật Miện Phán Quyết" (`wpn_light_01`, owner `char_light_01`)

| Mục | Hiệu ứng chung | Hiệu ứng độc quyền (chỉ Hikarine) |
| --- | --- | --- |
| Cộng hưởng nguyên tố | Người đeo hệ Quang: +15% ST Quang | — |
| Nội tại 1 | Người đeo +10% hiệu quả hồi máu | Toàn đội +8% hiệu quả hồi máu |
| Nội tại 2 | Kẻ địch có Phán quyết chịu +6% ST từ người đeo *(chỉ hệ Quang)* | Phán quyết từ Hikarine +8% → +12% ST nhận (toàn đội đều hưởng) |
| Nâng cấp skill_2 | skill_2 của người đeo hồi cho toàn đội 3% HP tối đa nếu trúng ít nhất 1 kẻ địch. | CD 12.0s → 10.0s. Hồi đồng đội trong vùng 60% → 90% ATK. Đồng đội trong vùng +10% tất cả ST trong 6s (làm mới) |
| Kĩ năng tăng thêm | Khi hồi máu cho đồng đội đang dưới 50% HP: người đeo +6% ST 5s (ICD 8s) | Khiên từ hồi thừa tối đa 8% → 12% HP tối đa |

### 1.5 Yomigari — ★5 Lưỡi hái "Liềm Khế Ước Trăng Khuyết" (`wpn_dark_01`, owner `char_dark_01`)

| Mục | Hiệu ứng chung | Hiệu ứng độc quyền (chỉ Yomigari) |
| --- | --- | --- |
| Cộng hưởng nguyên tố | Người đeo hệ Ám: +15% ST Ám | — |
| Nội tại 1 | Người đeo +8% tất cả ST. +4% hút máu | Toàn đội +6% hút máu khi đánh kẻ địch đang Nguyền |
| Nội tại 2 | Hạ gục kẻ địch: người đeo hồi 2% HP tối đa (ICD 2s) | Hạ gục kẻ địch giảm 1.5s CD Kĩ năng thường và Kĩ năng vũ khí (ICD 1.0s) |
| Nâng cấp skill_2 | skill_2 của người đeo Trói 0.8s (boss 0.3s). | CD 12.0s → 10.0s. Nguyền từ skill_2: −15% → −20% DEF. Hút máu skill_2 6% → 10% |
| Kĩ năng tăng thêm | Kẻ địch dưới 30% HP chịu +8% ST từ người đeo | Hạ gục kẻ địch đang Nguyền: toàn đội +8% ST lên mục tiêu Nguyền trong 6s |

### 1.6 Iwagane — ★5 Đại kiếm "Cốt Sơn Bất Khuất" (`wpn_earth_01`, owner `char_earth_01`)

| Mục | Hiệu ứng chung | Hiệu ứng độc quyền (chỉ Iwagane) |
| --- | --- | --- |
| Cộng hưởng nguyên tố | Người đeo hệ Địa: +15% ST Địa | — |
| Nội tại 1 | Người đeo +8% tất cả ST, giảm 6% ST nhận | Toàn đội giảm 6% ST nhận trong 6s sau khi Iwagane dùng skill_2 (làm mới, ICD 10s) |
| Nội tại 2 | Kẻ địch đang bị giảm DEF chịu +8% ST từ người đeo | Kẻ địch mang Phá Giáp chịu +12% ST từ Iwagane |
| Nâng cấp skill_2 | skill_2 của người đeo: giảm 20% ST nhận trong lúc dùng. | CD 14.0s → 12.0s. Bonus Cốt Đá kích hoạt ở **4 tầng** thay vì 5. Phá Giáp −15% → −20% DEF. Nổ cuối 130% → 180% ATK |
| Kĩ năng tăng thêm | Nhận ST: người đeo +4% DEF trong 5s (ICD 2s) | Cốt Đá tối đa 5 tầng, mỗi tầng giảm 3% → 3.5% ST nhận |

---

## 2. Vết thánh 5★

### Bảng tên vết thánh (tên tạm)

| Nhân vật | Bộ (nguồn cảm hứng) | Đầu | Thân | Chân |
| --- | --- | --- | --- | --- |
| Enkiba | Antoine Lavoisier | Oxy | Định Luật Bảo Toàn Khối Lượng | Chuyên Luận Hóa Học |
| Kazeyumi | Leonardo da Vinci | Chong Chóng Trên Không | Cỗ Máy Cánh Chim | Bản Thảo Codex |
| Raikiba | Benjamin Franklin | Con Diều Trong Bão | Cột Thu Lôi | Niên Lịch Richard Nghèo |
| Hikarine | Florence Nightingale | Ngọn Đèn Scutari | Biểu Đồ Hoa Hồng | Ghi Chép Về Điều Dưỡng |
| Yomigari | Edgar Allan Poe | Con Quạ | Trái Tim Tố Giác | Chiếc Hố Và Con Lắc |
| Iwagane | Charles Darwin | Chuyến Đi Beagle | Chọn Lọc Tự Nhiên | Lý Luận Tiến Hoá |

Tên mới thay cho tên bộ cũ (Lễ Phục Hỏa Hoàng, Áo Choàng Lữ Phong, Giáp Sấm Tích, Thánh Y Hào Quang, Bóng Phục Dạ Vương, Giáp Cốt Đá). ID dữ liệu giữ nguyên.

**Tên bộ (owner, 2026-11-14, mục 5.5 Q10):** bỏ "Nobel" và "Tesla" vì là thương hiệu đang hoạt động (quỹ, công ty). Hỏa đổi thành Antoine Lavoisier (người giải thích sự cháy), Lôi đổi thành Benjamin Franklin (thí nghiệm sét). Ghi nguồn cảm hứng và quyết định vào `docs/ASSET_LICENSES.md`. Không dùng nhân vật từ tiểu thuyết còn bản quyền.

### 2.1 Hiệu ứng chung theo từng món (mọi người đeo)

| Bộ | Đầu | Thân | Chân |
| --- | --- | --- | --- |
| Antoine Lavoisier | ST Hỏa +10% *(chỉ hệ Hỏa)* | HP tối đa +8%. Thời gian bị Cháy −30% *(chỉ hệ Hỏa)* | Tất cả ST +8% |
| Leonardo da Vinci | ST Phong +10% *(chỉ hệ Phong)* | Tốc độ di chuyển +8% | Tốc độ nạp EN +10% |
| Benjamin Franklin | ST Lôi +10% *(chỉ hệ Lôi)* | Tốc độ tấn công +8% | +8% ST lên kẻ địch mang hiệu ứng nguyên tố |
| Florence Nightingale | ST Quang +10% *(chỉ hệ Quang)* | Hiệu quả hồi máu +10% | HP tối đa +8% |
| Edgar Allan Poe | ST Ám +10% *(chỉ hệ Ám)* | Hút máu +5% | +8% ST lên kẻ địch bị giảm DEF. Nếu người đeo hệ Ám, kẻ địch đang Nguyền cũng được tính *(chỉ hệ Ám)* |
| Charles Darwin | ST Địa +10% *(chỉ hệ Địa)* | Giảm 6% ST nhận | HP tối đa +12% |

### 2.2 Enkiba — ★5 Bộ "Antoine Lavoisier" (`set_fire_01`, owner `char_fire_01`)

| Món | Hiệu ứng độc quyền (chỉ Enkiba) |
| --- | --- |
| Đầu "Oxy" `art_fire_01_top` | Nhiệt tồn tại 6s → 8s |
| Thân "Định Luật Bảo Toàn Khối Lượng" `art_fire_01_mid` | Mỗi tầng Nhiệt +4% → +5% ATK (tối đa +25%) |
| Chân "Chuyên Luận Hóa Học" `art_fire_01_bot` | ICD cộng tầng Nhiệt 0.3s → 0.2s |

| Mức bộ | Hiệu ứng chung | Hiệu ứng độc quyền |
| --- | --- | --- |
| **2 món** | Người đeo +10% ST Hỏa *(chỉ hệ Hỏa)*. Kẻ địch đang Cháy chịu +5% ST Hỏa từ người đeo *(chỉ hệ Hỏa)* | Kĩ năng thường trúng mục tiêu: +1 tầng Nhiệt ngay (ICD 3s) |
| **3 món** | Khi người đeo dùng Tuyệt kỹ: toàn đội +8% tất cả ST trong 8s | Đạt 5 Nhiệt: toàn đội +10% ST Hỏa 6s (làm mới, ICD 8s). Hỏa Hoàng +20% → +30% ST |

### 2.3 Kazeyumi — ★5 Bộ "Leonardo da Vinci" (`set_wind_01`, owner `char_wind_01`)

| Món | Hiệu ứng độc quyền (chỉ Kazeyumi) |
| --- | --- |
| Đầu "Chong Chóng Trên Không" `art_wind_01_top` | Gió Thuận kích hoạt khi bắn trúng 2 kẻ địch khác nhau thay vì 3 |
| Thân "Cỗ Máy Cánh Chim" `art_wind_01_mid` | Buff Gió Thuận kéo dài 5s → 7s |
| Chân "Bản Thảo Codex" `art_wind_01_bot` | ICD Gió Thuận 10s → 8s |

| Mức bộ | Hiệu ứng chung | Hiệu ứng độc quyền |
| --- | --- | --- |
| **2 món** | Người đeo +10% ST Phong *(chỉ hệ Phong)*. Né hoàn hảo: +10% tất cả ST 4s | Phong Vực kéo dài +1.5s. Chậm trong vùng 20% → 25% |
| **3 món** | Bắn trúng ≥ 3 kẻ địch khác nhau trong 4s: toàn đội +8% ST nguyên tố 6s (ICD 10s) | Tuyệt kỹ: bão kéo dài +2s. Buff đồng đội trong bão +15% → +20% ST |

### 2.4 Raikiba — ★5 Bộ "Benjamin Franklin" (`set_lightning_01`, owner `char_lightning_01`)

| Món | Hiệu ứng độc quyền (chỉ Raikiba) |
| --- | --- |
| Đầu "Con Diều Trong Bão" `art_lightning_01_top` | Dấu Sét tồn tại 6s → 8s |
| Thân "Cột Thu Lôi" `art_lightning_01_mid` | Bùng nổ Sét 150% → 170% ATK |
| Chân "Niên Lịch Richard Nghèo" `art_lightning_01_bot` | ICD Bùng nổ mỗi mục tiêu 4s → 3s |

| Mức bộ | Hiệu ứng chung | Hiệu ứng độc quyền |
| --- | --- | --- |
| **2 món** | Người đeo +10% ST Lôi *(chỉ hệ Lôi)*. Mục tiêu đang có hiệu ứng nguyên tố chịu +6% tất cả ST từ toàn đội | Bùng nổ Sét lan 1 Dấu Sét sang kẻ địch gần nhất (ICD 4s) |
| **3 món** | Gây hiệu ứng nguyên tố lên kẻ địch: người đeo +6% tốc độ tấn công 4s (ICD 4s) | Quá Tải +25% → +30% tốc độ tấn công. Sau Bùng nổ Sét: toàn đội +8% ST Lôi 6s |

### 2.5 Hikarine — ★5 Bộ "Florence Nightingale" (`set_light_01`, owner `char_light_01`)

| Món | Hiệu ứng độc quyền (chỉ Hikarine) |
| --- | --- |
| Đầu "Ngọn Đèn Scutari" `art_light_01_top` | Tỉ lệ hồi thừa chuyển thành Khiên 50% → 60% |
| Thân "Biểu Đồ Hoa Hồng" `art_light_01_mid` | Khiên tối đa 8% → 10% HP tối đa mục tiêu |
| Chân "Ghi Chép Về Điều Dưỡng" `art_light_01_bot` | ICD Ân Huệ Ánh Sáng 2s → 1.5s |

| Mức bộ | Hiệu ứng chung | Hiệu ứng độc quyền |
| --- | --- | --- |
| **2 món** | Người đeo +10% ST Quang *(chỉ hệ Quang)*. Mọi hồi máu của người đeo +8% | Kĩ năng thường gỡ 2 hiệu ứng xấu thay vì 1. Hệ số cho đồng đội thấp máu nhất ×1.3 → ×1.5 |
| **3 món** | Hồi máu cho đồng đội dưới 50% HP: toàn đội +8% ST 5s (ICD 8s) | Tuyệt kỹ: giảm ST nhận của đồng đội 25% → 30%. Hồi 4% → 5% HP tối đa mỗi giây |

### 2.6 Yomigari — ★5 Bộ "Edgar Allan Poe" (`set_dark_01`, owner `char_dark_01`)

| Món | Hiệu ứng độc quyền (chỉ Yomigari) |
| --- | --- |
| Đầu "Con Quạ" `art_dark_01_top` | Hồi máu từ sát thương lên mục tiêu Nguyền 4% → 6% (boss 2% → 3%) |
| Thân "Trái Tim Tố Giác" `art_dark_01_mid` | Nguyền −15% → −18% DEF |
| Chân "Chiếc Hố Và Con Lắc" `art_dark_01_bot` | ICD phần thưởng hạ gục 1.0s → 0.6s |

| Mức bộ | Hiệu ứng chung | Hiệu ứng độc quyền |
| --- | --- | --- |
| **2 món** | Người đeo +10% ST Ám *(chỉ hệ Ám)*. Hạ gục kẻ địch: hồi 3% HP tối đa (ICD 2s) | Hạ gục kẻ địch: giảm 1.5s SI-CD (kĩ năng vào sân), không vượt 3.0s mỗi chu kỳ |
| **3 món** | Kẻ địch dưới 30% HP chịu +10% ST từ người đeo | Thu hoạch: ngưỡng xử tử 20% → 25% HP. Dạ Vương +15% → +20% ST đòn thường. Hạ gục kẻ địch đang Nguyền: Nguyền lan sang 1 kẻ địch gần nhất, giữ thời gian còn lại |

### 2.7 Iwagane — ★5 Bộ "Charles Darwin" (`set_earth_01`, owner `char_earth_01`)

| Món | Hiệu ứng độc quyền (chỉ Iwagane) |
| --- | --- |
| Đầu "Chuyến Đi Beagle" `art_earth_01_top` | Cốt Đá tồn tại 8s → 10s |
| Thân "Chọn Lọc Tự Nhiên" `art_earth_01_mid` | Mỗi tầng Cốt Đá giảm 3% → 3.5% ST nhận |
| Chân "Lý Luận Tiến Hoá" `art_earth_01_bot` | ICD cộng tầng Cốt Đá 0.5s → 0.3s |

| Mức bộ | Hiệu ứng chung | Hiệu ứng độc quyền |
| --- | --- | --- |
| **2 món** | Người đeo +10% ST Địa *(chỉ hệ Địa)*. Dưới 50% HP: giảm thêm 8% ST nhận | Khiên Đá hấp thụ tối đa 20% → 25% HP tối đa |
| **3 món** | Dùng skill_2 hoặc Tuyệt kỹ: toàn đội giảm 6% ST nhận 6s (ICD 10s) | Thạch Thần: giảm ST nhận −40% → −45%, +20% → +25% ATK |

---

## 3. Cân bằng: quyết định đã chốt và giới hạn cứng

### 3.1 Giảm hồi chiêu chỉ nằm ở hiệu ứng độc quyền

- Hiệu ứng chung của vũ khí **không** giảm CD. Chỉ chủ sở hữu được giảm CD skill_2 (các bảng ở mục 1).
- Các cơ chế rút CD khác (Kazeyumi né hoàn hảo −3.0s, Yomigari hạ gục −1.5s, SI-CD của bộ Poe) đều là hiệu ứng độc quyền, theo cùng quy tắc.
- Người chơi được báo bằng mô tả ở mục 0 (Mô tả hiển thị cho người chơi).
- Giá trị giảm CD ở hiệu ứng độc quyền có thể tinh chỉnh trong config (`weapon_owner_cd`), hoặc giữ nguyên chờ bản nâng lên 6★ (tính năng Pri-arms trong tương lai, chưa thiết kế). Hiện giữ nguyên giá trị trong bảng.

### 3.2 Hiệu ứng chung của vũ khí và vết thánh gắn nguyên tố

- Phần nào gắn nguyên tố chỉ có tác dụng với nhân vật mang nguyên tố đó. Các phần đã gắn nhãn *(chỉ hệ X)* trong mục 1 (vũ khí) và mục 2 (vết thánh). Áp dụng cho vũ khí từ quyết định 5.3 (owner, 2026-11-14).
- Mục đích: tránh hiệu ứng như "ST Hỏa" rơi vào nhân vật không có nguồn Hỏa, hoặc trạng thái riêng (Nguyền, Cháy) bị gọi khi người đeo không tạo ra được.
- Test: mỗi dòng có `requires_element` được kiểm tra với người đeo đúng và sai nguyên tố.

### 3.3 Buff toàn đội

- Cùng ID chỉ lấy giá trị cao nhất, không cộng dồn. Khác ID thì nhân độc lập, tổng có thể khoảng +35–45% tất cả ST khi cả 3 nhân vật đeo 5★. Chặn bởi mục 3.4.
- Hiệu ứng độc quyền kiểm tra `wearer_id == owner_id`. Test: nhân vật khác đeo cùng món thì phần độc quyền không kích hoạt, phần chung vẫn kích hoạt.

### 3.4 Ngưỡng và giới hạn cứng (Claude tự kiểm tra)

**Nguyên tắc:** ưu tiên thiết kế để **không thể vượt ngưỡng**, tránh lỗi bất định khó sửa. Mọi giới hạn nằm trong config và được chặn ở một nơi duy nhất (ví dụ `StatResolver`), không rải rác trong từng hiệu ứng. Giá trị trần dưới đây đã được owner xác nhận ngày 2026-11-14 (mục 5.4), vẫn chỉnh được trong config sau playtest.

**Quy trình cho Claude:** sau khi cài đặt, tự viết và chạy test GdUnit4 cho từng dòng bên dưới (nguồn ngẫu nhiên có seed), ghi kết quả vào dev log. Nếu test cho thấy vượt ngưỡng hoặc hành vi không xác định, ưu tiên siết giới hạn hoặc bỏ cơ chế gây lỗi thay vì vá bằng ngoại lệ, và báo cho chủ dự án trước khi sửa tài liệu này.

| # | Hạng mục | Rủi ro | Giới hạn đề xuất | Test cần có |
| --- | --- | --- | --- | --- |
| 1 | CD skill_2 | CDR 40% + CD vũ khí độc quyền + cơ chế rút CD riêng cùng lúc | CD thực tế không dưới 50% CD sau khi vũ khí độc quyền giảm (ví dụ Raikiba 9.0s → sàn 4.5s), không âm | Mọi vũ khí chủ sở hữu, CDR tối đa, kích hoạt cơ chế rút CD liên tục |
| 2 | Nhiệt (Enkiba) | Vượt 5 tầng, âm tầng, bonus tiêu 3 tầng, bộ 3 món kích hoạt lặp | 0–5 tầng; bộ 3 món có ICD 8s | 0, 4, 5 tầng; ICD cộng tầng 0.2s; tiêu 3 tầng rồi đạt 5 lại |
| 3 | Tốc độ tấn công (Raikiba) | Bị động, Quá Tải, Thân, bộ 3 món, vũ khí cộng chồng | Tổng không quá +60% | Bật hết nguồn cùng lúc |
| 4 | Giảm ST nhận (Iwagane) | Cốt Đá, Giáp Địa, Thạch Thần, giáp cứng, buff toàn đội nhân chồng lên gần miễn nhiễm | Nhân độc lập, ST nhận tối thiểu 20% (giảm tối đa 80%) | Bật hết nguồn cùng lúc, kiểm tra không về 0 |
| 5 | Hút máu (Yomigari) | Vũ khí, Thân, Dạ Vương, skill_2, Tuyệt kỹ cộng chồng | Tổng hút máu không quá 30% | Bật hết nguồn cùng lúc |
| 6 | Hiệu quả hồi máu (Hikarine) | Vũ khí, Thân, bộ 2 món cộng chồng | Tổng không quá +50% | Bật hết nguồn cùng lúc |
| 7 | Khiên | Nhiều nguồn khiên cộng chồng | Lấy khiên lớn nhất. Khiên từ hồi thừa (Hikarine) tối đa 12% HP tối đa; Khiên Đá (Iwagane) tối đa 25% HP tối đa | Khiên từ Hikarine và Iwagane cùng lúc |
| 8 | Tất cả ST toàn đội | 3 người đeo 5★, nhiều ID khác nhau | Tích các buff độc lập nhóm "tất cả ST" và "ST nguyên tố" không quá ×2.0. Không tính % ATK và giảm DEF | 3 nhân vật đeo đủ vũ khí và bộ |
| 9 | Ngưỡng HP (30%, 50%) | HP dao động quanh ngưỡng bật tắt liên tục | Đánh giá khi HP đổi, có ICD hoặc đệm 5% | HP dao động quanh 30% và 50% trong 1s |
| 10 | Cốt Đá (Iwagane) | Ngưỡng 4 tầng (vũ khí) và 5 tầng (gốc), tiêu hết tầng | 0–5 tầng, không âm | 3, 4, 5 tầng; hết hạn đúng lúc bấm skill_2 |
| 11 | Thu hoạch (Yomigari) | Ngưỡng xử tử 25% HP, khác biệt thường và boss | Boss không bị xử tử, thay bằng +25% ST | Đúng 25.0%, 25.01%, kẻ địch thường và boss |
| 12 | Gió Thuận (Kazeyumi) | Ngưỡng 2 mục tiêu khác nhau trong 4s | ICD 8s | 1, 2, 3 mục tiêu; mốc 4.0s |
| 13 | SI-CD giảm (Yomigari) | Rút SI-CD liên tục | Tối đa −3.0s mỗi chu kỳ, không âm | Hạ gục liên tiếp |
| 14 | Buff khi dự bị | Hết hạn đúng lúc chuyển nhân vật | Nhận phần thời gian còn lại, không nhận nếu đã hết | Chuyển đúng khoảnh khắc hết hạn |
| 15 | Nhiều người đeo cùng bộ | Cùng ID cộng dồn ngoài ý muốn | Cùng ID chỉ lấy giá trị cao nhất | 3 nhân vật cùng đeo |
| 16 | Làm tròn | Sai số số thực ở ngưỡng (25.0%) | So sánh có epsilon hoặc dùng số nguyên | Các ngưỡng ở mục 9–12 |


## 4. Cập nhật cần làm ở tài liệu khác

- **README OD-5** (vũ khí cố định hay đổi được): thiết kế này giả định **mọi nhân vật đeo được mọi vũ khí và vết thánh**. Nếu OD-5 giữ "cố định theo nhân vật" thì hiệu ứng chung vẫn hợp lệ nhưng không có tác dụng với người ngoài. Cần xác nhận.
- **CHARACTER_SKILLS mục 0** ("Kĩ năng vũ khí gắn với loại vũ khí"): **không sửa** (owner, 2026-11-14). Quy tắc "Kĩ năng vũ khí thuộc về nhân vật, vũ khí 5★ nâng cấp nó" nằm ở tài liệu này và được ưu tiên (mục 5.2).
- **Số loại vũ khí:** 6 loại (Kiếm, Cung, Song đao, Trượng, Lưỡi hái, Đại kiếm). Nếu mở đeo chéo, nên cân nhắc khóa loại vũ khí theo nhân vật để tránh Kazeyumi cầm Đại kiếm, hoặc cho phép và chỉ đổi animation.
- **Dữ liệu:** thêm `data/equipment/weapons/` và `data/equipment/artifacts/` (README mục 7), mỗi món có `owner_id`, `rarity: 5`, `slot` và `set_id` (với vết thánh).

---

## 5. Việc chờ xác nhận (ĐỌC PHẦN NÀY TRƯỚC khi cập nhật trang bị)

**Hướng dẫn cho Claude:** khi chủ dự án đưa tài liệu này và yêu cầu đọc rồi cập nhật trang bị, đọc phần 5 này **trước tiên**. Hỏi chủ dự án về từng mục còn "Chưa xác nhận", ghi quyết định vào đây, rồi mới sửa các phần khác của tài liệu và các tài liệu liên quan (README, CHARACTER_SKILLS). Chưa có quyết định thì không tự sửa README hay CHARACTER_SKILLS.

### 5.1 README OD-5: vũ khí và vết thánh cố định hay đeo chéo

- **Trạng thái:** Đã xác nhận (owner, 2026-11-14).
- **Vấn đề:** README ghi vũ khí cố định theo nhân vật. Thiết kế trong tài liệu này giả định mọi nhân vật đeo được mọi vũ khí và vết thánh, vì hiệu ứng chung phải có tác dụng với mọi người đeo.
- **Lựa chọn:**
  - A. Đeo chéo hoàn toàn (thiết kế hiện tại). Cần quyết định có đổi animation theo loại vũ khí hay không.
  - B. Đeo chéo nhưng khóa loại vũ khí theo nhân vật (ví dụ Kazeyumi chỉ dùng Cung). Hiệu ứng chung của vũ khí chỉ có ý nghĩa với các nhân vật cùng loại, vết thánh vẫn đeo chéo được.
  - C. Giữ cố định theo nhân vật. Hiệu ứng chung chỉ còn tác dụng cho đúng chủ sở hữu, cần viết lại yêu cầu "có tác dụng với toàn bộ người đeo".
- **Quyết định:** **B.** Vũ khí khóa theo loại vũ khí của nhân vật (`EquipmentDef.weapon_type` khớp `CharacterDef.weapon_type`, code đã có sẵn). Vết thánh đeo chéo được. Không cần làm animation theo loại vũ khí.
- **Hệ quả:** 6 nhân vật hiện dùng 6 loại vũ khí khác nhau, nên hiệu ứng chung của vũ khí 5★ tạm thời chỉ chủ sở hữu dùng được. Hiệu ứng chung giữ lại cho nhân vật hoặc giáp mới cùng loại sau này. README OD-5 ("fixed per character") vẫn đúng tinh thần: cần thêm ý "theo loại vũ khí".

### 5.2 CHARACTER_SKILLS mục 0: Kĩ năng vũ khí thuộc về ai

- **Trạng thái:** Chưa xác nhận.
- **Vấn đề:** Mục 0 hiện ghi "Kĩ năng vũ khí gắn với loại vũ khí. Nếu sau này cho đổi vũ khí (OD-5), kỹ năng này đi theo vũ khí". Thiết kế trong tài liệu này coi Kĩ năng vũ khí (`{id nhân vật}.weapon`) thuộc về nhân vật, vũ khí 5★ chỉ nâng cấp nó (CD và hiệu ứng).
- **Câu đề xuất thay thế:** "Kĩ năng vũ khí thuộc về nhân vật. Vũ khí 5★ nâng cấp CD và hiệu ứng của nó, xem EQUIPMENT_5STAR.md."
- **Phụ thuộc:** phụ thuộc mục 5.1. Nếu chọn C ở 5.1 thì có thể giữ nguyên câu cũ.
- **Quyết định (owner, 2026-11-14):** **Không sửa CHARACTER_SKILLS** (giữ quy tắc "không sửa" của AGENTS.md). Quy tắc mới ghi tại tài liệu này: Kĩ năng vũ khí (`{id nhân vật}.weapon`) thuộc về nhân vật, vũ khí 5★ nâng cấp CD và hiệu ứng của nó. Khi mâu thuẫn với dòng "Kĩ năng vũ khí gắn với loại vũ khí" ở CHARACTER_SKILLS mục 0, **tài liệu này được ưu tiên**. Ghi chú này cũng chép vào `docs/DEVELOPMENT_LOG.md`.

### 5.3 Quy tắc "chỉ hệ X" có áp dụng cho vũ khí không

- **Trạng thái:** Chưa xác nhận.
- **Vấn đề:** quy tắc nguyên tố ở mục 3.2 mới áp dụng cho vết thánh. Hiệu ứng chung của vũ khí vẫn có phần gắn nguyên tố (ví dụ vũ khí Enkiba: "Kẻ địch đang Cháy chịu +8% ST Hỏa từ người đeo"), có cùng nguy cơ lỗi khi người đeo khác nguyên tố.
- **Lựa chọn:** A. Áp dụng cùng quy tắc cho vũ khí (đề xuất). B. Giữ nguyên, vũ khí không khóa nguyên tố.
- **Quyết định (owner, 2026-11-14):** **A.** Hiệu ứng chung của vũ khí dùng cùng quy tắc với vết thánh (`requires_element`). Các dòng gắn nguyên tố đã gắn nhãn *(chỉ hệ X)* ở mục 1; quy tắc ghi ở mục 3.2.

### 5.4 Giá trị trần đề xuất ở mục 3.4

- **Trạng thái:** Đã xác nhận (owner, 2026-11-14). Các trần (CD không dưới 50% CD gốc, tốc độ tấn công +60%, ST nhận tối thiểu 20%, hút máu 30%, hồi máu +50%, khiên 12% HP, tích buff ×2.0) là đề xuất của Claude, chưa qua playtest.
- **Quyết định:** nhận các trần ở mục 3.4, với 3 chỉnh sửa (đã cập nhật vào bảng 3.4):
  1. **Khiên:** trần 12% HP chỉ áp cho khiên từ hồi thừa (Hikarine). Khiên Đá (Iwagane) trần riêng 25% HP. Nhiều khiên cùng lúc: lấy khiên lớn nhất.
  2. **Sàn CD:** CD thực tế không dưới 50% CD **sau khi vũ khí độc quyền đã giảm** (ví dụ Raikiba 9.0s → sàn 4.5s).
  3. **Trần ×2.0:** chỉ tính nhóm "tất cả ST" và "ST nguyên tố". Không tính % ATK (Nhiệt...) và giảm DEF kẻ địch.
- Số trần vẫn chỉnh được trong config sau playtest.

### 5.5 Câu hỏi bổ sung (Claude hỏi khi đọc tài liệu, 2026-11-14)

| # | Câu hỏi | Quyết định |
| --- | --- | --- |
| Q1 | Hiệu ứng độc quyền kiểm tra theo giáp (Data ID) hay theo nhân vật (`person_id`)? | **Theo giáp (Data ID)** (owner, 2026-11-14). Giáp mới của cùng nhân vật cần đồ 5★ riêng |
| Q2 | "skill_2 chỉ tiêu 3 Nhiệt thay vì 5": kích hoạt bonus ở 3 tầng, hay vẫn ở 5 tầng nhưng chỉ tiêu 3? | **Vẫn cần 5 tầng, chỉ tiêu 3, giữ lại 2** (owner, 2026-11-14). Đã sửa dòng Nâng cấp skill_2 ở mục 1.1 |
| Q3 | Nhiều nguồn cùng sửa một giá trị ("A → B") có cộng dồn không? (Raikiba Bùng nổ Sét: vũ khí 190%, Thân 170%; Iwagane Cốt Đá 3.5% ở cả vũ khí và Thân) | **Cộng dồn phần tăng** (owner, 2026-11-14). Raikiba 210%, Iwagane 4% mỗi tầng. Quy tắc ghi ở mục 0, Thuật ngữ |
| Q4 | Hiệu ứng trùng nguyên văn giữa vũ khí và bộ (Raikiba hồi 8 EN; Yomigari +8% ST lên mục tiêu Nguyền): giữ hay thay một dòng? | **Giữ dòng ở vũ khí, thay dòng ở bộ** (owner, 2026-11-14). Raikiba bộ 2 món: Bùng nổ Sét lan 1 Dấu Sét sang kẻ địch gần nhất (ICD 4s). Yomigari bộ 3 món: hạ gục mục tiêu Nguyền thì Nguyền lan sang 1 kẻ địch gần nhất, giữ thời gian còn lại. Đã sửa mục 2.4 và 2.6 |
| Q5 | Mục 0 "CD −X giây chỉ ở độc quyền của vũ khí" nhưng bộ Poe cũng giảm SI-CD; câu "chỉ áp dụng khi CD gốc đang chạy và bị chặn bởi sàn CD" cần viết lại | **Nhận câu viết lại** (owner, 2026-11-14): rút CD chỉ ở hiệu ứng độc quyền (vũ khí hoặc vết thánh), chỉ khi kĩ năng đang hồi, ngoài trần CDR 40% nhưng không dưới sàn CD, mỗi cơ chế có mức tối đa mỗi chu kỳ. Đã sửa mục 0 và tiêu đề 3.1 |
| Q6 | Cỡ số hiệu ứng chung +5–12% nhưng Cộng hưởng nguyên tố +15% | **Ghi là ngoại lệ, giữ +15%** (owner, 2026-11-14). Đã thêm vào mục 0, Cỡ số |
| Q7 | Nguồn đồ 5★: tỉ lệ, pity, banner nào | **Banner 5★ riêng** (owner, 2026-11-14). Số liệu ở mục 5.6 |
| Q8 | % hiệu ứng có tăng theo cấp cường hóa / tinh luyện không | **Cố định** (owner, 2026-11-14). Mọi hiệu ứng % đúng số trong bảng từ +0; cường hóa chỉ tăng chỉ số cộng thẳng (ATK / HP / DEF). Không có tinh luyện; nâng cấp hiệu ứng để dành cho bản 6★ |
| Q9 | Hiệu ứng bộ 2 / 3 món có làm cho đồ 4★ không | **Có, bản nhỏ** (owner, 2026-11-14). Bộ 4★ có hiệu ứng bộ 2 / 3 món, chỉ phần chung (không độc quyền), số khoảng một nửa 5★. Dùng chung hệ thống bộ với 5★. Claude đặt số khởi điểm cho các bộ 4★ đang có và ghi nhật ký |
| Q10 | Giữ tên người thật làm tên bộ, hay chỉ dùng tên tác phẩm / phát minh | **Đổi 2 bộ** (owner, 2026-11-14): Nobel → Antoine Lavoisier (Oxy / Định Luật Bảo Toàn Khối Lượng / Chuyên Luận Hóa Học), Tesla → Benjamin Franklin (Con Diều Trong Bão / Cột Thu Lôi / Niên Lịch Richard Nghèo). 4 bộ còn lại giữ. Ghi nguồn cảm hứng cả 6 bộ vào `docs/ASSET_LICENSES.md` |
| Q11 | Món 5★ trùng: không quy đổi. Thêm tính năng **phân giải trang bị** | _(owner, 2026-11-14: hỏi lại ở mục riêng, chưa thiết kế)_ |

### 5.6 Banner 5★ (owner, 2026-11-14)

| # | Mục | Quyết định |
| --- | --- | --- |
| 1 | Cấu trúc | Một banner chung cho vũ khí và vết thánh. Mỗi kỳ chỉ có **1 bộ đề cử 5★** (1 vũ khí + 3 vết thánh của một nhân vật) |
| 2 | Tỉ lệ 5★ | **Mỗi món 0.15%** (owner 2026-11-15; trước đó 1.5%, các số % dưới dòng này chia 10). Món đã có thì không ra lại cho tới khi đủ bộ (4 món còn thiếu: 6%; 3 món: 4.5%; 2 món: 3%; 1 món: 1.5%) |
| 3 | Đã đủ 4 món | Giữ nguyên tỉ lệ banner (mỗi món 1.5%, tổng 6%), có thể ra món trùng |
| 4 | Pity cứng | Tối đa **50 lượt** cho mỗi món 5★. Ra 5★ thì pity về 0. Pity chỉ chắc chắn ra **món 5★ chưa có** (khi đã đủ bộ thì ra món bất kỳ trong bộ) |
| 5 | Pity mềm | Từ lượt **30**, tỉ lệ 5★ **+10% một lần** (giống banner nhân vật), giữ tới khi ra 5★ hoặc chạm pity 50 |
| 6 | Pity qua kỳ | **Về 0** khi sang banner mới, **kể cả khi banner cũ chạy lại** |
| 7 | Các bậc khác | Giữ như banner tiếp tế (vũ khí 4★ 2.87%, vết thánh 4★ 14%, vũ khí 3★ 10.7%, vết thánh 3★ 14.43%, pity 4★ 60, 10 lượt chắc chắn 1 món 4★). Phần trăm của bậc 5★ **lấy từ nguyên liệu** (58% trừ tỉ lệ 5★ hiện tại) |
| 8 | Giá | 280 / 2520 Ngọc (1 / 10 lượt) |
| 9 | Món trùng | Không quy đổi. Phân giải trang bị thiết kế sau (Q11) |

**Owner 2026-11-15:** mỗi món 0.15% → thiếu 4 / 3 / 2 / 1 món: 0.6 / 0.45 / 0.3 / 0.15%; đủ bộ 0.6%; nguyên liệu 57.4–57.85%. Pity mềm vẫn +10% từ lượt 30, pity cứng 50.

**Cách tính (owner xác nhận 2026-11-14, số cũ 1.5%):** tổng tỉ lệ 5★ theo số món còn thiếu: 4 món 6%, 3 món 4.5%, 2 món 3%, 1 món 1.5%; đủ bộ thì về 6% và có thể ra trùng. Nguyên liệu = 58% − tổng tỉ lệ 5★ (52–56.5%). Pity mềm "+10%" cộng vào **tổng** tỉ lệ 5★ của lượt đó, không phải mỗi món (ví dụ thiếu 4 món, từ lượt 30: 16%).

---

## 6. Cài đặt (2026-11-15)

### 6.1 ID dữ liệu

Theo quy ước đang có trong `data/equipment/` (thư mục phẳng), thay cho `wpn_*` / `set_*` / `art_*` tạm ở mục 1–2:

| Nhân vật | Vũ khí 5★ | Bộ vết thánh (`data/equipment/sets/`) | 3 món Đầu / Thân / Chân |
| --- | --- | --- | --- |
| Enkiba | `eq_weapon_dusk_inferno` | `set_lavoisier` | `eq_stigma_{top,mid,bot}_lavoisier` |
| Kazeyumi | `eq_weapon_last_gale` | `set_davinci` | `eq_stigma_{top,mid,bot}_davinci` |
| Raikiba | `eq_weapon_twin_thunder` | `set_franklin` | `eq_stigma_{top,mid,bot}_franklin` |
| Hikarine | `eq_weapon_solar_verdict` | `set_nightingale` | `eq_stigma_{top,mid,bot}_nightingale` |
| Yomigari | `eq_weapon_crescent_pact` | `set_poe` | `eq_stigma_{top,mid,bot}_poe` |
| Iwagane | `eq_weapon_unyielding_peak` | `set_darwin` | `eq_stigma_{top,mid,bot}_darwin` |

Bộ 4★ (Q9): `set_blaze` (kiếm), `set_bedrock` (đại kiếm); owner 2026-11-15 thêm một bộ cho mỗi loại vũ khí còn lại: `set_whirlwind` (cung, Phong), `set_thunderclap` (song đao, Lôi), `set_dawnlight` (trượng, Quang), `set_nightshade` (lưỡi hái, Ám), mỗi bộ kèm vũ khí 4★ cùng loại (xem nhật ký 2026-11-15). Banner 5★ đầu tiên: `data/banners/banner_star5_earth.tres` (đề cử Iwagane,
`pity_group = banner_star5_earth_r1`; kỳ chạy lại đổi hậu tố để pity về 0).

Sinh lại dữ liệu: `python -X utf8 tools/gen_equipment_5star.py` (đồ, bộ, khóa dịch), `python -X utf8 tools/gen_banner_data.py` (banner).

### 6.2 Cách chạy

- Mỗi dòng hiệu ứng là một `EquipEffect` (`scripts/progression/equip_effect.gd`): `STAT`, `PARAM` ("A → B", cộng phần
  tăng; đường dẫn lồng như `skill:weapon:heals.atk_ratio`, `skill:ultimate:hits[0].duration_ms`,
  `skill:skill:hits.statuses@slow.magnitude`), `VS_TARGET` (% ST lên mục tiêu thỏa điều kiện, có bản toàn đội),
  `ON_WEAPON_HIT` (Kĩ năng vũ khí trúng thì áp trạng thái), `TRIGGER` (sự kiện → hành động, chạy ở
  `scripts/combat/equip_triggers.gd`), `PENDING` (chưa có cơ chế trong game).
- `TRIGGER`: sự kiện dùng Tuyệt kỹ / Kĩ năng vũ khí, trúng, hạ gục (thường / đang Nguyền), né hoàn hảo, hồi cho đồng đội
  dưới 50% HP, gây hiệu ứng nguyên tố, Bùng nổ Sét, đủ tầng, trúng N kẻ địch khác nhau trong cửa sổ, nhận sát thương,
  liên tục khi đủ tầng / khi HP dưới ngưỡng (đệm 5%, mục 3.4 dòng 9), trong lúc dùng kỹ năng. Hành động: buff (bản thân /
  toàn đội / chỉ người cùng hệ), rút CD, rút SI-CD, hồi máu, nạp EN, cộng tầng, lan trạng thái sang kẻ địch gần nhất.
  Mỗi dòng có ICD riêng. Buff là trạng thái `data/statuses/eqb_*.tres` (REFRESH: cùng hiệu ứng không cộng dồn); phần
  sát thương của buff trang bị cộng vào nhóm trang bị và chịu trần ×2.0.
- `EquipmentResolver` gom hiệu ứng (chủ sở hữu theo giáp, khóa hệ, đếm món cùng bộ) và chặn trần ở một chỗ; trần ở
  `data/config/equipment_rules.tres`. Giảm ST nhận dùng trần sẵn có `CombatRules.damage_taken_reduction_cap` (0.80).
- Vào trận: `PlayerProfile.loadout_of` → `PartyManager.loadout_provider` → `PlayerController` (bản sao SkillDef và cấu
  hình kit đã cộng phần tăng, sàn CD Kĩ năng vũ khí) và `Combatant.equip` (sát thương, giảm ST nhận, hồi máu, hút máu,
  thời gian / độ mạnh trạng thái do người đeo gây ra). HP %, DEF %, chí mạng vào `Progression.stats_for`.
- Buff toàn đội tĩnh (vd vũ khí Enkiba: toàn đội +8% tất cả ST): cùng `effect_id` lấy mức cao nhất, cả 3 người nhận.

### 6.3 Chưa cài (PENDING): không còn

- Khiên Đá (bộ Darwin 2 món) = khiên của Giáp Địa, tức khiên 20% HP tối đa mà Kĩ năng thường của Iwagane tự áp
  (owner 2026-11-15). Cài bằng `skill:skill:self_statuses@shield.magnitude` +0.05, trần 25% (`param_caps`).
  Trạng thái Giáp Địa (−35% ST nhận) giữ nguyên.

### 6.4 Cách hiểu Claude chọn khi cài (owner kiểm tra)

- Vũ khí Raikiba: dòng chung "+1 Dấu Sét" và dòng độc quyền "2 Dấu Sét thay vì 1" cộng theo Q3 → chủ sở hữu được
  thêm 2 Dấu Sét mỗi lượt đao ngoài dấu gốc của kỹ năng (dễ đủ 3 dấu ngay). Nếu quá mạnh, đổi dòng độc quyền.
- Vũ khí Hikarine "Đồng đội trong vùng +10% ST": áp cho cả đội khi dùng Kĩ năng vũ khí (chỉ một người trên sân nên
  thực tế là người trên sân), không kiểm tra vị trí trong vùng.
- Bão Tuyệt kỹ Kazeyumi +2s: kéo dài vùng bão (đòn đầu) và buff Gió Bão (`storm_blessing`) +2s.
- Tốc độ tấn công / di chuyển / nạp EN từ buff vẫn lấy mức cao nhất như cơ chế cũ (không cộng hai buff khác tên).
- "Hồi cho đồng đội dưới 50% HP" tính cả khi hồi cho chính mình.

Chưa làm khác: mô tả hiệu ứng trên màn Trang bị / Nhân vật (đang chỉ có tên món và chỉ số), ảnh vũ khí / vết thánh,
dòng 9 (ngưỡng HP có đệm), 11, 12, 13, 14 của mục 3.4 (chạy theo cơ chế kit sẵn có, chưa có test riêng).
