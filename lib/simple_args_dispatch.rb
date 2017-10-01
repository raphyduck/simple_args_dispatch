require "simple_args_dispatch/version"

@speaker = SimpleSpeaker.new
LINE_SEPARATOR = '---------------------------------------------------------'

module SimpleArgsDispatch

  # Actions will be in the following format:
  #   {
  #       :help => ['Dispatcher', 'show_available'],
  #       :reconfigure => ['App', 'reconfigure'],
  #       :some_name => {
  #           :some_function => ['SomeName', 'SomeFunction'],
  #           .....
  #   }
  # end

  def self.dispatch(app_name, args, actions, parent = nil)
    arg = args.shift
    actions.each do |k, v|
      if arg == k.to_s
        if v.is_a?(Hash)
          self.dispatch(app_name, args, v, "#{parent} #{arg}")
        else
          self.launch(app_name, v, args, "#{parent} #{arg}")
        end
        return
      end
    end
    @speaker.speak_up('Unknown command/option

')
    self.show_available(app_name, actions, parent)
  end

  def self.launch(app_name, action, args, parent)
    args = Hash[args.flat_map { |s| s.scan(/--?([^=\s]+)(?:=(.+))?/) }]
    template_args = Utils.load_template(args['template_name'])
    model = Object.const_get(action[0])
    req_params = model.method(action[1].to_sym).parameters.map { |a| a.reverse! }
    req_params.each do |param|
      return self.show_available(app_name, Hash[req_params.map { |k| ["--#{k[0]}=<#{k[0]}>", k[1]] }], parent, ' ') if param[1] == :keyreq && args[param[0].to_s].nil? && template_args[param[0].to_s].nil?
    end
    $email_msg = nil if args['no_email_notif'].to_i > 0 || template_args['no_email_notif'].to_i > 0
    dameth = model.method(action[1])
    params = Hash[req_params.map { |k, _| [k, args[k.to_s] || template_args[k.to_s]] }].select { |_, v| !v.nil? }
    params.empty? ? dameth.call : dameth.call(params)
  rescue => e
    @speaker.tell_error(e, "Dispatcher.launch")
  end

  def self.show_available(app_name, available, prepend = nil, join='|', separator = LINE_SEPARATOR, extra_info = '')
    @speaker.speak_up("Usage: #{app_name} #{prepend + ' ' if prepend}#{available.map { |k, v| "#{k.to_s}#{'(optional)' if v == :opt}" }.join(join)}")
    if extra_info.to_s != ''
      @speaker.speak_up(separator)
      @speaker.speak_up(extra_info)
    end
  end
end
