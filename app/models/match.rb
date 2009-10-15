class Match < ActiveRecord::Base
  
  # Chats are messages said by one party or the other during the match.
  has_many :chats 

  # A gameplay record is a (eventually versioned) players' personal stash of data about the match
  # This includes their move_queue, their offers to draw, etc..
  has_many :players, :through    => :gameplays

  # The moves of this match. Before we add one, we ensure that it has a direct 
  # reference to this match instance, so it can use our history to validate.
  # After adding we store the new board instance, check for checkmate, and store any move queue
  has_many :moves,   :before_add => Proc.new{ |m, mv| mv.match = m },
                     :after_add  => [:save_board, :check_for_checkmate, :play_queued_moves]

  belongs_to :winning_player, :class_name => 'Player', :foreign_key => 'winning_player'

  named_scope :active,    :conditions => { :active => true }
  named_scope :completed, :conditions => { :active => false }

  # Defines the relations between the players involved, and this match, 
  # which are white and black, respectively.
  has_many :gameplays do
    def white; self[0]; end
    def black; self[1]; end
  end

  # The series of boards this match has been played through, a hash keyed on the move number.
  def boards
    return @boards if @boards

    @boards = { 0 => Board.new( self[:start_pos] ) }
    moves.each_with_index do |mv, idx|
      with( @boards[idx + 1] = Board.new ) do |b|
        0.upto(idx){ |i| b.play_move! moves[i] if moves[i].errors.empty? }
      end
    end
    @boards

  end

  # The current board of this match.
  def board
    boards[ boards.keys.max ]
  end

  def initialize( opts={} )
    white = opts.delete(:white) if opts[:white]
    black = opts.delete(:black) if opts[:black]
    super
    save!
    gameplays << Gameplay.new(:player_id => white.id) if white
    gameplays << Gameplay.new(:player_id => black.id, :black => true) if black
  end

  def player1
    @player1 ||= gameplays.white.player
  end

  def player2
    @player2 ||= gameplays.black.player
  end
  alias :white :player1;  alias :black :player2

  # The friendly name of this match, Player1 vs. Player2 by default.
  def name
    self[:name] || "#{player1.name} vs. #{player2.name}"
  end

  # Cache this board and make it the most recent one
  def save_board( last_move )
    return false unless last_move.errors.empty?
    self.boards.store( @boards.keys.max + 1, self.board.dup.play_move!( last_move ) )
  end

  def check_for_checkmate(last_move)
    return 
    me, other_guy =  last_move.side == :black ? [:black, :white] : [:white, :black]
    #checkmate_by( me ) if board.in_checkmate?( other_guy )
  end
    
  # for purposes of move validation it's handy to have access to such a variable
  def current_player
    next_to_move == :black ? gameplays.black.player : gameplays.white.player
  end
  
  def turn_of?( plyr )	
    #return true #HACK
    self.next_to_move == side_of(plyr)
  end

  # as long as the game starts at the beginning, white goes first
  def first_to_move
    return :white if self[:start_pos].blank?
    @first_to_move ||= Board.new( self[:start_pos] ).next_to_move
  end

  # the next_to_move alternates sides each move (technically every half-move)
  def next_to_move
    moves.count.even? ? first_to_move : opp(first_to_move)
  end

  def side_of( plyr ) 
    return :white if plyr == player1
    return :black if plyr == player2
  end

  def resign( plyr )
    self.result, self.active = ['Resigned', 0]
    self.winning_player = (plyr == player1) ? player2 : player1
    save!
  end

  def checkmate_by( side )
    self.reload
    self.result, self.active = ['Checkmate', 0]
    self.winning_player = (side == :white ? player1 : player2 )
    save!
  end

  # returns the opposite of a side, or nil
  def opp( s )
    case s
      when :white; :black
      when :black; :white
    end
  end

  # if moves are queued up, looks for matches and plays appropriate responses, or invalidates queue
  # for now requires exact match on the notation
  def play_queued_moves( m )
    opponent = m.match.gameplays.send( m.match.next_to_move )
    return unless opponent && opponent.move_queue.length > 1

    queue = MoveQueue.new(queue) unless MoveQueue === queue

    unless queue.hit?(actual = m)
      opponent.update_attribute(:move_queue, nil) and return 
    end

    # and make the response move - because we go direct, we can't rely on
    # automatic calling of the callback to continue evaluating queues - bumr !
    expected, response = queue.shift, queue.shift
    response_move = Move.create(:match_id => self.id, :notation => response)

    opponent.update_attribute(:move_queue, queue.to_s)

    # call it back from other side (continues until queue.hit? returns false)
    play_queued_moves(response_move)
    
  end

end
