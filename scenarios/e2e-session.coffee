CSON     = require 'cson'
Scenario = require '../src/scenario'
Gunslinger = require '../src/gunslinger'

GameSessionCommand = require '../models/game-session-command'
RoundPhase = require '../models/round-phase'

puzzles = CSON.load "#{__dirname}/../fixtures/puzzles.cson"

correct_selectors = puzzles.map (puzzle) -> puzzle.selector
incorrect_selectors = puzzles.map (puzzle) -> puzzle.incorrect_selectors

scenario = new Scenario

NUMBER_OF_PLAYERS = 20
NUMBER_OF_PUZZLES = 3

play_round = (puzzle_index) ->
	@as 'fake-game-master', ->
		@send 'command',
				new GameSessionCommand GameSessionCommand.START_ROUND, puzzle_index:puzzle_index

	.async ->
		@repeat NUMBER_OF_PLAYERS, (index) ->
			@as "fake-player-#{index}", ->
				@wait_cell 'round_phase', RoundPhase.IN_PROGRESS
				@repeat 10, -> [
					# @wait Gunslinger.any_in_range [50, 75]
					# do @refresh

					@exchange
						capture:
							"fake-player-#{index}":
								match: ({ result }) -> result is 'negative'
						send:
							selector: Gunslinger.any_of incorrect_selectors[puzzle_index]
				]
				@wait Gunslinger.any_in_range [10, 50]

				@exchange
					capture:
						"fake-player-#{index}":
							match: ({ result }) -> result is 'positive'
					send:
						selector: correct_selectors[puzzle_index]

	.as 'fake-game-master', ->
		@send 'command',
			new GameSessionCommand GameSessionCommand.END_ROUND

scenario
	.db_cleanup 'users', 'gamesessions', 'puzzles'

	.db_account 'fake-game-master'

	.repeat NUMBER_OF_PLAYERS, (index) ->
		@db_account "fake-player-#{index}"

	.db_puzzles puzzles

	.db_game_session 'test-game', 'fake-game-master'

	.service()

	.spawn \
		'fake-game-master',
		'test-game'

	.repeat NUMBER_OF_PLAYERS, (index) ->
		@as 'fake-game-master', ->
			@exchange
				capture:
					'fake-game-master':
						players: ({ data: { items: [player] } }) ->
							player.display_name is "fake-player-#{index}"

				action: ->
					@spawn \
						"fake-player-#{index}",
						'test-game'

	.async ->
		@as 'fake-game-master', ->
			@wait_cell 'round_phase', RoundPhase.WAIT_SCREEN

	.repeat NUMBER_OF_PUZZLES, (index) ->
		@call play_round, index

	.repeat NUMBER_OF_PLAYERS, (index) ->
		@end "fake-player-#{index}"

	.end 'fake-game-master'

	.kill_service()

	.db_cleanup 'users', 'gamesessions', 'puzzles'

module.exports = scenario
