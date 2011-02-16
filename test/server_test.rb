require 'test_helper'

class ServerTest < Test::Unit::TestCase

  def setup
    sources = Closure::Sources.new
    sources.add File.join(Closure.base_path, 'scripts', 'fixtures'), '/'
    @request = Rack::MockRequest.new(Closure::Server.new(sources))
  end

  def test_basics
    %w{/html /erb /haml}.each do |path|
      ['', '.html'].each do |ext|
        response = @request.get(path + ext)
        msg = "path: #{(path+ext).dump}"
        assert response.ok?, msg
        assert_equal 'text/html', response.content_type, msg
        # The string PASS is generated by Ruby from a partial
        # (except route_html which simply has is hardcoded)
        # This will test integration with Closure::Script
        assert response =~ /PASS/, msg
      end
    end
  end

  def test_static_of_template
    # It is critical we be able to get the raw files
    response = @request.get('/erb.erb')
    # It should be plain text (until Rack adds a Mime type)
    assert_equal 'text/plain', response.content_type
    # It should not have run as a template
    assert !(response =~ /PASS/)
  end
  
  def test_file_not_found
    assert @request.get("/nOT/Real.fILE").not_found?
  end
  
  def test_partials_not_found
    # We can always get the raw source
    assert @request.get("/_partial.haml").ok?
    # But partials refuse to be found for rendering
    assert @request.get("/partial").not_found?
    assert @request.get("/_partial").not_found?
    assert @request.get("/partial.html").not_found?
    assert @request.get("/_partial.html").not_found?
  end
  
  def test_static_html_extension_magic
    # The .html is always optional
    assert @request.get("/html").ok?
    assert @request.get("/html.html").ok?
    assert @request.get("/html.html.html").not_found?
  end
  
  def test_non_html_template_extension
    # The file proper comes back as text/plain
    response = @request.get("/route_js.js.erb")
    assert response.ok?
    assert_equal 'text/plain', response.content_type
    # The rendered version is application/javascript
    response = @request.get("/route_js.js")
    assert response.ok?
    assert_equal 'application/javascript', response.content_type
  end  

end
