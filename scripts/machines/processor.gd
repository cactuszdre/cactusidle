extends Machine

class_name CactusProcessor

var input_inventory: int = 0
var output_inventory: int = 0
var processing_timer: float = 0.0
const PROCESS_TIME: float = 5.0
const INPUT_REQUIRED: int = 10

func tick(delta: float) -> void:
	# Output logic
	if output_inventory > 0:
		var target_pos = get_output_world_pos()
		var target_machine = factory_manager.get_closest_machine(target_pos)
		
		if target_machine and target_machine.can_accept_item({ "type": "cactus_juice", "amount": 1 }, (rotation_dir + 2) % 4):
			target_machine.inject_item({ "type": "cactus_juice", "amount": 1 })
			output_inventory -= 1
	
	# Processing logic
	if input_inventory >= INPUT_REQUIRED:
		processing_timer += delta
		if processing_timer >= PROCESS_TIME:
			processing_timer = 0.0
			input_inventory -= INPUT_REQUIRED
			output_inventory += 1
			print("🏭 Processor: Created Cactus Juice!")

func can_accept_item(item: Dictionary, _from_dir: int) -> bool:
	return item.type == "cactus" and input_inventory < 50

func inject_item(item: Dictionary) -> void:
	if item.type == "cactus":
		input_inventory += item.amount
