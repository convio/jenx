#############################
# From Why's Pognant Guide
#############################
class Object
  def meta_class
    class << self
      self
    end
  end

  def meta_eval &blk
    meta_class.instance_eval &blk
  end

  # Adds methods to a metaclass
  def meta_def name, &blk
    meta_eval { define_method name, &blk }
  end

  # Defines an instance method within a class
  def class_def name, &blk
    class_eval { define_method name, &blk }
  end
end

module CIComm
  class Jenkins
    class << self
      def get_resource(url, username=nil, password=nil)
        url = url + ("/") unless url =~ /\/$/
        case url
          when /job\/.*?\/\d+\/$/
            CIComm::Jenkins::Build.new(url, username, password)
          when /job\/.*?\/$/
            CIComm::Jenkins::Job.new(url, username, password)
          when /view\/.*?\/$/
            CIComm::Jenkins::View.new(url, username, password)
          else
            raise "uh, dude, I don't know what to do with #{url}"
        end
      end
    end
    COLORS = %w[red red_anime blue_anime yellow_anime grey_anime aborted disabled unstable]
    attr_accessor :url
    attr_reader :data
    # @param [String] url
    def initialize(url, username = nil, password = nil)
      url = url + ("/") unless url =~ /\/$/
      @url      = url.to_s + "api/json"
      @username = username
      @password = password
      fetch
    end

    def fetch
      response = ::RestClient::Resource.new(URI.escape(url),
                                            :user => @username,
                                            :password => @password,
                                            :headers  => {:accept => :json, :content_type => :json}).get
      if @url[/config\.xml/]
        @data = Nokogiri.XML(response)
        define_config_methods
      else
        @data = JSON.parse(response)
        define_methods
      end

    end

    def define_config_methods
      [:svn_location, :schedule, :rake_targets].each do |method|
        meta_def method do
          case method
            when :svn_location
              @data.xpath("//hudson.scm.SubversionSCM_-ModuleLocation/remote").inner_text
            when :schedule
              @data.xpath("//hudson.triggers.TimerTrigger/spec").inner_text
            when :rake_targets
              @data.xpath("//hudson.plugins.rake.Rake/tasks").inner_text
          end
        end
      end
    end

    def define_methods
      @data.keys.each do |key|
        meta_def key.underscore.to_sym do
          if key == "timestamp"
            Time.at(@data[key]/1000)
          else
            structify(@data[key])
          end
        end
      end
    end

    def structify(thing)
      if thing.is_a?(Array)
        thing.map do |element|
          structify element
        end
      elsif thing.is_a?(Hash)
        replacement_hash = {}
        thing.each_pair do |key, value|
          if key == "timestamp"
            replacement_hash[key.underscore.to_sym] = (Time.at(value/1000))
          else
            replacement_hash[key.underscore.to_sym] = structify(value)
          end
        end
        ::OpenStruct.new(replacement_hash)
      else
        thing
      end
    end

    class View < CIComm::Jenkins
      # @param [String] url is the URL of the Jenkins View you wish to access, ending with a slash character
      def initialize(arg, username=nil, password=nil)
        super
        #if arg.kind_of?(String)
        #  super
        #elsif arg.kind_of?(Hash)
        #  @data = arg
        #  @url  = url
        #else
        #  raise "cannot create a #{self.class.to_s} from argument"
        #end
      end

      def has_views?
        self.respond_to?(:views)
      end

      def has_jobs?
        self.respond_to?(:jobs)
      end
    end

    # TODO: complete the Job API with accessor methods to all missing key values
    class Job < CIComm::Jenkins
      # @param [Object]
      def initialize(arg, username=nil, password=nil)
        if arg.kind_of?(String)
          super(arg, username, password)
        elsif arg.kind_of?(Hash)
          @data = arg
          @url  = url
        else
          raise "cannot create a #{self.class.to_s} from argument"
        end
      end

      # return [String] returns the build stability message of the Job
      def stability
        health_report.first.description.split(": ").last
      end

      # return [Integer] returns the score of the Job's health
      def score
        health_report.first.score
      end
    end

    class Build < CIComm::Jenkins
      def initialize(arg, username, password)
        if arg.kind_of?(String)
          super(arg, username, password)
        elsif arg.kind_of?(Hash)
          @data = arg
          @url  = url
        else
          raise "cannot create a #{self.class.to_s} from argument"
        end
      end
    end

    class Config < CIComm::Jenkins
      def initialize(url, username, password)
        super url, username, password
      end
    end

    class ChangeSet
      # @param [Hash] arg
      def initialize(arg)
        @data  = arg
        @items = @data["items"]
      end

      # @param [Array] Returns an Array of Item objects
      def items
        result = []
        @items.each do |i|
          result << Item.new(i)
        end
        result
      end

      class Item
        # @param [Hash] arg
        def initialize(arg)
          @data = arg
        end

        # @return [Array] of paths affected
        def affected_paths
          @data["affectedPaths"]
        end

        # @return [String] url to author's page
        def author_url
          author = @data["author"]
          author["absoluteUrl"]
        end

        # @return [String] full name of author
        def author_full_name
          author = @data["author"]
          author["fullName"]
        end

        # @return [Integer] the commit id
        def commit_id
          @data["commitId"].to_i
        end

        # @return [String] the commit message
        def message
          @data["msg"]
        end

        # @return [String] the commit timestamp
        def timestamp
          @data["timestamp"]
        end

        # @return [String] the date of the commit
        def date
          @data["date"]
        end

        def paths
          result = []
          @data["paths"].each do |p|
            result << Path.new(p)
          end
          result
        end

        class Path
          # @param [Hash] arg
          def initialize(arg)
            @data = arg
          end

          # @return [String]
          def edit_type
            @data["editType"]
          end

          # @return [String] path of the edited file
          def file
            @data["file"]
          end
        end

        # @return [Integer] revision number
        def revision
          @data["revision"].to_i
        end

        # @return [String] user name
        def user
          @data["user"]
        end
      end
    end
  end
end