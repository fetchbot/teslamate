defmodule TeslaMateWeb.ChargeLive.Cost do
  use Phoenix.LiveView

  require Logger

  alias TeslaMateWeb.ChargeView
  alias TeslaMateWeb.Router.Helpers, as: Routes

  alias TeslaMate.Log.ChargingProcess
  alias TeslaMate.Log

  import TeslaMateWeb.Gettext

  @impl true
  def render(assigns), do: ChargeView.render("cost.html", assigns)

  @impl true
  def mount(%{"id" => id}, %{"locale" => locale}, socket) do
    if connected?(socket), do: Gettext.put_locale(locale)

    charging_process = Log.get_charging_process!(id)

    socket =
      socket
      |> assign(notification: nil)
      |> assign_charging_process(charging_process)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    referrer =
      case {get_connect_params(socket)["referrer"], uri} do
        {uri, uri} -> nil
        {"", _uri} -> nil
        {referrer, _} when is_binary(referrer) -> referrer
        _ -> nil
      end

    {:noreply, assign(socket, redirect_to: referrer || Routes.car_path(socket, :index))}
  end

  @impl true
  def handle_event("save", %{"charging_process" => params}, socket) do
    case Log.update_charging_process(socket.assigns.charging_process, params) do
      {:ok, charging_process} ->
        notification = create_notification(:success, gettext("Saved!"))

        socket =
          socket
          |> assign(notification: notification)
          |> assign_charging_process(charging_process)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_info({:remove_notification, id}, %{assigns: %{notification: %{id: id}}} = socket) do
    {:noreply, assign(socket, notification: nil)}
  end

  def handle_info({:remove_notification, _id}, socket) do
    {:noreply, socket}
  end

  # Private

  defp assign_charging_process(socket, %ChargingProcess{} = c) do
    assign(socket, charging_process: c, changeset: ChargingProcess.changeset(c, %{}))
  end

  defp create_notification(key, msg) do
    id = make_ref()
    Process.send_after(self(), {:remove_notification, id}, 2500)
    %{id: id, message: msg, key: key}
  end
end