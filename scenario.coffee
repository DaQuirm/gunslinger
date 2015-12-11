class Scenario

	constructor: ->
		@queue = []

	method: (command) ->
		@queue.push command
		@

	spawn: (user_id, app, game_session_id) ->
		@method
			command: 'spawn'
			user_id: user_id
			app: app
			game_session_id: game_session_id

	as: (user_id) ->
		@method
			command: 'as'
			user_id: user_id

	wait_cell: (cell, value) ->
		@method
			command: 'wait_cell'
			cell: cell
			value: value

	wait_random: ([from, to]) ->
		@method
			command: 'wait_random'
			from: from
			to: to

	repeat: (times, callback) ->
		@method
			command: 'repeat'
			times: times
			callback: callback

	send: (cell, value) ->
		@method
			command: 'send'
			cell: cell
			value: value

	send_any: (cell, values) ->
		@method
			command: 'send_any'
			cell: cell
			values: values

	end: (id) ->
		@method
			command: 'end'
			id: id

	db_cleanup: (collections...) ->
		@method
			command: 'db_cleanup'
			collections: collections

	db_account: (user_id) ->
		@method
			command: 'db_account'
			user_id: user_id

	db_puzzles: (puzzles) ->
		@method
			command: 'db_puzzles'
			puzzles: puzzles

	db_game_session: (id, game_master_id) ->
		@method
			command: 'db_game_session'
			id: id
			game_master_id: game_master_id

	service: (dir) ->
		@method
			command: 'service'
			dir: dir

	kill_service: ->
		@method
			command: 'kill_service'

module.exports = Scenario
