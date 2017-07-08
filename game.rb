class Deck
  RANKS = %i[j q k a] + (2..10).to_a
  SUITS = %i[c d h s]

  attr_reader :cards

  def initialize
    @cards = stanard_deck_cards
  end

  def deal
    cards.shift
  end

  def shuffle!
    cards.shuffle!
  end

  private

  attr_writer :cards

  def stanard_deck_cards
    RANKS.product(SUITS)
         .map { |card| Card.new(*card) }
  end
end

class Card
  FACE_VALUES = { j: 10, q: 10, k: 10, a: 11 }
  REDUCTIONS  = { a: 10 }
  SYMBOLS     = { c: "♣", d: "♦", h: "♥", s: "♠" }

  attr_reader :rank, :suit, :reduction

  def initialize(rank, suit)
    @rank = rank
    @suit = suit
  end

  def reduction
    REDUCTIONS[rank]
  end

  def suit_symbol
    SYMBOLS[suit]
  end

  def to_s
    rank.to_s.upcase + suit_symbol
  end

  def value
    FACE_VALUES[rank] || rank
  end
end

class Hand
  BUSTED_THRESHOLD = 21

  def initialize
    @cards = []
  end

  def <<(card)
    cards << card
  end

  def busted?
    total > BUSTED_THRESHOLD
  end

  def to_s
    cards.map(&:to_s).join(" ")
  end

  def total
    curr_total = unreduced_total

    possible_reductions.sort.each do |reduction|
      curr_total -= reduction if curr_total > BUSTED_THRESHOLD
    end

    curr_total
  end

  private

  attr_reader :cards

  def possible_reductions
    cards.map(&:reduction).select(&:itself)
  end

  def unreduced_total
    cards.map(&:value).reduce(:+)
  end
end

class Game
  attr_reader :winner

  def initialize(deck, *players)
    @deck          = deck
    @players       = players
    @in_contention = players.dup
  end

  def detect_winner
    return self.winner = in_contention.first if last_man_standing?

    self.winner = winner_by_total
  end

  def hit(hand)
    hand << deck.deal
  end

  def initial_deal
    deck.shuffle!
    players.each { |player| player.initial_draw(self) }
  end

  def last_man_standing?
    in_contention.size == 1
  end

  def mark_as_busted(player)
    in_contention.delete(player)
  end

  def play
    players.each { |player| player.play_turn(self) }
  end

  private

  attr_accessor :in_contention
  attr_reader :deck, :players
  attr_writer :winner

  def winner_by_total
    max_score    = in_contention.map(&:total).max
    best_players = in_contention.find_all { |player| player.total == max_score }

    best_players.first if best_players.size == 1
  end
end

class Partaker
  attr_reader :hand, :name

  def initialize
    @name = assign_name
    new_hand
  end

  def busted?
    hand.busted?
  end

  def initial_draw
    reset
    raise NotImplementedError,
          "method not implemented in #{self.class}"
  end

  def play_turn(game)
    loop do
      make_decision(game)
      game.mark_as_busted(self) if busted?
      break if staying
    end
  end

  def stay
    self.staying = true
  end

  def to_s
    name
  end

  def total
    hand.total
  end

  private

  attr_accessor :staying
  attr_writer :hand

  def assign_name
    ""
  end

  def make_decision(_game)
    raise NotImplementedError,
          "method not implemented in #{self.class}"
  end

  def new_hand
    self.hand = Hand.new
  end

  def reset
    new_hand
    self.staying = false
  end
end

class Dealer < Partaker
  HITTING_THRESHOLD = 17

  def initial_draw(game)
    game.hit(hand)
  end

  private

  def assign_name
    "Dealer"
  end

  def limit_reached?
    total >= HITTING_THRESHOLD
  end

  def make_decision(game)
    game.hit(hand)

    game.hit(hand) until limit_reached?
    stay
  end
end

class Player < Partaker
  def initial_draw(game)
    2.times { game.hit(hand) }
  end

  private

  def assign_name
    "Player"
  end

  def make_decision(game) # temporary implementation
    game.hit(hand)
    stay
  end
end
