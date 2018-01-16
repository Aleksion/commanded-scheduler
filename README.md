# Commanded scheduler

One-off and recurring command scheduler for [Commanded](https://github.com/commanded/commanded) CQRS/ES applications using [Ecto](https://github.com/elixir-ecto/ecto) for persistence.

Commands can be scheduled in one of two ways:

- Using the `Commanded.Scheduler` module as described in the [Example usage](#example-usage) section.
- By [dispatching a scheduled command](#dispatch-scheduled-command) using your app's router or from within a process manager.

This library is under active development.

---

MIT License

[![Build Status](https://travis-ci.org/commanded/commanded-scheduler.svg?branch=master)](https://travis-ci.org/commanded/commanded-scheduler)

---

## Example usage

### Schedule a one-off command

Schedule a uniquely identified one-off job using the given command to dispatch at the specified date/time.

#### Example

```elixir
Scheduler.schedule_once(reservation_id, %TimeoutReservation{..}, ~N[2020-01-01 12:00:00])
```

Name the scheduled job:

```elixir
Scheduler.schedule_once(reservation_id, %TimeoutReservation{..}, due_at, name: "timeout")
```

### Schedule a recurring command

Schedule a uniquely identified recurring job using the given command to dispatch repeatedly on the given schedule.

Schedule supports the cron format where the minute, hour, day of month, month, and day of week (0 - 6, Sunday to Saturday) are specified. An example crontab schedule is "45 23 * * 6". It would trigger at 23:45 (11:45 PM) every Saturday.

For more details please refer to https://en.wikipedia.org/wiki/Cron.

#### Example

Schedule a job to run every 15 minutes:

```elixir
Scheduler.schedule_recurring(reservation_id, %TimeoutReservation{..}, "*/15 * * * *")
```

Name the recurring job that runs every day at midnight:

```elixir
Scheduler.schedule_recurring(reservation_id, %TimeoutReservation{..}, "@daily", name: "timeout")
```

## Schedule multiple one-off or recurring commands in a single batch

This guarantees that all, or none, of the commands are scheduled.

#### Example

```elixir
Scheduler.batch(reservation_id, fn batch ->
  batch
  |> Scheduler.schedule_once(%TimeoutReservation{..}, timeout_due_at, name: "timeout")
  |> Scheduler.schedule_once(%ReleaseSeat{..}, release_due_at, name: "release")
end)
```

## Dispatch scheduled command

You can dispatch a scheduled command by defining a composite Commanded router for your application and including the `Commanded.Scheduler.Router`:

```elixir
defmodule AppRouter do
  @moduledoc false

  use Commanded.Commands.CompositeRouter

  router ExampleDomain.TicketRouter
  router Commanded.Scheduler.Router
end
```

Then you can dispatch a `Commanded.Scheduler.ScheduleOnce`, `Commanded.Scheduler.ScheduleRecurring`, or `Commanded.Scheduler.ScheduleBatch` command, including the command to be executed later:

```elixir
timeout_reservation = %TimeoutReservation{
  ticket_uuid: ticket_uuid
}

schedule_once = %ScheduleOnce{
  schedule_uuid: ticket_uuid,
  command: timeout_reservation,
  due_at: expires_at,
}

AppRouter.dispatch(schedule_once)
```

This approach allows you to dispatch a command from within a process manager:

```elixir
defmodule TicketProcessManager do
  use Commanded.ProcessManagers.ProcessManager,
    name: "TicketProcessManager",
    router: AppRouter

  defstruct [:ticket_uuid]

  def interested?(%TicketReserved{ticket_uuid: ticket_uuid}),
    do: {:start, ticket_uuid}

  def handle(
    %TicketProcessManager{},
    %TicketReserved{ticket_uuid: ticket_uuid, expires_at: expires_at})
  do
    %ScheduleOnce{
      schedule_uuid: ticket_uuid,
      command: %TimeoutReservation{ticket_uuid: ticket_uuid},
      due_at: expires_at
    }
  end
end
```
