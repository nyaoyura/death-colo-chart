require 'sinatra'
require 'sinatra/reloader'
require 'haml'
require 'coffee-script'
require 'json'
require 'open-uri'
require 'nokogiri'
require 'ostruct'

def next_table node
  n = node
  loop do
    n = n.next_element
    break if n.matches? "table"
  end
  n
end

def treat elem, f
  header = elem.css("th").map{|h|h.text.strip}
  stats  = elem.css("tr").map{|td|f.call(td)}[1..-1]
  stats.map{|stat|Hash[*header.zip(stat).flatten]}
end

before do
  # 『デスマコロシアム』問題の参加状況集計記事URL
  @urls = {
    12 => "http://tbpgr.hatenablog.com/entry/2015/07/26/030211",
    11 => "http://tbpgr.hatenablog.com/entry/2015/05/10/224026",
    10 => "http://tbpgr.hatenablog.com/entry/2015/01/25/043826",
     9 => "http://tbpgr.hatenablog.com/entry/20141223/1419335771",
     8 => "http://tbpgr.hatenablog.com/entry/20141129/1417276802",
     7 => "http://tbpgr.hatenablog.com/entry/20140906/1410014268",
     6 => "http://tbpgr.hatenablog.com/entry/20140726/1406388500",
     5 => "http://tbpgr.hatenablog.com/entry/20140615/1402853082",
     4 => "http://tbpgr.hatenablog.com/entry/20140525/1401011965",
     3 => "http://tbpgr.hatenablog.com/entry/20140429/1398790099",
     2 => "http://tbpgr.hatenablog.com/entry/20140405/1396714344",
  }
  @deathcolo = -> n {
    charset = 'utf-8'
    html = open(@urls[n]){ |f|
      charset = f.charset
      f.read
    }
    doc = Nokogiri::HTML.parse(html, nil, charset)
    title = doc.css("h1.entry-title>a").text.strip
    trap = ":contains('エントリー状況')"
    targets = doc.css("h3#{trap},h5#{trap}")
    data = targets.map { |t|
      # 集計日
      date = t.text.split("：").last
      # 挑戦者数 正解者数 不正解者数
      summary = next_table t
      # Total PM TL DB SE PG
      members = next_table summary
      # 言語名 人数 ポイント 最短文字数 平均文字数
      langs = next_table members
      OpenStruct.new({:date => date, :summary => summary, :langs => langs})
    }
    OpenStruct.new({:title => title, :data => data})
  }
end

get '/' do
  min, max = @urls.keys.minmax
  haml :index, :locals => {:min => min, :max => max}
end

get '/stats/:n', :provides => :json do |n|
  dc = @deathcolo[n.to_i]
  res = {:title => dc.title, :dates => [], :summaries => [], :langs => []}
  dc.data.each do |d|
    res[:dates] << d.date
    res[:summaries] << treat(d.summary, -> td {
      td.text.strip.split(/\n/).map{|t|t.gsub(/\(.*\)/,'').rstrip.to_i}
    })
    res[:langs] << treat(d.langs, -> td {
      lang,n,pnt,min,avg = td.text.strip.split /\n/
      [lang,n.to_i,pnt.to_i,min.to_i,avg.to_i]
    })
  end
  JSON.pretty_generate res
end

get '/javascripts/script.js' do
  coffee :script
end
