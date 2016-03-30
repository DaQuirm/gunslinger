Nightmare = require 'nightmare'
co        = require 'co'
{spawn}   = require 'child_process'
colors    = require 'colors'
path      = require 'path'

Scenario    = require './scenario'
User        = require '../models/user'
GameSession = (require '../models/game-session').GameSessionModel
Puzzle      = (require '../models/puzzle').PuzzleModel

Gunslinger =

	nightmares: {}

	fake_accounts: {}
	game_sessions: {}

	configuration: {}

	configure: (@configuration) ->

	any_of: (array) ->
		random_index = Math.floor(Math.random() * array.length)
		array[random_index]

	any_in_range: ([from, to]) ->
		Math.random() * (to - from) + from

	stringify: (item) ->
		string = ''
		if item.user_id?
			string += "[#{item.user_id.cyan}] "
		string += "#{item.command.white}"
		for key, value of item
			if key isnt 'command'
				string += " #{key}:".yellow + "#{value}"
		string

	run: (scenario) ->
		new Promise (resolve) =>
			commands = scenario.queue or scenario
			next = (index) =>
				if index < commands.length
					item = commands[index++]
					console.log @stringify item

					co(=>
						@[item.command] item, item.user_id
					)
						.catch (err) -> console.log err
					 	.then        -> next index
				else
					do resolve
			next 0

	run_async: (scenario) ->
		co(=>
			yield scenario.queue.map (item) =>
				co(=>
					console.log "#{@stringify item} start"
					@[item.command] item, item.user_id
				)
					.then => console.log "#{@stringify item} done"
					.catch (err) -> console.log err
		)
		.catch (err) -> console.log err

	spawn: ({user_id, app, game_session_id}) ->
		nightmare = do Nightmare
		@nightmares[user_id] = nightmare

		session_data =
			passport:
				user: @fake_accounts[user_id].id

		cookie = new Buffer(JSON.stringify session_data).toString 'base64'

		game_session_oid = do @game_sessions[game_session_id].toString
		base_url = 'http://localhost:3000'
		app_url = "#{base_url}/#{app}.html?id=#{game_session_oid}"

		console.log 'spawn: setting auth cookie to deceive Warp'
		yield nightmare.cookies.set
			name: 'koa:sess'
			value: cookie
			url:   base_url

		console.log "spawn: opening #{app_url}"
		yield nightmare.goto app_url

	as: ({user_id, callback}) ->
		scenario = new Scenario
		callback.call scenario
		for item in scenario.queue
			item.user_id = user_id
		yield @run scenario

	async: ({user_id, callback}) ->
		scenario = new Scenario
		callback.call scenario
		yield @run_async scenario

	wait_cell: ({cell, value}, user_id) ->
		nightmare = @nightmares[user_id]
		yield nightmare.wait \
			((cell, value) -> window.app[cell].value is value),
			cell, value

	wait: (interval) ->
		yield new Promise (resolve) =>
			setTimeout (->
				do resolve
			), interval

	send: ({cell, value}, user_id) ->
		nightmare = @nightmares[user_id]
		yield nightmare.evaluate \
			((cell, value) -> window.app[cell].value = value),
			cell, value

	end: ({id}) ->
		nightmare = @nightmares[id]
		yield do nightmare.end

	db_cleanup: ({collections}) ->
		Collection =
			'users': User
			'puzzles': Puzzle
			'gamesessions': GameSession

		for name in collections
			yield Collection[name].remove {}

	db_account: ({user_id}) ->
		profile =
			id: user_id
			username: user_id
			provider: 'gunslinger'

		yield User.fromOAuthProfile profile
			.then (user) =>
				@fake_accounts[user_id] = user

	db_puzzles: ({puzzles}) ->
		yield Puzzle.create puzzles

	db_game_session: ({id, game_master_id}) ->
		puzzles = yield Puzzle.find {}
		game_session = yield GameSession.create
			puzzles: puzzles
			game_master_id: @fake_accounts[game_master_id]._id
		@game_sessions[id] = game_session._id

	service: ->
		yield new Promise (resolve) =>
			cwd = @configuration.service_path
			console.log "starting cssqd service from #{cwd}"

			@service_process = spawn 'npm', ['run', 'dev-test'], cwd: cwd

			@service_process.stdout.on 'data', (data) ->
				process.stdout.write "[#{'cssqd-service'.magenta}]#{data}"
				if data.toString() is 'cssqd-service:ready\n' # IPC anyone?
					do resolve

			@service_process.stderr.on 'data', (data) =>
				process.stdout.write "[#{'cssqd-service'.red}]#{data}"

			@service_process.on 'exit', (code) ->
				process.stdout.write "[#{'cssqd-service'.magenta}] service process exited with code #{code}"

	kill_service: ->
		do @service_process.kill

	check_cells: ({cell, assert}, user_id)->
		nightmare = @nightmares[user_id]
		assertion = assert yield nightmare.evaluate ((cell) -> window.app[cell].value), cell
		if assertion then console.log 'passed ✓'.green else console.log 'failed ✗'.red

module.exports = Gunslinger
