InstaGrad = {}

-- The timer object.
-- Injecting this inside self.GAME allows it to be saved within runs.
-- See lovely.toml for actual the injection.
InstaGrad.timer = {
	real = 1,
	display = "",
	-- Configs (in seconds)
	hand_time = 20, -- Time cost to play a hand
	discard_time = 10, -- Time cost to discard cards
	shuffle_time = 60, -- Time cost to shuffle deck if it's empty
	time_per_dollar = 25, -- At end of round, earn $1 for time remaining
}

-- ========================= BLIND TIMER =========================
---Updates the current blind timer by dt.
---@param dt number? If nil, reset the timer instead.
---@param flash boolean? Display visual effect?
---@param sfx boolean? Play sound effect?
function InstaGrad.update_timer(dt, flash, sfx)
	local timer = G.GAME.instagrad_timer
	if dt == nil then
		-- TODO: Fix this temporary number.
		local reset_time = G.GAME.round_resets.hands * InstaGrad.timer.hand_time
			+ G.GAME.round_resets.discards * InstaGrad.timer.discard_time
		timer.real = reset_time
	else
		timer.real = math.max(0, timer.real + dt)
	end
	-- I wish I could format floats with leading zeroes
	timer.display = string.format(
		"%d:%02d.%s",
		math.floor(timer.real / 60),
		math.floor(timer.real % 60),
		string.format("%.3f", timer.real % 1):sub(3)
	)

	if not G.HUD_blind then
		return
	end

	local timer_UI = G.HUD:get_UIE_by_ID("instagrad_timer_UI")
	if timer_UI then
		if flash then
			local dt_str
			local color
			if dt then
				dt_str = string.format("%d s", math.floor(dt))
				color = dt < 0 and G.C.RED or G.C.GREEN
				if dt > 0 then
					dt_str = "+" .. dt_str
				end
			else
				dt_str = ""
				color = G.C.GREEN
			end
			attention_text({
				text = dt_str,
				scale = timer_UI.config.object.scale,
				hold = 0.7,
				cover_colour = color,
				cover = timer_UI.parent.parent, -- ?
				align = "cm",
			})
		end
		if sfx then
			play_sound(dt and "cancel" or "tarot1")
		end
	end
end

local _Game_update = Game.update
function Game:update(dt)
	_Game_update(self, dt)

	-- Game is not paused, and player actually has control.
	if not G.SETTINGS.paused and self.STATE == self.STATES.SELECTING_HAND then
		InstaGrad.update_timer(-dt)

		if G.GAME.instagrad_timer.real == 0 then
			-- TODO: Mr. Bones should save this run (how?)
			G.STATE = G.STATES.GAME_OVER
			if not G.GAME.won and not G.GAME.seeded and not G.GAME.challenge then
				G.PROFILES[G.SETTINGS.profile].high_scores.current_streak.amt = 0
			end
			G:save_settings()
			G.FILE_HANDLER.force = true
			G.STATE_COMPLETE = false
		end
	end
end

local _G_FUNCS_play_cards_from_highlighted = G.FUNCS.play_cards_from_highlighted
function G.FUNCS.play_cards_from_highlighted(e, hook)
	if e and e.config and e.config.id == "play_button" then
		InstaGrad.update_timer(-G.GAME.instagrad_timer.hand_time, true, true)
	end
	_G_FUNCS_play_cards_from_highlighted(e, hook)
end

local _G_FUNCS_discard_cards_from_highlighted = G.FUNCS.discard_cards_from_highlighted
function G.FUNCS.discard_cards_from_highlighted(e, hook)
	if e and e.config and e.config.id == "discard_button" then
		InstaGrad.update_timer(-G.GAME.instagrad_timer.discard_time, true, true)
	end
	_G_FUNCS_discard_cards_from_highlighted(e, hook)
end

function ease_hands_played(mod, instant, silent) end
function ease_discard(mod, instant, silent) end

-- ========================= JOKER OVERRIDES =========================
-- Just overriding a single Joker as a test.
SMODS.Joker:take_ownership("banner", {
	config = { extra = { chips = 30, time = 30 } },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.chips, card.ability.extra.time } }
	end,
	calculate = function(self, card, context)
		if context.joker_main and G.GAME.instagrad_timer.real > card.ability.extra.time then
			local chips = card.ability.extra.chips * math.floor(G.GAME.instagrad_timer.real / card.ability.extra.time)
			return {
				chip_mod = chips,
				message = localize({ type = "variable", key = "a_chips", vars = { chips } }),
			}
		end
	end,
})

-- JokerDisplay mod support.
if JokerDisplay then
	SMODS.load_file("joker_display_definitions.lua")()
end

-- ========================= BLIND OVERRIDES =========================
-- TODO

-- ========================= DECK OVERRIDES =========================
-- TODO

-- ========================= STAKE OVERRIDES =========================
-- TODO
