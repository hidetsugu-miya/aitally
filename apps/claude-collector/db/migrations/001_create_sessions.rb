# frozen_string_literal: true

class CreateSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :sessions do |t|
      t.string :session_id, null: false
      t.string :project_path, null: false
      t.decimal :cost_usd, precision: 12, scale: 6
      t.bigint :total_input_tokens
      t.bigint :total_output_tokens
      t.bigint :total_cache_creation_input_tokens
      t.bigint :total_cache_read_input_tokens
      t.integer :total_web_search_requests
      t.bigint :duration_ms
      t.bigint :api_duration_ms
      t.integer :lines_added
      t.integer :lines_removed
      t.timestamps
    end

    add_index :sessions, :session_id, unique: true
    add_index :sessions, :project_path
  end
end
