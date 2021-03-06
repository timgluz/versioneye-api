require 'htmlentities'

module ProductHelpers


  def parse_query(query)
      query = query.to_s
      query = query.strip().downcase
      query.gsub!(/\%/, "")
      query
  end


  def get_language_param(lang)
    lang = lang.to_s
    lang = "," if lang.empty?
    lang
  end


  def get_language_array(lang)
    languages = []
    special_languages = {
      "php" => "PHP",
      "node.js" =>  "Node.JS",
      "nodejs" => "Node.JS"
    }

    langs = lang.split(",")
    langs.each do |language|
      language.to_s.strip.downcase!
      if language.length > 0
        if special_languages.has_key?(language)
          languages << special_languages[language]
        else
          languages << language.capitalize!
        end
      end

      languages
    end
  end


  def parse_language(lang)
    special_languages = {
      "php" => "PHP",
      "node.js" =>  "Node.JS",
      "nodejs" => "Node.JS",
      "javascript" => "JavaScript"
    }

    parsed_lang = lang.downcase

    if special_languages.has_key?(parsed_lang)
      parsed_lang = special_languages[parsed_lang]
    else
      parsed_lang = parsed_lang.capitalize
    end

    if parsed_lang.to_s.empty?
      error! "Language `#{lang}`is not correct."
    end

    parsed_lang
  end


  def encode_prod_key(prod_key)
    encoded_key = prod_key.to_s.gsub("/", ":").gsub(".", "~")
    HTMLEntities.new.encode(encoded_key, :named)
  end


  def decode_prod_key(prod_key)
    parsed_key = HTMLEntities.new.decode prod_key
    parsed_key = parsed_key.to_s.gsub(":", "/")
    parsed_key.gsub("~", ".")
  end


  def fetch_product(lang, prod_key)
    lang = parse_language(lang)
    prod_key = decode_prod_key(prod_key)
    current_product = Product.fetch_product(lang, prod_key)
    current_product = Product.fetch_bower( prod_key ) if current_product.nil?
    if current_product.nil?
      error! "Zero results for prod_key `#{params[:prod_key]}`", 404
    else
      current_product.version = VersionService.newest_version_from( current_product.versions )
    end
    current_product
  end


end
