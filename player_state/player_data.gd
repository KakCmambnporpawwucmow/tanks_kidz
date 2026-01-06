extends Resource

class_name PlayerData

enum EBattleResult{NONE, WIN, LOSE}

var _ps:PlayerState = null
# ============= в бою ==============
@export var battle_time_s:int 	# времени проведено в бою без учёта ИИ
@export var battle_hit:int		# пробитий
@export var battle_ricoche:int	# рикошетов
@export var battle_miss:int		# промахов
@export var battle_damage:int	:# нанесено урона
	set(value):
		battle_damage = value
		if _ps != null:
			_ps.send_change_data.emit()
@export var battle_get_damage:int# получено урона
@export var battle_frags:int	:# уничтожено противников
	set(value):
		battle_frags = value
		if _ps != null:
			_ps.send_change_data.emit()
@export var battle_get_frag:int	# был уничтожен противником
@export var battle_result:EBattleResult  = EBattleResult.NONE# бой выигран?
# ============== всего в игре ================
@export var total_time_s:int 	# времени проведено в бою без учёта ИИ
@export var total_hit:int		# пробитий
@export var total_ricoche:int	# рикошетов
@export var total_miss:int		# промахов
@export var total_damage:int	# нанесено урона
@export var total_get_damage:int# получено урона
@export var total_frags:int		# уничтожено противников
@export var total_get_frag:int	# был уничтожен противником
@export var total_win:int
@export var total_lose:int

func clear_battle_data():
	battle_time_s = 0
	battle_hit = 0
	battle_ricoche = 0
	battle_miss = 0
	battle_damage = 0
	battle_get_damage = 0
	battle_frags = 0
	battle_get_frag = 0
	battle_result = EBattleResult.NONE
	
func add_to_total():
	total_hit += battle_hit
	total_ricoche += battle_ricoche
	total_miss += battle_miss
	total_damage += battle_damage
	total_get_damage += battle_get_damage
	total_frags += battle_frags
	total_get_frag += battle_get_frag
	match battle_result:
		EBattleResult.WIN:
			total_win += 1
		EBattleResult.LOSE:
			total_lose += 1
	clear_battle_data()
