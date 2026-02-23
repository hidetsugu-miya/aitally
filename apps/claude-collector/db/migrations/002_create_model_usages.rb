# frozen_string_literal: true

class CreateModelUsages < ActiveRecord::Migration[8.0]
  def change
    create_table :model_usages do |t|
      t.references :session, null: false, foreign_key: true
      t.string :model_id, null: false
      t.bigint :input_tokens
      t.bigint :output_tokens
      t.bigint :cache_read_input_tokens
      t.bigint :cache_creation_input_tokens
      t.integer :web_search_requests
      t.decimal :cost_usd, precision: 12, scale: 6
      t.timestamps
    end

    add_index :model_usages, [:session_id, :model_id], unique: true
  end
end
