#class_name Term

extends Control

const bg_colors = [Color("483a52"), Color("3a5248")]
const bg_color_highlight = Color.WHITE

const PrimVal = preload("res://vm/templates/primval.tscn")
const Term = preload("res://vm/templates/term.tscn")

enum TermType {PrimvalTerm, AbsTerm, AppTerm, OpTerm, DummyTerm, VauTerm}
enum OpType {Vau, Add, Sub, Mul, Div, Eq}

var lam_name : String
var op : OpType
var color_variant : int:
	get:
		return color_variant
	set(new_value):
		color_variant = new_value
		_set_stylebox_color(bg_colors[color_variant])
var type : TermType:
	get:
		return type
	set(new_type):
		type = new_type
		for i in range($TermValueContainer.get_child_count()):
			var child : Control = $TermValueContainer.get_child(i)
			if i == new_type:
				child.visible = true
			else:
				child.visible = false
		for c in $TermValueContainer.get_children():
			if c.visible == false:
				c.queue_free()
var is_highlighted: bool = false:
	get:
		return is_highlighted
	set(new_value):
		is_highlighted = new_value
		if is_highlighted:
			_set_stylebox_color(bg_color_highlight)
		else:
			_set_stylebox_color(bg_colors[color_variant])
var is_minimized: bool = false:
	get:
		return is_minimized
	set(new_value):
		is_minimized = new_value
		$TermValueContainer.visible = not is_minimized
		$Minimized.visible = is_minimized
		is_highlighted = false

func _set_stylebox_color(color : Color):
	var stylebox : StyleBoxFlat = get_theme_stylebox("panel").duplicate()
	stylebox.bg_color = color
	add_theme_stylebox_override("panel", stylebox)

func set_color_variant(new_color_variant):
	color_variant = new_color_variant % bg_colors.size()

func deserialize(serializer: Serializer):
	type = serializer.read_uint8() as TermType
	match type:
		TermType.PrimvalTerm: # PrimVal
			var primval = PrimVal.instantiate()
			primval.deserialize(serializer)
			#list all children
			$TermValueContainer/PrimVal/Value.add_child(primval)
		TermType.AbsTerm: # Abs
			lam_name = serializer.read_null_terminated_string()
			var lam_name_primval = PrimVal.instantiate()
			lam_name_primval.type = lam_name_primval.PrimValType.SymbolValue
			lam_name_primval.text = lam_name
			$TermValueContainer/Abs/Symbol.add_child(lam_name_primval)
			var term = Term.instantiate()
			term.set_color_variant(color_variant + 1)
			term.deserialize(serializer)
			$TermValueContainer/Abs/Term.add_child(term)
		TermType.AppTerm: # LazyApp / StrictApp
			var term1 = Term.instantiate()
			var term2 = Term.instantiate()
			term1.set_color_variant(color_variant + 1)
			term1.deserialize(serializer)
			term2.set_color_variant(color_variant + 1)
			term2.deserialize(serializer)
			$TermValueContainer/App/Term1.add_child(term1)
			$TermValueContainer/App/Term2.add_child(term2)
		TermType.OpTerm: # Op
			op = serializer.read_uint8() as OpType
			var op_primval = PrimVal.instantiate()
			op_primval.type = op_primval.PrimValType.SymbolValue
			match op:
				OpType.Vau:     op_primval.text = "Vau"
				OpType.Add:     op_primval.text = "+"
				OpType.Sub:     op_primval.text = "-"
				OpType.Mul:     op_primval.text = "*"
				OpType.Div:     op_primval.text = "/"
				OpType.Eq:      op_primval.text = "="
			$TermValueContainer/Op/Value.add_child(op_primval)
		TermType.DummyTerm: # World
			pass
		TermType.VauTerm: #Vau
			var vau_term = Term.instantiate()
			vau_term.set_color_variant(color_variant + 1)
			vau_term.deserialize(serializer)
			$TermValueContainer/Vau/Term.add_child(vau_term)

func _on_mouse_entered():
	is_highlighted = true

func _on_mouse_exited():
	is_highlighted = false

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed == false:
			is_minimized = not is_minimized
