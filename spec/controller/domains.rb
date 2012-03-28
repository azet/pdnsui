require_relative '../helper'

describe "The Domains controller" do
  behaves_like :rack_test

  before do
    @domain = Domain.new(:name => '0.example.com', :type => 'MASTER').save
    Domain.new(:name => 'zzzz.example.com', :type => 'MASTER').save
  end

  after do
    Domain.filter(:name => '0.example.com').destroy
    Domain.filter(:name => '1.example.com').destroy
    Domain.filter(:name => 'zzzz.example.com').destroy
  end

  should 'show domains list' do
    get('/domains/').status.should == 200
    last_response.should =~ /0.example.com/
  end

  should 'show domains list in ascending order' do
    # Fixtures
    ('0000'..'0050').each do |t|
      Domain.create(:name => "#{t}.spec-sdliao.com",
                    :type => 'MASTER',
                    :master => 'spec-sdliao')
    end
    # Test
    get('/domains/', :order => 'asc').status.should == 200
    last_response.should =~ /0000.spec-sdliao.com/
    # Cleanup
    Domain.filter(:master => 'spec-sdliao').destroy
  end

  should 'show domains list in descending order' do
    # Fixtures
    ('zzya'..'zzzz').each do |t|
      Domain.create(:name => "#{t}.spec-sdlido.com",
                    :type => 'MASTER',
                    :master => 'spec-sdlido')
    end
    # Test
    get('/domains/', :order => 'desc').status.should == 200
    last_response.should =~ /zzzz.spec-sdlido.com/
    # Cleanup
    Domain.filter(:master => 'spec-sdlido').destroy
  end

  should 'show records page' do
    get("/domains/records/#{@domain.id}").status.should == 200
    last_response['Content-Type'].should == 'text/html'
    last_response.should =~ /<h1>0.example.com<\/h1>/
  end

  should 'show records page in ascending order' do
    # Fixtures
    ('0000'..'0050').each do |t|
      @domain.add_record(:name => "#{t}.srpiao-spec.com",
                         :type => 'A', :content => 'srpiao-spec.com')
    end
    # Test
    get("/domains/records/#{@domain.id}", :order => 'asc').status.should == 200
    last_response['Content-Type'].should == 'text/html'
    last_response.should =~ /0000.srpiao-spec.com/
  end

  should 'show records page in descending order' do
    # Fixtures
    ('zzya'..'zzzz').each do |t|
      @domain.add_record(:name => "#{t}.srpido-spec.com",
                         :type => 'A', :content => 'srpido-spec')
    end
    # Test
    get("/domains/records/#{@domain.id}", :order => 'desc').status.should == 200
    last_response['Content-Type'].should == 'text/html'
    last_response.should =~ /zzzz.srpido-spec.com/
  end

  should 'not show a records for a non-existent domain' do
    get("/domains/records/99999").status.should == 302
    follow_redirect!
    last_response.status.should == 200
    last_response['Content-Type'].should == 'text/html'
    last_response.should =~ /Sorry, the domain id '99999' doesn't exist/
  end

  should 'not show a records for a nil domain' do
    get("/domains/records/").status.should == 302
    follow_redirect!
    last_response.status.should == 200
    last_response['Content-Type'].should == 'text/html'
    last_response.should =~ /Ooops, you didn't ask me which domain you wanted/
  end

  should 'add domain' do
    post('/domains/save',
         :name => '1.example.com',
         :type => 'SLAVE',
         :master => '1.2.3.4').status.should == 302
    last_response['Content-Type'].should == 'text/html'
    follow_redirect! 
    last_response.status.should == 200
    last_response['Content-Type'].should == 'text/html'
    last_response.should =~ /Entry 1.example.com created successfully/
  end

  should 'update domain' do
    id = Domain.filter(:name => '0.example.com').first[:id]

    # THINK: Well, this should probably be made illegal
    # or handled properly, e.g. rename all records for this domain
    post('/domains/save',
         :domain_id   => id,
         :name =>'1.example.com',
         :type => 'MASTER',
         :master => '4.3.2.1').status.should == 302
    follow_redirect!
    last_response.status.should == 200
    last_response.should =~ /Entry 1.example.com updated successfully/
   end

  should 'not update a non-existent domain' do
    post('/domains/save',
         :domain_id   => 999999,
         :name =>'1.example.com',
         :type => 'MASTER',
         :master => '4.3.2.1').status.should == 302
    follow_redirect!
    last_response.status.should == 200
    last_response.should =~ /Can not update this domain/
  end

  should 'not create or update a nil domain' do
    post('/domains/save').status.should == 302
    follow_redirect!
    last_response.status.should == 200
    last_response.should =~ /Invalid data : name is not present, type is not present, type is not a valid domain type/
  end

  should 'delete domain' do
    id = Domain.filter(:name => '0.example.com').first[:id]

    get("/domains/delete/#{id}").status.should == 302
    follow_redirect!
    last_response.status.should == 200
    last_response['Content-Type'].should == 'text/html'
    last_response.should =~ /Entry 0.example.com deleted successfully/
  end

  should 'not delete a non-existent domain' do
    get("/domains/delete/99999").status.should == 302
    follow_redirect!
    last_response.status.should == 200
    last_response['Content-Type'].should == 'text/html'
    last_response.should =~ /Sorry, the domain id '99999' doesn't exist/
  end

  should 'not delete a nil domain' do
    get("/domains/delete/").status.should == 302
    follow_redirect!
    last_response.status.should == 200
    last_response['Content-Type'].should == 'text/html'
    last_response.should =~ /Ooops, you didn't ask me which domain you wanted/
  end

  should 'not add the same domain twice' do
    post('/domains/save',
         :name => '0.example.com',
         :type => 'SLAVE',
         :master => '1.2.3.4').status.should == 302
    follow_redirect!
    last_response.status.should == 200
    last_response['Content-Type'].should == 'text/html'
    last_response.should =~ /Invalid data : name is already taken/
  end

  # 'View' oriented specs
  
  # TODO: Lame test alert. Use hpricot. See pagination helper in Ramaze for help 
  should 'highligh domain properly in sidebar' do
    get("/domains/records/#{@domain.id}").status.should == 200
    last_response['Content-Type'].should == 'text/html'
    last_response.should =~ /<li class="active">/
  end

end
