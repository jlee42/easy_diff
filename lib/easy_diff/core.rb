module EasyDiff
  module Core
    def self.remove_ignored(input_hash, ignore_array)
      if input_hash.is_a?(Hash)
        input_hash.each do |key, value|
          if value.is_a?(Hash)
            remove_ignored(value, ignore_array)
          elsif value.is_a?(Array)
            value.each {|v| remove_ignored(v, ignore_array) }
          else
            input_hash[key] = nil if ignore_array.include?(key)
          end
        end
      else
        input_hash
      end
    end
    
    def self.easy_diff(original, modified, options = {})
      removed = nil
      added   = nil
      
      if options[:ignore]
        remove_ignored(original, options[:ignore])
        remove_ignored(modified, options[:ignore])
      end
      
      if original.nil?
        added = modified.safe_dup 
      elsif modified.nil?
        removed = original.safe_dup 
      elsif original.is_a?(Hash) && modified.is_a?(Hash)
        removed = {}
        added   = {}
        original_keys   = original.keys
        modified_keys   = modified.keys
        keys_in_common  = original_keys & modified_keys
        keys_removed    = original_keys - modified_keys
        keys_added      = modified_keys - original_keys
        keys_removed.each{ |key| removed[key] = original[key].safe_dup }
        keys_added.each{ |key| added[key] = modified[key].safe_dup }
        keys_in_common.each do |key|
          r, a = easy_diff original[key], modified[key]
          removed[key] = r unless r.nil? || r.empty?
          added[key] = a unless a.nil? || a.empty?
        end
      elsif original.is_a?(Array) && modified.is_a?(Array)
        removed = original - modified
        added   = modified - original
      elsif original != modified
        removed   = original
        added     = modified
      end
      if removed.respond_to?(:empty?) && removed.empty? && added.respond_to?(:empty?) && added.empty?
        return nil
      else
        return removed, added
      end
    end
  
    def self.easy_unmerge!(original, removed)
      if original.is_a?(Hash) && removed.is_a?(Hash)
        original_keys  = original.keys
        removed_keys   = removed.keys
        keys_in_common = original_keys & removed_keys
        keys_in_common.each{ |key| original.delete(key) if easy_unmerge!(original[key], removed[key]).nil? }
      elsif original.is_a?(Array) && removed.is_a?(Array)
        original.reject!{ |e| removed.include?(e) }
        original.sort!
      elsif original == removed
        original = nil
      end
      original
    end
  
    def self.easy_merge!(original, added)
      if added.nil?
        return original
      elsif original.is_a?(Hash) && added.is_a?(Hash)
        added_keys = added.keys
        added_keys.each{ |key| original[key] = easy_merge!(original[key], added[key])}
      elsif original.is_a?(Array) && added.is_a?(Array)
        original |=  added
        original.sort!
      else
        original = added.safe_dup
      end
      original
    end
    
    def self.easy_clone(original)
      Marshal::load(Marshal.dump(original))
    end
  end
end