class Deck
  RANKS = %i[j q k a] + (2..10).to_a
  SUITS = %i[c d h s]

  attr_reader :cards

  def initialize
    @cards = stanard_deck_cards
  end

  private

  def stanard_deck_cards
    RANKS.map { |rank| SUITS.map { |suit| Card.new(rank, suit) } }
         .flatten
  end
end

class Card
  SYMBOLS = { c: "♣", d: "♦", h: "♥", s: "♠" }

  attr_reader :rank, :suit

  def initialize(rank, suit)
    @rank = rank
    @suit = suit
  end

  def suit_symbol
    SYMBOLS[suit]
  end

  def to_s
    rank.to_s.upcase + suit_symbol
  end
end

class Hand
end
