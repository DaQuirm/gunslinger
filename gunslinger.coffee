Nightmare = require 'nightmare'
co        = require 'co'

Scenario = require './scenario'

Gunslinger =

	nightmares: {}
	current_nightmare: null

	run: (scenario, done) ->
		commands = scenario.queue or scenario
		next = (index) =>
			if index < commands.length
				item = commands[index++]
				console.log "#{JSON.stringify item}"
				@[item.command] item, -> next index
			else
				do done
		next 0

	spawn: ({id, url, cookie}, done) ->
		co(=>
			nightmare = do Nightmare
			@nightmares[id] = nightmare
			yield nightmare.goto 'http://localhost:3000'
			yield nightmare.evaluate \
				((cookie)->
					document.cookie = cookie),
				cookie
			yield nightmare.goto url
		).then done

	as: ({id}, done) ->
		@current_nightmare = @nightmares[id]
		do done

	wait_cell: ({cell, value}, done) ->
		co(=>
			nightmare = @current_nightmare
			yield nightmare.wait \
				((cell, value) -> window.app),
				cell, value
		).then done

	wait_random: ({from, to}, done) ->
		ms = Math.random() * (to - from) + from
		setTimeout done, ms

	send: ({cell, value}, done) ->
		co(=>
			nightmare = @current_nightmare
			yield nightmare.evaluate \
				((cell, value) -> window.app[cell].value = value),
				cell, value
		).then done

	send_any: ({cell, values}, done) ->
		random_index = Math.floor(Math.random() * values.length)
		value = values[random_index]
		@send {cell, value}, done

	repeat: ({times, callback}, done) ->
		commands = Array.apply(null, new Array times)
			.map ->
				scenario = new Scenario
				callback.call scenario
				scenario.queue
			.reduce (acc, item) ->
				acc.concat item
		@run commands, done

	end: ({id}, done) ->
		nightmare = @nightmares[id]
		co(=>
				yield do nightmare.end
		).then done

module.exports = Gunslinger
