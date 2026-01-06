extends Panel

func _ready() -> void:
	$VBoxContainer/win_title.visible = false
	$VBoxContainer/lose_title.visible = false
	
	if PlayerState.get_ps().battle_result == PlayerData.EBattleResult.LOSE:
		$VBoxContainer/lose_title.visible = true
	else:
		$VBoxContainer/win_title.visible = true
	
	$VBoxContainer/stata/values/time.text = str(PlayerState.get_ps().battle_time_s)
	$VBoxContainer/stata/values/hit.text = str(PlayerState.get_ps().battle_hit)
	$VBoxContainer/stata/values/ricoche.text = str(PlayerState.get_ps().battle_ricoche)
	$VBoxContainer/stata/values/miss.text = str(PlayerState.get_ps().battle_miss)
	$VBoxContainer/stata/values/damage.text = str(PlayerState.get_ps().battle_damage)
	$VBoxContainer/stata/values/get_damage.text = str(PlayerState.get_ps().battle_get_damage)
	$VBoxContainer/stata/values/frags.text = str(PlayerState.get_ps().battle_frags)
	$VBoxContainer/stata/values/get_frags.text = str(PlayerState.get_ps().battle_get_frag)
		
	PlayerState.get_ps().add_to_total()
