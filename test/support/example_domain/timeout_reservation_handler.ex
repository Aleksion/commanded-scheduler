defmodule ExampleDomain.TimeoutReservationHandler do
  use Commanded.Event.Handler, name: __MODULE__

  alias Commanded.Scheduler.ScheduleOnce
  alias ExampleDomain.TicketCompositeRouter
  alias ExampleDomain.TicketBooking.Commands.TimeoutReservation
  alias ExampleDomain.TicketBooking.Events.TicketReserved

  def handle(
    %TicketReserved{ticket_uuid: ticket_uuid, expires_at: expires_at},
    _metadata)
  do
    timeout_reservation = %TimeoutReservation{
      ticket_uuid: ticket_uuid
    }

    schedule_once = %ScheduleOnce{
      schedule_uuid: "schedule-" <> ticket_uuid,
      command: timeout_reservation,
      due_at: expires_at,
    }

    TicketCompositeRouter.dispatch(schedule_once)
  end
end
