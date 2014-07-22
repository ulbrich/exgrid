defmodule ExGrid.Bounces do
  use Timex
  alias ExGrid.HTTPHandler

  @doc """
  get bounces
  """
  def get(credentials) do
    {code, body} = HTTPHandler.get(credentials, build_url("bounces", "get", credentials))
  end

  @doc """
  get bounces with optional parameters
  
  * see [sendgrid api docs](https://sendgrid.com/docs/API_Reference/Web_API/bounces.html)

  * note for `start_date` and `end_date` they must be in `YYYY-M-D` string format

  ### Example:\r\n
  iex> ExGrid.Bounces.get(credentials, %{start_date: "2014-7-10", end_date: "2014-7-20"})\r\n
  iex> ExGrid.Bounces.get(credentials, %{date: "1"})\r\n
  iex> ExGrid.Bounces.get(credentials, %{date: 1, limit: 1})\r\n
  
  """
  def get(credentials, %{start_date: start_date, end_date: end_date}) do
    {:ok, sdate, _} = create_date_object(start_date)
    {:ok, edate, _} = create_date_object(end_date)
    result = comapre_dates(sdate, edate)
    case result do
      1 ->
        {code, body} = HTTPHandler.get(credentials, build_url("bounces", "get", Map.merge(credentials, %{start_date: start_date, end_date: end_date})))
      0 ->
        {:error, "Dates are the same"}
      -1 ->
        {:error, "Start date is older than end date"}   
    end   
  end

  def get(credentials, %{start_date: start_date}=sdate) do
    cond do
      {:ok, start_date, ""} = create_date_object(sdate.start_date) ->
        {code, body} = HTTPHandler.get(credentials, build_url("bounces", "get", Map.merge(credentials, sdate)))
      {:error, start_date, "" } ==  create_date_object(sdate.start_date) ->
        {:error, "Start date is older than end date"}   
    end 
  end

  def get(credentials, optional_parameters) when is_map(optional_parameters) do
    {code, body} = HTTPHandler.get(credentials, build_url("bounces", "get", Map.merge(credentials, optional_parameters)))
  end

  def remove(credentials, optional_parameters) when is_map(optional_parameters) do
    {code, body} = HTTPHandler.post(credentials, build_url("bounces", "delete"), build_form_data(credentials, optional_parameters))
  end

  defp build_form_data(creds, message) do
    full_message = Map.merge(creds, message)
    Enum.map(Map.to_list(full_message), fn {k,v} -> ("#{k}=#{v}") end ) |>
    Enum.join("&")
  end

  defp build_form_data(creds) do
    Enum.map(Map.to_list(creds), fn {k,v} -> ("#{k}=#{v}") end ) |>
    Enum.join("&")
  end

  
  defp build_url(context, verb) do
    "https://api.sendgrid.com/api/" <> context <> "." <> verb <> ".json?"
  end

  defp build_url(context, verb, query_params) do
    "https://api.sendgrid.com/api/" <> context <> "." <> verb <> ".json?" <> build_form_data(query_params)
  end

  # uses YYYY-M-D format by defaault
  defp create_date_object(date, format \\ "{YYYY}-{M}-{D}") do
    {:ok, sdate, ""} = DateFormat.parse(date, format)
  end

  #`1` == start date is before end date
  #`0` == dates are the same
  #`-1` == start date is 
  defp comapre_dates(first_date, second_date) do
    Date.compare(first_date, second_date)
  end
end
