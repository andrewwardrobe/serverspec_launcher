require 'json'
require 'yaml'

module ReShaper
  def self.deep_set(hash, path, value)
    *path, final_key = path
    to_set = path.empty? ? hash : hash.dig(*path)

    return unless to_set
    to_set[final_key] = to_set[final_key] ? to_set[final_key].merge(value) : value
  end

  def self.transform_data(data)
    new_data = {}
    (data['examples'] || {}).each do |ex|
      tree = []
      ex['context'].push(ex['description']).each do |k|
        tree.push k
        deep_set(new_data, tree, {})
        deep_set(new_data, tree, ex) if tree.length == ex['context'].length
      end
    end
    {"examples" => new_data }.merge(data.reject{ |k,v| k == 'examples' })
  end

  def self.get_report(report_file)
    json = File.read(report_file).gsub(',]', ']').gsub(',}', '}')
    data = JSON.parse(json)
    data
  end

  def self.reshape_report(file)
    report_name = /\/([\w\-:]*)_extended.json/.match(file)[1]
    report = get_report(file)
    data = transform_data report
    outpath = File.dirname file
    File.open("#{outpath}/#{report_name}_reshaped.json", 'w') { |f| f.write data.to_json }
    File.open("#{outpath}/#{report_name}_reshaped.yaml", 'w') { |f| f.write data.to_yaml }
  end
end