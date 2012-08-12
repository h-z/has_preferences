require 'helper'
require 'active_record'

ActiveRecord::Migration.verbose = false
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :preferences do |t|
      t.column :holder_type, :string
      t.column :holder_id, :integer
      t.column :key, :string
      t.column :value, :string
      t.column :created_at, :datetime      
      t.column :updated_at, :datetime
    end
    create_table :cats do |t|
      t.column :title, :string
      t.column :created_at, :datetime      
      t.column :updated_at, :datetime
    end
    create_table :dogs do |t|
      t.column :title, :string
      t.column :created_at, :datetime      
      t.column :updated_at, :datetime
    end 
    create_table :bones do |t|
      t.column :title, :string
      t.column :dog_id, :integer
      t.column :created_at, :datetime      
      t.column :updated_at, :datetime
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class Cat < ActiveRecord::Base
  has_preferences
end

class Dog < ActiveRecord::Base
  has_preferences
  has_many :bones
end

class Bone < ActiveRecord::Base
  has_preferences :parent => :dog
  belongs_to :dog
end

class TestHasPreferencesWithOneModel < Test::Unit::TestCase
  context "single model" do
    setup do
      setup_db
      @object = Cat.find_or_create_by_title("Garfield")
    end

    teardown do
      teardown_db
    end

    should "respond if added" do
      assert_equal true, @object.respond_to?(:pref)
    end

    should "be able to set pref with 2 params" do
      assert_equal :value.to_s, @object.pref(:key, :value)
    end

    should "be able to get setted param" do
      @object.pref(:fav_meal, :lasagne)
      assert_equal :lasagne.to_s, @object.pref(:fav_meal)
    end

    should "be able to get setted param in new instance" do
      @object.pref(:random_key, :random_value)
      @o2 = Cat.find_by_title("Garfield")
      assert_equal :random_value.to_s, @o2.pref(:random_key)
    end

    should "return nil for unsetted preference" do
      assert_equal true, @object.pref(:unsetted_key).nil?
    end

    should "have one preference after pref()" do
      @object.pref(:my_own_key, :secret_value)
      assert_equal 1, @object.preferences.size
      assert_equal :secret_value.to_s, @object.preferences.first.value
    end
  end
end

class TestHasPreferencesWithTwoModels < Test::Unit::TestCase
  context "child" do
    setup do
      setup_db
      @dog = Dog.find_or_create_by_title("Scooby")
      @bone = Bone.find_or_create_by_title("bigbone")
      @dog.bones << @bone
    end

    teardown do
      teardown_db
    end 

    should "be able to set pref with 2 params" do
      assert_equal :value.to_s, @dog.pref(:key, :value)
    end

    should "be able to get setted param" do
      @dog.pref(:fav_meal, :meat)
      assert_equal :meat.to_s, @dog.pref(:fav_meal)
    end

    should "have own pref, not parent prefs" do
      @dog.pref(:key, :dog_value)
      @bone.pref(:key, :bone_value)
      assert_equal :bone_value.to_s, @bone.pref(:key)
    end

    should "get parent prefs if there is no own" do
      @dog.pref(:key, :my_very_own_value)
      assert_equal :my_very_own_value.to_s, @bone.pref(:key)
    end

    should "get nil if there is no pref for child and parent" do
      @dog.pref(:key, :my_very_own_value)
      assert_equal nil, @bone.pref(:key2)
    end
  end
end
