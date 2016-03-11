class Scenario

	constructor: ->
		@queue = []

	method: (command, data) ->
		data.command = command
		@queue.push data
		@

	spawn: (user_id, app, game_session_id) ->
		@method 'spawn', { user_id, app, game_session_id }

	as: (user_id) ->
		@method 'as', { user_id }

	wait_cell: (cell, value) ->
		@method 'wait_cell', { cell, value }

	wait_random: ([from, to]) ->
		@method 'wait_random', { from, to }

	repeat: (times, callback) ->
		@method 'repeat', { times, callback }

	send: (cell, value) ->
		@method 'send', { cell, value }

	send_any: (cell, values) ->
		@method 'send_any', { cell, values }

	end: (id) ->
		@method 'end', { id }

	db_cleanup: (collections...) ->
		@method 'db_cleanup', { collections }

	db_account: (user_id) ->
		@method 'db_account', { user_id }

	db_puzzles: (puzzles) ->
		@method 'db_puzzles', { puzzles }

	db_game_session: (id, game_master_id) ->
		@method 'db_game_session', { id,  game_master_id }

	service: ->
		@method 'service', {}

	kill_service: ->
		@method 'kill_service', {}

	check_cells: (cell, assert) ->
		@method 'check_cells', { cell, assert }

module.exports = Scenario