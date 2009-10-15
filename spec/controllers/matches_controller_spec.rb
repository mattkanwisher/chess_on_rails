require File.dirname(__FILE__) + '/../spec_helper'

describe MatchesController do

  integrate_views

  before(:all) do
    @controller = MatchesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  it 'should successfully render a brand new match' do
    get :show, {:id => matches(:unstarted_match).id}, {:player_id => players(:dean).id }
    response.should be_success
  end

  it 'should allow POST creation of a match between two player_ids' do
    post :create, {:match => {:opponent_name => 'Paul'}, :opponent_side => 'black'}, {:player_id => players(:dean).id }

    match = assigns[:match]

    match.should_not be_nil
    response.should redirect_to( :controller => :match, :action => :show, :id => match.id )
    match.player2.should == Player.find(3)
  end

  it 'should show a match requested' do
    get :show, {:id => matches(:dean_vs_paul).id},  {:player_id => players(:dean).id }
    assigns[:match].should_not be_nil
  end

  it 'should render a form for a new match' do
    get :new, {},  {:player_id => players(:dean).id }
    response.should be_success
  end

  it 'should populate the start position for a new match if FEN given' do
    post :create, {:opponent_id => 3, :opponent_side => 'black', :start_pos => 'R7/8/8/8/8/8/8/8'},  {:player_id => players(:dean).id }
    assigns[:match].start_pos.should == 'R7/8/8/8/8/8/8/8'
  end

  it 'should create moves for a new match if PGN given' do
    post :create, {:opponent_id => 3, :opponent_side => 'black', :start_pos => '1. e4'},  {:player_id => players(:dean).id }
    assigns[:match].moves.count.should == 1
    assigns[:match].moves[0].notation.should == 'e4'
  end

  it 'should allow resignation via POST' do
    post :resign , {:id => matches(:dean_vs_paul).id},  {:player_id => players(:dean).id }
    assigns[:match].should_not be_active
  end
  
  it 'should show any current move queue in the page' do
    get :show, {:id => matches(:dean_vs_paul).id, :format => 'html'}, {:player_id => players(:dean).id }

    response.should have_tag("input#gameplay_move_queue", :value => 'Nc4 b5')
  end

  describe 'Routes' do
    it 'should have helpers' do
      @controller.instance_eval{ create_move_path(25) }.should == '/matches/25/moves'
      @controller.instance_eval{ match_path(24) }.should == '/matches/24'
    end

    it 'should route match/N to the show action' do
      params_from(:get, '/match/25').should == { 
        :controller    => 'matches', 
        :action        => 'show',
        :id            => '25'
      }
    end

    it 'should allow move creation via post at matches/25/moves' do
      puts @controller.instance_eval{ create_move_path(25) }
      params_from(:post, '/matches/25/moves').should == {
        :controller    => 'matches', 
        :action        => 'create_move',
        :match_id      => '25'
      }
    end
  end

  unless RUBY_PLATFORM =~ /w(in)?32/i
    it 'should allow curl-based fetching of a board' do
      # curl -u chicagogrooves@gmail.com:9 -H "Accept: text/plain" http://localhost:3000/match/526254980.txt
      # Cant't test w/o server running ... hmm...
    end
  end

  describe '- status updating' do
    before(:all) do 
    end

    # /match/5/status?move=8 - white queries if the 8th move has been made by black yet
    it 'should detect that the client does not need updating if it sends current value of move param' do
      @match = matches(:castled) #paul white, dean black, dean to move
      get :status, { :id => @match.id, :move => @match.moves.length + 1 }, { :player_id => players(:paul).id }
      assigns(:status_has_changed).should be_false
    end

    # /match/5/status?move=8, black queries if the status has changed for move 7
    it 'should detect that the client needs updating if it sends old value of move param' do
      @match = matches(:castled)
      get :status, { :id => @match.id, :move => (@match.moves.length) }, { :player_id => players(:dean).id }
      assigns(:status_has_changed).should be_true
    end

  end

end
