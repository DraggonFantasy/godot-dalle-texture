extends TextureRect

enum State {
	IDLE = 0,
	WAITING_DALLE_RESPONSE = 1,
	DOWNLOADING_IMAGE = 2
}

var _prompt
var state = State.IDLE

signal started_generating(prompt, model)
signal finished_generating(prompt, model)

@onready var http_request = $HTTPRequest
@export_enum("dall-e-3", "dall-e-2") var model = "dall-e-3"
@export var prompt: String:
	get:
		return _prompt
	set(value):
		_prompt = value
		print("Updated prompt: %s" % _prompt)
		if http_request.get_http_client_status() != 0:
			print("Canceled running request")
			http_request.cancel_request()
		
		if not visible:
			print("Do not generate - node is not visible")
			return
		
		state = State.IDLE
		set_texture(null)
		started_generating.emit(_prompt, model)
		var url = "https://api.openai.com/v1/images/generations"
		var body = JSON.stringify({"prompt": prompt, "n": 1, "model": model})
		var headers = [
			"Content-Type: application/json",
			"Authorization: Bearer " + GlobalManager.openaiKey
		]
		
		var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
		if error != OK:
			push_error("An error occurred in the HTTP request.")
		else:
			state = State.WAITING_DALLE_RESPONSE
			print("Requested the image. Waiting for DALL-E response")


func _http_request_completed(result, response_code, headers, body):
	if not visible:
		return
	if state == State.WAITING_DALLE_RESPONSE:
		var json = JSON.new()

		var error = json.parse(body.get_string_from_utf8())
		if error != OK:
			push_error(error)
		else:
			var response = json.data
			print("DALL-E Response: ", response)
			
			state = State.DOWNLOADING_IMAGE
			http_request.request(response.data[0].url)
			
			print("Processed DALL-E response. Downloading the image")
	elif state == State.DOWNLOADING_IMAGE:
		state = State.IDLE
		if response_code == 200:
			var image = Image.new()
			if image.load_png_from_buffer(body) == OK:
				var texture = ImageTexture.create_from_image(image)
				set_texture(texture)
				finished_generating.emit(_prompt, model)
				print("Downloaded the image. Finished processing")
		else:
			push_error("Failed to load the generated image")
	else:
		push_error("Invalid state when received the HTTP response: " + str(state))
