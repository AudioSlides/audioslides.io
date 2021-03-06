defmodule PlatformWeb.SlideController do
  use PlatformWeb, :controller

  alias Platform.Core
  alias Platform.VideoProcessing

  def show(conn, %{"lesson_id" => lesson_id, "id" => slide_id}) do
    lesson =
      lesson_id
      |> Core.get_lesson_with_slides!()
      |> authorize_action!(conn)

    slide =
      slide_id
      |> Core.get_slide!()
      |> authorize_action!(conn)

    render(conn, "show.html", lesson: lesson, slide: slide)
  end

  def edit(conn, %{"lesson_id" => lesson_id, "id" => slide_id}) do
    lesson =
      lesson_id
      |> Core.get_lesson_with_slides!()

    slide =
      slide_id
      |> Core.get_slide!()
      |> authorize_action!(conn)

    changeset = Core.change_slide(lesson, slide)

    render(conn, "edit.html", lesson: lesson, slide: slide, changeset: changeset)
  end

  @slide_api Application.get_env(:platform, Platform.SlideAPI, [])[:adapter]
  def update(conn, %{"lesson_id" => lesson_id, "id" => slide_id, "slide" => slide_params}) do
    lesson =
      lesson_id
      |> Core.get_lesson_with_slides!()

    slide =
      slide_id
      |> Core.get_slide!()
      |> authorize_action!(conn)

    case Core.update_slide(slide, slide_params) do
      {:ok, slide} ->
        @slide_api.update_speaker_notes!(lesson.google_presentation_id, slide.google_object_id, slide.speaker_notes)

        conn
        |> put_flash(:info, "Slide updated successfully.")
        |> redirect(to: lesson_slide_path(conn, :show, lesson, slide))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", lesson: lesson, slide: slide, changeset: changeset)
    end
  end

  def generate_video(conn, %{"lesson_id" => lesson_id, "id" => slide_id}) do
    lesson =
      lesson_id
      |> Core.get_lesson!()
      |> authorize_action!(conn)

    slide =
      slide_id
      |> Core.get_slide!()
      |> authorize_action!(conn)

    VideoProcessing.generate_video_for_slide(lesson, slide)

    conn
    |> put_flash(:info, "Thumb downloaded successfully.")
    |> redirect(to: lesson_slide_path(conn, :show, lesson, slide_id))
  end
end
