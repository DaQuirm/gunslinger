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

	stringify: (command) ->
		string = ''
		if command.user_id?
			string += "[#{command.user_id.cyan}] "
		string += "#{command.name.white}"
		unless command.silent
			for key, value of command.data
				string += " #{key}:".yellow + "#{JSON.stringify value}"
		string

	run: (scenario) ->
		new Promise (resolve) =>
			commands = scenario.queue or scenario
			next = (index) =>
				if index < commands.length
					command = commands[index++]
					console.log @stringify command

					co(=>
						@[command.name] command.data, command.user_id
					)
						.catch (err) -> console.log err
					 	.then        -> next index
				else
					do resolve
			next 0

	run_async: (scenario) ->
		co(=>
			yield scenario.queue.map (command) =>
				co(=>
					console.log "#{@stringify command} start"
					@[command.name] command.data, command.user_id
				)
					.then => console.log "#{@stringify command} done"
					.catch (err) -> console.log err
		)
		.catch (err) -> console.log err

	spawn: ({user_id, game_session_id}) ->
		nightmare = do Nightmare
		@nightmares[user_id] = nightmare

		session_data =
			passport:
				user: @fake_accounts[user_id].id

		cookie = new Buffer(JSON.stringify session_data).toString 'base64'

		game_session_oid = do @game_sessions[game_session_id].toString
		base_url = 'http://localhost:3000'
		app_url = "#{base_url}/game?id=#{game_session_oid}&user_id=gunslinger#{user_id}"

		console.log 'spawn: setting auth cookie to deceive Warp'
		yield nightmare.cookies.set
			name: 'koa:sess'
			value: cookie
			url:   base_url

		console.log "spawn: opening #{app_url}"
		yield nightmare.goto app_url

		console.log 'spawn: injecting WarpExchange'
		yield nightmare.inject 'js', "#{__dirname}/exchange.js"

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

	use_game_session: ({ id }) ->
		@game_sessions[id] = id

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

			process.on 'exit', =>
				do @service_process.kill

	kill_service: ->
		do @service_process.kill

	check_cells: ({cell, assert}, user_id) ->
		nightmare = @nightmares[user_id]
		assertion = assert yield nightmare.evaluate ((cell) -> window.app[cell].value), cell
		if assertion then console.log 'passed ✓'.green else console.log 'failed ✗'.red

	exchange: ({action, capture}, user_id) ->

		received = null
		time = do process.hrtime

		user_ids = Object.keys capture

		capture_ids = yield for uid in user_ids
			nightmare = @nightmares[uid]
			assertions = capture[uid]
			nightmare.evaluate \
				((cells) -> window.WarpExchange.capture cells),
				Object.keys assertions

		if action?
			yield @as
				user_id: user_id
				callback: action

		yield capture_ids.map (capture_id) ->
			nightmare.wait \
				((cid) -> window.WarpExchange.captures[cid].done),
				capture_id

		values = yield capture_ids.map (capture_id) ->
			nightmare.evaluate \
				((cid) -> window.WarpExchange.captures[cid].values),
				capture_id

		time = process.hrtime time
		console.log "[#{user_id.cyan}] exchange: time #{time[0]*1000000+time[1]/1000}μs"

		for uid, index in user_ids
			# yield nightmare.screenshot "#{__dirname}/#{uid}-#{do Date.now}.png"
			assertions = capture[uid]
			for cell, assertion of assertions
				result = if typeof assertion is 'function'
					assertion values[index][cell]
				else
					assertion is values[index][cell]

				if result
					console.log "[#{user_id.cyan}]" + ' passed ✓'.green
				else
					console.log "[#{user_id.cyan}]" + " failed ✗: expected cell `#{cell}` to pass assertion #{assertion}".red

		yield capture_ids.map (capture_id) ->
			nightmare.evaluate \
				((cid) -> window.WarpExchange.release cid),
				capture_id

	refresh: (_, user_id) ->
		nightmare = @nightmares[user_id]
		yield do nightmare.refresh

		session_data =
			passport:
				user: @fake_accounts[user_id].id

		cookie = new Buffer(JSON.stringify session_data).toString 'base64'


		base_url = 'http://localhost:3000'
		yield nightmare.cookies.set
			name: 'koa:sess'
			value: cookie
			url:   base_url

		yield nightmare.inject 'js', "#{__dirname}/exchange.js"

module.exports = Gunslinger
