require "spec_helper"

require "spyke/fixtures/pirates"

RSpec.describe FmData::Spyke::Model::Attributes do
  let :test_class do
    Class.new(Spyke::Base) do
      include FmData::Spyke

      # Needed by ActiveModel::Name
      def self.name; "TestClass"; end

      attributes foo: "Bar"
    end
  end

  describe ".attribute_method_matchers" do
    it "doesn't include a plain entry" do
      expect(test_class.attribute_method_matchers.first.method_missing_target).to_not eq("attribute")
    end
  end

  describe ".attributes" do
    it "allows setting mapped attributes" do
      expect(test_class.new(foo: "Boo").attributes).to eq("Bar" => "Boo")
    end
  end

  describe ".mapped_attributes" do
    it "returns a hash of the class' mapped attributes" do
      expect(test_class.mapped_attributes).to eq("foo" => "Bar")
    end
  end

  describe "#mod_id" do
    it "returns the current mod_id" do
      expect(test_class.new.mod_id).to eq(nil)
    end
  end

  describe "#mod_id=" do
    it "sets the current mod_id" do
      instance = test_class.new
      instance.mod_id = 1
      expect(instance.mod_id).to eq(1)
    end
  end

  describe "attribute setters" do
    it "marks attribute as changed" do
      instance = test_class.new
      expect(instance.foo_changed?).to eq(false)

      instance.foo = "Boo"
      expect(instance.foo_changed?).to eq(true)
    end
  end

  describe "#save" do
    before do
      stub_session_login
      stub_request(:post, fm_url(layout: "Ships") + "/records").to_return_fm({})
    end

    it "resets changes information for self and portal records" do
      ship = Ship.new name: "Mary Celeste"
      expect { ship.save }.to change { ship.changed? }.from(true).to(false)
    end
  end

  describe "#reload" do
    before do
      stub_session_login
      stub_request(:get, fm_url(layout: "Ships", id: 1)).to_return_fm(
        data: [
          {
            fieldData: { name: "Obra Djinn" },
            recordId: 1,
            modId: 0
          }
        ]
      )
    end

    it "resets changes information" do
      ship = Ship.new id: 1, name: "Obra Djinn"
      expect { ship.reload }.to change { ship.changed? }.from(true).to(false)
    end
  end

  describe "#to_params" do
    xit "only includes changed fields"
    xit "includes portal data"
  end

  describe "#attributes=" do
    it "sanitizes parameters" do
      instance = test_class.new
      params = double("ProtectedParams", permitted?: false, empty?: false)
      expect { instance.attributes = params }.to raise_error(ActiveModel::ForbiddenAttributesError)
    end
  end
end