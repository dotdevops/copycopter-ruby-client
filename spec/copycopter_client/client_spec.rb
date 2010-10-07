require 'spec_helper'

describe CopycopterClient do
  def build_client(config = {})
    default_config = CopycopterClient::Configuration.new.to_hash
    CopycopterClient::Client.new(default_config.update(config))
  end

  def add_project
    api_key = 'xyz123'
    FakeCopycopterApp.add_project(api_key)
  end

  describe "opening a connection" do
    let(:config) { CopycopterClient::Configuration.new }
    let(:http) { Net::HTTP.new(config.host, config.port) }

    before do
      Net::HTTP.stubs(:new => http)
    end

    it "should timeout when connecting" do
      project = add_project
      client = build_client(:api_key => project.api_key, :http_open_timeout => 4)
      client.download
      http.open_timeout.should == 4
    end

    it "should timeout when reading" do
      project = add_project
      client = build_client(:api_key => project.api_key, :http_read_timeout => 4)
      client.download
      http.read_timeout.should == 4
    end

    it "uses ssl when secure" do
      project = add_project
      client = build_client(:api_key => project.api_key, :secure => true)
      client.download
      http.use_ssl.should == true
    end

    it "doesn't use ssl when insecure" do
      project = add_project
      client = build_client(:api_key => project.api_key, :secure => false)
      client.download
      http.use_ssl.should == false
    end
  end

  it "downloads published blurbs for an existing project" do
    project = add_project
    project.update({
      'draft' => {
        'key.one'   => "unexpected one",
        'key.three' => "unexpected three"
      },
      'published' => {
        'key.one' => "expected one",
        'key.two' => "expected two"
      }
    })

    blurbs = build_client(:api_key => project.api_key, :public => true).download

    blurbs.should == {
      'key.one' => 'expected one',
      'key.two' => 'expected two'
    }
  end

  it "downloads draft blurbs for an existing project" do
    project = add_project
    project.update({
      'draft' => {
        'key.one' => "expected one",
        'key.two' => "expected two"
      },
      'published' => {
        'key.one'   => "unexpected one",
        'key.three' => "unexpected three"
      }
    })

    blurbs = build_client(:api_key => project.api_key, :public => false).download

    blurbs.should == {
      'key.one' => 'expected one',
      'key.two' => 'expected two'
    }
  end

  it "uploads defaults for missing blurbs in an existing project" do
    project = add_project

    blurbs = {
      'key.one' => 'expected one',
      'key.two' => 'expected two'
    }

    client = build_client(:api_key => project.api_key, :public => true)
    client.upload(blurbs)

    project.reload.draft.should == blurbs
  end
end

