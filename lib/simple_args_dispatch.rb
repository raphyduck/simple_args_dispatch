require "simple_args_dispatch/version"
require 'simple_speaker'
require 'yaml'

module SimpleArgsDispatch
  class Agent

    # Actions will be in the following format:
    #   {
    #       :help => ['Dispatcher', 'show_available'],
    #       :reconfigure => ['App', 'reconfigure'],
    #       :some_name => {
    #           :some_function => ['SomeName', 'SomeFunction'],
    #           .....
    #   }
    # end

    def initialize(speaker = nil)
      @speaker = speaker
    end

    def dispatch(app_name, args, actions, parent = nil, template_dir = '')
      arg = args.shift
      actions.each do |k, v|
        if arg == k.to_s
          if v.is_a?(Hash)
            self.dispatch(app_name, args, v, "#{parent} #{arg}", template_dir)
          else
            self.launch(app_name, v, args, "#{parent} #{arg}", template_dir)
          end
          return
        end
      end
      @speaker.speak_up('Unknown command/option

')
      self.show_available(app_name, actions, parent)
    end

    def launch(app_name, action, args, parent, template_dir)
      args = Hash[args.flat_map { |s| s.scan(/--?([^=\s]+)(?:=(.+))?/) }]
      template_args = parse_template_args(load_template(args['template_name'], template_dir), template_dir)
      model = Object.const_get(action[0])
      req_params = model.method(action[1].to_sym).parameters.map { |a| a.reverse! }
      req_params.each do |param|
        return self.show_available(app_name, Hash[req_params.map { |k| ["--#{k[0]}=<#{k[0]}>", k[1]] }], parent, ' ') if param[1] == :keyreq && args[param[0].to_s].nil? && template_args[param[0].to_s].nil?
      end
      $env_flags.each do |k, _|
        Thread.current[k.to_sym] = (args[k] || template_args[k]).to_i
      end
      dameth = model.method(action[1])
      params = Hash[req_params.map do |k, _|
        val = args[k.to_s] || template_args[k.to_s]
        val = eval(val) if val.is_a?(String) && val.match(/^[{\[].*[}\]]$/)
        [k, val]
      end].select { |_, v| !v.nil? }
      @speaker.speak_up("Running with arguments: " + params.map { |a, v| "#{a.to_s}='#{v.to_s}'" }.join(' ')) if $env_flags['debug'] > 0
      params.empty? ? dameth.call : dameth.call(params)
    rescue => e
      @speaker.tell_error(e, "SimpleAgrsDispatch.launch")
    end

    def load_template(template_name, template_dir)
      if template_name.to_s != '' && File.exist?(template_dir + '/' + "#{template_name}.yml")
        return YAML.load_file(template_dir + '/' + "#{template_name}.yml")
      end
      {}
    rescue
      {}
    end

    def new_line
      '---------------------------------------------------------'
    end

    def parse_template_args(template, template_dir)
      template.keys.each do |k|
        if k.to_s == 'load_template'
          template[k] = [template[k]] if template[k].is_a?(String)
          template[k].each do |t|
            template.merge!(parse_template_args(load_template(t.to_s, template_dir), template_dir))
          end
          template.delete(k)
        elsif template[k].is_a?(Hash)
          template[k] = parse_template_args(template[k], template_dir)
        end
      end
      template
    end

    def show_available(app_name, available, prepend = nil, join='|', separator = new_line, extra_info = '')
      @speaker.speak_up("Usage: #{app_name} #{prepend + ' ' if prepend}#{available.map { |k, v| "#{k.to_s}#{'(optional)' if v == :opt}" }.join(join)}")
      if extra_info.to_s != ''
        @speaker.speak_up(separator)
        @speaker.speak_up(extra_info)
      end
    end
  end
end
