module UX
  PROMPT = ">> "

  def clear_terminal
    system("cls") || system("clear")
  end

  def concat_on_both_sides(original, left, right = nil)
    right ||= left

    left + original + right
  end

  def prompt(*messages)
    messages.each { |msg| puts PROMPT + msg }
  end
end

module UI
  require 'io/console'
  include UX

  TERMINATION_CHARS = { "\u0003" => "^C",
                        "\u0004" => "^D",
                        "\u001A" => "^Z" }

  def get_char(args)
    get_input(**args) { yield_char }
  end

  def get_string(args)
    get_input(**args) { gets.strip }
  end

  def wait_for_any_key
    get_char(message: "Press ANY KEY to continue")
  end

  private

  def fitting?(expected, input)
    !expected || expected.include?(input)
  end

  def get_input(message:, invalid_msg: "Invalid input!", expected: nil)
    prompt message
    loop do
      input = yield

      return input if !input.empty? && fitting?(expected, input)

      prompt invalid_msg
    end
  end

  def quit_if_terminating(char_input)
    termination_input = TERMINATION_CHARS[char_input]
    abort("Program aborted (#{termination_input})") if termination_input
  end

  def yield_char
    char_input = STDIN.getch.downcase

    quit_if_terminating(char_input)

    char_input
  end
end

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

  def value
    FACE_VALUES[rank] || rank
  end
end

class Hand
  include Comparable, UX

  BUSTED_THRESHOLD = 21
  CARD_WIDTH       = 3
  CARD_EDGES       = { top: "_", side: "|", bottom: "‾" }

  def initialize
    @cards = []
  end

  def <<(card)
    cards << card
  end

  def <=>(another)
    [busted_factor, total] <=> [another.busted_factor, another.total]
  end

  def busted?
    total > BUSTED_THRESHOLD
  end

  def size
    cards.size
  end

  def to_s
    all_rows.join("\n")
  end

  def total
    curr_total = unreduced_total

    possible_reductions.sort.each do |reduction|
      curr_total -= reduction if curr_total > BUSTED_THRESHOLD
    end

    curr_total
  end

  protected

  def busted_factor
    busted? ? 0 : 1
  end

  private

  attr_reader :cards

  def all_rows
    [top_edges, top_row, middle_row, bottom_row, bottom_edges]
  end

  def bottom_edges
    edgize(:bottom)
  end

  def bottom_row
    rowize(ranks.map { |rank| rank.to_s.upcase.ljust(CARD_WIDTH) })
  end

  def edgize(edge)
    width = CARD_WIDTH
    cards.map { |_| (CARD_EDGES[edge] * width).center(width + 2) }
         .join
  end

  def middle_row
    rowize(symbols.map { |symbol| symbol.center(CARD_WIDTH) })
  end

  def possible_reductions
    cards.map(&:reduction).compact
  end

  def ranks
    cards.map(&:rank)
  end

  def rowize(elements)
    elements.map { |element| concat_on_both_sides(element, CARD_EDGES[:side]) }
            .join
  end

  def symbols
    cards.map(&:suit_symbol)
  end

  def top_edges
    edgize(:top)
  end

  def top_row
    rowize(ranks.map { |rank| rank.to_s.upcase.rjust(CARD_WIDTH) })
  end

  def unreduced_total
    cards.map(&:value).reduce(:+)
  end
end

class TwentyOneGame
  include UX

  def initialize(deck, *players)
    @deck          = deck
    @players       = players
  end

  def display(clear_screen: true)
    clear_terminal if clear_screen
    players_in_display_order.each(&:display_with_cards)
  end

  def hit(hand)
    hand << deck.deal
  end

  def initial_deal
    deck.shuffle
    players.each { |player| player.initial_draw(self) }
  end

  def play
    initial_deal
    ask_for_playing(*players_in_move_order)
    display_outcome
  end

  private

  attr_reader :deck, :players

  def ask_for_playing(*players)
    players.each do |player|
      player.play_turn(self)
      break if last_man_standing?
    end
  end

  def display_outcome
    display
    winner ? prompt("#{winner} wins!") : prompt("It's a tie!")
  end

  def last_man_standing?
    players.reject(&:busted?).size == 1
  end

  def players_in_descending_order_by(criterium)
    players.sort_by { |player| -player.send(criterium) }
  end

  def players_in_display_order
    players_in_descending_order_by(:display_priority)
  end

  def players_in_move_order
    players_in_descending_order_by(:move_sequence)
  end

  def runner_up
    players.sort[-2]
  end

  def winner
    best = players.max
    best if best != runner_up
  end
end

class Partaker
  include Comparable

  attr_reader :display_priority, :hand, :move_sequence, :name

  DISPLAY_PRIORITY = 0
  MOVE_SEQUENCE    = 0
  NAME             = ""

  def initialize
    setup
    new_hand
  end

  def <=>(another)
    hand <=> another.hand
  end

  def busted?
    hand.busted?
  end

  def display_with_cards
    puts name + ":", hand

    print "total: #{total}"
    puts (busted? ? " (busted)" : ""), ""
  end

  def hit(game)
    game.hit(hand)
  end

  def initial_draw
    reset
    raise NotImplementedError,
          "method not implemented in #{self.class}"
  end

  def play_turn(game)
    loop do
      game.display
      make_decision(game)
      break if busted? || staying
    end
  end

  def reset
    new_hand
    self.staying = false
  end

  def setup
    partaker_type = self.class

    @display_priority = partaker_type::DISPLAY_PRIORITY
    @name             = partaker_type::NAME
    @move_sequence    = partaker_type::MOVE_SEQUENCE
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

  def make_decision(_game)
    raise NotImplementedError,
          "method not implemented in #{self.class}"
  end

  def new_hand
    self.hand = Hand.new
  end
end

class Dealer < Partaker
  include UX

  DISPLAY_PRIORITY  = 1
  HITTING_THRESHOLD = 17
  MOVE_DELAY_SECS   = 1.5
  NAME              = "Dealer"

  def initial_draw(game)
    hit(game)
  end

  private

  def delay_progress
    sleep MOVE_DELAY_SECS
  end

  def make_decision(game)
    if under_hitting_limit?
      delay_progress unless hand.size == 1
      hit(game)
    else
      stay
    end
  end

  def under_hitting_limit?
    total < HITTING_THRESHOLD
  end
end

class Player < Partaker
  include UI, UX

  MOVE_SEQUENCE = 1
  NAME          = "Player"

  def initial_draw(game)
    2.times { hit(game) }
  end

  private

  def ask_about_move
    get_char(message:     "Please choose: <h>it or <s>tay",
             invalid_msg: "Please choose \"h\" or \"s\"",
             expected:    %w[h s])
  end

  def make_decision(game)
    ask_about_move == "h" ? hit(game) : stay
  end
end

class GameHandler
  include UI, UX

  def initialize(*players)
    @players = players
  end

  def start
    loop do
      TwentyOneGame.new(new_deck, *players).play
      break unless rematch?
      reset
    end
  end

  private

  attr_reader :players

  def ask_about_rematch
    get_char(message:     "Would you like to play again? (y/n)",
             expected:    %w[y n],
             invalid_msg: "Please choose 'y' or 'n'")
  end

  def new_deck
    Deck.new
  end

  def rematch?
    ask_about_rematch == "y"
  end

  def reset
    players.each(&:reset)
  end
end

GameHandler.new(Player.new, Dealer.new).start
