require 'hexapdf'
require 'open-uri'
require 'json'

class PdfFile

  attr_reader :file_name

  def initialize(file_name)
    @file_name = file_name
  end

  def page_count
    document.pages.length
  end

  def read_page(page_number)
    if page_number < document.pages.length
      new_doc = HexaPDF::Document.new
      new_doc.pages << new_doc.import(document.pages[page_number])
      new_doc.write('temp.pdf', optimize: true)
      file = File.new('temp.pdf', 'r')
      file.read
    else
      return false
    end
  end

  private

  def file
    @file ||= URI.open("#{ENV.fetch('ORIGIN_URL')}/#{file_name}")
  end

  def document
    @document ||= HexaPDF::Document.open(file)
  end

end


class PdfSplitApp

  REGEX = /\A\/([^\/]+)\/((?:\d+|info))\z/

  def call(env)

    req = Rack::Request.new(env)

    path_match = req.path_info.match(REGEX)

    if path_match

      file_name = path_match[1]
      page = path_match[2]

      file = PdfFile.new(file_name)

      if page == 'info'

        [
          200,
          {"Content-Type" => "application/json"}, [{page_count: file.page_count}.to_json]
        ]

      else

        page_id = path_match[2].to_i

        page_file = file.read_page(page_id)

        if page_file
          [
            200,
            {"Content-Type" => "application/pdf"}, [page_file]
          ]
        else

        [
          404,
          {"Content-Type" => "text/plain"}, ["Page out of range"]
        ]

        end
      end

    else

      [
        404,
        {"Content-Type" => "text/plain"}, ["Not found"]
      ]

    end

  end

end
