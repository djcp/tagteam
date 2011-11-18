class FeedRetrieval < ActiveRecord::Base
  belongs_to :feed
  has_and_belongs_to_many :feed_items 

  scope :successful, where(['success is true'])

  after_save :update_feed_updated_at
  attr_accessor :changelog_summary_cache

  def update_feed_updated_at
    self.feed.updated_at = DateTime.now
    self.feed.save
  end

  def parsed_changelog
    return nil if changelog.nil?
    YAML.load(self.changelog)
  end

  def new_feed_items
    self.changelog_summary[:new_records]
  end

  def changed_feed_items
    self.changelog_summary[:changed_records]
  end

  def has_changes?
    return (new_feed_items.blank? && changed_feed_items.blank?) ? false : true
  end

  def changelog_summary

    return self.changelog_summary_cache unless self.changelog_summary_cache.nil?

    changelog_yaml = self.parsed_changelog
    changes = {
      :new_records => [],
      :changed_records => []
    }

    return changes if changelog_yaml.nil?

    changelog_yaml.keys.each do|ch|
      if changelog_yaml[ch].include?(:new_record)
        changes[:new_records] << ch
      else
        # Something happened to this item
        # FIXME
        changed_fields = [ch]
        changelog_yaml[ch].keys.each do|change|
         changed_fields << change.to_s.titleize
        end
        changes[:changed_records] << changed_fields
      end
    end
    self.changelog_summary_cache = changes
    return changes
  end

end
