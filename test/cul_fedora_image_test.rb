require 'test_helper'
class CulFedoraImageTest < Test::Unit::TestCase
  include Cul::Fedora::Image
  TEST = 'test'
  CASE1 = "#{TEST}/fixtures/case1"
  CASE2 = "#{TEST}/fixtures/case2"
  CASE3 = "#{TEST}/fixtures/case3"
  def initialize(test_method_name)
    super(test_method_name)
  end
  context "image library given a bitmap" do
    setup do
      @src = "#{CASE3}/test001.bmp"
      @expected = {}
      @expected[:width] = 373
      @expected[:length] = 156
      @expected[:size] = 174858
      @expected[:mime] = 'image/bmp'
      @expected[:sampling_unit] = :cm
      @expected[:x_sampling] = 29
      @expected[:y_sampling] = 29
      @expected
    # @expected[:bitdepth] = 24
    end
    should "correctly identify properties" do
      actual = analyze_image(@src)
      actual
      assert_equal @expected, actual
    end
    teardown do
      
    end
  end
context "image library given a PNG" do
  setup do
    @src = "#{CASE3}/test001.png"
    @expected = {}
    @expected[:width] = 512
    @expected[:length] = 512
    @expected[:size] = 675412
    @expected
  # @expected[:bitdepth] = 32
  end
  should "correctly identify properties" do
    actual = analyze_image(@src,true)
    actual
    assert_equal @expected, actual
  end
  teardown do
    
  end
end
context "image library given a JPEG" do
  setup do
    @src = "#{CASE3}/test001.jpg"
    @expected = {}
    @expected[:width] = 313
    @expected[:length] = 234
    @expected[:x_sampling] = 72
    @expected[:y_sampling] = 72
    @expected[:size] = 15138
    @expected[:mime] = 'image/jpeg'
    @expected
  end
  should "correctly identify properties" do
    actual = analyze_image(@src,false)
    actual
    assert_equal @expected, actual
  end
  teardown do
    
  end
end
context "image library given a GIF" do
  setup do
    @src = "#{CASE3}/test001.gif"
    @expected = {}
    @expected[:width] = 492
    @expected[:length] = 1392
    @expected[:size] = 474706
    @expected[:mime] = 'image/gif'
    @expected
  end
  should "correctly identify properties" do
    actual = analyze_image(@src)
    actual
    assert_equal @expected, actual
  end
  teardown do
    
  end
end
context "image library given a TIFF" do
  setup do
    @src = "#{CASE3}/test001.tiff"
    @expected = {}
    @expected[:width] = 2085
    @expected[:length] = 1470
    @expected[:size] = 5658702
    @expected[:x_sampling] = 600
    @expected[:y_sampling] = 600
    @expected[:mime] = 'image/tiff'
    @expected[:sampling_unit] = :inch
    @expected
    # @expected['compression'] = LSW
    # @expected[:bitdepth] = 24
  end
  should "correctly identify properties" do
    actual = analyze_image(@src)
    actual
    assert_equal @expected, actual
  end
  teardown do
    
  end
end
end