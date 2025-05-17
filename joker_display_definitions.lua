local jd_def = JokerDisplay.Definitions

jd_def["j_banner"] = {
	text = {
		{ text = "+" },
		{ ref_table = "card.joker_display_values", ref_value = "chips", retrigger_type = "mult" },
	},
	text_config = { colour = G.C.CHIPS },
	calc_function = function(card)
		if G.GAME.instagrad_timer then
			local chips = card.ability.extra.chips * math.floor(G.GAME.instagrad_timer.real / card.ability.extra.time)
			card.joker_display_values.chips = chips
		else
			card.joker_display_values.chips = 0
		end
	end,
}
