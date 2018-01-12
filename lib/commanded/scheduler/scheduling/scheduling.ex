defmodule Commanded.Scheduler.Scheduling do
  @moduledoc false

  use Commanded.Event.Handler, name: "Commanded.Scheduler.Scheduling"

  require Logger

  alias Commanded.Scheduler.{
    Dispatcher,
    Jobs,
    Repo,
    ScheduledOnce,
    ScheduleTriggered,
    TriggerSchedule
  }

  alias Commanded.Scheduler.Projection.Schedule

  @doc """
  Reschedule all existing schedules on start.
  """
  def init do
    for schedule <- Repo.all(Schedule) do
      %Schedule{
        schedule_uuid: schedule_uuid,
        name: name,
        due_at: due_at,
      } = schedule

      schedule_once(schedule_uuid, name, due_at)
    end

    :ok
  end

  @doc """
  Schedule the command to be triggered at the given due date/time.
  """
  def handle(%ScheduledOnce{} = event, _metadata) do
    %ScheduledOnce{
      schedule_uuid: schedule_uuid,
      name: name,
      command: command,
      due_at: due_at
    } = event

    Logger.debug(fn -> "Scheduling command #{inspect(command)} once at: #{inspect(due_at)}" end)

    case schedule_once(schedule_uuid, name, due_at) do
      :ok -> :ok
      {:error, :already_scheduled} -> :ok
    end
  end

  @doc """
  Execute the command using the configured router when triggered at its
  scheduled date/time.
  """
  def handle(%ScheduleTriggered{command: command}, metadata) do
    %{
      correlation_id: correlation_id,
      event_id: event_id
    } = metadata

    Logger.debug(fn -> "Attempting to dispatch scheduled command: #{inspect(command)}" end)

    router().dispatch(command, causation_id: event_id, correlation_id: correlation_id)
  end

  defp schedule_once(schedule_uuid, name, due_at) do
    trigger_schedule = %TriggerSchedule{schedule_uuid: schedule_uuid, name: name}

    Jobs.schedule_once({schedule_uuid, name}, Dispatcher, trigger_schedule, due_at)
  end

  defp router do
    Application.get_env(:commanded_scheduler, :router) ||
      raise "Commanded scheduler expects `:router` to be defined in config"
  end
end
