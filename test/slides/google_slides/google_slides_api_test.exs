defmodule Platform.GoogleSlidesAPITest do
  @moduledoc """
  Test GoogleSlide functions and mock external API
  """
  use ExUnit.Case

  import Mock

  alias Goth.Token
  alias GoogleApi.Slides.V1.Api.Presentations
  alias GoogleApi.Slides.V1.Connection
  alias FileHelper

  import Platform.GoogleSlidesAPI

  setup_with_mocks [
    {Presentations, [], [
      slides_presentations_get: fn _con, _presentation_id, _opts -> {:ok, %{ }} end,
      slides_presentations_pages_get: fn _con, _presentation_id, _slide_id -> {:ok, %{
        slideProperties: %{ notesPage: %{notesProperties: %{speakerNotesObjectId: "p"}}}
      }} end,
      slides_presentations_pages_get_thumbnail: fn _con, _presentation_id, _slide_id ->
        {:ok, %{contentUrl: "https://some.content/for/you.png"}}
      end,
      slides_presentations_batch_update: fn _con, _presentation_id, _opts -> {:ok, %{}} end
    ]},
    {Connection, [], [new: fn _ -> %{} end]},
    {Token, [], [for_scope: fn _ -> {:ok, %{token: "SUPER_TOKEN"}} end]},
    {FileHelper, [], [write_to_file: fn _, _ -> {:ok, "mock file written"} end]},
    {HTTPoison, [], [get!: fn _url -> %HTTPoison.Response{body: "data"} end]}
  ] do
    {:ok, nothing: "yes"}
  end

  describe "get_presentation" do
    test "should get a presentation via GoogleAPI" do
      get_presentation("1")

      assert called(Presentations.slides_presentations_get(:_, "1", :_))
    end
  end

  describe "get_slide!" do
    test "should get a slide via GoogleAPI" do
      get_slide!("presentation_id", "slide_id")

      assert called(Presentations.slides_presentations_pages_get(:_, "presentation_id", "slide_id"))
    end
  end

  describe "get_slide_thumb!" do
    test "gets a slide via GoogleAPI" do
      get_slide_thumb!("presentation_id", "slide_id")

      assert called(
               Presentations.slides_presentations_pages_get_thumbnail(
                 :_,
                 "presentation_id",
                 "slide_id"
               )
             )
    end
  end

  describe "download_slide_thumb!" do
    test "gets a slide via GoogleAPI" do
      download_slide_thumb!("presentation_id", "slide_id", "file/name/example.png")

      assert called(FileHelper.write_to_file("file/name/example.png", "data"))
    end
  end

  describe "update_speaker_notes!" do
    test "updates a slide via GoogleAPI" do
      update_speaker_notes!("presentation_id", "slide_id", "New speaker notes")

      assert called(
               Presentations.slides_presentations_batch_update(
                 :_,
                 "presentation_id",
                 :_
               )
             )
    end
  end
end
