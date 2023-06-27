#class_name Term

extends Control

const bg_colors = [Color("483a52"), Color("3a5248")]

const PrimVal = preload("res://vm/templates/primval.tscn")
const Term = preload("res://vm/templates/term.tscn")

enum TermType {PrimvalTerm, AbsTerm, LazyAppTerm, StrictAppTerm, OpTerm, WorldTerm}
enum OpType {Lambda, Eval, Add, Sub, Mul, Div, Eq}

var lam_name : String
var op : OpType
var color_variant : int:
	get:
		return color_variant
	set(new_value):
		color_variant = new_value
		var stylebox : StyleBoxFlat = get_theme_stylebox("panel").duplicate()
		stylebox.bg_color = bg_colors[color_variant]
		add_theme_stylebox_override("panel", stylebox)
var type : TermType:
	get:
		return type
	set(new_type):
		type = new_type
		for i in range(get_child_count()):
			var child : Control = get_child(i)
			if i == new_type:
				child.visible = true
			else:
				child.visible = false
		for c in get_children():
			if c.visible == false:
				c.queue_free()

func set_color_variant(new_color_variant):
	color_variant = new_color_variant % bg_colors.size()

func deserialize(serializer: Serializer):
	type = serializer.read_uint8() as TermType
	match type:
		0: # PrimVal
			var primval = PrimVal.instantiate()
			primval.deserialize(serializer)
			#list all children
			$PrimVal/Value.add_child(primval)
		1: # Abs
			lam_name = serializer.read_null_terminated_string()
			var lam_name_primval = PrimVal.instantiate()
			lam_name_primval.type = lam_name_primval.PrimValType.StringValue
			lam_name_primval.value = lam_name
			$Abs/Symbol.add_child(lam_name_primval)
			var term = Term.instantiate()
			term.set_color_variant(color_variant + 1)
			term.deserialize(serializer)
			$Abs/Term.add_child(term)
		2, 3: # LazyApp / StrictApp
			var term1 = Term.instantiate()
			var term2 = Term.instantiate()
			term1.set_color_variant(color_variant + 1)
			term1.deserialize(serializer)
			term2.set_color_variant(color_variant + 1)
			term2.deserialize(serializer)
			if type == 2:
				$LazyApp/Term1.add_child(term1)
				$LazyApp/Term2.add_child(term2)
			else:
				$StrictApp/Term1.add_child(term1)
				$StrictApp/Term2.add_child(term2)
		4: # Op
			op = serializer.read_uint8() as OpType
			var op_primval = PrimVal.instantiate()
			op_primval.type = op_primval.PrimValType.StringValue
			match op:
				0: op_primval.text = "Lambda"
				1: op_primval.text = "Eval"
				2: op_primval.text = "+"
				3: op_primval.text = "-"
				4: op_primval.text = "*"
				5: op_primval.text = "/"
				6: op_primval.text = "="
			$Op/Value.add_child(op_primval)
		5: # World
			pass # TODO

