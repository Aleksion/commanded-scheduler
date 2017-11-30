defmodule Commanded.Scheduler.Repo.Migrations.AddScheduleTable do
  use Ecto.Migration

  def change do
    create table(:schedules, primary_key: false) do
      add :schedule_uuid, :text, primary_key: true
      add :cancellation_token, :text
      add :command, :map
      add :command_type, :text
      add :due_at, :naive_datetime
      add :schedule, :text

      timestamps()
    end

    create index(:schedules, [:schedule_uuid, :cancellation_token])
  end
end
