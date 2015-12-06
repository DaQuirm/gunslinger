class Scenario

	constructor: ->
		@queue = []

	method: (command) ->
		@queue.push command
		@

	spawn: (id, url, cookie) ->
		@method
			command: 'spawn'
			id: id
			url: url
			cookie: cookie

	as: (id) ->
		@method
			command: 'as'
			id: id

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

module.exports = Scenario
