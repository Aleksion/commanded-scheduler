defmodule Commanded.Scheduler.RuntimeCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias Commanded.Scheduler.Repo

  setup do
    Application.stop(:commanded_scheduler)
    Application.stop(:commanded)

    {:ok, event_store} = Commanded.EventStore.Adapters.InMemory.start_link()
    reset_database()

    Application.ensure_all_started(:commanded)
    Application.ensure_all_started(:commanded_scheduler)

    on_exit fn ->
      shutdown(event_store)
    end

    :ok
  end

  def shutdown(pid) when is_pid(pid) do
    Process.unlink(pid)
    Process.exit(pid, :shutdown)

    ref = Process.monitor(pid)
    assert_receive {:DOWN, ^ref, _, _, _}, 5_000
  end

  @truncate_tables_statement """
    TRUNCATE TABLE
      projection_versions,
      schedules
    RESTART IDENTITY;
  """

  defp reset_database do
    database_config = Application.get_env(:commanded_scheduler, Repo)

    Application.ensure_all_started(:postgrex)

    with {:ok, conn} <- Postgrex.start_link(database_config) do
      Postgrex.query!(conn, @truncate_tables_statement, [])
    end
  end
end
