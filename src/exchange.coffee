window.WarpExchange =
	capture_id: 0
	captures: {}

	feed: []

	capture: (ids, cells = {}) ->
		@captures[@capture_id] =
			ids:  ids
			done: no
			values: {}

		for cell, value of cells
			window.app[cell].value = value

		@capture_id++

	release: (cid) ->
		delete @captures[cid]

warp_client = window.app.warp_client

entities = warp_client.entities
for id, entity of entities
	do (id) =>
		entity.link.onvalue.add (value) =>
			captures = window.WarpExchange.captures
			for _, capture of captures when id in capture.ids
				unless capture.values[id]?
					capture.values[id] = value
					if Object.keys capture.values is capture.ids.length
						capture.done = yes

original_sync = warp_client.transport.sync
warp_client.transport.sync = (message) ->
	window.WarpExchange.feed.push message
	original_sync.call warp_client.transport, message
