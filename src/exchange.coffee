window.WarpExchange =
	capture_id: 0
	captures: {}

	capture: (ids) ->
		@captures[@capture_id] =
			ids:  ids
			done: no
			values: {}

		@capture_id++

	release: (cid) ->
		delete @captures[cid]

entities = window.app.warp_client.entities
for id, entity of entities
	do (id) =>
		entity.link.onvalue.add (value) =>
			captures = window.WarpExchange.captures
			for _, capture of captures when id in capture.ids
				unless capture.values[id]?
					capture.values[id] = value
					if Object.keys capture.values is capture.ids.length
						capture.done = yes
