class_name MovementConfig
extends Resource
## Thông số di chuyển (README 3.5, 15.7). Mọi số chỉnh trong file .tres, không sửa code.
## Đơn vị: pixel logic (khung 1920x1080) và giây.

@export_group("Chạy")
## Tốc độ chạy tối đa (px/s).
@export var run_speed := 450.0
## Gia tốc khi đang tăng tốc trên mặt đất (px/s²).
@export var ground_accel := 4000.0
## Gia tốc khi thả nút / đổi hướng trên mặt đất (px/s²).
@export var ground_decel := 5000.0
## Gia tốc trên không.
@export var air_accel := 2600.0
@export var air_decel := 1400.0

@export_group("Nhảy")
## Độ cao nhảy tối đa khi giữ nút (px). Nhân vật cao khoảng 256 px.
@export var jump_height := 320.0
## Thời gian từ lúc nhảy tới đỉnh khi giữ nút (s).
@export var jump_time_to_peak := 0.38
## Trọng lực khi rơi = trọng lực lên × hệ số này (rơi nhanh hơn lên cho chắc tay).
@export var fall_gravity_multiplier := 1.5
## Thả nút nhảy khi đang lên: vận tốc lên nhân hệ số này (nhảy thấp).
@export_range(0.0, 1.0) var jump_cut_multiplier := 0.4
## Vận tốc rơi tối đa (px/s).
@export var max_fall_speed := 1600.0

@export_group("Độ dễ chịu")
## Coyote time: vẫn nhảy được sau khi rời mép (s). Đặc tả 0.08-0.12.
@export_range(0.0, 0.3) var coyote_time := 0.1
## Bộ đệm nhảy: nhấn sớm trước khi chạm đất vẫn nhảy (s). Đặc tả 0.10-0.15.
@export_range(0.0, 0.3) var jump_buffer_time := 0.12
## Thời gian state Land (s); có thể nhảy/chạy ngay để huỷ.
@export var land_duration := 0.08


## Trọng lực khi đi lên, suy ra từ độ cao và thời gian lên đỉnh: g = 2h / t².
func rise_gravity() -> float:
	return 2.0 * jump_height / (jump_time_to_peak * jump_time_to_peak)


func fall_gravity() -> float:
	return rise_gravity() * fall_gravity_multiplier


## Vận tốc nhảy ban đầu (độ lớn, hướng lên): v = 2h / t.
func jump_velocity() -> float:
	return 2.0 * jump_height / jump_time_to_peak
