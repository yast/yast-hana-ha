# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2016 SUSE Linux GmbH, Nuernberg, Germany.
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact SUSE Linux GmbH.
#
# ------------------------------------------------------------------------------
#
# Summary: SUSE High Availability Setup for SAP Products: common routines
# Authors: Ilya Manyugin <ilya.manyugin@suse.com>

require 'erb'
require 'tmpdir'
require 'sap_ha/exceptions'

module SapHA
  # Common routines
  class HelpersClass
    include Singleton
    include ERB::Util
    include Yast::Logger
    include Yast::I18n
    include SapHA::Exceptions

    attr_reader :rpc_server_cmd

    def initialize
      @storage = {}
      if ENV['Y2DIR'] # tests/local run
        @data_path = 'data/'
        @var_path = File.join(Dir.tmpdir, 'yast-sap-ha-tmp')
        begin
          Dir.mkdir(@var_path)
        rescue StandardError => e
          log.debug "Cannot create the tmp_dir: #{e.message}"
        end
        @rpc_server_cmd = 'systemd-cat /usr/bin/ruby '\
          '/root/yast-sap-ha/src/lib/sap_ha/rpc_server.rb'
      else # production
        @data_path = '/usr/share/YaST2/data/sap_ha'
        @var_path = '/var/lib/YaST2/sap_ha'
        # /sbin/yast in SLES, /usr/sbin/yast in OpenSuse
        # @rpc_server_cmd = 'yast sap_ha_rpc'
        # TODO: fix it
        @rpc_server_cmd = 'systemd-cat /usr/bin/ruby '\
          '/usr/share/YaST2/lib/sap_ha/rpc_server.rb'
      end
    end

    # Render an ERB template by its name
    def render_template(basename, binding)
      if !@storage.key? basename
        full_path = File.join(@data_path, basename)
        template = ERB.new(read_file(full_path), nil, '-')
        @storage[basename] = template
      end
      begin
        return @storage[basename].result(binding)
      rescue StandardError => e
        log.error("Error while rendering template '#{full_path}': #{e.message}")
        exc = TemplateRenderException.new("Error rendering template.")
        exc.renderer_message = e.message
        raise exc
      end
    end

    # Load the help file by its name
    def load_help(basename)
      file_name = "help_#{basename}.html"
      if !@storage.key? file_name
        full_path = File.join(@data_path, file_name)
        # TODO: apply the CSS
        contents = read_file(full_path)
        @storage[file_name] = contents
      end
      @storage[file_name]
    end

    # Get the path to the file given its name
    def data_file_path(basename)
      File.join(@data_path, basename)
    end

    def var_file_path(basename)
      File.join(@var_path, basename)
    end

    # def program_file_path(basename)
    #   File.join(@yast_path, basename)
    # end

    def write_var_file(basename, data, options = {})
      if options[:timestamp]
        basename = timestamp_file(basename)
      end
      file_path = var_file_path(basename)
      File.open(file_path, 'wb') do |fh|
        fh.write(data)
      end
      file_path
    end

    def write_file(path, data)
      begin
        File.open(path, 'wb') do |fh|
          fh.write(data)
        end
      rescue RuntimeError => e
        log.error "Error writing file #{path}: #{e.message}"
        return false
      end
      true
    end

    def open_url(url)
      require 'yast'
      Yast.import 'UI'
      Yast::UI.BusyCursor
      system("xdg-open #{url}")
      sleep 5
      Yast::UI.NormalCursor
    end

    def timestamp_file(basename)
      ext = File.extname(basename)
      name = File.basename(basename, ext)
      basename = "#{name}_#{Time.now.strftime('%Y%m%d_%H%M%S')}#{ext}"
    end

    private

    # Read file's contents
    def read_file(path)
      File.read(path)
    rescue Errno::ENOENT => e
      log.error("Could not find the file '#{path}': #{e.message}.")
      raise _("Program data could not be found. Please reinstall the package.")
    rescue Errno::EACCES => e
      log.error("Could not access the file '#{path}': #{e.message}.")
      raise _("Program data could not be accessed. Please reinstall the package.")
    end
  end

  Helpers = HelpersClass.instance
end
