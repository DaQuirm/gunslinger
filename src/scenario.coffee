class Scenario

	constructor: ->
		@queue = []

	method: (command, data) ->
		data.command = command
		@queue.push data
		@

	spawn: (user_id, game_session_id) ->
		@method 'spawn', { user_id, game_session_id }

	as: (user_id, callback) ->
		@method 'as', { user_id, callback }

	async: (callback) ->
		@method 'async', { callback }

	wait_cell: (cell, value) ->
		@method 'wait_cell', { cell, value }

	wait: (interval) ->
		@method 'wait', { interval }

	repeat: (times, callback) ->
		for index in [0...times]
			callback.call @, index
		@

	send: (cell, value) ->
		@method 'send', { cell, value }

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

	use_game_session: (id) ->
		@method 'use_game_session', { id }

	service: ->
		@method 'service', {}

	kill_service: ->
		@method 'kill_service', {}

	check_cells: (cell, assert) ->
		@method 'check_cells', { cell, assert }

	exchange: (data) ->
		@method 'exchange', data

	refresh: ->
		@method 'refresh', {}

module.exports = Scenario
