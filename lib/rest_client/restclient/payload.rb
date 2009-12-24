require "tempfile"
require "stringio"

module RestClient
	module Payload
		extend self

		def generate(params)
			if params.is_a?(String)
				Base.new(params)
			elsif params
				if params.delete(:multipart) == true || has_file?(params)
					Multipart.new(params)
				else
					UrlEncoded.new(params)
				end
			else
				nil
			end
		end

		def has_file?(params)
			params.any? do |_, v|
				case v
				when Hash
					has_file?(v)
				else
					v.respond_to?(:path) && v.respond_to?(:read)
				end
			end
		end

		class Base
			def initialize(params)
				build_stream(params)
			end

			def build_stream(params)
				@stream = StringIO.new(params)
				@stream.seek(0)
			end

			def read(bytes=nil)
				@stream.read(bytes)
			end
			alias :to_s :read

			def escape(v)
				URI.escape(v.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
			end

			def headers
				{ 'Content-Length' => size.to_s }
			end

			def size
				@stream.size
			end
			alias :length :size

			def close
				@stream.close
			end

			def inspect
				to_s.inspect
				@stream.seek(0)
			end
		end

		class UrlEncoded < Base
		  
      #       def build_stream(params)
      #   @stream = StringIO.new(params.map do |k,v| 
      #     "#{escape(k)}=#{escape(v)}"
      #   end.join("&"))
      # end
			
		  def build_stream( params = nil )
		    @stream = StringIO.new process( params )
      	@stream.seek(0)
      end
      
      def process( params, parent_key = nil )
	      unless params.is_a? Hash
	        params
        else
	        params.keys.map do |k|
    		    key = parent_key ? "#{parent_key}[#{ k }]" : k
      			if params[ k ].is_a? Hash
      			  process( params[ k ], key )
      			else
              value = URI.escape( params[ k ].to_s, Regexp.new( "[^#{URI::PATTERN::UNRESERVED}]" ) )
      				"#{key}=#{value}"
      			end
      		end.join( "&" )
    		end
    	end
		  
			def headers
				super.merge({ 'Content-Type' => 'application/x-www-form-urlencoded' })
			end

		end

		class Multipart < Base
			EOL = "\r\n"

			def build_stream(params)
				b = "--#{boundary}"

				@stream = Tempfile.new("RESTClient.Stream.#{rand(1000)}")
				@stream.write(b + EOL)
				x = params.to_a
				last_index = x.length - 1
				x.each_with_index do |a, index|
					k, v = *a
					if v.respond_to?(:read) && v.respond_to?(:path)
						create_file_field(@stream, k,v)
					else
						create_regular_field(@stream, k,v)
					end
					@stream.write(EOL + b)
					@stream.write(EOL) unless last_index == index
				end
				@stream.write('--')
				@stream.write(EOL)
				@stream.seek(0)
			end

			def create_regular_field(s, k, v)
				s.write("Content-Disposition: multipart/form-data; name=\"#{k}\"")
				s.write(EOL)
				s.write(EOL)
				s.write(v)
			end

			def create_file_field(s, k, v)
				begin
					s.write("Content-Disposition: multipart/form-data; name=\"#{k}\"; filename=\"#{v.respond_to?(:original_filename) ? v.original_filename : File.basename(v.path)}\"#{EOL}")
					s.write("Content-Type: #{v.respond_to?(:content_type) ? v.content_type : mime_for(v.path)}#{EOL}")
					s.write(EOL)
					while data = v.read(8124)
						s.write(data)
					end
				ensure
					v.close
				end
			end

			def mime_for(path)
				ext = File.extname(path)[1..-1]
				MIME_TYPES[ext] || 'text/plain'
			end

			def boundary
				@boundary ||= rand(1_000_000).to_s
			end

			def headers
				super.merge({'Content-Type' => %Q{multipart/form-data; boundary="#{boundary}"}})
			end

			def close
				@stream.close
			end
		end

		# :stopdoc:
		# From WEBrick.
		MIME_TYPES = {
			"ai"    => "application/postscript",
			"asc"   => "text/plain",
			"avi"   => "video/x-msvideo",
			"bin"   => "application/octet-stream",
			"bmp"   => "image/bmp",
			"class" => "application/octet-stream",
			"cer"   => "application/pkix-cert",
			"crl"   => "application/pkix-crl",
			"crt"   => "application/x-x509-ca-cert",
			"css"   => "text/css",
			"dms"   => "application/octet-stream",
			"doc"   => "application/msword",
			"dvi"   => "application/x-dvi",
			"eps"   => "application/postscript",
			"etx"   => "text/x-setext",
			"exe"   => "application/octet-stream",
			"gif"   => "image/gif",
			"gz"   => "application/x-gzip",
			"htm"   => "text/html",
			"html"  => "text/html",
			"jpe"   => "image/jpeg",
			"jpeg"  => "image/jpeg",
			"jpg"   => "image/jpeg",
			"js"    => "text/javascript",
			"lha"   => "application/octet-stream",
			"lzh"   => "application/octet-stream",
			"mov"   => "video/quicktime",
			"mpe"   => "video/mpeg",
			"mpeg"  => "video/mpeg",
			"mpg"   => "video/mpeg",
			"pbm"   => "image/x-portable-bitmap",
			"pdf"   => "application/pdf",
			"pgm"   => "image/x-portable-graymap",
			"png"   => "image/png",
			"pnm"   => "image/x-portable-anymap",
			"ppm"   => "image/x-portable-pixmap",
			"ppt"   => "application/vnd.ms-powerpoint",
			"ps"    => "application/postscript",
			"qt"    => "video/quicktime",
			"ras"   => "image/x-cmu-raster",
			"rb"    => "text/plain",
			"rd"    => "text/plain",
			"rtf"   => "application/rtf",
			"sgm"   => "text/sgml",
			"sgml"  => "text/sgml",
			"tif"   => "image/tiff",
			"tiff"  => "image/tiff",
			"txt"   => "text/plain",
			"xbm"   => "image/x-xbitmap",
			"xls"   => "application/vnd.ms-excel",
			"xml"   => "text/xml",
			"xpm"   => "image/x-xpixmap",
			"xwd"   => "image/x-xwindowdump",
			"zip"   => "application/zip",
		}
		# :startdoc:
	end
end
