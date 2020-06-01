require "./mappings"
require "./publishing/publisher_manager"
require "./router/*"

module PlaceOS::MQTT
  class Manager
    Log = ::Log.for("mqtt.manager")

    getter control_system_router : Router::ControlSystem
    getter driver_router : Router::Driver
    getter module_router : Router::Module
    getter zone_router : Router::Zone

    getter status_events : StatusEvents

    getter publisher_manager : PublisherManager

    getter? started = false

    @@instance : Manager?

    def self.instance : Manager
      (@@instance ||= Manager.new).as(Manager)
    end

    def initialize(
      @publisher_manager : PublisherManager = PublisherManager.new,
      @mappings : Mappings = Mappings.new
    )
      @control_system_router = Router::ControlSystem.new(mappings, publisher_manager)
      @driver_router = Router::Driver.new(mappings, publisher_manager)
      @module_router = Router::Module.new(mappings)
      @zone_router = Router::Zone.new(mappings, publisher_manager)
      @status_events = StatusEvents.new(mappings, publisher_manager)
    end

    def start
      return if started?
      @started = true

      Log.info { "registering Brokers" }
      publisher_manager.start

      # Acquire the Zones (hierarchy) first
      Log.info { "starting Zone router" }
      zone_router.start

      # Map ControlSystems beneath Zones
      Log.info { "starting ControlSystem router" }
      control_system_router.start

      # Map to driver_ids and module_names
      Log.info { "starting Module router" }
      module_router.start

      # Publish any relevant driver metadata
      Log.info { "starting Driver router" }
      driver_router.start

      Log.info { "listening for Module state events" }
      spawn(same_thread: true) { status_events.start }

      Fiber.yield
    end

    def stop
      return unless started?

      @started = false
      status_events.stop
      publisher_manager.stop
      control_system_router.stop
      driver_router.stop
      module_router.stop
      zone_router.stop
    end
  end
end
