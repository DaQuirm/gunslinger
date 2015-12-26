Nightmare = require 'nightmare'
co        = require 'co'
{spawn}   = require 'child_process'
colors    = require 'colors'
path      = require 'path'

Scenario    = require './scenario'
User        = require './models/user'
GameSession = (require './models/game-session').GameSessionModel
Puzzle      = (require './models/puzzle').PuzzleModel

Gunslinger =

	nightmares: {}
	current_nightmare: null

	fake_accounts: {}
	game_sessions: {}

	run: (scenario) ->
		new Promise (resolve) =>
			commands = scenario.queue or scenario
			next = (index) =>
				if index < commands.length
					item = commands[index++]
					console.log "#{JSON.stringify item}"
					co(=>
						@[item.command] item
					).catch (err) -> console.log err
					 .then ->
						 next index
				else
					do resolve
			next 0

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
		yield nightmare.goto base_url
		yield nightmare.evaluate \
			((cookie) ->
				document.cookie = "koa:sess=#{cookie}"),
			cookie

		console.log "spawn: opening #{app_url}"
		yield nightmare.goto app_url

	as: ({user_id}) ->
		@current_nightmare = @nightmares[user_id]

	wait_cell: ({cell, value}) ->
		nightmare = @current_nightmare
		yield nightmare.wait \
			((cell, value) -> window.app[cell].value is value),
			cell, value

	wait_random: ({from, to}) ->
		ms = Math.random() * (to - from) + from
		yield new Promise (resolve) =>
			setTimeout (->
				do resolve
			), ms

	send: ({cell, value}) ->
		nightmare = @current_nightmare
		yield nightmare.evaluate \
			((cell, value) -> window.app[cell].value = value),
			cell, value

	send_any: ({cell, values}) ->
		random_index = Math.floor(Math.random() * values.length)
		value = values[random_index]
		@send {cell, value}

	repeat: ({times, callback}) ->
		commands = Array.apply(null, new Array times)
			.map ->
				scenario = new Scenario
				callback.call scenario
				scenario.queue
			.reduce (acc, item) ->
				acc.concat item
		yield @run commands

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

	service: ({dir}) ->
		yield new Promise (resolve) =>
			cwd = path.join __dirname, dir
			console.log "starting cssqd service from #{cwd}"

			@service_process = spawn 'npm', ['run', 'dev-test'], cwd: cwd

			@service_process.stdout.on 'data', (data) ->
				process.stdout.write "[#{'cssqd-service'.cyan}]#{data}"
				if data.toString() is 'cssqd-service:ready\n' # IPC anyone?
					do resolve

			@service_process.stderr.on 'data', (data) =>
				process.stdout.write "[#{'cssqd-service'.red}]#{data}"

			@service_process.on 'exit', (code) ->
				process.stdout.write "[#{'cssqd-service'.cyan}] service process exited with code #{code}"

	kill_service: ->
		do @service_process.kill

module.exports = Gunslinger
