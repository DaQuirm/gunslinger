Gunslinger = require './gunslinger'
Scenario = require './scenario'

incorrect_selectors = [
	'd'
	'*'
	'#woo'
	'header, footer'
]

correct_selector = '.match'

scenario = new Scenario
scenario
	.spawn \
		'gm',
		'http://localhost:3000/game-master.html?id=563e67b5e3177999a8406ac4',
		'koa:sess=eyJwYXNzcG9ydCI6IHsgInVzZXIiOiAiZ2l0aHViNjY5Nzg0IiB9IH0='

	.spawn \
		'player',
		'http://localhost:3000/game.html?id=563e67b5e3177999a8406ac4',
		'koa:sess=eyJwYXNzcG9ydCI6IHsgInVzZXIiOiAiZmFjZWJvb2s1MDI5MzYwNzMyNDYzMDYiIH0gfQ=='

	.as 'gm'
	.wait_cell 'round_phase', 'wait_screen'
	.send 'current_puzzle_index', 1

	.as 'player'
	.wait_cell 'round_phase', 'in_progress'
	.wait_random [1000, 3000]
	.repeat 10, -> [
		@wait_random [100, 500]
		@send_any 'selector', incorrect_selectors
	]
	.wait_random [500, 1000]
	.send 'selector', correct_selector

	.end 'player'
	.end 'gm'

Gunslinger.run scenario, ->
	console.log 'wooo'

	# .nightmare, ->
	# .refresh



