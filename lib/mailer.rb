# -*- coding: utf-8 -*-
#
# Copyright 2013 whiteleaf. All rights reserved.
#

require "pony"
require "yaml"
require_relative "narou"

class Mailer
  include Singleton

  SETTING_FILE = "mail_setting.yaml"

  class SettingNotFound < StandardError; end
  class SettingUncompleteError < StandardError; end

  attr_reader :error_message

  def self.create
    this = instance
    this.clear
    setting_file_path = File.join(Narou.get_root_dir, SETTING_FILE)
    if File.exists?(setting_file_path)
      options = YAML.load_file(setting_file_path)
      unless options.delete(:complete)
        raise SettingUncompleteError, "設定ファイルの書き換えが終了していないようです。\n" +
                                      "設定ファイルは #{setting_file_path} にあります"
      end
      this.options = options
    else
      raise SettingNotFound
    end
    this
  end

  def initialize
    @options = {}
    @error_message = ""
  end

  def clear
    @options.clear
  end

  def options=(options)
    @options.merge!(options)
  end

  def send(message, attached_file_path = nil)
    @error_message = ""
    params = @options.dup
    params[:body] = message
    params[:charset] = "UTF-8"
    params[:text_part_charset] = "UTF-8"
    if attached_file_path
      params[:attachments] = { File.basename(attached_file_path) => File.binread(attached_file_path) }
    end
    begin
      Pony.mail(params)
    rescue StandardError => e
      @error_message = e.message
      return false
    end
    true
  end
end