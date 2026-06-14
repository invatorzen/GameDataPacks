# Per-pack manifest generator for GameDataPacks.
#
# Walks every `Gen N/<version>/` folder and writes a `manifest.json` summarising
# what that pack ships. Tools (e.g. PSDK's apply_data_pack.rb) read these
# manifests to know:
#
#   * which dbSymbols a pack contains (per category)
#   * the max id / textId / formTextId values used inside the pack
#   * how many rows each shipped Data/Text/Dialogs CSV has
#
# Pack tooling can then identify "custom" entries reliably (anything in a
# project not present in ANY pack's manifest is project-custom), and renumber
# safely without re-scanning every JSON at runtime.
#
# Usage: from the repo root, `ruby "Manifest tool/generate.rb"`.
#        Or double-click `launch.bat`.

require 'json'
require 'csv'
require 'fileutils'
require 'time'

CATEGORY_DIRS = {
  'pokemon' => 'Data/Studio/pokemon',
  'moves' => 'Data/Studio/moves',
  'items' => 'Data/Studio/items',
  'abilities' => 'Data/Studio/abilities',
  'types' => 'Data/Studio/types'
}.freeze

REPO_ROOT = File.expand_path('..', __dir__)

# Returns a human-readable UTC timestamp, e.g. "June 6, 2026 — 18:04:35 UTC"
def pretty_timestamp
  Time.now.utc.strftime('%B %-d, %Y — %H:%M:%S UTC')
end
SCHEMA_VERSION = 1

# Scans a Data/Studio/<category> folder and returns aggregate stats for the
# manifest entry.
def scan_category(dir)
  result = {
    symbols: [],
    max_id: 0,
    max_text_id: 0,
    max_form_text_id_name: 0,
    max_form_text_id_description: 0
  }
  return result unless Dir.exist?(dir)

  Dir.glob(File.join(dir, '*.json')).each do |path|
    data = JSON.parse(File.read(path))
    sym = data['dbSymbol']
    next unless sym

    result[:symbols] << sym
    result[:max_id] = data['id'].to_i if data['id'].to_i > result[:max_id]
    result[:max_text_id] = data['textId'].to_i if data['textId'].to_i > result[:max_text_id]
    (data['forms'] || []).each do |form|
      ftid = form['formTextId'] || {}
      n = ftid['name'].to_i
      d = ftid['description'].to_i
      result[:max_form_text_id_name] = n if n > result[:max_form_text_id_name]
      result[:max_form_text_id_description] = d if d > result[:max_form_text_id_description]
    end
  rescue JSON::ParserError => e
    warn "  WARN: skipping unparseable #{path}: #{e.message}"
  end

  result[:symbols].sort!
  result
end

# Counts rows in every shipped Data/Text/Dialogs/*.csv. Pack overlay covers
# rows 0..(count - 1) so the merge tool needs the count to pick safe row
# positions for custom entries.
def scan_csv_rows(pack_root)
  rows = {}
  dialogs = File.join(pack_root, 'Data', 'Text', 'Dialogs')
  return rows unless Dir.exist?(dialogs)

  Dir.children(dialogs).sort.each do |fname|
    next unless fname =~ /\A(\d+)\.csv\z/i

    rows[Regexp.last_match(1)] = CSV.read(File.join(dialogs, fname)).length
  end
  rows
end

def build_pack_manifest(pack_root, gen, version)
  categories = {}
  CATEGORY_DIRS.each do |cat, rel|
    info = scan_category(File.join(pack_root, rel))
    entry = {
      'data_dir' => rel,
      'count' => info[:symbols].size,
      'max_id' => info[:max_id],
      'symbols' => info[:symbols]
    }
    entry['max_text_id'] = info[:max_text_id] if %w[abilities types].include?(cat)
    if cat == 'pokemon'
      entry['max_form_text_id_name'] = info[:max_form_text_id_name]
      entry['max_form_text_id_description'] = info[:max_form_text_id_description]
    end
    categories[cat] = entry
  end

  {
    'schema_version' => SCHEMA_VERSION,
    'generated_at' => pretty_timestamp,
    'gen' => gen,
    'version' => version,
    'categories' => categories,
    'csv_rows' => scan_csv_rows(pack_root)
  }
end

# Top-level summary: union of every pack's symbols per category, plus a list
# of every pack and the path to its manifest. Lets tools detect custom entries
# without having to load every per-pack manifest individually.
def build_index(per_pack)
  union = CATEGORY_DIRS.keys.each_with_object({}) { |cat, h| h[cat] = [] }
  packs = []

  per_pack.each do |gen, version, manifest, rel_path|
    packs << { 'gen' => gen, 'version' => version, 'manifest' => rel_path }
    manifest['categories'].each do |cat, entry|
      union[cat].concat(entry['symbols']) if union.key?(cat)
    end
  end

  union.each_value(&:uniq!)
  union.each_value(&:sort!)

  {
    'schema_version' => SCHEMA_VERSION,
    'generated_at' => pretty_timestamp,
    'packs' => packs,
    'official_symbols' => union
  }
end

def write_json(path, data)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, "#{JSON.pretty_generate(data)}\n")
end

def main
  per_pack = []

  Dir.children(REPO_ROOT).select { |c| c.match?(/\AGen \d+\z/) }.sort.each do |gen_name|
    gen = gen_name.match(/\AGen (\d+)\z/)[1].to_i
    gen_dir = File.join(REPO_ROOT, gen_name)

    Dir.children(gen_dir).sort.each do |version|
      pack_root = File.join(gen_dir, version)
      next unless File.directory?(pack_root)

      puts "Generating manifest for Gen #{gen} / #{version} ..."
      manifest = build_pack_manifest(pack_root, gen, version)
      out_path = File.join(pack_root, 'manifest.json')
      write_json(out_path, manifest)

      rel = out_path.sub("#{REPO_ROOT}/", '').tr('\\', '/')
      per_pack << [gen, version, manifest, rel]
    end
  end

  index_path = File.join(REPO_ROOT, 'Manifest tool', 'manifests.json')
  puts "\nGenerating top-level index at #{index_path} ..."
  write_json(index_path, build_index(per_pack))

  puts "\nDone. Wrote #{per_pack.size} pack manifests and the index."
end

main if __FILE__ == $PROGRAM_NAME
