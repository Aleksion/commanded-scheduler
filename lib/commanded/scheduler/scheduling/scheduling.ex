defmodule Commanded.Scheduler.Scheduling do
  @moduledoc false

  use Commanded.Event.Handler,
    name: "Commanded.Scheduler.Scheduling"

  require Logger

  alias Commanded.Scheduler
  alias Commanded.Scheduler.{
    Dispatcher,
    Repo,
    ScheduleElapsed,
    ScheduledOnce,
    TriggerSchedule,
  }
  alias Commanded.Scheduler.Projection.Schedule

  @doc """
  Reschedule all existing schedules on start.
  """
  def init do
    for schedule <- Repo.all(Schedule) do
      schedule_once(schedule.schedule_uuid, schedule.due_at)
    end

    :ok
  end

  def handle(%ScheduledOnce{schedule_uuid: schedule_uuid, due_at: due_at}, _metadata) do
    schedule_once(schedule_uuid, due_at)
  end

  def handle(%ScheduleElapsed{command: command}, _metadata) do
    Logger.debug(fn -> "Attempting to dispatch scheduled command: #{inspect command}" end)

    router().dispatch(command)
  end

  defp schedule_once(schedule_uuid, due_at) do
    trigger_schedule = %TriggerSchedule{schedule_uuid: schedule_uuid}

    Scheduler.schedule_once(schedule_uuid, Dispatcher, trigger_schedule, due_at)
  end

  def router do
    Application.get_env(:commanded_scheduler, :router) ||
      raise "Commanded scheduler expects `:router` to be defined in config"
  end
end
