require "../spec_helper"

module PlaceOS::Source
  describe MqttPublisher do
    describe "keys" do
      it "creates a state event topic" do
        state = mock_state(
          module_id: "mod-1234",
          index: 1,
          module_name: "M'Odule",
          driver_id: "12345",
          control_system_id: "cs-9445",
          area_id: "2042",
          level_id: "nek",
          building_id: "cards",
          org_id: "org-donor",
        )

        status_event = Mappings.new(state).status_events?("mod-1234", "power").not_nil!.first
        key = MqttPublisher.generate_key(status_event)
        key.should_not be_nil
        key.not_nil!.should eq "placeos/org-donor/state/cards/nek/2042/cs-9445/12345/M'Odule/1/power"
      end

      it "doesn't create topics for Modules without a top-level scope Zone" do
        state = mock_state(module_id: "mod-1234", control_system_id: "cs-id")

        # Remove the top level scope mapping
        state.system_zones["cs-id"].delete(Mappings.scope)

        status_event = Mappings.new(state).status_events?("mod-1234", "power").not_nil!.first

        MqttPublisher.generate_key(status_event).should be_nil
      end

      it "replaces missing hierarchy Zone ids with a placeholder" do
        state = mock_state(
          module_id: "mod-1234",
          index: 1,
          module_name: "M'Odule",
          driver_id: "12345",
          control_system_id: "cs-9445",
          area_id: "2042",
          level_id: "nek",
          org_id: "org-donor",
        )

        state.system_zones["cs-9445"].delete("building")

        status_event = Mappings.new(state).status_events?("mod-1234", "power").not_nil!.first

        key = MqttPublisher.generate_key(status_event)
        key.should_not be_nil
        key.not_nil!.should eq "placeos/org-donor/state/_/nek/2042/cs-9445/12345/M'Odule/1/power"
      end

      it "generates a metadata key" do
        metadata_event = Mappings::Metadata.new("mod-1234", "hello")
        key = MqttPublisher.generate_key(metadata_event).not_nil!
        key.should eq "placeos/hello/metadata/mod-1234"
      end
    end

    describe "payloads" do
      it "non-empty" do
        JSON.parse(MqttPublisher.payload(%("hello"), nil))["value"].raw.should eq "hello"
      end

      it "empty payload metadata" do
        JSON.parse(MqttPublisher.payload(nil, nil))["value"].raw.should be_nil
      end
    end
  end
end
