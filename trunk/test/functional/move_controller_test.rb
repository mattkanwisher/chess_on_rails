require File.dirname(__FILE__) + '/../test_helper'

class MoveControllerTest < ActionController::TestCase

	def setup
		super
		@request.env['HTTP_REFERER'] = '/match/3/show.html' #any address will keep back error from occurring
	end	
	
	#todo - this, like other gameplay methods should not raise exceptions out of the controller
	def test_reject_move_made_with_one_or_more_invalid_coordinates
		post :create, {:move=>{ :from_coord => 'e2', :to_coord => 'x9', :match_id => 3 } }, {:player_id => 1}
		assert_not_nil flash[:move_error]
	end
	
      def test_accepts_and_notates_move_via_coordinates
		m = matches(:paul_vs_dean)
		
		assert_equal 0, m.moves.length
	
		post :create, { :move=>{:from_coord => 'a2', :to_coord => 'a4', :match_id => m.id } }, {:player_id => m.player1.id}
		assert_response 302
		assert_nil flash[:move_error]

		assert_equal 1, m.reload.moves.length
		assert_not_nil m.moves.last.notation
	end
	
	def test_errs_if_specified_match_not_there_or_active
		post :create, { :move=>{:match_id => 9, :from_coord => 'e2', :to_coord => 'e4'} }, {:player_id => 1}
		assert_not_nil flash[:move_error]
	end

	def test_cant_move_when_on_match_you_dont_own
		m = matches(:paul_vs_dean)
		assert_equal 0, m.moves.length

		post :create, { :move=>{:match_id => m.id, :from_coord => 'e2', :to_coord => 'e4'} }, {:player_id => players(:maria).id }
		assert_not_nil flash[:move_error]
	end

	def test_reject_move_made_with_notation_and_one_or_more_coordinates
		post :create, {:move=>{ :from_coord => 'e2', :to_coord => 'e4', :notation => 'e4', :match_id => 3 } }, {:player_id => 1}
		assert_not_nil flash[:move_error]
	end

	def test_reject_move_made_without_notation_or_coordinates
		post :create, {:move=>{ :match_id => 3 } }, {:player_id => 1}
		assert_not_nil flash[:move_error]
	end

	def test_cant_move_when_not_your_turn
		m = matches(:paul_vs_dean)
		assert_equal 0, m.moves.length

		post :create, { :move=>{:match_id=>m.id, :from_coord=>'e2', :to_coord=>'e4'} }, {:player_id => players(:dean).id }
		assert_not_nil flash[:move_error]
	end

	def test_game_over_when_checkmating_move_posted
		m = matches(:scholars_mate)	
		post :create, { :move=>{:match_id => m.id, :notation => 'Qf7' } }, {:player_id => players(:chris).id }		
		m.reload
	
		#doesn't work yet but shows you can play the move
		assert_equal players(:chris), m.winning_player
		assert_not_equal 1, m.active
	end

	def test_non_ajax_move_posting_redirects_to_match_page
		m = matches(:paul_vs_dean)
		post :create, { :move=>{:match_id => m.id, :from_coord => 'e2', :to_coord => 'e4'} }, {:player_id => players(:paul).id }
		assert_response :redirect		
	end

	def test_ajax_move_responds_with_rjs_template_to_update_status
		m = matches(:paul_vs_dean)
		xhr :post, :create, { :move=>{:match_id => m.id, :from_coord => 'e2', :to_coord => 'e4'} }, {:player_id => players(:paul).id }
		assert_template 'match/status'
		assert_response :success
	end

	def test_invalid_ajax_move_responds_with_error
		m = matches(:paul_vs_dean)
		xhr :post, :create, { :move=>{:match_id => m.id, :from_coord => 'e4', :to_coord => 'e6'} }, {:player_id => players(:paul).id }
		assert_template 'match/status'
		assert_not_nil flash[:move_error]
	end

end
