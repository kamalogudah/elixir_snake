defmodule ElixirSnake.Scene.Game do
  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives, only: [text: 3]
  import Scenic.Primitives, only: [rrect: 3, text: 3]

  # Constants
  @graph Graph.build(font: :roboto, font_size: 36)
  @tile_size 32
  @snake_starting_size 5
  @tile_radius 8
  @frame_ms 192

  # Initialize the game scene
  def init(_arg, opts) do
    viewport = opts[:viewport]

    # calculate the transform that centers the snake in the viewport
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)
    # how many tiles can the viewport hold in each dimension?
    vp_tile_width = trunc(vp_width / @tile_size)
    vp_tile_height = trunc(vp_height / @tile_size)

    # snake always starts centered
    snake_start_coords = {
      trunc(vp_tile_width / 2),
      trunc(vp_tile_height / 2)
    }

    # start a very simple animation timer
    {:ok, timer} = :timer.send_interval(@frame_ms, :frame)

    # The entire game state will be held here
    state = %{
      viewport: viewport,
      tile_width: vp_tile_width,
      tile_height: vp_tile_height,
      graph: @graph,
      frame_count: 1,
      frame_timer: timer,
      score: 0,
      # Game objects
      objects: %{
        snake: %{body: [snake_start_coords], size: @snake_starting_size, direction: {1, 0}}
      }
    }

    # Update the graph and push it to be rendered
    state.graph
    |> draw_score(state.score)
    |> draw_game_objects(state.objects)
    |> push_graph()

    {:ok, state}
  end

  def handle_info(:frame, %{frame_count: frame_count} = state) do
    state = move_snake(state)

    state.graph |> draw_game_objects(state.objects) |> draw_score(state.score) |> push_graph()

    {:noreply, %{state | frame_count: frame_count + 1}}
  end

  # Keyboard controls
  def handle_input({:key, {"left", :press, _}}, _context, state) do
    {:noreply, update_snake_direction(state, {-1, 0})}
  end

  def handle_input({:key, {"right", :press, _}}, _context, state) do
    {:noreply, update_snake_direction(state, {1, 0})}
  end

  def handle_input({:key, {"up", :press, _}}, _context, state) do
    {:noreply, update_snake_direction(state, {0, -1})}
  end

  def handle_input({:key, {"down", :press, _}}, _context, state) do
    {:noreply, update_snake_direction(state, {0, 1})}
  end

  def handle_input(_input, _context, state), do: {:noreply, state}

  # Change the snake's current direction.
  defp update_snake_direction(state, direction) do
    put_in(state, [:objects, :snake, :direction], direction)
  end

  # Move the snake to its next position according to the direction. Also limits the size.
  defp move_snake(%{objects: %{snake: snake}} = state) do
    [head | _] = snake.body
    new_head_pos = move(state, head, snake.direction)

    new_body = Enum.take([new_head_pos | snake.body], snake.size)

    put_in(state, [:objects, :snake, :body], new_body)
  end

  defp move(%{tile_width: w, tile_height: h}, {pos_x, pos_y}, {vec_x, vec_y}) do
    {rem(pos_x + vec_x + w, w), rem(pos_y + vec_y + h, h)}
  end

  # Iterates over the object map, rendering each object
  defp draw_game_objects(graph, object_map) do
    Enum.reduce(object_map, graph, fn {object_type, object_data}, graph ->
      draw_object(graph, object_type, object_data)
    end)
  end

  # Snake's body is an array of coordinate pairs
  defp draw_object(graph, :snake, %{body: snake}) do
    Enum.reduce(snake, graph, fn {x, y}, graph ->
      draw_tile(graph, x, y, fill: :lime)
    end)
  end

  # Draw tiles as rounded rectangles to look nice
  defp draw_tile(graph, x, y, opts) do
    tile_opts = Keyword.merge([fill: :white, translate: {x * @tile_size, y * @tile_size}], opts)
    graph |> rrect({@tile_size, @tile_size, @tile_radius}, tile_opts)
  end

  # Draw the score HUD
  defp draw_score(graph, score) do
    graph
    |> text("Score: #{score}", fill: :white, translate: {@tile_size, @tile_size})
  end
end
