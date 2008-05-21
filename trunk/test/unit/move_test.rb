require File.dirname(__FILE__) + '/../test_helper'

class MoveTest < ActiveSupport::TestCase
	# Replace this with your real tests.
	def test_truth
		assert true
	end
		
	def test_unstarted_match_has_no_moves
		m1 = matches(:unstarted_match)
		assert_equal 0, m1.moves.count
	end
	
	def test_moves_are_returned_in_order_created
		m1 = matches(:dean_vs_maria)
		#assert_equal 2, m1.moves.count
		assert_equal players(:dean), m1.moves[0].player
		assert_equal players(:maria), m1.moves[1].player
	end
			
	def test_nodoc_can_play_first_two_moves_correctly
		m1 = matches(:unstarted_match)	  
		

		m1.moves << Move.new( :from_coord => "e2", :to_coord => "e4", :notation => "e4", :moved_by => 1 )
		m1.moves << Move.new( :from_coord => "d7", :to_coord => "d5", :notation => "d5", :moved_by => 2 )
		
		assert m1.valid?
		assert m1.save!
	end
	
	def test_notates_simple_move
		match = matches(:unstarted_match)
		move = Move.new( :match_id => match.id, :from_coord => "b1", :to_coord => "c3", :moved_by => 1 ) #knight opening
		assert_equal "Nc3", move.notate
		match.moves << move
	end
	
	def test_notates_pawn_moves_correctly
		match = matches(:unstarted_match)
		move1 = Move.new( :match_id => match.id, :from_coord => "d2", :to_coord => "d4", :moved_by => 1 ) #queens pawn
		assert_equal "d4", move1.notate
		match.moves << move1
	
		move2 = Move.new( :match_id => match.id, :from_coord => "e7", :to_coord => "e5", :moved_by => 2 ) 
		assert_equal "e5", move2.notate
		match.moves << move2

		move3 = Move.new( :match_id => match.id, :from_coord => "d4", :to_coord => "e5", :moved_by => 1 ) 
		assert_equal "dxe5", move3.notate
		match.moves << move3
	end

	def test_notates_white_kingside_castle_correctly
		match = matches(:dean_vs_maria)
		wc = Move.new( :match_id => match.id, :from_coord => "e1", :to_coord => "g1", :moved_by => 1 ) 
		assert_equal "O-O", wc.notate
	end

	def test_notates_check
		match = matches(:dean_vs_paul)
		ck = Move.new( :match_id => match.id, :from_coord => "f8", :to_coord => "b4", :moved_by => 2 ) 
		assert_equal "Bb4+", ck.notate
	end
	
end
