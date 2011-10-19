require "./pastebin"

use Rack::ShowExceptions

run Pastebin.new
