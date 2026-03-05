local mod = SMODS.current_mod
VanillaConfig = SMODS.current_mod.config
SMODS.Atlas({key = "DeckExpansion", path = "DeckExpansion.png", px = 71, py = 95, atlas_table = "ASSET_ATLAS"}):register()
SMODS.Atlas({key = "JokerExpansion", path = "JokerExpansion.png", px = 71, py = 95, atlas_table = "ASSET_ATLAS"}):register()

SMODS.current_mod.config_tab = function() --Config tab
    return {
      n = G.UIT.ROOT,
      config = {
        align = "cm",
        padding = 0.05,
        colour = G.C.CLEAR,
      },
      nodes = {
        create_toggle({
            label = "Jokers (restart required)",
            ref_table = VanillaConfig,
            ref_value = "jokers",
        }),
        create_toggle({
            label = "Decls (restart required)",
            ref_table = VanillaConfig,
            ref_value = "decks",
        })
      },
    }
end

-- Resets

local function get_trump_x_pos()
    local trumpNextPos = 2
    if G.GAME.current_round.trump_card and G.GAME.current_round.trump_card.suit and G.GAME.current_round.trump_card.suit == "Clubs" then trumpNextPos = 3
    elseif G.GAME.current_round.trump_card and G.GAME.current_round.trump_card.suit and G.GAME.current_round.trump_card.suit == "Diamonds" then trumpNextPos = 4
    elseif G.GAME.current_round.trump_card and G.GAME.current_round.trump_card.suit and G.GAME.current_round.trump_card.suit == "Spades" then trumpNextPos = 5 end
    return trumpNextPos
end

local function reset_trump_card()
	local trump_suits = {}
    G.GAME.current_round.trump_card = G.GAME.current_round.trump_card or {}
	for k, suit in pairs(SMODS.Suits) do
		if
			k ~= G.GAME.current_round.trump_card.suit
			and (type(suit.in_pool) ~= "function" or suit:in_pool({ rank = "" }))
		then
			trump_suits[#trump_suits + 1] = k
		end
	end
	local trump_card = pseudorandom_element(trump_suits, pseudoseed("trump" .. G.GAME.round_resets.ante))
	G.GAME.current_round.trump_card.suit = trump_card
end

local function reset_paper_shredder()
    G.GAME.current_round.paper_shredder = { rank = 'Ace' }
    local valid_cards = {}
    for _, playing_card in ipairs(G.playing_cards) do
        if not SMODS.has_no_rank(playing_card) then
            valid_cards[#valid_cards + 1] = playing_card
        end
    end
    local mail_card = pseudorandom_element(valid_cards, 'paper_shredder' .. G.GAME.round_resets.ante)
    if mail_card then
        G.GAME.current_round.paper_shredder.rank = mail_card.base.value
        G.GAME.current_round.paper_shredder.id = mail_card.base.id
    end
end

mod.reset_game_globals = function(run_start)
	reset_trump_card()
    reset_paper_shredder()
end

-- Booster Packs

local function arcana_revenant_card(self, card, i)
    local _card
    if G.GAME.used_vouchers.v_omen_globe and pseudorandom('omen_globe') > 0.8 or
    next(find_joker('Revenant')) and pseudorandom('revenant') > 0.8 then
        _card = {
            set = "Spectral",
            area = G.pack_cards,
            skip_materialize = true,
            soulable = true,
            key_append =
            "vremade_ar2"
        }
    else
        _card = {
            set = "Tarot",
            area = G.pack_cards,
            skip_materialize = true,
            soulable = true,
            key_append =
            "vremade_ar2"
        }
    end
    return _card
end

local function celestial_revenant_card(self, card, i)
    local _card
    if G.GAME.used_vouchers.v_telescope and i == 1 then
        local _planet, _hand, _tally = nil, nil, 0
        for _, handname in ipairs(G.handlist) do
            if SMODS.is_poker_hand_visible(handname) and G.GAME.hands[handname].played > _tally then
                _hand = handname
                _tally = G.GAME.hands[handname].played
            end
        end
        if _hand then
            for _, planet_center in pairs(G.P_CENTER_POOLS.Planet) do
                if planet_center.config.hand_type == _hand then
                    _planet = planet_center.key
                end
            end
        end
        _card = {
            set = "Planet",
            area = G.pack_cards,
            skip_materialize = true,
            soulable = true,
            key = _planet,
            key_append =
            "vremade_pl1"
        }
    elseif next(find_joker('Revenant')) and pseudorandom('revenant') > 0.8 then
        _card = {
            set = "Spectral",
            area = G.pack_cards,
            skip_materialize = true,
            soulable = true,
            key_append =
            "vremade_ar2"
        }
    else
        _card = {
            set = "Planet",
            area = G.pack_cards,
            skip_materialize = true,
            soulable = true,
            key_append =
            "vremade_pl1"
        }
    end
    return _card
end

local function revenant_update_pack(self, dt)
    if G.buttons then G.buttons:remove(); G.buttons = nil end
    if G.shop then G.shop.alignment.offset.y = G.ROOM.T.y+11 end

    if not G.STATE_COMPLETE then
        G.STATE_COMPLETE = true
        G.CONTROLLER.interrupt.focus = true
        G.E_MANAGER:add_event(Event({
            trigger = 'immediate',
            func = function()
                if self.particles and type(self.particles) == "function" then self:particles() end
                G.booster_pack = UIBox{
                    definition = self:create_UIBox(),
                    config = {align="tmi", offset = {x=0,y=G.ROOM.T.y + 9}, major = G.hand, bond = 'Weak'}
                }
                G.booster_pack.alignment.offset.y = -2.2
                G.ROOM.jiggle = G.ROOM.jiggle + 3
                self:ease_background_colour()
                G.E_MANAGER:add_event(Event({
                    trigger = 'immediate',
                    func = function()
                        if self.draw_hand == true or next(find_joker('Revenant')) then G.FUNCS.draw_from_deck_to_hand() end

                        G.E_MANAGER:add_event(Event({
                            trigger = 'after',
                            delay = 0.5,
                            func = function()
                                G.CONTROLLER:recall_cardarea_focus('pack_cards')
                                return true
                            end}))
                        return true
                    end
                }))
                return true
            end
        }))
    end
end

-- Necronomicon

local function get_tarot_name(index)
    local c_tbl = {
        [0] = "The Fool",
        [1] = "The Magician",
        [2] = "The High Priestess",
        [3] = "The Empress",
        [4] = "The Empreror",
        [5] = "The Hierophant",
        [6] = "The Lovers",
        [7] = "The Chariot",
        [8] = "Justice",
        [9] = "The Hermit",
        [10] = "The Wheel of Fortune",
        [11] = "Strength",
        [12] = "The Hanged Man",
        [13] = "Death",
        [14] = "Temperance",
        [15] = "The Devil",
        [16] = "The Tower",
        [17] = "The Star",
        [18] = "The Moon",
        [19] = "The Sun",
        [20] = "Judgement",
        [21] = "The World"
    }
    return c_tbl[index]
end

local function get_tarot_id(index)
    local c_tbl = {
        [0] = "c_fool",
        [1] = "c_magician",
        [2] = "c_high_priestess",
        [3] = "c_empress",
        [4] = "c_emperor",
        [5] = "c_heirophant",
        [6] = "c_lovers",
        [7] = "c_chariot",
        [8] = "c_justice",
        [9] = "c_hermit",
        [10] = "c_wheel_of_fortune",
        [11] = "c_strength",
        [12] = "c_hanged_man",
        [13] = "c_death",
        [14] = "c_temperance",
        [15] = "c_devil",
        [16] = "c_tower",
        [17] = "c_star",
        [18] = "c_moon",
        [19] = "c_sun",
        [20] = "c_judgement",
        [21] = "c_world"
    }
    return c_tbl[index]
end

-- Utils

local function contains(table_, value)
    for _, v in pairs(table_) do
        if v == value then
            return true
        end
    end

    return false
end

if VanillaConfig.decks then
SMODS.Back{ --Inferno Deck
    name = "Inferno Deck",
	key = "infernodeck",  
  loc_txt = {      
    name = 'Inferno Deck',      
    text = {
        "Start run with",
        "{C:attention}2{} copies of",
        "{C:tarot,T:c_devil}#2#{} and {C:money}$0#"
    } 
  }, 
	order = 70,
  unlocked = true,
  discovered = true,
	config = {dollars = -4, consumables = {'c_devil', 'c_devil'}},
  loc_vars = function(self, info_queue, center)
    return {vars = {self.config.dollars, localize{type = 'name_text', key = 'c_devil', set = 'Tarot'}}}
  end,
	pos = { x = 1, y = 1 },
	atlas = "DeckExpansion"
}

SMODS.Back{ --Pirate Deck
    name = "Pirate Deck",
	key = "piratedeck",  
  loc_txt = {      
    name = 'Pirate Deck',      
    text = {
        "After defeating each",
        "{C:attention}Boss Blind{}, create a",
        "{C:tarot,T:c_hanged_man}#1#",
        "{C:inactive}(Must have room)",
    } 
  }, 
	order = 71,
  unlocked = true,
  discovered = true,
	config = {},
  loc_vars = function(self, info_queue, center)
    return {vars = {localize{type = 'name_text', key = 'c_hanged_man', set = 'Tarot'}}}
  end,
  calculate = function(self, back, context)
        if context.round_eval and G.GAME.last_blind and G.GAME.last_blind.boss and #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
            G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
            G.E_MANAGER:add_event(Event({
                func = function()
                    local card = create_card('Tarot',G.consumeables, nil, nil, nil, nil, 'c_hanged_man', nil)
                    card:add_to_deck()
                    G.consumeables:emplace(card)
                    G.GAME.consumeable_buffer = 0
                    return true
                end
            }))
        end
    end,
	pos = { x = 2, y = 1 },
	atlas = "DeckExpansion"
}

SMODS.Back{ --Royal Deck
    name = "Royal Deck",
	key = "royaldeck",  
  loc_txt = {      
    name = 'Royal Deck',      
    text = {
        "Start with a {C:attention}#1#{},",
        "a {C:red}Red Seal{}, a {C:purple}Purple Seal{},",
        "and a {C:blue}Blue Seal{}",
        "-1 {C:attention}Booster Pack{} in the Shop",
    } 
  }, 
	order = 72,
  unlocked = true,
  discovered = true,
	config = {boosters_in_shop = 1},
  apply = function(self, back)
    G.GAME.starting_params.extra_seals = true
    G.GAME.starting_params.less_boosters = true
  end,
  loc_vars = function(self, info_queue, center)
    return {vars = {localize{type = 'name_text', key = 'gold_seal', set = 'Other'}, localize{type = 'name_text', key = 'red_seal', set = 'Other'}, localize{type = 'name_text', key = 'blue_seal', set = 'Other'}, localize{type = 'name_text', key = 'purple_seal', set = 'Other'}}}
  end,
	pos = { x = 3, y = 1 },
	atlas = "DeckExpansion"
}

SMODS.Back{ --Premium Deck
    name = "Premium Deck",
	key = "premiumdeck",  
  loc_txt = {      
    name = 'Premium Deck',      
    text = {
        "Start with an {C:dark_edition}Holographic{} card,",
        "a {C:dark_edition}Foil{} card, a {C:dark_edition}Polychrome{} card,",
        "and a copy of {C:tarot,T:c_death}#1#",
        "{C:tarot}Tarot{} cards no longer",
        "appear in the Shop"
    } 
  }, 
	order = 73,
  unlocked = true,
  discovered = true,
	config = {consumables = { 'c_death' }},
  apply = function(self, back)
    G.GAME.tarot_rate = 0
    G.GAME.starting_params.no_tarot = true
    G.GAME.starting_params.extra_editions = true
  end,
  loc_vars = function(self, info_queue, center)
    return {vars = {localize{type = 'name_text', key = 'c_death', set = 'Tarot'}}}
  end,
	pos = { x = 4, y = 1 },
	atlas = "DeckExpansion"
}

SMODS.Voucher:take_ownership('tarot_merchant', {
        redeem = function(self, card)
        G.E_MANAGER:add_event(Event({
            func = function()
                G.GAME.tarot_rate = 4 * card.ability.extra
                if G.GAME.starting_params.no_tarot then G.GAME.tarot_rate = 0 end
                return true
            end
        }))
      end,
    })

SMODS.Voucher:take_ownership('tarot_tycoon', {
        redeem = function(self, card)
        G.E_MANAGER:add_event(Event({
            func = function()
                G.GAME.tarot_rate = 4 * card.ability.extra
                if G.GAME.starting_params.no_tarot then G.GAME.tarot_rate = 0 end
                return true
            end
        }))
      end,
    })

SMODS.DrawStep:take_ownership('back', {
        func = function(self)
        local overlay = G.C.WHITE
        if self.area and self.area.config.type == 'deck' and self.rank > 3 then
            self.back_overlay = self.back_overlay or {}
            self.back_overlay[1] = 0.5 + ((#self.area.cards - self.rank)%7)/50
            self.back_overlay[2] = 0.5 + ((#self.area.cards - self.rank)%7)/50
            self.back_overlay[3] = 0.5 + ((#self.area.cards - self.rank)%7)/50
            self.back_overlay[4] = 1
            overlay = self.back_overlay
        end

        if self.area and self.area.config.type == 'deck' then
            if self.children.back.sprite_pos.x == 4 and self.children.back.sprite_pos.y == 1 then
                self.children.back:draw_shader('polychrome', nil, nil, true)
            else
                self.children.back:draw(overlay)
            end                    
        else
           if self.children.back.sprite_pos.x == 4 and self.children.back.sprite_pos.y == 1 then
                self.children.back:draw_shader('polychrome', nil, nil, true)
           else
                self.children.back:draw_shader('dissolve')
           end
        end
    end,
    })

SMODS.Back{ --Carnival Deck
    name = "Carnival Deck",
	key = "carnivaldeck",  
  loc_txt = {      
    name = 'Carnival Deck',      
    text = {
        "{C:attention}Vouchers{} restock after",
        "defeating each Blind",
        "Voucher price increased",
        "by {C:attention}20%{}",
    } 
  }, 
	order = 74,
  unlocked = true,
  discovered = true,
	config = {},
  apply = function(self, back)
    G.GAME.starting_params.extra_vouchers = true
    G.GAME.starting_params.expensive_vouchers = true
  end,
  loc_vars = function(self, info_queue, center)
    return {}
  end,
	pos = { x = 5, y = 1 },
	atlas = "DeckExpansion"
}

SMODS.add_voucher_to_shop = function(key, dont_save)
    if key then assert(G.P_CENTERS[key], "Invalid voucher key: "..key) else
        key = get_next_voucher_key()
        if not dont_save then
            G.GAME.current_round.voucher.spawn[key] = true
            G.GAME.current_round.voucher[#G.GAME.current_round.voucher + 1] = key
        end
    end
    local voucher_info = G.P_CENTERS[key]
    if G.GAME.starting_params.expensive_vouchers then
        voucher_info.cost = 12
    else
        voucher_info.cost = 10
    end
    local card = Card(G.shop_vouchers.T.x + G.shop_vouchers.T.w/2,
        G.shop_vouchers.T.y, G.CARD_W, G.CARD_H, G.P_CARDS.empty, voucher_info,{bypass_discovery_center = true, bypass_discovery_ui = true})
        card.shop_voucher = true
        create_shop_card_ui(card, 'Voucher', G.shop_vouchers)
        card:start_materialize()
        G.shop_vouchers:emplace(card)
        G.shop_vouchers.config.card_limit = #G.shop_vouchers.cards
        return card
end

SMODS.Back{ --Alchemy Deck
    name = "Alchemy Deck",
	key = "alchemydeck",  
  loc_txt = {      
    name = 'Alchemy Deck',      
    text = {
        "Played {C:attention}Three of a Kind{} create a {C:planet}Planet{} card",
        "Player {C:attention}Four of a Kind{} create a {C:tarot}Tarot{} card",
        "Played {C:attention}Five of a Kind{} create a {C:spectral}Spectral{} card",
        "{C:inactive}(Must have room)",
    } 
  }, 
	order = 75,
  unlocked = true,
  discovered = true,
	config = {},
  apply = function(self, back)
    G.GAME.starting_params.poker_hand_1 = "Three of a Kind"
    G.GAME.starting_params.poker_hand_2 = "Four of a Kind"
    G.GAME.starting_params.poker_hand_3 = "Five of a Kind"
  end,
  loc_vars = function(self, info_queue, center)
    return {}
  end,
  calculate = function(self, card, context)
      if context.before and context.scoring_name == G.GAME.starting_params.poker_hand_3 and
          #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
          G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
          G.E_MANAGER:add_event(Event({
              func = (function()
                  SMODS.add_card {
                      set = 'Spectral',
                  }
                  G.GAME.consumeable_buffer = 0
                  return true
              end)
          }))
      elseif context.before and context.scoring_name == G.GAME.starting_params.poker_hand_2 and
          #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
          G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
          G.E_MANAGER:add_event(Event({
              func = (function()
                  SMODS.add_card {
                      set = 'Tarot',
                  }
                  G.GAME.consumeable_buffer = 0
                  return true
              end)
          }))
        elseif context.before and context.scoring_name == G.GAME.starting_params.poker_hand_1 and
          #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
          G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
          G.E_MANAGER:add_event(Event({
              func = (function()
                  SMODS.add_card {
                      set = 'Planet',
                  }
                  G.GAME.consumeable_buffer = 0
                  return true
              end)
          }))
      end
  end,
	pos = { x = 6, y = 1 },
	atlas = "DeckExpansion"
}

SMODS.Back{ --Eldritch Deck
    name = "Eldritch Deck",
	key = "eldritchdeck",  
  loc_txt = {      
    name = 'Eldritch Deck',      
    text={
        "At end of each Round:",
        "{C:money}$#1#{s:0.85} per remaining {C:blue}Hand",
        "{C:money}$#2#{s:0.85} per remaining {C:red}Discard",
    } 
  }, 
	order = 76,
  unlocked = true,
  discovered = true,
	config = {extra_hand_bonus = 0, extra_discard_bonus = 2},
  loc_vars = function(self, info_queue, center)
    return { vars = { self.config.extra_hand_bonus, self.config.extra_discard_bonus } }
  end,
	pos = { x = 6, y = 0 },
	atlas = "DeckExpansion"
}
end

if VanillaConfig.jokers then
SMODS.Joker { --Folder
    key = "binder",
    pos = { x = 0, y = 0 },
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    cost = 4,
    config = { extra = { chips = 15 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    loc_txt = {
        ['name'] = 'Folder',
        ['text'] = {
            [1] = '{C:chips}+#1#{} Chips for every',
            [2] = 'card {C:attention}held in hand'
        }
    },
    calculate = function(self, card, context)
        if context.joker_main then
            return { chips = #G.hand.cards * card.ability.extra.chips }
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Bingo Card
    key = "bingo_card",
    pos = { x = 1, y = 0 },
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 5,
    config = { extra = { mult = 13 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    loc_txt = {
        ['name'] = 'Bingo Card',
        ['text'] = {
            [1] = '{C:mult}+#1#{} Mult if all scoring',
            [2] = 'cards in played hand',
            [3] = 'are {C:attention}numbered cards'
        }
    },
     calculate = function(self, card, context)
        if context.joker_main then
            for _, playing_card in ipairs(context.scoring_hand) do
                if not playing_card:is_numbered() then
                    return {}
                end
            end
            return { mult = card.ability.extra.mult }
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Pentagram
    key = "pentagram",
    pos = { x = 2, y = 0 },
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 5,
    config = { extra = {can_create = true } },
    loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end,
    loc_txt = {
        ['name'] = 'Pentagram',
        ['text'] = {
            [1] = 'Once per round, if',
            [2] = 'played hand has a scoring {C:attention}5{},',
            [3] = 'create a {C:tarot}Tarot{} card',
            [4] = '{C:inactive}(Must have room)'
        }
    },
    calculate = function(self, card, context)
      if context.before and
          #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
            for _, playing_card in ipairs(context.scoring_hand) do
                if playing_card:get_id() == 5 and card.ability.extra.can_create then
                    G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                    return {
                    func = (function()
                        G.E_MANAGER:add_event(Event({
                            func = function()
                                SMODS.add_card {
                                    set = 'Tarot',
                                }
                                G.GAME.consumeable_buffer = 0
                                return true
                            end
                        }))
                        SMODS.calculate_effect({ message = localize('k_plus_tarot'), colour = G.C.PURPLE },
                            context.blueprint_card or card)
                        return true
                    end)
                }
                end
            end
      end
      if context.after and card.ability.extra.can_create then
        for _, playing_card in ipairs(context.scoring_hand) do
            if playing_card:get_id() == 5 then
              card.ability.extra.can_create = false
            end
        end
      end
      if context.end_of_round then
        card.ability.extra.can_create = true
      end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Pharaoh
    key = "pharaoh",
    pos = { x = 3, y = 0 },
    rarity = 1,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 5,
    config = {},
    loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end,
    loc_txt = {
        ['name'] = 'Pharaoh',
        ['text'] = {
            [1] = 'If {C:attention}first hand{} of round',
            [2] = 'has only {C:attention}1{} card,',
            [3] = 'add a random {C:dark_edition}edition{} to it'
        }
    },
    calculate = function(self, card, context)
        if context.first_hand_drawn and not context.blueprint then
            local eval = function() return G.GAME.current_round.hands_played == 0 and not G.RESET_JIGGLES end
            juice_card_until(card, eval, true)
        end
        if context.before and G.GAME.current_round.hands_played == 0 and #context.full_hand == 1 and not context.full_hand[1].edition then
            local edition = poll_edition("pharaoh", nil, true, true, { 'e_polychrome', 'e_holo', 'e_foil' })
            context.full_hand[1]:set_edition(edition, true)
            G.E_MANAGER:add_event(Event({
                        func = function()
                            context.full_hand[1]:juice_up()
                            return true
                        end
                    }))
            return {
                    message = localize('k_edition'),
                    colour = G.C.WHITE
                }
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Postcard
    key = "postcard",
    pos = { x = 4, y = 0 },
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 4,
    config = { extra = { dollars = 7 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
    loc_txt = {
        ['name'] = 'Postcard',
        ['text'] = {
            [1] = 'Earn {C:money}$#1#{} when playing a',
            [2] = 'poker hand for the',
            [3] = '{C:attention}first time{} this run'
        }
    },
    calculate = function(self, card, context)
        if context.before and G.GAME.hands[context.scoring_name].played == 1 then
            G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + card.ability.extra.dollars
            return {
                dollars = card.ability.extra.dollars,
                func = function() -- This is for timing purposes, it runs after the dollar manipulation
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            G.GAME.dollar_buffer = 0
                            return true
                        end
                    }))
                end
            }
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Scorecard
    key = "scorecard",
    pos = { x = 5, y = 0 },
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    unlocked = true,
    discovered = true,    
    cost = 4,
    config = { extra = { chips = 0, chip_mod = 12, score = 9, score_remaining = 9 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chip_mod, card.ability.extra.score, card.ability.extra.score_remaining, card.ability.extra.chips } }
    end,
    loc_txt = {
        ['name'] = 'Scorecard',
        ['text'] = {
            [1] = 'This Joker gains {C:chips}+#1#{} Chips',
            [2] = 'for every {C:attention}#2#{}{C:inactive} [#3#]{} cards scored',
            [3] = "{C:inactive}(Currently {C:blue}+#4#{C:inactive} Chips)"
        }
    },
    calculate = function(self, card, context)
        if context.individual and not context.blueprint and context.cardarea == G.play then
            card.ability.extra.score_remaining = card.ability.extra.score_remaining - 1
            if card.ability.extra.score_remaining == 0 then
              card.ability.extra.score_remaining = card.ability.extra.score
              card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
              return {
                  message = localize('k_upgrade_ex'),
                  colour = G.C.CHIPS,
                  message_card = card
              }
            end
        end
        if context.joker_main then
            return {
                chips = card.ability.extra.chips
            }
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Slot Machine
    key = "slotMachine",
    pos = { x = 6, y = 0 },
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 4,
    config = { extra = { dollars_1 = 1, odds_1 = 2, dollars_2 = 1, odds_2 = 5, dollars_3 = 10, odds_3 = 15 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars_1, G.GAME.probabilities.normal, card.ability.extra.odds_1, card.ability.extra.dollars_2, G.GAME.probabilities.normal, card.ability.extra.odds_2, card.ability.extra.dollars_3, G.GAME.probabilities.normal, card.ability.extra.odds_3 } }
    end,
    loc_txt = {
        ['name'] = 'Slot Machine',
        ['text'] = {
            [1] = '{C:green}#2# in #3#{} chance to earn',
            [2] = '{C:money}$#1#{} per hand played',
            [3] = '{C:green}#5# in #6#{} chance to earn',
            [4] = 'an additional {C:money}$#4#{}',
            [5] = '{C:green}#8# in #9#{} chance to earn',
            [6] = 'an additional {C:money}$#7#{}'
        }
    },
    calculate = function(self, card, context)
        if context.before then
            local total_money = 0
            if pseudorandom('slot_machine') < G.GAME.probabilities.normal / card.ability.extra.odds_1 then
              total_money = total_money + card.ability.extra.dollars_1
            end
            if pseudorandom('slot_machine') < G.GAME.probabilities.normal / card.ability.extra.odds_2 then
              total_money = total_money + card.ability.extra.dollars_2
            end
            if pseudorandom('slot_machine') < G.GAME.probabilities.normal / card.ability.extra.odds_3 then
              total_money = total_money + card.ability.extra.dollars_3
            end
            if (total_money > 0 ) then
                G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + total_money
                return {
                    dollars = total_money,
                    func = function() -- This is for timing purposes, it runs after the dollar manipulation
                        G.E_MANAGER:add_event(Event({
                            func = function()
                                G.GAME.dollar_buffer = 0
                                return true
                            end
                        }))
                    end
                }
            else
                return nil, true -- This is for Joker retrigger purposes
            end
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Stargazer
    key = "stargazer",
    pos = { x = 0, y = 1 },
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 4,
    config = { extra = { odds = 3 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { G.GAME.probabilities.normal, card.ability.extra.odds } }
    end,
    loc_txt = {
        ['name'] = 'Stargazer',
        ['text'] = {
            [1] = '{C:green}#1# in #2#{} chance to create',
            [2] = 'a {C:planet}Planet{} card when',
            [3] = 'shop is {C:attention}rerolled',
            [4] = '{C:inactive}(Must have room)'
        }
    },
    calculate = function(self, card, context)
        if context.reroll_shop and #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
            if pseudorandom('stargazer') < G.GAME.probabilities.normal / card.ability.extra.odds then
              G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
              G.E_MANAGER:add_event(Event({
                  func = (function()
                      G.E_MANAGER:add_event(Event({
                          func = function()
                              SMODS.add_card {
                                  set = 'Planet',
                              }
                              G.GAME.consumeable_buffer = 0
                              return true
                          end
                      }))
                      SMODS.calculate_effect({ message = localize('k_plus_planet'), colour = G.C.BLUE },
                          context.blueprint_card or card)
                      return true
                  end)
              }))
              return nil, true -- This is for Joker retrigger purposes
            end
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Teddy the Prize Bear
    key = "teddyThePrizeBear",
    pos = { x = 1, y = 1 },
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 5,
    config = { extra = { mult = 6 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.mult * (G.GAME.total_vouchers or 0) } }
    end,
    loc_txt = {
        ['name'] = 'Teddy the Prize Bear',
        ['text'] = {
            [1] = '{C:mult}+#1#{} Mult per {C:red}Voucher',
            [2] = 'redeemed this run',
            [3] = "{C:inactive}(Currently {C:red}+#2#{C:inactive} Mult)"
        }
    },
    calculate = function(self, card, context)
        if context.using_voucher and not context.blueprint then
          SMODS.calculate_effect({ message = localize { type = 'variable', key = 'a_mult', vars = { (G.GAME.total_vouchers or 0) * card.ability.extra.mult } } },
                          context.blueprint_card or card)
          return nil, true -- This is for Joker retrigger purposes
        end
        if context.joker_main then
            return { mult = card.ability.extra.mult * (G.GAME.total_vouchers or 0) }
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Trump Card
    key = "trumpCard",
    pos = { x = 2, y = 1 },
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 5,
    config = { extra = { chips = 15, mult = 2 }, },
    loc_vars = function(self, info_queue, card)
        local current_suit = (G.GAME.current_round.trump_card or {}).suit or 'Hearts'
        return { vars = { card.ability.extra.chips, card.ability.extra.mult, localize(current_suit, 'suits_singular'), colours = { G.C.SUITS[current_suit] } } }
    end,
    loc_txt = {
        ['name'] = 'Trump Card',
        ['text'] = {
            [1] = 'Played cards with {V:1}#3#{} suit',
            [2] = 'give {C:chips}+#1#{} Chips and {C:mult}+#2#{} Mult',
            [3] = 'when scored,',
            [4] = "{s:0.8}suit changes at end of round"
        }
    },
    calculate = function(self, card, context)
        card.children.center.sprite_pos.x = get_trump_x_pos()
        if context.individual and context.cardarea == G.play and context.other_card:is_suit(G.GAME.current_round.trump_card.suit) then
            return {
                mult = card.ability.extra.mult,
                chips = card.ability.extra.chips
            }
        end
    end,
    set_sprites = function(self, card, context)
        card.children.center.sprite_pos.x = get_trump_x_pos()
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Fish Bowl
    key = "fishBowl",
    pos = { x = 6, y = 1 },
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 4,
    config = { extra = { mult = 0, s_mult = 0, mult_mod = 1, last_card = nil }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    loc_txt = {
        ['name'] = 'Fish Bowl',
        ['text'] = {
            [1] = 'Played cards give {C:mult}Mult',
            [2] = 'equal to the number of',
            [3] = '{C:attention}cards scored{} this hand'
        }
    },
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if not (card.ability.extra.last_card == context.other_card) then
                card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mult_mod
                card.ability.extra.last_card = context.other_card
            end
            return {
                mult = card.ability.extra.mult
            }
        end
        if context.after and not context.blueprint then
            card.ability.extra.mult = card.ability.extra.s_mult
            card.ability.extra.last_card = nil
            return {
                message = localize('k_reset')
            }
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Two Minutes to Midnight 
    key = "twoMinutesToMidnight",
    pos = { x = 0, y = 2 },
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 6,
    config = { extra = { mult = 0, mult_mod = 1 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult_mod, card.ability.extra.mult } }
    end,
    loc_txt = {
        ['name'] = 'Two Minutes to Midnight',
        ['text'] = {
            [1] = 'This Joker gains {C:mult}+#1#{} Mult',
            [2] = 'per card scored during the',
            [3] = '{C:attention}final hand{} of the round',
            [4] = "{C:inactive}(Currently {C:red}+#2#{C:inactive} Mult)"
        }
    },
    calculate = function(self, card, context)
        if context.individual and not context.blueprint and context.cardarea == G.play and 
        G.GAME.current_round.hands_left == 0 then
            card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mult_mod
            return {
                message = localize('k_upgrade_ex'),
                colour = G.C.MULT,
                message_card = card
            }
        end
        if context.joker_main then
            return {
                mult = card.ability.extra.mult
            }
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Seedling
    key = "seedling",
    pos = { x = 5, y = 4 },
    rarity = 1,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 3,
    config = { extra = { rounds = 0, total_rounds = 1 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.total_rounds, card.ability.extra.rounds } }
    end,
    loc_txt = {
        ['name'] = 'Seedling',
        ['text'] = {
            [1] = 'After {C:attention}#1#{} round,',
            [2] = 'sell this card to',
            [3] = 'create an {C:green}Uncommon{C:attention} Joker',
            [4] = "{C:inactive}(Currently {C:attention}#2#{C:inactive}/#1#)"
        }
    },
    calculate = function(self, card, context)
        if context.selling_self and (card.ability.extra.rounds >= card.ability.extra.total_rounds) and not context.blueprint then
            if #G.jokers.cards <= G.jokers.config.card_limit then
                G.GAME.joker_buffer = G.GAME.joker_buffer + 1
                G.E_MANAGER:add_event(Event({
                    func = function()
                        SMODS.add_card {
                            set = 'Joker',
                            rarity = 'Uncommon',
                            key_append = 'seedling'
                        }
                        G.GAME.joker_buffer = 0
                        return true
                    end
                }))
                return { 
                    message = localize('k_plus_joker'),
                    colour = G.C.GREEN, 
                }
            else
                return { message = localize('k_no_room_ex') }
            end
        end
        if context.end_of_round and context.game_over == false and context.main_eval and not context.blueprint then
            card.ability.extra.rounds = card.ability.extra.rounds + 1
            if card.ability.extra.rounds == card.ability.extra.total_rounds then
                local eval = function(card) return not card.REMOVED end
                juice_card_until(card, eval, true)
            end
            return {
                message = (card.ability.extra.rounds < card.ability.extra.total_rounds) and
                    (card.ability.extra.rounds .. '/' .. card.ability.extra.total_rounds) or
                    localize('k_active_ex'),
                colour = G.C.FILTER
            }
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Head-Scratcher
    key = "head-scratcher",
    pos = { x = 6, y = 4 },
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    unlocked = true,
    discovered = true,    
    cost = 5,
    config = { extra = { mult = 0, mult_mod = 1, target = 1 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult_mod, card.ability.extra.target, card.ability.extra.mult } }
    end,
    loc_txt = {
        ['name'] = 'Head-Scratcher',
        ['text'] = {
            [1] = 'This Joker gains {C:mult}+#1#{} Mult',
            [2] = 'if played hand has exactly',
            [3] = '{C:attention}#2#{} scoring card(s)',
            [4] = 'Number changes from 1 to 5',
            [5] = "{C:inactive}(Currently {C:red}+#3#{C:inactive} Mult)"
        }
    },
    calculate = function(self, card, context)
        if context.before and not context.blueprint and #context.scoring_hand == card.ability.extra.target then
            card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mult_mod
            card.ability.extra.target = card.ability.extra.target + 1
            if card.ability.extra.target > 5 then card.ability.extra.target = 1 end
            return {
                message = localize('k_upgrade_ex'),
                colour = G.C.MULT
            }
        end
        if context.joker_main then
            return {
                mult = card.ability.extra.mult
            }
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Lifeguard
    key = "lifeguard",
    pos = { x = 0, y = 5 },
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 4,
    config = { extra = { mult = 20 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    loc_txt = {
        ['name'] = 'Lifeguard',
        ['text'] = {
            [1] = '{C:mult}+#1#{} Mult on {C:attention}final',
            [2] = "{C:attention}hand{} of round"
        }
    },
    calculate = function(self, card, context)
        if context.joker_main and G.GAME.current_round.hands_left == 0 then
            return {
                mult = card.ability.extra.mult
            }
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Wedding Ring
    key = "weddingRing",
    pos = { x = 1, y = 5 },
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 4,
    config = { extra = { mult = 6, Xmult = 2 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.Xmult } }
    end,
    loc_txt = {
        ['name'] = 'Wedding Ring',
        ['text'] = {
            [1] = '{C:mult}+#1#{} Mult',
            [2] = "{X:red,C:white}X#2#{} Mult with {C:attention}Bride"
        }
    },
    calculate = function(self, card, context)
        if context.joker_main then
            local bride_xmult = 1
            if next(find_joker('Bride')) then bride_xmult = card.ability.extra.Xmult end
            return {
                mult = card.ability.extra.mult,
                xmult = bride_xmult
            }
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Dollar
    key = "dollar",
    pos = { x = 2, y = 5 },
    rarity = 1,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 5,
    config = { extra = { dollars = 1 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
    loc_txt = {
        ['name'] = 'Dollar',
        ['text'] = {
            [1] = 'Earn {C:money}$#1#{} whenever',
            [2] = 'you {C:attention}buy{} or {C:attention}sell{}',
            [3] = 'an item',
        }
    },
    calculate = function(self, card, context)
        if (context.selling_card or context.buying_card) and not (context.card == card) then
            G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + card.ability.extra.dollars
            return {
                dollars = card.ability.extra.dollars,
                delay = 0.45,
                func = function() -- This is for timing purposes, it runs after the dollar manipulation
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            G.GAME.dollar_buffer = 0
                            return true
                        end
                    }))
                end
            }
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Revenant
    name = "Revenant",
    key = "revenant",
    pos = { x = 0, y = 3 },
    rarity = 2,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 6,
    config = { },
    loc_vars = function(self, info_queue, card)
        return { vars = { } }
    end,
    loc_txt = {
        ['name'] = 'Revenant',
        ['text'] = {
            [1] = '{C:spectral}Spectral{} cards may appear in any',
            [2] = 'of the {C:tarot}Arcana{} and {C:planet}Celestial{} packs',
        }
    },
    atlas = 'JokerExpansion'
}

SMODS.Booster:take_ownership('arcana_normal_1', {
    create_card = function(self, card, i)
        return arcana_revenant_card(self, card, i)
    end
})

SMODS.Booster:take_ownership('arcana_normal_2', {
    create_card = function(self, card, i)
        return arcana_revenant_card(self, card, i)
    end
})

SMODS.Booster:take_ownership('arcana_normal_3', {
    create_card = function(self, card, i)
        return arcana_revenant_card(self, card, i)
    end
})

SMODS.Booster:take_ownership('arcana_normal_4', {
    create_card = function(self, card, i)
        return arcana_revenant_card(self, card, i)
    end
})

SMODS.Booster:take_ownership('arcana_jumbo_1', {
    create_card = function(self, card, i)
        return arcana_revenant_card(self, card, i)
    end
})

SMODS.Booster:take_ownership('arcana_jumbo_2', {
    create_card = function(self, card, i)
        return arcana_revenant_card(self, card, i)
    end
})

SMODS.Booster:take_ownership('arcana_mega_1', {
    create_card = function(self, card, i)
        return arcana_revenant_card(self, card, i)
    end
})

SMODS.Booster:take_ownership('arcana_mega_2', {
    create_card = function(self, card, i)
        return arcana_revenant_card(self, card, i)
    end
})

SMODS.Booster:take_ownership('celestial_normal_1', {
    update_pack = revenant_update_pack,
    create_card = function(self, card, i)
        return celestial_revenant_card(self, card, i)
    end
})

SMODS.Booster:take_ownership('celestial_normal_2', {
    update_pack = revenant_update_pack,
    create_card = function(self, card, i)
        return celestial_revenant_card(self, card, i)
    end
})

SMODS.Booster:take_ownership('celestial_normal_3', {
    update_pack = revenant_update_pack,
    create_card = function(self, card, i)
        return celestial_revenant_card(self, card, i)
    end
})

SMODS.Booster:take_ownership('celestial_normal_4', {
    update_pack = revenant_update_pack,
    create_card = function(self, card, i)
        return celestial_revenant_card(self, card, i)
    end
})

SMODS.Booster:take_ownership('celestial_jumbo_1', {
    update_pack = revenant_update_pack,
    create_card = function(self, card, i)
        return celestial_revenant_card(self, card, i)
    end
})

SMODS.Booster:take_ownership('celestial_jumbo_2', {
    update_pack = revenant_update_pack,
    create_card = function(self, card, i)
        return celestial_revenant_card(self, card, i)
    end
})

SMODS.Booster:take_ownership('celestial_mega_1', {
    update_pack = revenant_update_pack,
    create_card = function(self, card, i)
        return celestial_revenant_card(self, card, i)
    end
})

SMODS.Booster:take_ownership('celestial_mega_2', {
    update_pack = revenant_update_pack,
    create_card = function(self, card, i)
        return celestial_revenant_card(self, card, i)
    end
})

SMODS.Joker { --Seven of Pentacles
    key = "sevenOfPentacles",
    pos = { x = 1, y = 3 },
    rarity = 2,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 7,
    config = { extra = { Xmult = 0.75 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult, 1 + card.ability.extra.Xmult * ((G.consumeables and (#G.consumeables.cards + G.GAME.consumeable_buffer)) or 0) } }
    end,
    loc_txt = {
        ['name'] = 'Seven of Pentacles',
        ['text'] = {
            [1] = 'Gives {X:mult,C:white}X#1#{} Mult for each',
            [2] = 'filled {C:attention}consumable slot',
            [3] = "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)"
        }
    },
    calculate = function(self, card, context)
        if context.joker_main then
            return {
                Xmult = 1 + card.ability.extra.Xmult * (#G.consumeables.cards + G.GAME.consumeable_buffer),
            }
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Close Call
    key = "closeCall",
    pos = { x = 2, y = 3 },
    rarity = 2,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 6,
    config = { extra = { }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { } }
    end,
    loc_txt = {
        ['name'] = 'Close Call',
        ['text'] = {
            [1] = 'Retrigger {C:attention}first{} played ',
            [2] = '{C:attention}enhanced{} card used in scoring',
            [3] = 'and {C:attention}first enhanced{} card',
            [4] = '{C:attention}held in hand{}'
        }
    },
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play then
            local _card = nil
            for _, card in ipairs(context.scoring_hand) do
                if card.ability.set == 'Enhanced' then _card = card break end
            end
            if (_card and context.other_card == _card) then
                return {
                    repetitions = 1
                }
            else return nil, true -- This is for Joker retrigger purposes
            end
        end
        if context.repetition and context.cardarea == G.hand then
            local _card = nil
            for _, card in ipairs(G.hand.cards) do
                if card.ability.set == 'Enhanced' then _card = card break end
            end
            if (_card and context.other_card == _card) then
                return {
                    repetitions = 1
                }
            else return nil, true -- This is for Joker retrigger purposes
            end
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Bride
    name = "Bride", 
    key = "bride",
    pos = { x = 3, y = 3 },
    rarity = 2,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 6,
    config = { extra = { h_plays = 1, h_discards = 1, h_size = -1 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.h_plays, card.ability.extra.h_discards, card.ability.extra.h_size } }
    end,
    loc_txt = {
        ['name'] = 'Bride',
        ['text'] = {
            [1] = '{C:blue}+#1#{} hand each round',
            [2] = '{C:red}+#2#{} discard each round',
            [3] = '{C:attention}#3#{} hand size'
        }
    },
    add_to_deck = function(self, card, from_debuff)
        G.GAME.round_resets.hands = G.GAME.round_resets.hands + card.ability.extra.h_plays
        G.GAME.round_resets.discards = G.GAME.round_resets.discards + card.ability.extra.h_discards
        G.hand:change_size(card.ability.extra.h_size)
    end,
    remove_from_deck = function(self, card, from_debuff)
        G.GAME.round_resets.hands = G.GAME.round_resets.hands - card.ability.extra.h_plays
        G.GAME.round_resets.discards = G.GAME.round_resets.discards - card.ability.extra.h_discards
        G.hand:change_size(-card.ability.extra.h_size)
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Angel
    name = "Angel",
    key = "angel",
    pos = { x = 4, y = 3 },
    rarity = 2,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 5,
    config = { },
    loc_vars = function(self, info_queue, card)
        return { vars = { } }
    end,
    loc_txt = {
        ['name'] = 'Angel',
        ['text'] = {
            [1] = 'Whenever a {C:tarot}Tarot{} card is created,',
            [2] = 'also create a {C:planet}Planet{} card',
            [3] = 'Whenever a {C:planet}Planet{} card is created,',
            [4] = 'also create a {C:tarot}Tarot{} card',
            [5] = "{C:inactive}(Must have room)",
        }
    },
    atlas = 'JokerExpansion'
}

SMODS.Consumable:take_ownership('high_priestess', {
    use = function(self, card, area, copier)
        local to_generate = math.min(2, G.consumeables.config.card_limit - #G.consumeables.cards)
        G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + to_generate

        for i = 1, to_generate do
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.4,
                func = function()
                    if G.consumeables.config.card_limit > #G.consumeables.cards then
                        play_sound('timpani')
                        SMODS.add_card({ set = 'Planet' })
                        card:juice_up(0.3, 0.5)
                        G.GAME.consumeable_buffer = 0
                    end
                    return true
                end
            }))
        end
        delay(0.6)
    end,
    can_use = function(self, card)
        return (G.consumeables and #G.consumeables.cards < G.consumeables.config.card_limit) or
            (card.area == G.consumeables)
    end
})

SMODS.Consumable:take_ownership('emperor', {
    use = function(self, card, area, copier)
        local to_generate = math.min(2, G.consumeables.config.card_limit - #G.consumeables.cards)
        G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + to_generate

        for i = 1, to_generate do
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.4,
                func = function()
                    if G.consumeables.config.card_limit > #G.consumeables.cards then
                        play_sound('timpani')
                        SMODS.add_card({ set = 'Tarot' })
                        card:juice_up(0.3, 0.5)
                        G.GAME.consumeable_buffer = 0
                    end
                    return true
                end
            }))
        end
        delay(0.6)
    end,
    can_use = function(self, card)
        return (G.consumeables and #G.consumeables.cards < G.consumeables.config.card_limit) or
            (card.area == G.consumeables)
    end
})

SMODS.Joker { --Hotrod
    key = "hotrod",
    pos = { x = 5, y = 3 },
    rarity = 2,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 7,
    config = { extra = { Xmult = 0.5 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult, 1 + (G.GAME.current_round.hands_left + G.GAME.current_round.discards_left) * card.ability.extra.Xmult } }
    end,
    loc_txt = {
        ['name'] = 'Hotrod',
        ['text'] = {
            [1] = 'Gives {X:mult,C:white}X#1#{} Mult for each',
            [2] = 'remaining {C:blue}hand{} and {C:red}discard{}',
            [3] = "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)"
        }
    },
    calculate = function(self, card, context)
        if context.joker_main then
            return{
                Xmult = 1 + (G.GAME.current_round.hands_left + G.GAME.current_round.discards_left) * card.ability.extra.Xmult
            }
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Floppy Disk
    key = "floppyDisk",
    pos = { x = 6, y = 3 },
    rarity = 2,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 6,
    config = { extra = { chips = 0, chip_mod = 2 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chip_mod, card.ability.extra.chips } }
    end,
    loc_txt = {
        ['name'] = 'Floppy Disk',
        ['text'] = {
            [1] = 'This Joker gains {C:chips}+#1#{} Chips for',
            [2] = 'every scored {C:attention}numbered card',
            [3] = "{C:inactive}(Currently {C:blue}+#2#{C:inactive} Chips)"
        }
    },
    calculate = function(self, card, context)
        if context.individual and not context.blueprint and context.cardarea == G.play and context.other_card:is_numbered() then
            card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
            return {
                message = localize('k_upgrade_ex'),
                colour = G.C.CHIPS,
                message_card = card
            }
        end
        if context.joker_main then
            return {
                chips = card.ability.extra.chips
            }
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Accumulated Knowledge 
    key = "accumulatedKnowledge",
    pos = { x = 0, y = 4 },
    rarity = 2,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 5,
    config = { extra = { chips = 30 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    loc_txt = {
        ['name'] = 'Accumulated Knowledge',
        ['text'] = {
            [1] = '{C:attention}Bonus cards{} gain',
            [2] = '{C:chips}+#1#{} Chips when scored'
        }
    },
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card.config.center.key == "m_bonus" then
            context.other_card.ability.perma_bonus = (context.other_card.ability.perma_bonus or 0) +
                card.ability.extra.chips
            return {
                message = localize('k_upgrade_ex'),
                colour = G.C.CHIPS
            }
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Vault 
    key = "vault",
    pos = { x = 1, y = 4 },
    rarity = 2,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 6,
    config = { extra = { safe = { }, to_safe = { } } },
    loc_vars = function(self, info_queue, card)
        return { vars = { } }
    end,
    loc_txt = {
        ['name'] = 'Vault',
        ['text'] = {
            [1] = 'Destroy all {C:attention}scoring{} cards',
            [2] = 'in {C:attention}first hand{} of round',
            [3] = 'played against the {C:attention}Boss Blind{}',
            [4] = 'Sell this card to add the',
            [5] = 'destroyed cards to your deck'
        }
    },
    calculate = function(self, card, context)
        if context.first_hand_drawn and G.GAME.blind.boss and not context.blueprint then
            local eval = function() return G.GAME.current_round.hands_played == 0 and not G.RESET_JIGGLES end
            juice_card_until(card, eval, true)
        end
        if G.GAME.blind.boss and context.before and G.GAME.current_round.hands_played == 0 then
            for _, full_hand_card in ipairs(context.scoring_hand) do
                card.ability.extra.to_safe[#card.ability.extra.to_safe + 1] = full_hand_card
                card.ability.extra.safe[#card.ability.extra.safe + 1] = {
                    base = full_hand_card.config.card,
                    ability = full_hand_card.config.center,
                    edition = full_hand_card.edition,
                    seal = full_hand_card.seal
                }
            end
        end
        if G.GAME.blind.boss and context.destroying_card and not context.blueprint then
            return contains(card.ability.extra.to_safe, context.destroying_card)
        end
        if G.GAME.blind.boss and context.after and not context.blueprint then
            card.ability.extra.to_safe = {}
        end
        if context.selling_self then
            for _, safe_card in ipairs(card.ability.extra.safe) do
                G.playing_card = (G.playing_card and G.playing_card + 1) or 1
                local _card = SMODS.create_card { set = "Base", edition = safe_card.edition, seal = safe_card.seal, area = G.discard }
                _card:set_base(safe_card.base)
                _card:set_ability(safe_card.ability)
                _card.playing_card = G.playing_card
                card:add_to_deck()
                G.deck.config.card_limit = G.deck.config.card_limit + 1
                table.insert(G.playing_cards, _card)
                G.deck:emplace(_card)
                SMODS.calculate_context({ playing_card_added = true, cards = { _card } })
            end
            card.ability.extra.safe = {}
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Paparazzo 
    key = "paparazzo",
    pos = { x = 2, y = 4 },
    rarity = 2,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 7,
    config = { },
    loc_vars = function(self, info_queue, card)
        return { vars = { } }
    end,
    loc_txt = {
        ['name'] = 'Paparazzo',
        ['text'] = {
            [1] = 'If {C:attention}final hand{} of round has',
            [2] = '2 or more scoring {C:attention}face{} cards,',
            [3] = 'create a {C:dark_edition}Negative Tag'
        }
    },
    calculate = function(self, card, context)
        if context.before and G.GAME.current_round.hands_left == 0 then
            local _face_cards = 0
            for _, playing_card in ipairs(context.scoring_hand) do
                if playing_card:is_face() then _face_cards = _face_cards + 1 end
            end
            if _face_cards >= 2 then
                G.E_MANAGER:add_event(Event({
                    func = (function()
                    add_tag(Tag('tag_negative'))
                    play_sound('generic1', 0.9 + math.random() * 0.1, 0.8)
                    play_sound('holo1', 1.2 + math.random() * 0.1, 0.4)
                    return true
                    end)
                }))
                return {
                    message = 'Photo!',
                    colour = G.C.WHITE
                }
            end
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Scratchcard 
    key = "scratchcard",
    pos = { x = 3, y = 4 },
    rarity = 2,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 8,
    config = { extra = { dollars = 1 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
    loc_txt = {
        ['name'] = 'Scratchcard',
        ['text'] = {
            [1] = 'Played {C:attention}numbered cards{}',
            [2] = 'earn {C:money}$#1#{} when scored'
        }
    },
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card:is_numbered() then
            G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + card.ability.extra.dollars
            return {
                dollars = card.ability.extra.dollars,
                func = function() -- This is for timing purposes, it runs after the dollar manipulation
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            G.GAME.dollar_buffer = 0
                            return true
                        end
                    }))
                end
            }
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Call to Arms 
    key = "callToArms",
    pos = { x = 4, y = 4 },
    rarity = 2,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 7,
    config = { },
    loc_vars = function(self, info_queue, card)
        return { vars = { } }
    end,
    loc_txt = {
        ['name'] = 'Call to Arms',
        ['text'] = {
            [1] = 'When round begins, add a card',
            [2] = 'with the {C:attention}most common rank',
            [3] = 'amongst cards in your deck',
            [4] = 'to your hand'
        }
    },
    calculate = function(self, card, context)
        if context.first_hand_drawn then
            local _rank = {}
            local _rank_count = 0
            local _rank_all = {}

            for _, playing_card in ipairs(G.playing_cards) do
                _rank_all[playing_card.base.value] = (_rank_all[playing_card.base.value] or 0) + 1
                if (_rank_all[playing_card.base.value]) > _rank_count then
                    _rank_count = _rank_all[playing_card.base.value]
                    _rank = { playing_card.base.value }
                elseif (_rank_all[playing_card.base.value]) == _rank_count then
                    _rank[#_rank + 1] = playing_card.base.value
                end
            end

            _rank = pseudorandom_element(_rank, 'call_to_arms')

            local cen_pool = {}
            for _, enhancement_center in pairs(G.P_CENTER_POOLS["Enhanced"]) do
                if enhancement_center.key ~= 'm_stone' and not enhancement_center.overrides_base_rank then
                    cen_pool[#cen_pool + 1] = enhancement_center
                end
            end
            
            local _enhancement = pseudorandom_element(cen_pool, 'call_to_arms')
            if pseudorandom('call_to_arms') > 0.25 then _enhancement = nil else _enhancement = _enhancement.key end
            local _card = SMODS.create_card { 
                set = "Base",
                rank = _rank,
                enhancement = _enhancement,
                edition = poll_edition("call_to_arms", nil, true, false, { 'e_polychrome', 'e_holo', 'e_foil' }),
                seal = SMODS.poll_seal({ mod = 10, type_key = 'call_to_arms' }),
                area = G.discard 
            }
            G.playing_card = (G.playing_card and G.playing_card + 1) or 1
            _card.playing_card = G.playing_card
            table.insert(G.playing_cards, _card)

            G.E_MANAGER:add_event(Event({
                func = function()
                    G.hand:emplace(_card)
                    _card:start_materialize()
                    G.GAME.blind:debuff_card(_card)
                    G.hand:sort()
                    if context.blueprint_card then
                        context.blueprint_card:juice_up()
                    else
                        card:juice_up()
                    end
                    SMODS.calculate_context({ playing_card_added = true, cards = { _card } })
                    save_run()
                    return true
                end
            }))

            return nil, true -- This is for Joker retrigger purposes
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Zombie
    key = "zombie",
    pos = { x = 3, y = 5 },
    rarity = 2,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 6,
    config = { extra = { mult = 2 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    loc_txt = {
        ['name'] = 'Zombie',
        ['text'] = {
            [1] = 'When {C:attention}Blind{} is selected, add',
            [2] = '{C:green}Infected{} to the Joker to the right',
            [3] = 'When {C:attention}Blind{} is selected,',
            [4] = '{C:green}infected{} Jokers gain {C:mult}+#1#{} Mult'
        }
    },
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            local my_pos = nil
            for i = 1, #G.jokers.cards do
                if G.jokers.cards[i] == card then
                    my_pos = i
                    break
                end
            end
            if my_pos and G.jokers.cards[my_pos + 1] and not G.jokers.cards[my_pos + 1].edition then
                local infected = G.jokers.cards[my_pos + 1]
                infected:set_edition('e_VP_infected', true)
                return {
                    message = "Infected!",
                    colour = G.C.GREEN,
                    message_card = infected
                }
            end
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Shader {
    key = 'infected',
    path = 'infected.fs',
}

SMODS.Edition {
    key = 'infected',
    shader = 'infected',
    config = { mult_mod = 2, mult = 0 },
    in_shop = false,
    weight = 0,
    extra_cost = 0,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.edition.mult } }
    end,
    loc_txt = {
        ['name'] = 'Infected',
        ['text'] = {
            [1] = '{C:mult}+#1#{} Mult'
        }
    },
    get_weight = function(self)
        return 0
    end,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            card.edition.mult = card.edition.mult + card.edition.mult_mod
            return {
                message = "Brains!"
            }
        end
        if context.pre_joker then
            return {
                mult = card.edition.mult
            }
        end
    end
}

SMODS.Joker { --Cosmologist
    name = "Cosmologist",
    key = "cosmologist",
    pos = { x = 1, y = 2 },
    rarity = 3,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 9,
    config = { },
    loc_vars = function(self, info_queue, card)
        return { vars = { } }
    end,
    loc_txt = {
        ['name'] = 'Cosmologist',
        ['text'] = {
            [1] = '{C:planet}Planet{} cards give {C:mult}Mult{} equal',
            [2] = 'to half their amount of {C:chips}Chips{C:chips}',
        }
    },
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Test Card
    key = "testCard",
    pos = { x = 2, y = 2 },
    rarity = 3,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 8,
    config = { extra = { h_size = 1 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.h_size } }
    end,
    loc_txt = {
        ['name'] = 'Test Card',
        ['text'] = {
            [1] = 'After defeating each {C:attention}Boss Blind{},',
            [2] = '{C:attention}+#1#{} hand size',
        }
    },
    calculate = function(self, card, context)
        if context.end_of_round and not context.repetition and not context.individual and G.GAME.blind.boss and not context.blueprint then
            G.hand:change_size(card.ability.extra.h_size)
            return {
                    message = localize{type='variable',key='a_handsize',vars={card.ability.extra.h_size}},
                    colour = G.C.FILTER
                }
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --The Heart
    key = "theHeart",
    pos = { x = 3, y = 2 },
    rarity = 3,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 8,
    config = { extra = { Xmult = 0.1 }, },
    loc_vars = function(self, info_queue, card)
        local heart_tally = 0
        if G.playing_cards then
            for _, playing_card in ipairs(G.playing_cards) do
                if playing_card:is_suit('Hearts') then heart_tally = heart_tally + 1 end
            end
        end
        return { vars = { card.ability.extra.Xmult, 1 + card.ability.extra.Xmult * heart_tally } }
    end,
    loc_txt = {
        ['name'] = 'The Heart',
        ['text'] = {
            [1] = 'Gives {X:mult,C:white}X#1#{} Mult for each',
            [2] = 'card with {C:hearts}Heart{} suit',
            [3] = 'in your full deck',
            [4] = "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)"
        }
    },
    calculate = function(self, card, context)
        if context.joker_main then
            local heart_tally = 0
            for _, playing_card in ipairs(G.playing_cards) do
                if playing_card:is_suit('Hearts') then heart_tally = heart_tally + 1 end
            end
            return {
                Xmult = 1 + card.ability.extra.Xmult * heart_tally,
            }
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Paper Shredder
    key = "paperShredder",
    pos = { x = 6, y = 2 },
    rarity = 3,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 8,
    config = { },
    loc_vars = function(self, info_queue, card)
        local current_rank = (G.GAME.current_round.paper_shredder or {}).rank or 'Ace'
        return { vars = { current_rank } }
    end,
    loc_txt = {
        ['name'] = 'Paper Shredder',
        ['text'] = {
            [1] = 'Each discarded {C:attention}#1#{} is destroyed,',
            [2] = "{s:0.8}rank changes at end of round"
        }
    },
    calculate = function(self, card, context)
        if context.discard and not context.blueprint and
            context.other_card:get_id() == G.GAME.current_round.paper_shredder.id then
            return {
                remove = true,
                delay = 0.45
            }
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Meditation 
    key = "meditation",
    pos = { x = 4, y = 2 },
    rarity = 3,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    unlocked = true,
    discovered = true,    
    cost = 9,
    config = { extra = { Xmult = 1, Xmult_mod = 0.2, Xmult_s = 1 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult_mod, card.ability.extra.Xmult } }
    end,
    loc_txt = {
        ['name'] = 'Meditation',
        ['text'] = {
            [1] = 'This Joker gains {X:mult,C:white}X#1#{} Mult per',
            [2] = '{C:attention}consecutive{} hand played',
            [3] = '{C:attention}without discarding',
            [4] = "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)"
        }
    },
    calculate = function(self, card, context)
        if context.discard and not context.blueprint and context.other_card == context.full_hand[#context.full_hand] then
            card.ability.extra.Xmult = card.ability.extra.Xmult_s
            return {
                message = localize('k_reset')
            }
        end
        if context.before and not context.blueprint then
            -- See note about SMODS Scaling Manipulation on the wiki
            card.ability.extra.Xmult = card.ability.extra.Xmult + card.ability.extra.Xmult_mod
            return {
                message = localize { type = 'variable', key = 'a_xmult', vars = { card.ability.extra.Xmult_mod } },
                colour = G.C.RED
            }
        end
        if context.joker_main then
            return {
                Xmult = card.ability.extra.Xmult
            }
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Demonic Pact  
    key = "demonicPact",
    pos = { x = 5, y = 2 },
    rarity = 3,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = false,
    unlocked = true,
    discovered = true,    
    cost = 8,
    config = { extra = { Xmult = 1, Xmult_loss = 0.15 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult_loss, card.ability.extra.Xmult } }
    end,
    loc_txt = {
        ['name'] = 'Demonic Pact',
        ['text'] = {
            [1] = 'When {C:attention}Blind{} is selected, add {C:dark_edition}Negative',
            [2] = 'to the Joker to the right',
            [3] = 'and lose {X:mult,C:white}X#1#{} Mult to {C:attention}final scoring{}',
            [4] = 'When this Joker is sold or destroyed,',
            [5] = 'destroy all {C:dark_edition}Negative{} jokers',
            [6] = "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)"
        }
    },
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            local my_pos = nil
            for i = 1, #G.jokers.cards do
                if G.jokers.cards[i] == card then
                    my_pos = i
                    break
                end
            end
            if my_pos and G.jokers.cards[my_pos + 1] and not G.jokers.cards[my_pos + 1].edition and not G.jokers.cards[my_pos + 1].getting_sliced then
                local target = G.jokers.cards[my_pos + 1]
                target:set_edition({ negative = true })
                card.ability.extra.Xmult = card.ability.extra.Xmult - card.ability.extra.Xmult_loss
                if card.ability.extra.Xmult > 0 then
                    return {
                        message = localize { type = 'variable', key = 'a_xmult_minus', vars = { card.ability.extra.Xmult_loss } },
                        colour = G.C.RED,
                    }
                else
                    card.getting_sliced = true
                    SMODS.destroy_cards(card, nil, nil, true)
                    return {
                        message = 'Doom!'
                    }
                end
            end
        end
        if context.final_scoring_step then
            return {
                Xmult = card.ability.extra.Xmult
            }
        end
    end,
    remove_from_deck = function(self, card, from_debuff)
        for i = 1, #G.jokers.cards do
            if G.jokers.cards[i].edition and G.jokers.cards[i].edition.negative then
                G.jokers.cards[i].getting_sliced = true
                SMODS.destroy_cards(G.jokers.cards[i], nil, nil, true)
            end
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --High Cultist
    key = "necronomicon",
    pos = { x = 4, y = 5 },
    rarity = 3,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 8,
    config = { extra = { next_card = 21, next_card_name = get_tarot_name(21) }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.next_card_name } }
    end,
    loc_txt = {
        ['name'] = 'High Cultist',
        ['text'] = {
            [1] = 'When {C:attention}Blind{} is selected,',
            [2] = 'fill consumable slots with',
            [3] = 'the next {C:tarot}Tarot{} cards in',
            [4] = '{C:attention}descending numerical{} order',
            [5] = "{C:inactive}(Next card: {C:attention}#1#{C:inactive})"
        }
    },
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            for i=1, (G.consumeables.config.card_limit) do
                if #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
                    G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                    local _card = get_tarot_id(card.ability.extra.next_card)
                    G.E_MANAGER:add_event(Event({
                        trigger = 'before',
                        delay = 0.0,
                        func = (function()
                            local card = create_card('Tarot',G.consumeables, nil, nil, nil, nil, _card)
                            card:add_to_deck()
                            G.consumeables:emplace(card)
                            G.GAME.consumeable_buffer = 0
                            card:juice_up(0.5, 0.5)
                            return true
                        end)}))
                    card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil, {message = localize('k_plus_tarot'), colour = G.C.PURPLE})
                    card.ability.extra.next_card = card.ability.extra.next_card - 1
                    if card.ability.extra.next_card < 0 then card.ability.extra.next_card = 21 end
                    card.ability.extra.next_card_name = get_tarot_name(card.ability.extra.next_card)
                end
            end
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Sol and Luna
    key = "solAndLuna",
    pos = { x = 5, y = 5 },
    rarity = 3,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 8,
    config = { extra = { sun = true, sun_mult = 2, moon_mult = 2, phrase_1_a = "", phrase_1_b = "", phrase_1_c = "", phrase_1_d = "", phrase_2_a = "", phrase_2_b = "", phrase_2_c = "" }, },
    loc_vars = function(self, info_queue, card)
        if card.ability.extra.sun then
            card.ability.extra.phrase_1_a = 'Played '
            card.ability.extra.phrase_1_b = 'enhanced '
            card.ability.extra.phrase_1_c = 'cards give'
            card.ability.extra.phrase_1_d = ''
            card.ability.extra.phrase_2_a = ''
            card.ability.extra.phrase_2_b = 'X2'
            card.ability.extra.phrase_2_c = ' Mult when scored'
        else
            card.ability.extra.phrase_1_a = ''
            card.ability.extra.phrase_1_b = 'Enhanced '
            card.ability.extra.phrase_1_c = 'cards '
            card.ability.extra.phrase_1_d = 'held in hand'
            card.ability.extra.phrase_2_a = 'give '
            card.ability.extra.phrase_2_b = 'X2'
            card.ability.extra.phrase_2_c = ' Mult'
        end
        return { vars = { card.ability.extra.phrase_1_a, card.ability.extra.phrase_1_b, card.ability.extra.phrase_1_c, card.ability.extra.phrase_1_d, card.ability.extra.phrase_2_a, card.ability.extra.phrase_2_b, card.ability.extra.phrase_2_c  } }
    end,
    loc_txt = {
        ['name'] = 'Sol and Luna',
        ['text'] = {
            [1] = '#1#{C:attention}#2#{}#3#{C:attention}#4#{}',
            [2] = '#5#{X:mult,C:white}#6#{}#7#',
            [3] = "{C:inactive}(Changes at end of round)"
        }
    },
    calculate = function(self, card, context)
        if context.individual and card.ability.extra.sun and context.cardarea == G.play and context.other_card.ability.set == 'Enhanced' then
            if context.other_card.debuff then
                return {
                    message = localize('k_debuffed'),
                    colour = G.C.RED
                }
            else
                return {
                    xmult = card.ability.extra.sun_mult
                }
            end
        end
        if context.individual and not card.ability.extra.sun and context.cardarea == G.hand and not context.end_of_round and context.other_card.ability.set == 'Enhanced' then
            if context.other_card.debuff then
                return {
                    message = localize('k_debuffed'),
                    colour = G.C.RED
                }
            else
                return {
                    xmult = card.ability.extra.moon_mult
                }
            end
        end
        if context.end_of_round and context.game_over == false and context.main_eval and not context.blueprint then
            card.ability.extra.sun = not card.ability.extra.sun
            if card.ability.extra.sun then
                return {
                    message = "Dawn"
                }
            else
                return {
                    message = "Twilight"
                }
            end
        end
    end,
    atlas = 'JokerExpansion'
}

SMODS.Joker { --Phantasm
    key = "phantasm",
    pos = { x = 6, y = 5 },
    rarity = 3,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,    
    cost = 8,
    config = { extra = { Xmult = 1 }, },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult, 1 + (card.ability.extra.Xmult * (G.GAME.consumeable_usage_total and G.GAME.consumeable_usage_total.spectral or 0)) } }
    end,
    loc_txt = {
        ['name'] = 'Phantasm',
        ['text'] = {
            [1] = 'Gives {X:mult,C:white}X#1#{} Mult',
            [2] = 'per {C:spectral}Spectral{} card',
            [3] = 'used this run',
            [4] = "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)"
        }
    },
    calculate = function(self, card, context)
        if context.using_consumeable and not context.blueprint and context.consumeable.ability.set == "Spectral" then
            return {
                message = localize { type = 'variable', key = 'a_xmult', vars = { 1 + G.GAME.consumeable_usage_total.spectral * card.ability.extra.Xmult } },
            }
        end
        if context.joker_main then
            return {
                xmult = 1 + (card.ability.extra.Xmult *
                    (G.GAME.consumeable_usage_total and G.GAME.consumeable_usage_total.spectral or 0))
            }
        end
    end,
    atlas = 'JokerExpansion'
}

end