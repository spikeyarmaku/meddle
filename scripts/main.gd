# UI Layout:
# +----------+----------+
# | code     |          |
# |          |   tree   |
# +----------+          |
# |          +----------+
# | REPL     | controls |
# +----------+----------+

extends Control

enum DebuggerState {Disconnected, Connecting, Connected}
enum ResponseType {EvalStateResponse, TermResponse, VMDataResponse,
                    VoidResponse, InvalidCommandResponse, ExitResponse}

var connection : StreamPeerTCP
var state := DebuggerState.Disconnected

var _send_queue = []

var debug = true

# Called when the node enters the scene tree for the first time.
func _ready():
    connection = StreamPeerTCP.new()
    %ButtonConnect.connect("pressed", _on_button_connect_pressed)

func _process(_delta):
    match state:
        DebuggerState.Disconnected:
            pass
        DebuggerState.Connecting:
            connection.poll()
            var connection_status = connection.get_status()
            if connection_status == StreamPeerTCP.STATUS_ERROR:
                $LoadingScreen.text = "Error"
            if connection_status == StreamPeerTCP.STATUS_CONNECTED:
                state = DebuggerState.Connected
                $LoadingScreen.visible = false
                $VM.visible = true
        DebuggerState.Connected:
            connection.poll()
            var byte_count = connection.get_available_bytes()
            if byte_count > 0:
                _interpret_response(connection.get_data(byte_count)[1])
            if connection.get_status() == StreamPeerTCP.STATUS_NONE:
                state = DebuggerState.Disconnected
            _send_messages()

func _on_button_connect_pressed():
    var port := int(%PortNumber.text)
    var err_code = connection.connect_to_host("127.0.0.1", port)
    assert(err_code == OK)
    $Menu.visible = false
    $LoadingScreen.visible = true
    state = DebuggerState.Connecting

# TODO add the messages to a queue, and send them after previous response has
# arrived
func _on_vm_send_text(text):
    _send_queue.append(text)

func _send_messages():
    if _send_queue.size() > 0:
        var text = _send_queue.pop_front()
        var serializer = Serializer.new()
        serializer.from_network(connection)
        serializer.write_string(text)
        if text == "exit":
            get_tree().quit()

func _interpret_response(bytes : PackedByteArray):
    var serializer := Serializer.new()
    serializer.from_bytes(bytes)
    while not serializer.has_finished():
        var resp_type : ResponseType = serializer.read_uint8() as ResponseType
        print("New response size: ", bytes.size(), ", type: ", resp_type)
        match resp_type:
            ResponseType.EvalStateResponse:
                $VM.is_finished = 1 - serializer.read_uint8()
            ResponseType.VMDataResponse:
                var vm_bytes = serializer.get_data()
                $VM.new_state(vm_bytes)
            ResponseType.TermResponse: pass
