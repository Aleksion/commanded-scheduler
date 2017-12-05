defmodule Commanded.Scheduling.ProjectionTest do
  use Commanded.Scheduler.RuntimeCase

  import Commanded.Scheduler.Factory

  alias Commanded.Helpers.Wait
  alias Commanded.Scheduler.Projection.Schedule
  alias Commanded.Scheduler.Repo

  describe "schedule once" do
    setup [:schedule_once]

    test "should persist scheduled job", context do
      {:ok, schedule} = get_schedule(context.schedule_uuid)

      assert schedule.command == %{
        "ticket_uuid" => context.ticket_uuid,
      }
      assert schedule.command_type == "Elixir.ExampleDomain.TicketBooking.Commands.TimeoutReservation"
      assert schedule.due_at == context.due_at
    end
  end

  describe "schedule once triggered" do
    setup [:reserve_ticket, :schedule_once, :trigger_schedule]

    test "should delete persisted job schedule", context do
      Wait.until(fn ->
        case Repo.get(Schedule, context.schedule_uuid) do
          nil -> :ok
          _schedule -> flunk("Schedule #{inspect context.schedule_uuid} exists")
        end
      end)
    end
  end

  defp get_schedule(schedule_uuid) do
    Wait.until(fn ->
      case Repo.get(Schedule, schedule_uuid) do
        nil -> flunk("Schedule #{inspect schedule_uuid} does not exist")
        schedule -> {:ok, schedule}
      end
    end)
  end
end
