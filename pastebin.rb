# -*- coding: utf-8 -*-

require 'rubygems'
require 'rack'
require 'haml'
require 'gdbm'
require 'base64'

class Pastebin
	def initialize
		@html5_layout_doc = <<EOF
!!! 5
%html
	%head= header
	%body= body
EOF

		@paste_template_doc = <<EOF
%form{:action => "/paste", :method => "post"}
	%textarea{:name => "code", :style => "width: 800px; height: 600px;"}
	%br
	%input{:type => "submit", :value => "給我url"}
EOF

		@page404 = '%h1= "404 Not a valid document: #{path}"'
	end

	def html(haml, model={})
		body = Haml::Engine.new(haml).render(Object.new, model)
		Haml::Engine.new(@html5_layout_doc).render(Object.new, {:header => "", :body => body})
	end

	def call(env)
		req = Rack::Request.new env
		if req.path == "/"
			return index
		elsif req.path == "/paste"
			return paster req
		else
			return get_doc req.path
		end
	end

	def index
		[200, {"Content-Type" => "text/html"}, [html(@paste_template_doc)]]
	end

	def paster(req)
		code = req.POST["code"]

		last_key = nil
		GDBM.open("pastebin.db") do |db|
			last_key = db.fetch("last_key", "0").to_i + 1

			db[last_key.to_s] = Base64.encode64 code

			db["last_key"] = last_key.to_s
		end

		[302, {"Location" => "/#{last_key}", "Content-Type" => ""}, []]
	end

	def get_doc(path)
		key = path[1..-1]
		GDBM.open("pastebin.db") do |db|
			if db.has_key? key
				[200, {"Content-Type" => "text/plain"}, [Base64.decode64(db[key])]]
			else
				[404, {"Content-Type" => "text/html"}, [html(@page404, {:path => path})]]
			end
		end
	end
end
