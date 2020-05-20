# Application dependencies
require "action-controller"

# Application code
require "./placeos-mqtt"
require "./controllers/*"

# Server required after application controllers
require "action-controller/server"

PROD = ENV["ENV"]? == "PROD"

# Add handlers that should run before your application
ActionController::Server.before(
  ActionController::ErrorHandler.new(PROD, ["X-Request-ID"]),
  ActionController::LogHandler.new
)

# Allow signals to change the log level at run-time
logging = Proc(Signal, Nil).new do |signal|
  level = signal.usr1? ? Log::Severity::Debug : Log::Severity::Info
  puts " > Log level changed to #{level}"
  Log.builder.bind "mqtt.*", level, PlaceOS::MQTT::LOG_BACKEND
  signal.ignore
end

# Turn on DEBUG level logging `kill -s USR1 %PID`
# Default production log levels (INFO and above) `kill -s USR2 %PID`
Signal::USR1.trap &logging
Signal::USR2.trap &logging

# Logging configuration
log_level = PROD ? Log::Severity::Info : Log::Severity::Debug
Log.builder.bind "*", log_level, PlaceOS::MQTT::LOG_BACKEND