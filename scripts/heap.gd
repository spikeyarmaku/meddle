extends Control

const Closure = preload("res://vm/templates/closure.tscn")
const HeapElem = preload("res://vm/heap_elem.tscn")

var _elements : Array
var _parents : Array

func _ready():
    reset()

func deserialize(serializer : Serializer):
    var count : int = serializer.read_word()
    for n in range(count):
        var binding_name : String = serializer.read_null_terminated_string()
        var closure := Closure.instantiate()
        closure.deserialize(serializer)
        closure.set_expand(true)
        closure.connect("highlight_frame", highlight_frame)
        closure.connect("jump_to_frame", jump_to_frame)
        var heap_elem = HeapElem.instantiate()
        heap_elem.set_binding_name(_elements.size(), binding_name)
        heap_elem.set_binding_closure(closure)
        _elements.append(heap_elem)
        var parent_index : int = serializer.read_word()
        _parents.append(parent_index)
        if _elements[parent_index] == null:
            %PanelContainer.add_child(heap_elem)
        else:
            _elements[parent_index].add_child_elem(heap_elem)

func highlight_frame(frame_index, to_highlight):
    var container = _elements[frame_index]
    if container != null:
        container.get_binding_closure().is_highlighted = to_highlight
        if frame_index != 0:
            highlight_frame(_parents[frame_index], to_highlight)

func jump_to_frame(frame_index):
    var container = _elements[frame_index]
    var closure = container.get_binding_closure()
    if container != null:
        if closure.get_term() != null:
            $ScrollContainer.ensure_control_visible(closure.get_term())
        closure.blink()

func reset():
    for c in %PanelContainer.get_children():
        c.queue_free()
    _elements = []
    _parents = [0]
    # Ground frame:
    var heap_elem = HeapElem.instantiate()
    heap_elem.set_binding_name(0, "GROUND FRAME")
    var closure = Closure.instantiate()
    heap_elem.set_binding_closure(closure)
    closure.set_expand(true)
    closure.connect("highlight_frame", highlight_frame)
    _elements.append(heap_elem)
    %PanelContainer.add_child(heap_elem)
