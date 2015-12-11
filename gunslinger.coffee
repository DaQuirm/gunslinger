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

	spawn: ({user_id, app, game_session_id}, done) ->
		co(=>
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
		).then done

	as: ({user_id}, done) ->
		@current_nightmare = @nightmares[user_id]
		do done

	wait_cell: ({cell, value}, done) ->
		co(=>
			nightmare = @current_nightmare
			yield nightmare.wait \
				((cell, value) -> window.app[cell].value is value),
				cell, value
		).catch (err) -> console.log err
		 .then done

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

	db_cleanup: ({collections}, done) ->
		Collection =
			'users': User
			'puzzles': Puzzle
			'gamesessions': GameSession

		co(->
			for name in collections
				yield Collection[name].remove {}
		)
			.catch (err) -> console.log err
			.then done

	db_account: ({user_id}, done) ->
		profile =
			id: user_id
			username: user_id
			provider: 'gunslinger'

		User.fromOAuthProfile profile
			.then (user) =>
				@fake_accounts[user_id] = user
				do done

	db_puzzles: ({puzzles}, done) ->
		Puzzle.create puzzles
			.then done

	db_game_session: ({id, game_master_id}, done) ->
		co(=>
			puzzles = yield Puzzle.find {}
			yield GameSession.create
				puzzles: puzzles
				game_master_id: @fake_accounts[game_master_id]._id
		).then (game_session) =>
			@game_sessions[id] = game_session._id
			do done

	service: ({dir}, done) ->
		cwd = path.join __dirname, dir
		console.log "starting cssqd service from #{cwd}"

		@service_process = spawn 'npm', ['run', 'dev-test'], cwd: cwd

		@service_process.stdout.on 'data', (data) ->
			process.stdout.write "[#{'cssqd-service'.cyan}]#{data}"
			if data.toString() is 'cssqd-service:ready\n' # IPC anyone?
				do done

		@service_process.stderr.on 'data', (data) =>
			process.stdout.write "[#{'cssqd-service'.red}]#{data}"

		@service_process.on 'exit', (code) ->
			process.stdout.write "[#{'cssqd-service'.cyan}] service process exited with code #{code}"

	kill_service: (_, done) ->
		do @service_process.kill
		do done

module.exports = Gunslinger
