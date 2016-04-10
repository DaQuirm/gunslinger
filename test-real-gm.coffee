argv = (require 'minimist') process.argv.slice 2

mongoose = require 'mongoose'

Gunslinger = require './src/gunslinger'
create_scenario = require './scenarios/real_gm'

{connection} = mongoose.connect 'mongodb://localhost/cssqd-test'
connection.once 'open', ->

	Gunslinger.run create_scenario argv.session_id
		.then ->
			console.log 'all done!'
			do process.exit
			do done
