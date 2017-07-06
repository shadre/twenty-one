class Deck
end

class Card
  SYMBOLS  = { c: "♣", d: "♦", h: "♥", s: "♠" }

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
