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

  def shuffle
    cards.shuffle
  end

  private

  attr_writer :cards

  def stanard_deck_cards
    RANKS.map { |rank| SUITS.map { |suit| Card.new(rank, suit) } }
         .flatten
         .shuffle
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
  VALUE_THRESHOLD = 21

  def initialize
    @cards = []
  end

  def <<(card)
    cards << card
  end

  def busted?
    total > VALUE_THRESHOLD
  end

  def to_s
    cards.map(&:to_s).join(" ")
  end

  def total
    curr_total = unreduced_total

    possible_reductions.sort.each do |reduction|
      curr_total -= reduction if curr_total > VALUE_THRESHOLD
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
